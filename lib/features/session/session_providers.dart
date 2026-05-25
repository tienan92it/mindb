import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../data/llm/anthropic_provider.dart';
import '../../data/llm/kimi_provider.dart';
import '../../data/llm/llm_tools.dart';
import '../../data/llm/openai_provider.dart';
import '../../data/persistence/connection_repository.dart';
import '../../data/persistence/settings_repository.dart';
import '../../data/persistence/session_context_repository.dart';
import '../../data/postgres/postgres_database_client.dart';
import '../../domain/ai/ai_agent_orchestrator.dart';
import '../../domain/models/models.dart';
import '../../domain/models/session_context.dart';
import '../../domain/ports/ports.dart';
import '../../domain/query/query_executor.dart';
import '../../domain/safety/safety_policy.dart';
import '../../domain/schema/schema_service.dart';
import '../../domain/session/session_context_builder.dart';
import '../connections/connections_providers.dart';
import 'session_error_mapper.dart';

/// Maps agent tool results to transcript lines (parity with direct `sql:` path).
TranscriptLine transcriptLineForAgentToolResult(AgentToolResultEvent event) {
  if (event.toolName == 'execute_sql' && event.queryResult != null) {
    return ResultLine(event.queryResult!);
  }
  return SystemLine(event.result);
}

/// Transcript lines for a tool result, including executed SQL for `execute_sql`.
List<TranscriptLine> transcriptLinesForAgentToolResult(AgentToolResultEvent event) {
  final lines = <TranscriptLine>[];
  if (event.toolName == 'execute_sql') {
    final sql = event.executedSql?.trim();
    if (sql != null && sql.isNotEmpty) {
      lines.add(SystemLine(sql));
    }
  }
  lines.add(transcriptLineForAgentToolResult(event));
  return lines;
}

/// Whether to show the `tool → …` call marker for this tool name.
bool showAgentToolCallLine(String toolName) => toolName != 'execute_sql';

final sessionContextRepositoryProvider = Provider<SessionContextRepository>((ref) {
  return SessionContextRepository(ref.watch(appDatabaseProvider));
});

final sharedPreferencesProvider = FutureProvider<SharedPreferences>((ref) async {
  return SharedPreferences.getInstance();
});

final settingsRepositoryProvider = FutureProvider<SettingsRepository>((ref) async {
  final prefs = await ref.watch(sharedPreferencesProvider.future);
  return SettingsRepository(prefs);
});

final appSettingsProvider = FutureProvider<AppSettings>((ref) async {
  final repo = await ref.watch(settingsRepositoryProvider.future);
  await repo.migrateIfNeeded();
  return repo.load();
});

class PendingConfirmation {
  const PendingConfirmation({
    required this.sql,
    required this.classification,
  });

  final String sql;
  final SqlClassification classification;
}

class SessionState {
  const SessionState({
    this.lines = const [],
    this.isBusy = false,
    this.isConnected = false,
    this.connectionName,
    this.llmProvider,
    this.llmModel,
    this.error,
    this.errorAction,
    this.pendingConfirmation,
  });

  final List<TranscriptLine> lines;
  final bool isBusy;
  final bool isConnected;
  final String? connectionName;
  final LlmProviderType? llmProvider;
  final String? llmModel;
  final String? error;
  final SessionRecoveryAction? errorAction;
  final PendingConfirmation? pendingConfirmation;

  SessionState copyWith({
    List<TranscriptLine>? lines,
    bool? isBusy,
    bool? isConnected,
    String? connectionName,
    LlmProviderType? llmProvider,
    String? llmModel,
    String? error,
    SessionRecoveryAction? errorAction,
    PendingConfirmation? pendingConfirmation,
    bool clearPendingConfirmation = false,
    bool clearError = false,
  }) {
    return SessionState(
      lines: lines ?? this.lines,
      isBusy: isBusy ?? this.isBusy,
      isConnected: isConnected ?? this.isConnected,
      connectionName: connectionName ?? this.connectionName,
      llmProvider: llmProvider ?? this.llmProvider,
      llmModel: llmModel ?? this.llmModel,
      error: clearError ? null : (error ?? this.error),
      errorAction: clearError ? null : (errorAction ?? this.errorAction),
      pendingConfirmation: clearPendingConfirmation
          ? null
          : pendingConfirmation ?? this.pendingConfirmation,
    );
  }
}

class SessionController extends StateNotifier<SessionState> {
  SessionController(this._ref, this.connectionId) : super(const SessionState()) {
    _connect();
  }

  final Ref _ref;
  final String connectionId;
  Completer<bool>? _confirmationCompleter;

  PostgresDatabaseClient get _client => _ref.read(postgresClientProvider);
  ConnectionRepository get _connectionRepo =>
      _ref.read(connectionRepositoryProvider);

  SchemaService? _schemaService;
  QueryExecutor? _queryExecutor;
  AiAgentOrchestrator? _orchestrator;
  SessionContext? _sessionContext;
  final _contextBuilder = SessionContextBuilder();

  SessionContextRepository get _sessionContextRepo =>
      _ref.read(sessionContextRepositoryProvider);

  Future<void> _connect() async {
    state = state.copyWith(isBusy: true, clearError: true);
    try {
      final profile = await _connectionRepo.getById(connectionId);
      if (profile == null) {
        throw StateError('Connection not found');
      }

      final password = await _connectionRepo.readPassword(connectionId);
      if (password == null || password.isEmpty) {
        throw StateError('Password not stored for this connection');
      }

      await _client.connect(profile, password);
      await _connectionRepo.touchLastUsed(connectionId);
      _ref.invalidate(connectionsListProvider);

      final settings = await _ref.read(appSettingsProvider.future);
      final safetyPolicy = SafetyPolicy(readOnlyMode: settings.readOnlyMode);
      _schemaService = SchemaService(_client);
      _queryExecutor = QueryExecutor(
        client: _client,
        safetyPolicy: safetyPolicy,
        maxRows: settings.maxRows,
        queryTimeout: Duration(seconds: settings.queryTimeoutSeconds),
        confirmationHandler: _handleConfirmation,
      );

      final llm = await _buildLlmProvider(settings);
      _orchestrator = AiAgentOrchestrator(
        llmProvider: llm,
        schemaService: _schemaService!,
        queryExecutor: _queryExecutor!,
      );

      _sessionContext = await _sessionContextRepo.load(connectionId);
      final restoredLines = _contextBuilder.buildTranscriptLines(_sessionContext!);

      state = state.copyWith(
        isBusy: false,
        isConnected: true,
        clearError: true,
        connectionName: profile.name,
        llmProvider: settings.llmProvider,
        llmModel: settings.llmModel,
        lines: [
          SystemLine('Connected to ${profile.name} (${profile.host})'),
          SystemLine(_llmSystemLine(settings)),
          ...restoredLines,
        ],
      );
    } catch (e) {
      final mapped = SessionErrorMapper.map(e);
      state = state.copyWith(
        isBusy: false,
        isConnected: false,
        error: mapped.message,
        errorAction: mapped.action,
        lines: [ErrorLine('Connection failed: ${mapped.message}')],
      );
    }
  }

  Future<LlmProvider> _buildLlmProvider(AppSettings settings) async {
    final store = _ref.read(credentialStoreProvider);
    final apiKey = await store.readLlmApiKey(settings.llmProvider);
    if (apiKey == null || apiKey.isEmpty) {
      throw StateError('LLM API key not configured. Open Settings.');
    }

    switch (settings.llmProvider) {
      case LlmProviderType.openai:
        return OpenAiProvider(apiKey: apiKey, model: settings.llmModel);
      case LlmProviderType.anthropic:
        return AnthropicProvider(apiKey: apiKey, model: settings.llmModel);
      case LlmProviderType.kimi:
        return KimiProvider(apiKey: apiKey, model: settings.llmModel);
    }
  }

  Future<bool> _handleConfirmation(
    String sql,
    SqlClassification classification,
  ) async {
    _confirmationCompleter = Completer<bool>();
    state = state.copyWith(
      pendingConfirmation: PendingConfirmation(
        sql: sql,
        classification: classification,
      ),
    );
    return _confirmationCompleter!.future;
  }

  void resolveConfirmation(bool approved) {
    state = state.copyWith(clearPendingConfirmation: true);
    final completer = _confirmationCompleter;
    _confirmationCompleter = null;
    completer?.complete(approved);
  }

  Future<void> submitPrompt(String prompt) async {
    final trimmed = prompt.trim();
    if (trimmed.isEmpty || state.isBusy) return;

    final orchestrator = _orchestrator;
    final executor = _queryExecutor;
    if (orchestrator == null || executor == null) {
      state = state.copyWith(
        lines: [...state.lines, const ErrorLine('Not connected')],
      );
      return;
    }

    state = state.copyWith(
      isBusy: true,
      lines: [...state.lines, UserLine(trimmed)],
    );

    try {
      if (trimmed.toLowerCase().startsWith('sql:')) {
        final sql = trimmed.substring(4).trim();
        final result = await executor.execute(sql);
        final reply = _formatSqlResult(result);
        await _persistTurns(
          userContent: trimmed,
          assistantContent: reply,
        );
        state = state.copyWith(
          lines: [...state.lines, ResultLine(result), AssistantLine(reply)],
          isBusy: false,
        );
        return;
      }

      final context = _sessionContext!;
      final history = _contextBuilder.buildLlmHistory(context);

      final events = await orchestrator.run(
        userPrompt: trimmed,
        tools: mindbLlmTools,
        history: history,
        sessionSummary:
            context.summary.trim().isEmpty ? null : context.summary.trim(),
      );

      final newLines = <TranscriptLine>[];
      final assistantReply = _contextBuilder.extractAssistantReply(events);
      for (final event in events) {
        switch (event) {
          case AgentToolCallEvent(:final toolName):
            if (showAgentToolCallLine(toolName)) {
              newLines.add(SystemLine('tool → $toolName'));
            }
          case AgentToolResultEvent event:
            newLines.addAll(transcriptLinesForAgentToolResult(event));
          case AgentErrorEvent(:final message):
            newLines.add(ErrorLine(message));
          case AgentTextEvent():
          case AgentDoneEvent():
            break;
        }
      }

      if (assistantReply != null && assistantReply.isNotEmpty) {
        newLines.add(AssistantLine(assistantReply));
        await _persistTurns(
          userContent: trimmed,
          assistantContent: assistantReply,
        );
      }

      state = state.copyWith(
        lines: [...state.lines, ...newLines],
        isBusy: false,
      );
    } catch (e) {
      state = state.copyWith(
        lines: [...state.lines, ErrorLine(e.toString())],
        isBusy: false,
      );
    }
  }

  Future<void> clearSessionContext() async {
    await _sessionContextRepo.delete(connectionId);
    _sessionContext = SessionContext(
      connectionId: connectionId,
      updatedAt: DateTime.now(),
    );
    final name = state.connectionName;
    final provider = state.llmProvider;
    final model = state.llmModel;
    state = state.copyWith(
      lines: [
        if (name != null)
          SystemLine('Connected to $name — session cleared')
        else
          const SystemLine('Session cleared'),
        if (provider != null && model != null)
          SystemLine(_llmSystemLineFor(provider, model)),
      ],
    );
  }

  static String _llmSystemLine(AppSettings settings) {
    return _llmSystemLineFor(settings.llmProvider, settings.llmModel);
  }

  static String _llmSystemLineFor(LlmProviderType provider, String model) {
    return 'llm: ${provider.label} · $model';
  }

  Future<void> _persistTurns({
    required String userContent,
    required String assistantContent,
  }) async {
    var context = _sessionContext!;
    final now = DateTime.now();
    context = _contextBuilder.appendTurn(
      context,
      SessionTurn(role: 'user', content: userContent, createdAt: now),
    );
    context = _contextBuilder.appendTurn(
      context,
      SessionTurn(
        role: 'assistant',
        content: assistantContent,
        createdAt: DateTime.now(),
      ),
    );
    _sessionContext = context;
    await _sessionContextRepo.save(context);
  }

  String _formatSqlResult(QueryResult result) {
    if (result.isSelect) {
      return 'Returned ${result.rows.length} row(s). '
          'Columns: ${result.columns.join(', ')}';
    }
    return 'OK. Rows affected: ${result.rowsAffected ?? 0}';
  }

  Future<void> executeSqlDirect(String sql) async {
    final executor = _queryExecutor;
    if (executor == null) return;

    state = state.copyWith(
      isBusy: true,
      lines: [...state.lines, UserLine('sql: $sql')],
    );
    try {
      final result = await executor.execute(sql);
      final userContent = 'sql: $sql';
      final reply = _formatSqlResult(result);
      await _persistTurns(userContent: userContent, assistantContent: reply);
      state = state.copyWith(
        lines: [...state.lines, ResultLine(result), AssistantLine(reply)],
        isBusy: false,
      );
    } catch (e) {
      state = state.copyWith(
        lines: [...state.lines, ErrorLine(e.toString())],
        isBusy: false,
      );
    }
  }
}

final sessionControllerProvider = StateNotifierProvider.autoDispose
    .family<SessionController, SessionState, String>((ref, connectionId) {
  return SessionController(ref, connectionId);
});

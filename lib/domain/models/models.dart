import 'package:uuid/uuid.dart';

const uuid = Uuid();

enum SqlClassification { safe, write, destructive }

enum LlmProviderType { openai, anthropic, kimi }

extension LlmProviderTypeX on LlmProviderType {
  String get label {
    switch (this) {
      case LlmProviderType.openai:
        return 'OpenAI';
      case LlmProviderType.anthropic:
        return 'Anthropic';
      case LlmProviderType.kimi:
        return 'Kimi';
    }
  }

  String get defaultModel {
    switch (this) {
      case LlmProviderType.openai:
        return 'gpt-4o-mini';
      case LlmProviderType.anthropic:
        return 'claude-3-5-haiku-latest';
      case LlmProviderType.kimi:
        return 'moonshot-v1-8k';
    }
  }

  static LlmProviderType fromName(String name) {
    return LlmProviderType.values.firstWhere(
      (provider) => provider.name == name,
      orElse: () => LlmProviderType.openai,
    );
  }
}

class ConnectionProfile {
  const ConnectionProfile({
    required this.id,
    required this.name,
    required this.host,
    required this.port,
    required this.database,
    required this.username,
    this.useSsl = false,
    this.lastUsedAt,
    required this.createdAt,
  });

  final String id;
  final String name;
  final String host;
  final int port;
  final String database;
  final String username;
  final bool useSsl;
  final DateTime? lastUsedAt;
  final DateTime createdAt;

  ConnectionProfile copyWith({
    String? id,
    String? name,
    String? host,
    int? port,
    String? database,
    String? username,
    bool? useSsl,
    DateTime? lastUsedAt,
    DateTime? createdAt,
  }) {
    return ConnectionProfile(
      id: id ?? this.id,
      name: name ?? this.name,
      host: host ?? this.host,
      port: port ?? this.port,
      database: database ?? this.database,
      username: username ?? this.username,
      useSsl: useSsl ?? this.useSsl,
      lastUsedAt: lastUsedAt ?? this.lastUsedAt,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  static ConnectionProfile create({
    required String name,
    required String host,
    required int port,
    required String database,
    required String username,
    bool useSsl = false,
  }) {
    return ConnectionProfile(
      id: uuid.v4(),
      name: name,
      host: host,
      port: port,
      database: database,
      username: username,
      useSsl: useSsl,
      createdAt: DateTime.now(),
    );
  }
}

class AppSettings {
  const AppSettings({
    this.llmProvider = LlmProviderType.openai,
    this.llmModel = 'gpt-4o-mini',
    this.readOnlyMode = false,
    this.maxRows = 200,
    this.queryTimeoutSeconds = 30,
  });

  final LlmProviderType llmProvider;
  final String llmModel;
  final bool readOnlyMode;
  final int maxRows;
  final int queryTimeoutSeconds;

  AppSettings copyWith({
    LlmProviderType? llmProvider,
    String? llmModel,
    bool? readOnlyMode,
    int? maxRows,
    int? queryTimeoutSeconds,
  }) {
    return AppSettings(
      llmProvider: llmProvider ?? this.llmProvider,
      llmModel: llmModel ?? this.llmModel,
      readOnlyMode: readOnlyMode ?? this.readOnlyMode,
      maxRows: maxRows ?? this.maxRows,
      queryTimeoutSeconds: queryTimeoutSeconds ?? this.queryTimeoutSeconds,
    );
  }
}

class QueryResult {
  const QueryResult({
    required this.columns,
    required this.rows,
    this.rowsAffected,
    required this.duration,
    this.sql,
    this.rowCapApplied = false,
    this.appliedRowCap,
  });

  final List<String> columns;
  final List<List<Object?>> rows;
  final int? rowsAffected;
  final Duration duration;
  final String? sql;
  final bool rowCapApplied;
  final int? appliedRowCap;

  bool get isSelect => columns.isNotEmpty;

  bool get showsRowCapNotice =>
      isSelect && rowCapApplied && appliedRowCap != null;

  String? get rowCapNoticeText {
    if (!showsRowCapNotice) return null;
    final cap = appliedRowCap!;
    final shown = rows.length;
    if (shown >= cap) {
      return 'Showing first $cap rows · row cap $cap applied · results may be partial';
    }
    return 'Row cap $cap applied · showing $shown rows';
  }
}

class SchemaColumn {
  const SchemaColumn({
    required this.name,
    required this.dataType,
    this.isNullable = true,
    this.isPrimaryKey = false,
  });

  final String name;
  final String dataType;
  final bool isNullable;
  final bool isPrimaryKey;
}

class SchemaTable {
  const SchemaTable({
    required this.schema,
    required this.name,
    required this.columns,
  });

  final String schema;
  final String name;
  final List<SchemaColumn> columns;

  String get qualifiedName => schema == 'public' ? name : '$schema.$name';
}

class DatabaseSchema {
  const DatabaseSchema({required this.tables, required this.fetchedAt});

  final List<SchemaTable> tables;
  final DateTime fetchedAt;

  String toSummary() {
    if (tables.isEmpty) {
      return 'No tables found.';
    }

    final buffer = StringBuffer();
    for (final table in tables) {
      buffer.writeln('${table.qualifiedName} (${table.columns.length} columns)');
      for (final column in table.columns) {
        final flags = <String>[
          if (column.isPrimaryKey) 'PK',
          if (!column.isNullable) 'NOT NULL',
        ];
        final suffix = flags.isEmpty ? '' : ' [${flags.join(', ')}]';
        buffer.writeln('  - ${column.name}: ${column.dataType}$suffix');
      }
    }
    return buffer.toString().trim();
  }
}

sealed class TranscriptLine {
  const TranscriptLine();
}

class UserLine extends TranscriptLine {
  const UserLine(this.text);

  final String text;
}

class AssistantLine extends TranscriptLine {
  const AssistantLine(this.text);

  final String text;
}

class ResultLine extends TranscriptLine {
  const ResultLine(this.result);

  final QueryResult result;
}

class ErrorLine extends TranscriptLine {
  const ErrorLine(this.message);

  final String message;
}

class SystemLine extends TranscriptLine {
  const SystemLine(this.text);

  final String text;
}

sealed class AgentEvent {
  const AgentEvent();
}

class AgentTextEvent extends AgentEvent {
  const AgentTextEvent(this.text);

  final String text;
}

class AgentToolCallEvent extends AgentEvent {
  const AgentToolCallEvent({
    required this.toolName,
    required this.arguments,
  });

  final String toolName;
  final Map<String, dynamic> arguments;
}

class AgentToolResultEvent extends AgentEvent {
  const AgentToolResultEvent({
    required this.toolName,
    required this.result,
    this.queryResult,
    this.executedSql,
  });

  final String toolName;
  final String result;
  final QueryResult? queryResult;
  final String? executedSql;
}

class AgentDoneEvent extends AgentEvent {
  const AgentDoneEvent(this.finalText);

  final String finalText;
}

class AgentErrorEvent extends AgentEvent {
  const AgentErrorEvent(this.message);

  final String message;
}

class AgentSchemaDegradedEvent extends AgentEvent {
  const AgentSchemaDegradedEvent(this.message);

  final String message;
}

class AgentSchemaPartialEvent extends AgentEvent {
  const AgentSchemaPartialEvent({
    required this.shownTables,
    required this.totalTables,
  });

  final int shownTables;
  final int totalTables;
}

class LlmToolCall {
  const LlmToolCall({
    required this.id,
    required this.name,
    required this.arguments,
  });

  final String id;
  final String name;
  final Map<String, dynamic> arguments;
}

class ChatMessage {
  const ChatMessage({
    required this.role,
    this.content = '',
    this.toolCallId,
    this.toolCalls,
    this.reasoningContent,
  });

  final String role;
  final String content;
  final String? toolCallId;
  final List<LlmToolCall>? toolCalls;
  final String? reasoningContent;

  ChatMessage copyWith({
    String? role,
    String? content,
    String? toolCallId,
    List<LlmToolCall>? toolCalls,
    String? reasoningContent,
  }) {
    return ChatMessage(
      role: role ?? this.role,
      content: content ?? this.content,
      toolCallId: toolCallId ?? this.toolCallId,
      toolCalls: toolCalls ?? this.toolCalls,
      reasoningContent: reasoningContent ?? this.reasoningContent,
    );
  }
}

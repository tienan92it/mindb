import '../models/models.dart';
import '../ports/ports.dart';
import '../query/query_executor.dart';
import '../schema/schema_service.dart';
import 'agent_prompts.dart';
import 'evidence_policy.dart';
import 'tool_result_formatter.dart';

class AiAgentOrchestrator {
  AiAgentOrchestrator({
    required LlmProvider llmProvider,
    required SchemaService schemaService,
    required QueryExecutor queryExecutor,
    this.maxRounds = 8,
  })  : _llmProvider = llmProvider,
        _schemaService = schemaService,
        _queryExecutor = queryExecutor;

  final LlmProvider _llmProvider;
  final SchemaService _schemaService;
  final QueryExecutor _queryExecutor;
  final int maxRounds;

  Future<List<AgentEvent>> run({
    required String userPrompt,
    required List<LlmToolDefinition> tools,
    List<ChatMessage> history = const [],
    String? sessionSummary,
  }) async {
    final events = <AgentEvent>[];
    final schemaSummary = await _loadSchemaSummary();
    final systemParts = <String>[
      mindbAgentSystemPrompt,
      'Schema:\n$schemaSummary',
      if (sessionSummary != null && sessionSummary.trim().isNotEmpty)
        'Prior conversation summary (unverified — re-query if needed):\n${sessionSummary.trim()}',
    ];

    final requiresEvidence = EvidencePolicy.requiresDatabaseQuery(userPrompt);
    final wrappedPrompt = requiresEvidence
        ? '$userPrompt\n$mindbUserEvidenceReminder'
        : userPrompt;

    final messages = <ChatMessage>[
      ChatMessage(
        role: 'system',
        content: systemParts.join('\n\n'),
      ),
      ...history,
      ChatMessage(role: 'user', content: wrappedPrompt),
    ];

    var evidenceRetryUsed = false;

    for (var round = 0; round < maxRounds; round++) {
      final response = await _llmProvider.chat(messages: messages, tools: tools);

      if (response.text != null && response.text!.trim().isNotEmpty) {
        events.add(AgentTextEvent(response.text!.trim()));
      }

      if (!response.hasToolCalls) {
        final hasEvidence = _messagesHaveToolResults(messages);
        if (requiresEvidence && !hasEvidence) {
          if (!evidenceRetryUsed) {
            evidenceRetryUsed = true;
            if (response.text != null && response.text!.trim().isNotEmpty) {
              messages.add(
                ChatMessage(role: 'assistant', content: response.text!.trim()),
              );
            }
            messages.add(
              const ChatMessage(role: 'user', content: mindbEvidenceRetryPrompt),
            );
            continue;
          }

          events.add(const AgentDoneEvent(EvidencePolicy.noEvidenceReply));
          return events;
        }

        events.add(AgentDoneEvent(response.text ?? ''));
        return events;
      }

      messages.add(
        ChatMessage(
          role: 'assistant',
          content: response.text ?? '',
          toolCalls: response.toolCalls,
          reasoningContent: response.reasoningContent,
        ),
      );

      for (final toolCall in response.toolCalls) {
        events.add(
          AgentToolCallEvent(
            toolName: toolCall.name,
            arguments: toolCall.arguments,
          ),
        );

        final toolOutcome = await _executeTool(toolCall);
        events.add(
          AgentToolResultEvent(
            toolName: toolCall.name,
            result: toolOutcome.formatted,
            queryResult: toolOutcome.queryResult,
          ),
        );

        messages.add(
          ChatMessage(
            role: 'tool',
            content: toolOutcome.formatted,
            toolCallId: toolCall.id,
          ),
        );
      }
    }

    events.add(const AgentErrorEvent('Agent reached maximum tool rounds'));
    return events;
  }

  bool _messagesHaveToolResults(List<ChatMessage> messages) {
    return EvidencePolicy.messagesIncludeToolResults(
      messages.map((message) => (role: message.role)).toList(),
    );
  }

  Future<String> _loadSchemaSummary() async {
    try {
      final schema = await _schemaService.fetchSchema();
      return schema.toSummary();
    } catch (e) {
      return 'Schema unavailable: $e';
    }
  }

  Future<({String formatted, QueryResult? queryResult})> _executeTool(
    LlmToolCall toolCall,
  ) async {
    switch (toolCall.name) {
      case 'get_schema':
        try {
          final schema = await _schemaService.fetchSchema();
          return (
            formatted: ToolResultFormatter.schema(schema.toSummary()),
            queryResult: null,
          );
        } catch (e) {
          return (
            formatted: ToolResultFormatter.sqlError('schema fetch failed: $e'),
            queryResult: null,
          );
        }
      case 'execute_sql':
        final sql = toolCall.arguments['sql']?.toString() ?? '';
        if (sql.trim().isEmpty) {
          return (
            formatted: ToolResultFormatter.sqlError('sql argument is required'),
            queryResult: null,
          );
        }
        try {
          final result = await _queryExecutor.execute(sql);
          return (
            formatted: ToolResultFormatter.sqlResult(result),
            queryResult: result,
          );
        } catch (e) {
          return (
            formatted: ToolResultFormatter.sqlError(e.toString()),
            queryResult: null,
          );
        }
      case 'explain_sql':
        final sql = toolCall.arguments['sql']?.toString() ?? '';
        if (sql.trim().isEmpty) {
          return (
            formatted: ToolResultFormatter.sqlError('sql argument is required'),
            queryResult: null,
          );
        }
        try {
          final explainSql = 'EXPLAIN $sql';
          final result = await _queryExecutor.execute(explainSql);
          final lines =
              result.rows.map((row) => row.first?.toString() ?? '').toList();
          return (
            formatted: ToolResultFormatter.explainResult(lines),
            queryResult: null,
          );
        } catch (e) {
          return (
            formatted: ToolResultFormatter.sqlError('explain failed: $e'),
            queryResult: null,
          );
        }
      default:
        return (
          formatted: ToolResultFormatter.sqlError('unknown tool: ${toolCall.name}'),
          queryResult: null,
        );
    }
  }
}

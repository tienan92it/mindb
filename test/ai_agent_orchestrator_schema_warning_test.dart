import 'package:flutter_test/flutter_test.dart';
import 'package:mindb/data/llm/llm_tools.dart';
import 'package:mindb/domain/ai/ai_agent_orchestrator.dart';
import 'package:mindb/domain/models/models.dart';
import 'package:mindb/domain/ports/ports.dart';
import 'package:mindb/domain/query/query_executor.dart';
import 'package:mindb/domain/safety/safety_policy.dart';
import 'package:mindb/domain/schema/schema_service.dart';

class _FailingSchemaClient implements DatabaseClient {
  @override
  bool get isConnected => true;

  @override
  Future<void> connect(ConnectionProfile profile, String password) async {}

  @override
  Future<void> disconnect() async {}

  @override
  Future<QueryResult> execute(String sql, {Duration? timeout}) async {
    throw Exception('permission denied for relation information_schema.columns');
  }
}

class _StubLlmProvider implements LlmProvider {
  _StubLlmProvider(this._responses);

  final List<LlmResponse> _responses;
  final List<List<ChatMessage>> capturedMessageLists = [];
  var _callIndex = 0;

  @override
  LlmProviderType get providerType => LlmProviderType.openai;

  @override
  Future<LlmResponse> chat({
    required List<ChatMessage> messages,
    required List<LlmToolDefinition> tools,
  }) async {
    capturedMessageLists.add(List<ChatMessage>.from(messages));
    if (_callIndex >= _responses.length) {
      return const LlmResponse(text: 'done');
    }
    return _responses[_callIndex++];
  }
}

Future<bool> _autoApprove(String sql, SqlClassification classification) async {
  return true;
}

void main() {
  group('AiAgentOrchestrator schema degradation', () {
    late SchemaService schemaService;
    late QueryExecutor queryExecutor;
    late _FailingSchemaClient client;

    setUp(() {
      client = _FailingSchemaClient();
      schemaService = SchemaService(client);
      queryExecutor = QueryExecutor(
        client: client,
        safetyPolicy: const SafetyPolicy(),
        schemaService: schemaService,
        maxRows: 100,
        queryTimeout: const Duration(seconds: 30),
        confirmationHandler: _autoApprove,
      );
    });

    test('index failure emits degraded event before LLM with model fallback', () async {
      final llm = _StubLlmProvider([
        const LlmResponse(text: 'I cannot list tables without schema.'),
      ]);
      final orchestrator = AiAgentOrchestrator(
        llmProvider: llm,
        schemaService: schemaService,
        queryExecutor: queryExecutor,
      );

      final events = await orchestrator.run(
        userPrompt: 'hello',
        tools: mindbLlmTools,
      );

      expect(events.first, isA<AgentSchemaDegradedEvent>());
      expect(
        (events.first as AgentSchemaDegradedEvent).message,
        contains('permission denied'),
      );

      final systemMessage = llm.capturedMessageLists.first
          .where((m) => m.role == 'system')
          .map((m) => m.content)
          .single;
      expect(systemMessage, contains('Schema unavailable:'));
    });

    test('get_schema failure emits tool error and degraded event', () async {
      final llm = _StubLlmProvider([
        LlmResponse(
          toolCalls: [
            LlmToolCall(id: 'call_1', name: 'get_schema', arguments: {}),
          ],
        ),
        const LlmResponse(text: 'Schema is unavailable.'),
      ]);
      final orchestrator = AiAgentOrchestrator(
        llmProvider: llm,
        schemaService: schemaService,
        queryExecutor: queryExecutor,
      );

      final events = await orchestrator.run(
        userPrompt: 'list tables',
        tools: mindbLlmTools,
      );

      final toolResults = events.whereType<AgentToolResultEvent>().toList();
      expect(toolResults, hasLength(1));
      expect(toolResults.single.result, contains('source: get_schema'));
      expect(toolResults.single.result, contains('status: error'));

      final degraded = events.whereType<AgentSchemaDegradedEvent>().toList();
      expect(degraded, hasLength(1));
      expect(degraded.single.message, contains('permission denied'));
    });

    test('dedupes degraded event when index and get_schema fail alike', () async {
      final llm = _StubLlmProvider([
        LlmResponse(
          toolCalls: [
            LlmToolCall(id: 'call_1', name: 'get_schema', arguments: {}),
          ],
        ),
        const LlmResponse(text: 'Still no schema.'),
      ]);
      final orchestrator = AiAgentOrchestrator(
        llmProvider: llm,
        schemaService: schemaService,
        queryExecutor: queryExecutor,
      );

      final events = await orchestrator.run(
        userPrompt: 'list tables',
        tools: mindbLlmTools,
      );

      expect(
        events.whereType<AgentSchemaDegradedEvent>().length,
        1,
      );
    });
  });
}

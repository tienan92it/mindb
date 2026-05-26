import 'package:flutter_test/flutter_test.dart';
import 'package:mindb/data/llm/llm_tools.dart';
import 'package:mindb/domain/ai/ai_agent_orchestrator.dart';
import 'package:mindb/domain/models/models.dart';
import 'package:mindb/domain/ports/ports.dart';
import 'package:mindb/domain/query/query_executor.dart';
import 'package:mindb/domain/safety/safety_policy.dart';
import 'package:mindb/domain/schema/schema_service.dart';

class _LargeSchemaClient implements DatabaseClient {
  static const tableCount = 2500;

  @override
  bool get isConnected => true;

  @override
  Future<void> connect(ConnectionProfile profile, String password) async {}

  @override
  Future<void> disconnect() async {}

  @override
  Future<QueryResult> execute(String sql, {Duration? timeout}) async {
    if (sql.contains('information_schema.tables')) {
      return QueryResult(
        columns: const ['table_schema', 'table_name'],
        rows: List.generate(
          tableCount,
          (index) => ['public', 'table_$index'],
        ),
        duration: Duration.zero,
      );
    }
    if (sql.contains('information_schema.columns')) {
      return const QueryResult(
        columns: [
          'table_schema',
          'table_name',
          'column_name',
          'data_type',
          'is_nullable',
          'is_pk',
        ],
        rows: [
          ['public', 'table_0', 'id', 'integer', 'NO', true],
        ],
        duration: Duration.zero,
      );
    }
    return const QueryResult(
      columns: [],
      rows: [],
      rowsAffected: 0,
      duration: Duration.zero,
    );
  }
}

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
  group('AiAgentOrchestrator schema partial index', () {
    test('large DB emits partial event before LLM with truncated index', () async {
      final client = _LargeSchemaClient();
      final schemaService = SchemaService(client);
      final queryExecutor = QueryExecutor(
        client: client,
        safetyPolicy: const SafetyPolicy(),
        schemaService: schemaService,
        maxRows: 100,
        queryTimeout: const Duration(seconds: 30),
        confirmationHandler: _autoApprove,
      );
      final llm = _StubLlmProvider([
        const LlmResponse(text: 'Many tables in this database.'),
      ]);
      final orchestrator = AiAgentOrchestrator(
        llmProvider: llm,
        schemaService: schemaService,
        queryExecutor: queryExecutor,
      );

      final events = await orchestrator.run(
        userPrompt: 'list all tables',
        tools: mindbLlmTools,
      );

      expect(events.first, isA<AgentSchemaPartialEvent>());
      final partial = events.first as AgentSchemaPartialEvent;
      expect(partial.totalTables, 2500);
      expect(partial.shownTables, lessThan(2500));

      final systemMessage = llm.capturedMessageLists.first
          .where((m) => m.role == 'system')
          .map((m) => m.content)
          .single;
      expect(systemMessage, contains('Schema index:'));
      expect(systemMessage, contains('more tables not shown'));
    });

    test('schema failure emits degraded event only', () async {
      final client = _FailingSchemaClient();
      final schemaService = SchemaService(client);
      final queryExecutor = QueryExecutor(
        client: client,
        safetyPolicy: const SafetyPolicy(),
        schemaService: schemaService,
        maxRows: 100,
        queryTimeout: const Duration(seconds: 30),
        confirmationHandler: _autoApprove,
      );
      final llm = _StubLlmProvider([
        const LlmResponse(text: 'Cannot list tables.'),
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
      expect(events.whereType<AgentSchemaPartialEvent>(), isEmpty);
    });
  });
}

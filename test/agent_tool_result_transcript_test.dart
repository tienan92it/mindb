import 'package:flutter_test/flutter_test.dart';
import 'package:mindb/domain/ai/tool_result_formatter.dart';
import 'package:mindb/domain/models/models.dart';
import 'package:mindb/features/session/session_providers.dart';

void main() {
  const sampleResult = QueryResult(
    columns: ['id', 'name'],
    rows: [
      [1, 'alice'],
      [2, 'bob'],
    ],
    duration: Duration(milliseconds: 12),
    sql: 'SELECT id, name FROM users',
  );

  group('transcriptLineForAgentToolResult', () {
    test('execute_sql success maps to ResultLine', () {
      final event = AgentToolResultEvent(
        toolName: 'execute_sql',
        result: ToolResultFormatter.sqlResult(sampleResult),
        queryResult: sampleResult,
      );

      final line = transcriptLineForAgentToolResult(event);
      expect(line, isA<ResultLine>());
      expect((line as ResultLine).result, same(sampleResult));
    });

    test('execute_sql error maps to SystemLine', () {
      const errorText = '''
source: execute_sql
status: error
no_data: true
error: syntax error
instruction: Do not invent a result. Report the error or answer Unknown.
''';
      final event = AgentToolResultEvent(
        toolName: 'execute_sql',
        result: errorText,
      );

      final line = transcriptLineForAgentToolResult(event);
      expect(line, isA<SystemLine>());
      expect((line as SystemLine).text, errorText);
    });

    test('get_schema maps to SystemLine', () {
      const schemaText = '''
source: get_schema
status: success
no_data: false
schema:
public.users
instruction: Only reference tables and columns listed above.
''';
      final event = AgentToolResultEvent(
        toolName: 'get_schema',
        result: schemaText,
      );

      final line = transcriptLineForAgentToolResult(event);
      expect(line, isA<SystemLine>());
      expect((line as SystemLine).text, schemaText);
    });
  });
}

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
    sql: 'SELECT id, name FROM users LIMIT 100',
  );

  group('transcriptLineForAgentToolResult', () {
    test('execute_sql success maps to ResultLine', () {
      final event = AgentToolResultEvent(
        toolName: 'execute_sql',
        result: ToolResultFormatter.sqlResult(sampleResult),
        queryResult: sampleResult,
        executedSql: sampleResult.sql,
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
        executedSql: 'SELECT bad',
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

  group('transcriptLinesForAgentToolResult', () {
    test('execute_sql success prepends SQL then ResultLine', () {
      final event = AgentToolResultEvent(
        toolName: 'execute_sql',
        result: ToolResultFormatter.sqlResult(sampleResult),
        queryResult: sampleResult,
        executedSql: sampleResult.sql,
      );

      final lines = transcriptLinesForAgentToolResult(event);
      expect(lines, hasLength(2));
      expect(lines[0], isA<SystemLine>());
      expect((lines[0] as SystemLine).text, sampleResult.sql);
      expect(lines[1], isA<ResultLine>());
    });

    test('execute_sql error prepends SQL then formatter SystemLine', () {
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
        executedSql: 'SELECT bad',
      );

      final lines = transcriptLinesForAgentToolResult(event);
      expect(lines, hasLength(2));
      expect(lines[0], isA<SystemLine>());
      expect((lines[0] as SystemLine).text, 'SELECT bad');
      expect(lines[1], isA<SystemLine>());
      expect((lines[1] as SystemLine).text, errorText);
    });

    test('get_schema unchanged single SystemLine', () {
      const schemaText = 'source: get_schema\nstatus: success';
      final event = AgentToolResultEvent(
        toolName: 'get_schema',
        result: schemaText,
      );

      final lines = transcriptLinesForAgentToolResult(event);
      expect(lines, hasLength(1));
      expect(lines[0], isA<SystemLine>());
      expect((lines[0] as SystemLine).text, schemaText);
    });
  });

  group('showAgentToolCallLine', () {
    test('suppresses execute_sql call marker', () {
      expect(showAgentToolCallLine('execute_sql'), isFalse);
    });

    test('shows other tool call markers', () {
      expect(showAgentToolCallLine('get_schema'), isTrue);
      expect(showAgentToolCallLine('explain_sql'), isTrue);
    });
  });
}

import 'package:flutter_test/flutter_test.dart';
import 'package:mindb/domain/ai/evidence_policy.dart';
import 'package:mindb/domain/ai/tool_result_formatter.dart';
import 'package:mindb/domain/models/models.dart';

void main() {
  group('EvidencePolicy', () {
    test('requires query for data questions', () {
      expect(EvidencePolicy.requiresDatabaseQuery('how many users?'), isTrue);
      expect(EvidencePolicy.requiresDatabaseQuery('list orders'), isTrue);
    });

    test('exempts sql prefix and small talk', () {
      expect(EvidencePolicy.requiresDatabaseQuery('sql: select 1'), isFalse);
      expect(EvidencePolicy.requiresDatabaseQuery('hello'), isFalse);
      expect(EvidencePolicy.requiresDatabaseQuery('thanks'), isFalse);
    });

    test('detects tool results in messages', () {
      expect(
        EvidencePolicy.messagesIncludeToolResults([
          (role: 'user'),
          (role: 'assistant'),
        ]),
        isFalse,
      );
      expect(
        EvidencePolicy.messagesIncludeToolResults([
          (role: 'tool'),
        ]),
        isTrue,
      );
    });
  });

  group('ToolResultFormatter', () {
    test('marks empty select as no_data', () {
      final formatted = ToolResultFormatter.sqlResult(
        const QueryResult(
          columns: ['id'],
          rows: [],
          duration: Duration(milliseconds: 1),
        ),
      );

      expect(formatted, contains('no_data: true'));
      expect(formatted, contains('row_count: 0'));
      expect(formatted, contains('Do not invent rows'));
    });

    test('includes row values for non-empty select', () {
      final formatted = ToolResultFormatter.sqlResult(
        QueryResult(
          columns: ['id', 'email'],
          rows: [
            [1, 'a@example.com'],
          ],
          duration: const Duration(milliseconds: 2),
        ),
      );

      expect(formatted, contains('no_data: false'));
      expect(formatted, contains('a@example.com'));
    });
  });
}

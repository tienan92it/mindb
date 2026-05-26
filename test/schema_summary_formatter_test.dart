import 'package:flutter_test/flutter_test.dart';
import 'package:mindb/domain/models/models.dart';
import 'package:mindb/domain/schema/schema_query.dart';
import 'package:mindb/domain/schema/schema_summary_formatter.dart';

DatabaseSchema _largeSchema({required int tableCount}) {
  return DatabaseSchema(
    fetchedAt: DateTime(2026),
    tables: List.generate(
      tableCount,
      (index) => SchemaTable(
        schema: 'public',
        name: 'table_$index',
        columns: List.generate(
          20,
          (columnIndex) => SchemaColumn(
            name: 'col_$columnIndex',
            dataType: 'text',
          ),
        ),
      ),
    ),
  );
}

void main() {
  group('SchemaSummaryFormatter', () {
    test('formatSystemIndex stays compact for large schemas', () {
      final result = SchemaSummaryFormatter.formatSystemIndex(
        _largeSchema(tableCount: 500),
      );

      expect(result.text.length, lessThan(50000));
      expect(result.text, contains('500 tables'));
      expect(result.text, contains('table_0 (20 cols)'));
      expect(result.text, isNot(contains('col_0: text')));
    });

    test('formatSystemIndex reports partial when truncated', () {
      final result = SchemaSummaryFormatter.formatSystemIndex(
        _largeSchema(tableCount: 200),
        maxChars: 2000,
      );

      expect(result.isPartial, isTrue);
      expect(result.shownTables, lessThan(200));
      expect(result.totalTables, 200);
      expect(result.text, contains('more tables not shown'));
    });

    test('formatSystemIndex is not partial for small schemas', () {
      final schema = DatabaseSchema(
        fetchedAt: DateTime(2026),
        tables: const [
          SchemaTable(
            schema: 'public',
            name: 'users',
            columns: [SchemaColumn(name: 'id', dataType: 'integer')],
          ),
          SchemaTable(
            schema: 'public',
            name: 'orders',
            columns: [SchemaColumn(name: 'id', dataType: 'integer')],
          ),
        ],
      );

      final result = SchemaSummaryFormatter.formatSystemIndex(schema);

      expect(result.isPartial, isFalse);
      expect(result.shownTables, 2);
      expect(result.totalTables, 2);
    });

    test('formatForTool returns detailed columns when filtered', () {
      final schema = DatabaseSchema(
        fetchedAt: DateTime(2026),
        tables: const [
          SchemaTable(
            schema: 'public',
            name: 'users',
            columns: [
              SchemaColumn(name: 'id', dataType: 'integer', isPrimaryKey: true),
              SchemaColumn(name: 'email', dataType: 'text'),
            ],
          ),
          SchemaTable(
            schema: 'public',
            name: 'orders',
            columns: [
              SchemaColumn(name: 'id', dataType: 'integer'),
            ],
          ),
        ],
      );

      final summary = SchemaSummaryFormatter.formatForTool(
        schema,
        query: const SchemaQuery(table: 'users'),
      );

      expect(summary, contains('users (2 columns)'));
      expect(summary, contains('id: integer [PK]'));
      expect(summary, isNot(contains('orders')));
    });

    test('formatForTool returns index when unfiltered schema is too large', () {
      final summary = SchemaSummaryFormatter.formatForTool(
        _largeSchema(tableCount: 2000),
        maxChars: 10000,
      );

      expect(summary, contains('2000 tables'));
      expect(summary, isNot(contains('col_0: text')));
    });

    test('SchemaQuery.fromArguments ignores blank values', () {
      final query = SchemaQuery.fromArguments({
        'schema': ' public ',
        'table': '',
        'search': null,
      });

      expect(query.schema, 'public');
      expect(query.table, isNull);
      expect(query.search, isNull);
      expect(query.isEmpty, isFalse);
    });
  });
}

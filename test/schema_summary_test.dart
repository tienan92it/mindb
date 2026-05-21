import 'package:flutter_test/flutter_test.dart';
import 'package:mindb/domain/models/models.dart';

void main() {
  group('DatabaseSchema.toSummary', () {
    test('returns message when no tables', () {
      final schema = DatabaseSchema(tables: const [], fetchedAt: DateTime(2026));
      expect(schema.toSummary(), 'No tables found.');
    });

    test('includes table and column details', () {
      final schema = DatabaseSchema(
        fetchedAt: DateTime(2026),
        tables: const [
          SchemaTable(
            schema: 'public',
            name: 'users',
            columns: [
              SchemaColumn(
                name: 'id',
                dataType: 'integer',
                isNullable: false,
                isPrimaryKey: true,
              ),
              SchemaColumn(
                name: 'email',
                dataType: 'text',
              ),
            ],
          ),
        ],
      );

      final summary = schema.toSummary();
      expect(summary, contains('users (2 columns)'));
      expect(summary, contains('id: integer [PK, NOT NULL]'));
      expect(summary, contains('email: text'));
    });
  });
}

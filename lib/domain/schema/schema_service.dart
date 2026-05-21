import '../models/models.dart';
import '../ports/ports.dart';

class SchemaService {
  SchemaService(this._client);

  final DatabaseClient _client;
  DatabaseSchema? _cache;

  /// Exposed for regression tests (ambiguous column refs in JOIN SELECT).
  static const columnsSql = '''
SELECT c.table_schema, c.table_name, c.column_name, c.data_type, c.is_nullable,
       CASE WHEN pk.column_name IS NOT NULL THEN true ELSE false END AS is_pk
FROM information_schema.columns c
LEFT JOIN (
  SELECT kcu.table_schema, kcu.table_name, kcu.column_name
  FROM information_schema.table_constraints tc
  JOIN information_schema.key_column_usage kcu
    ON tc.constraint_name = kcu.constraint_name
   AND tc.table_schema = kcu.table_schema
   AND tc.table_catalog = kcu.table_catalog
  WHERE tc.constraint_type = 'PRIMARY KEY'
) pk ON c.table_schema = pk.table_schema
    AND c.table_name = pk.table_name
    AND c.column_name = pk.column_name
WHERE c.table_schema NOT IN ('pg_catalog', 'information_schema')
ORDER BY c.table_schema, c.table_name, c.ordinal_position
''';

  DatabaseSchema? get cachedSchema => _cache;

  void clearCache() {
    _cache = null;
  }

  Future<DatabaseSchema> fetchSchema({bool forceRefresh = false}) async {
    if (!forceRefresh && _cache != null) {
      return _cache!;
    }

    if (!_client.isConnected) {
      throw StateError('Not connected to database');
    }

    const tablesSql = '''
SELECT table_schema, table_name
FROM information_schema.tables
WHERE table_type = 'BASE TABLE'
  AND table_schema NOT IN ('pg_catalog', 'information_schema')
ORDER BY table_schema, table_name
''';

    const columnsSql = SchemaService.columnsSql;

    final tablesResult = await _client.execute(tablesSql);
    final columnsResult = await _client.execute(columnsSql);

    final columnsByTable = <String, List<SchemaColumn>>{};
    for (final row in columnsResult.rows) {
      final schema = row[0]?.toString() ?? 'public';
      final table = row[1]?.toString() ?? '';
      final key = '$schema.$table';
      columnsByTable.putIfAbsent(key, () => []);
      columnsByTable[key]!.add(
        SchemaColumn(
          name: row[2]?.toString() ?? '',
          dataType: row[3]?.toString() ?? 'unknown',
          isNullable: row[4]?.toString().toUpperCase() == 'YES',
          isPrimaryKey: row[5] == true || row[5]?.toString() == 'true',
        ),
      );
    }

    final tables = <SchemaTable>[];
    for (final row in tablesResult.rows) {
      final schema = row[0]?.toString() ?? 'public';
      final name = row[1]?.toString() ?? '';
      final key = '$schema.$name';
      tables.add(
        SchemaTable(
          schema: schema,
          name: name,
          columns: columnsByTable[key] ?? const [],
        ),
      );
    }

    _cache = DatabaseSchema(tables: tables, fetchedAt: DateTime.now());
    return _cache!;
  }

  String getSchemaSummary() {
    return _cache?.toSummary() ?? 'Schema not loaded.';
  }
}

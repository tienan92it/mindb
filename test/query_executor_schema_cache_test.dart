import 'package:flutter_test/flutter_test.dart';
import 'package:mindb/domain/models/models.dart';
import 'package:mindb/domain/ports/ports.dart';
import 'package:mindb/domain/query/query_executor.dart';
import 'package:mindb/domain/safety/safety_policy.dart';
import 'package:mindb/domain/schema/schema_service.dart';

class _RecordingDatabaseClient implements DatabaseClient {
  _RecordingDatabaseClient();

  final List<String> executedSql = [];
  bool connected = true;

  @override
  bool get isConnected => connected;

  @override
  Future<void> connect(ConnectionProfile profile, String password) async {
    connected = true;
  }

  @override
  Future<void> disconnect() async {
    connected = false;
  }

  @override
  Future<QueryResult> execute(String sql, {Duration? timeout}) async {
    executedSql.add(sql);
    if (sql.contains('information_schema.tables')) {
      return const QueryResult(
        columns: ['table_schema', 'table_name'],
        rows: [
          ['public', 'users'],
        ],
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
          ['public', 'users', 'id', 'integer', 'NO', true],
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

Future<bool> _autoApprove(String sql, SqlClassification classification) async {
  return true;
}

void main() {
  group('QueryExecutor schema cache', () {
    late _RecordingDatabaseClient client;
    late SchemaService schemaService;
    late QueryExecutor executor;

    setUp(() {
      client = _RecordingDatabaseClient();
      schemaService = SchemaService(client);
      executor = QueryExecutor(
        client: client,
        safetyPolicy: const SafetyPolicy(),
        schemaService: schemaService,
        maxRows: 100,
        queryTimeout: const Duration(seconds: 30),
        confirmationHandler: _autoApprove,
      );
    });

    test('DDL execute clears schema cache', () async {
      await schemaService.fetchSchema();
      expect(schemaService.cachedSchema, isNotNull);
      final introspectionCountBefore = client.executedSql.length;

      await executor.execute('CREATE TABLE new_table (id int)');

      expect(schemaService.cachedSchema, isNull);

      await schemaService.fetchSchema();
      expect(client.executedSql.length, greaterThan(introspectionCountBefore));
    });

    test('SELECT execute keeps schema cache', () async {
      await schemaService.fetchSchema();
      expect(schemaService.cachedSchema, isNotNull);
      final introspectionCountBefore = client.executedSql.length;

      await executor.execute('SELECT 1');

      expect(schemaService.cachedSchema, isNotNull);

      await schemaService.fetchSchema();
      expect(client.executedSql.length, introspectionCountBefore);
    });

    test('INSERT execute keeps schema cache', () async {
      await schemaService.fetchSchema();
      expect(schemaService.cachedSchema, isNotNull);

      await executor.execute('INSERT INTO users (id) VALUES (1)');

      expect(schemaService.cachedSchema, isNotNull);
    });
  });
}

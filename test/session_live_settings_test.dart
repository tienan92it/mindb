import 'package:flutter_test/flutter_test.dart';
import 'package:mindb/domain/models/models.dart';
import 'package:mindb/domain/ports/ports.dart';
import 'package:mindb/domain/query/query_executor.dart';
import 'package:mindb/domain/safety/safety_policy.dart';

Future<bool> _autoApprove(String sql, SqlClassification classification) async {
  return true;
}

class _RecordingDatabaseClient implements DatabaseClient {
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
    if (sql.trim().toUpperCase().startsWith('SELECT')) {
      return QueryResult(
        columns: const ['id'],
        rows: List.generate(3, (i) => [i]),
        duration: Duration.zero,
        sql: sql,
      );
    }
    return const QueryResult(
      columns: [],
      rows: [],
      rowsAffected: 1,
      duration: Duration.zero,
    );
  }
}

QueryExecutor _executorFor(
  _RecordingDatabaseClient client, {
  required bool readOnlyMode,
  required int maxRows,
}) {
  return QueryExecutor(
    client: client,
    safetyPolicy: SafetyPolicy(readOnlyMode: readOnlyMode),
    maxRows: maxRows,
    queryTimeout: const Duration(seconds: 30),
    confirmationHandler: _autoApprove,
  );
}

void main() {
  group('live settings refresh — executor wiring', () {
    late _RecordingDatabaseClient client;

    setUp(() {
      client = _RecordingDatabaseClient();
    });

    test('read-only policy blocks DELETE after rebuild', () async {
      final writable = _executorFor(client, readOnlyMode: false, maxRows: 200);
      await writable.execute('DELETE FROM t');

      final readOnly = _executorFor(client, readOnlyMode: true, maxRows: 200);
      expect(
        () => readOnly.execute('DELETE FROM t'),
        throwsA(
          isA<StateError>().having(
            (e) => e.message,
            'message',
            contains('Read-only mode'),
          ),
        ),
      );
    });

    test('row cap applies on next execute after rebuild', () async {
      final capped5 = _executorFor(client, readOnlyMode: false, maxRows: 5);
      await capped5.execute('SELECT * FROM users');
      expect(client.executedSql.last, contains('LIMIT 5'));

      final capped10 = _executorFor(client, readOnlyMode: false, maxRows: 10);
      await capped10.execute('SELECT * FROM users');
      expect(client.executedSql.last, contains('LIMIT 10'));
    });
  });
}

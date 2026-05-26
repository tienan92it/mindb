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

void main() {
  group('QueryExecutor row cap metadata', () {
    late _RecordingDatabaseClient client;
    late QueryExecutor executor;

    setUp(() {
      client = _RecordingDatabaseClient();
      executor = QueryExecutor(
        client: client,
        safetyPolicy: const SafetyPolicy(),
        maxRows: 5,
        queryTimeout: const Duration(seconds: 30),
        confirmationHandler: _autoApprove,
      );
    });

    test('injects LIMIT and sets cap metadata', () async {
      final result = await executor.execute('SELECT * FROM users');

      expect(client.executedSql.single, contains('LIMIT 5'));
      expect(result.rowCapApplied, isTrue);
      expect(result.appliedRowCap, 5);
    });

    test('existing LIMIT leaves metadata unset', () async {
      final result = await executor.execute('SELECT * FROM users LIMIT 50');

      expect(client.executedSql.single, 'SELECT * FROM users LIMIT 50');
      expect(result.rowCapApplied, isFalse);
      expect(result.appliedRowCap, isNull);
    });

    test('INSERT does not set cap metadata', () async {
      final result = await executor.execute('INSERT INTO t VALUES (1)');

      expect(result.rowCapApplied, isFalse);
      expect(result.appliedRowCap, isNull);
    });
  });

  group('QueryResult rowCapNoticeText', () {
    test('shown below cap', () {
      const result = QueryResult(
        columns: ['id'],
        rows: [
          [1],
          [2],
        ],
        duration: Duration.zero,
        rowCapApplied: true,
        appliedRowCap: 100,
      );

      expect(result.rowCapNoticeText, contains('showing 2 rows'));
      expect(result.rowCapNoticeText, contains('100'));
    });

    test('shown at cap indicates partial', () {
      final result = QueryResult(
        columns: const ['id'],
        rows: List.generate(100, (i) => [i]),
        duration: Duration.zero,
        rowCapApplied: true,
        appliedRowCap: 100,
      );

      expect(result.rowCapNoticeText, contains('may be partial'));
      expect(result.rowCapNoticeText, contains('100'));
    });
  });
}

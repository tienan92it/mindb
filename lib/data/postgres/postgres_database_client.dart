import 'package:postgres/postgres.dart';

import '../../core/app_logger.dart';
import '../../domain/models/models.dart';
import '../../domain/ports/ports.dart';
import 'cell_value_formatter.dart';

class PostgresDatabaseClient implements DatabaseClient {
  Connection? _connection;
  ConnectionProfile? _profile;

  @override
  bool get isConnected => _connection != null;

  @override
  Future<void> connect(ConnectionProfile profile, String password) async {
    await disconnect();

    final sslMode = profile.useSsl ? SslMode.require : SslMode.disable;

    appLogger.info('Connecting to ${profile.host}:${profile.port}/${profile.database}');

    _connection = await Connection.open(
      Endpoint(
        host: profile.host,
        port: profile.port,
        database: profile.database,
        username: profile.username,
        password: password,
      ),
      settings: ConnectionSettings(sslMode: sslMode),
    );
    _profile = profile;
  }

  @override
  Future<void> disconnect() async {
    final connection = _connection;
    _connection = null;
    _profile = null;
    if (connection != null) {
      await connection.close();
    }
  }

  @override
  Future<QueryResult> execute(String sql, {Duration? timeout}) async {
    final connection = _connection;
    if (connection == null) {
      throw StateError('Not connected');
    }

    final stopwatch = Stopwatch()..start();
    final future = _runQuery(connection, sql);
    final result =
        timeout == null ? await future : await future.timeout(timeout);

    stopwatch.stop();

    return QueryResult(
      columns: result.columns,
      rows: result.rows,
      rowsAffected: result.rowsAffected,
      duration: stopwatch.elapsed,
      sql: sql,
    );
  }

  Future<QueryResult> testConnection(
    ConnectionProfile profile,
    String password,
  ) async {
    final sslMode = profile.useSsl ? SslMode.require : SslMode.disable;
    final connection = await Connection.open(
      Endpoint(
        host: profile.host,
        port: profile.port,
        database: profile.database,
        username: profile.username,
        password: password,
      ),
      settings: ConnectionSettings(sslMode: sslMode),
    );

    try {
      final stopwatch = Stopwatch()..start();
      final result = await connection.execute('SELECT 1');
      stopwatch.stop();
      return QueryResult(
        columns: _columnNames(result),
        rows: _normalizeRows(result),
        duration: stopwatch.elapsed,
        sql: 'SELECT 1',
      );
    } finally {
      await connection.close();
    }
  }

  ConnectionProfile? get activeProfile => _profile;

  List<String> _columnNames(Result result) {
    return result.schema.columns
        .map((column) => column.columnName ?? 'column')
        .toList();
  }

  List<List<Object?>> _normalizeRows(Result result) {
    return result
        .map((row) => row.map(normalizeCellValue).toList())
        .toList();
  }

  Future<_RawQueryResult> _runQuery(Connection connection, String sql) async {
    final result = await connection.execute(sql);
    if (result.isEmpty && result.affectedRows == 0) {
      return const _RawQueryResult(
        columns: [],
        rows: [],
        rowsAffected: 0,
      );
    }

    final columns = _columnNames(result);
    final rows = _normalizeRows(result);

    return _RawQueryResult(
      columns: columns,
      rows: rows,
      rowsAffected: result.affectedRows,
    );
  }
}

class _RawQueryResult {
  const _RawQueryResult({
    required this.columns,
    required this.rows,
    this.rowsAffected,
  });

  final List<String> columns;
  final List<List<Object?>> rows;
  final int? rowsAffected;
}

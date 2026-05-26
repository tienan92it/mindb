import '../models/models.dart';
import '../ports/ports.dart';
import '../safety/safety_policy.dart';
import '../schema/schema_service.dart';

class QueryExecutor {
  QueryExecutor({
    required DatabaseClient client,
    required SafetyPolicy safetyPolicy,
    required int maxRows,
    required Duration queryTimeout,
    SchemaService? schemaService,
    ConfirmationHandler? confirmationHandler,
  })  : _client = client,
        _safetyPolicy = safetyPolicy,
        _schemaService = schemaService,
        _maxRows = maxRows,
        _queryTimeout = queryTimeout,
        _confirmationHandler = confirmationHandler;

  final DatabaseClient _client;
  final SafetyPolicy _safetyPolicy;
  final SchemaService? _schemaService;
  final int _maxRows;
  final Duration _queryTimeout;
  final ConfirmationHandler? _confirmationHandler;

  Future<QueryResult> execute(String sql) async {
    if (!_client.isConnected) {
      throw StateError('Not connected to database');
    }

    final trimmed = sql.trim();
    if (trimmed.isEmpty) {
      throw ArgumentError('SQL cannot be empty');
    }

    if (!_safetyPolicy.isReadOnlyAllowed(trimmed)) {
      throw StateError('Read-only mode: write/destructive SQL is blocked');
    }

    if (_safetyPolicy.requiresConfirmation(trimmed)) {
      final handler = _confirmationHandler;
      if (handler == null) {
        throw StateError('Confirmation required but no handler configured');
      }
      final classification = _safetyPolicy.classify(trimmed);
      final approved = await handler(trimmed, classification);
      if (!approved) {
        throw StateError('Query cancelled by user');
      }
    }

    final limitedSql = _safetyPolicy.injectLimit(trimmed, _maxRows);
    final result = await _client.execute(limitedSql, timeout: _queryTimeout);

    final schemaService = _schemaService;
    if (schemaService != null && _safetyPolicy.affectsSchemaStructure(trimmed)) {
      schemaService.clearCache();
    }

    return QueryResult(
      columns: result.columns,
      rows: result.rows,
      rowsAffected: result.rowsAffected,
      duration: result.duration,
      sql: limitedSql,
    );
  }
}

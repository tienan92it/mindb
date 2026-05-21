import 'dart:convert';

import 'package:drift/drift.dart';

import '../../domain/models/session_context.dart';
import 'app_database.dart';

class SessionContextRepository {
  SessionContextRepository(this._db);

  final AppDatabase _db;

  Future<SessionContext> load(String connectionId) async {
    final row = await (_db.select(_db.sessionHistories)
          ..where((t) => t.connectionId.equals(connectionId)))
        .getSingleOrNull();

    if (row == null) {
      return SessionContext(
        connectionId: connectionId,
        updatedAt: DateTime.now(),
      );
    }

    final turnsJson = jsonDecode(row.turnsJson) as List<dynamic>;
    final turns = turnsJson
        .map((item) => SessionTurn.fromJson(Map<String, dynamic>.from(item as Map)))
        .toList();

    return SessionContext(
      connectionId: connectionId,
      summary: row.summary ?? '',
      turns: turns,
      updatedAt: row.updatedAt,
    );
  }

  Future<void> save(SessionContext context) async {
    await _db.into(_db.sessionHistories).insertOnConflictUpdate(
          SessionHistoriesCompanion(
            connectionId: Value(context.connectionId),
            summary: Value(
              context.summary.trim().isEmpty ? null : context.summary.trim(),
            ),
            turnsJson: Value(jsonEncode(context.turns.map((t) => t.toJson()).toList())),
            updatedAt: Value(context.updatedAt),
          ),
        );
  }

  Future<void> delete(String connectionId) async {
    await (_db.delete(_db.sessionHistories)
          ..where((t) => t.connectionId.equals(connectionId)))
        .go();
  }
}

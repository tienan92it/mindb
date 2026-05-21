import 'package:drift/drift.dart';

import '../../domain/models/models.dart';
import '../secure/secure_credential_store.dart';
import 'app_database.dart';

class ConnectionRepository {
  ConnectionRepository(this._db, this._credentialStore);

  final AppDatabase _db;
  final SecureCredentialStore _credentialStore;

  Future<List<ConnectionProfile>> listAll() async {
    final rows = await (_db.select(_db.connectionProfiles)
          ..orderBy([
            (t) => OrderingTerm(
                  expression: t.lastUsedAt,
                  mode: OrderingMode.desc,
                  nulls: NullsOrder.last,
                ),
            (t) => OrderingTerm.asc(t.name),
          ]))
        .get();

    return rows.map(_mapRow).toList();
  }

  Future<ConnectionProfile?> getById(String id) async {
    final row = await (_db.select(_db.connectionProfiles)
          ..where((t) => t.id.equals(id)))
        .getSingleOrNull();
    return row == null ? null : _mapRow(row);
  }

  Future<void> save(ConnectionProfile profile, {String? password}) async {
    await _db.into(_db.connectionProfiles).insertOnConflictUpdate(
          ConnectionProfilesCompanion.insert(
            id: profile.id,
            name: profile.name,
            host: profile.host,
            port: profile.port,
            databaseName: profile.database,
            username: profile.username,
            useSsl: Value(profile.useSsl),
            lastUsedAt: Value(profile.lastUsedAt),
            createdAt: profile.createdAt,
          ),
        );

    if (password != null && password.isNotEmpty) {
      await _credentialStore.saveConnectionPassword(profile.id, password);
    }
  }

  Future<void> touchLastUsed(String id) async {
    await (_db.update(_db.connectionProfiles)..where((t) => t.id.equals(id)))
        .write(ConnectionProfilesCompanion(lastUsedAt: Value(DateTime.now())));
  }

  Future<void> delete(String id) async {
    await (_db.delete(_db.connectionProfiles)..where((t) => t.id.equals(id)))
        .go();
    await _credentialStore.deleteConnectionPassword(id);
  }

  Future<String?> readPassword(String connectionId) {
    return _credentialStore.readConnectionPassword(connectionId);
  }

  ConnectionProfile _mapRow(ConnectionProfileRow row) {
    return ConnectionProfile(
      id: row.id,
      name: row.name,
      host: row.host,
      port: row.port,
      database: row.databaseName,
      username: row.username,
      useSsl: row.useSsl,
      lastUsedAt: row.lastUsedAt,
      createdAt: row.createdAt,
    );
  }
}

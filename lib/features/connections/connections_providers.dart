import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/persistence/app_database.dart';
import '../../data/persistence/connection_repository.dart';
import '../../data/postgres/postgres_database_client.dart';
import '../../data/secure/secure_credential_store.dart';
import '../../domain/models/models.dart';

final appDatabaseProvider = Provider<AppDatabase>((ref) {
  final db = AppDatabase();
  ref.onDispose(db.close);
  return db;
});

final credentialStoreProvider = Provider<SecureCredentialStore>((ref) {
  return SecureCredentialStore();
});

final connectionRepositoryProvider = Provider<ConnectionRepository>((ref) {
  return ConnectionRepository(
    ref.watch(appDatabaseProvider),
    ref.watch(credentialStoreProvider),
  );
});

final postgresClientProvider = Provider<PostgresDatabaseClient>((ref) {
  final client = PostgresDatabaseClient();
  ref.onDispose(client.disconnect);
  return client;
});

final connectionsListProvider = FutureProvider<List<ConnectionProfile>>((ref) {
  return ref.watch(connectionRepositoryProvider).listAll();
});

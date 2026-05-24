import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../data/persistence/app_database.dart';
import '../../data/persistence/connection_repository.dart';
import '../../data/persistence/settings_repository.dart';
import '../../data/postgres/postgres_database_client.dart';
import '../../data/secure/secure_credential_store.dart';
import '../../domain/models/models.dart';
import 'onboarding_status.dart';

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

final onboardingReadinessProvider = FutureProvider<OnboardingStatus>((ref) async {
  final connections = await ref.watch(connectionsListProvider.future);
  final prefs = await SharedPreferences.getInstance();
  final settingsRepo = SettingsRepository(prefs);
  await settingsRepo.migrateIfNeeded();
  final settings = settingsRepo.load();
  final apiKey = await ref
      .read(credentialStoreProvider)
      .readLlmApiKey(settings.llmProvider);
  final hasLlmKey = apiKey != null && apiKey.trim().isNotEmpty;
  return computeOnboardingStatus(
    connectionCount: connections.length,
    hasLlmKey: hasLlmKey,
  );
});

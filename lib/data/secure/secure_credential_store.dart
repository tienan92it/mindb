import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../../domain/models/models.dart';
import '../../domain/ports/ports.dart';

class SecureCredentialStore implements CredentialStore {
  SecureCredentialStore({FlutterSecureStorage? storage})
      : _storage = storage ?? const FlutterSecureStorage();

  final FlutterSecureStorage _storage;

  static String connectionPasswordKey(String connectionId) =>
      'mindb_conn_password:$connectionId';

  static String llmApiKeyKey(LlmProviderType provider) =>
      'mindb_llm_api_key:${provider.name}';

  @override
  Future<void> saveConnectionPassword(String connectionId, String password) {
    return _storage.write(
      key: connectionPasswordKey(connectionId),
      value: password,
    );
  }

  @override
  Future<String?> readConnectionPassword(String connectionId) {
    return _storage.read(key: connectionPasswordKey(connectionId));
  }

  @override
  Future<void> deleteConnectionPassword(String connectionId) {
    return _storage.delete(key: connectionPasswordKey(connectionId));
  }

  @override
  Future<void> saveLlmApiKey(LlmProviderType provider, String apiKey) {
    return _storage.write(key: llmApiKeyKey(provider), value: apiKey);
  }

  @override
  Future<String?> readLlmApiKey(LlmProviderType provider) {
    return _storage.read(key: llmApiKeyKey(provider));
  }

  @override
  Future<void> deleteLlmApiKey(LlmProviderType provider) {
    return _storage.delete(key: llmApiKeyKey(provider));
  }
}

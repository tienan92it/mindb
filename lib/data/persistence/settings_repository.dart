import 'package:shared_preferences/shared_preferences.dart';

import '../../domain/models/models.dart';
import '../llm/kimi_models.dart';
import '../llm/llm_provider_models.dart';

class SettingsRepository {
  SettingsRepository(this._prefs);

  final SharedPreferences _prefs;

  static const _llmProviderKey = 'llm_provider';
  static const _legacyLlmModelKey = 'llm_model';
  static const _readOnlyModeKey = 'read_only_mode';
  static const _maxRowsKey = 'max_rows';
  static const _queryTimeoutKey = 'query_timeout_seconds';
  static const _providerModelsMigrationKey = 'settings_migrated_provider_models_v1';

  static String modelKeyFor(LlmProviderType provider) =>
      'llm_model_${provider.name}';

  Future<void> migrateIfNeeded() async {
    if (_prefs.getBool(KimiModels.migrationKey) != true) {
      final providerName = _prefs.getString(_llmProviderKey);
      final model = _prefs.getString(_legacyLlmModelKey);
      if (providerName == LlmProviderType.kimi.name &&
          (model == KimiModels.legacyAppDefault ||
              KimiModels.deprecated.contains(model))) {
        await _prefs.setString(modelKeyFor(LlmProviderType.kimi), KimiModels.recommended);
        await _prefs.setString(_legacyLlmModelKey, KimiModels.recommended);
      }
      await _prefs.setBool(KimiModels.migrationKey, true);
    }

    if (_prefs.getBool(_providerModelsMigrationKey) != true) {
      final legacyModel = _prefs.getString(_legacyLlmModelKey);
      if (legacyModel != null && legacyModel.isNotEmpty) {
        final provider = LlmProviderTypeX.fromName(
          _prefs.getString(_llmProviderKey) ?? 'openai',
        );
        final key = modelKeyFor(provider);
        if (!_prefs.containsKey(key)) {
          await _prefs.setString(
            key,
            LlmProviderModels.resolve(provider, legacyModel),
          );
        }
      }
      await _prefs.setBool(_providerModelsMigrationKey, true);
    }
  }

  Map<LlmProviderType, String> loadAllModels() {
    return {
      for (final provider in LlmProviderType.values)
        provider: loadModelFor(provider),
    };
  }

  String loadModelFor(LlmProviderType provider) {
    final raw = _prefs.getString(modelKeyFor(provider)) ??
        (provider == _activeProvider() ? _prefs.getString(_legacyLlmModelKey) : null) ??
        provider.defaultModel;
    return LlmProviderModels.resolve(provider, raw);
  }

  AppSettings load() {
    final providerName = _prefs.getString(_llmProviderKey) ?? 'openai';
    final provider = LlmProviderTypeX.fromName(providerName);

    return AppSettings(
      llmProvider: provider,
      llmModel: loadModelFor(provider),
      readOnlyMode: _prefs.getBool(_readOnlyModeKey) ?? false,
      maxRows: _prefs.getInt(_maxRowsKey) ?? 200,
      queryTimeoutSeconds: _prefs.getInt(_queryTimeoutKey) ?? 30,
    );
  }

  Future<void> save(
    AppSettings settings, {
    Map<LlmProviderType, String>? modelsByProvider,
  }) async {
    final models = modelsByProvider ??
        {
          settings.llmProvider: LlmProviderModels.resolve(
            settings.llmProvider,
            settings.llmModel,
          ),
        };

    for (final entry in models.entries) {
      final resolved = LlmProviderModels.resolve(entry.key, entry.value);
      await _prefs.setString(modelKeyFor(entry.key), resolved);
    }

    final activeModel = LlmProviderModels.resolve(
      settings.llmProvider,
      models[settings.llmProvider] ?? settings.llmModel,
    );

    await _prefs.setString(_llmProviderKey, settings.llmProvider.name);
    await _prefs.setString(_legacyLlmModelKey, activeModel);
    await _prefs.setBool(_readOnlyModeKey, settings.readOnlyMode);
    await _prefs.setInt(_maxRowsKey, settings.maxRows);
    await _prefs.setInt(_queryTimeoutKey, settings.queryTimeoutSeconds);
  }

  LlmProviderType _activeProvider() {
    return LlmProviderTypeX.fromName(_prefs.getString(_llmProviderKey) ?? 'openai');
  }
}

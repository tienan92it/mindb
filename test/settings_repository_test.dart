import 'package:flutter_test/flutter_test.dart';
import 'package:mindb/data/llm/anthropic_models.dart';
import 'package:mindb/data/llm/kimi_models.dart';
import 'package:mindb/data/llm/llm_provider_models.dart';
import 'package:mindb/data/llm/openai_models.dart';
import 'package:mindb/data/persistence/settings_repository.dart';
import 'package:mindb/domain/models/models.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  test('SettingsRepository migrates legacy Kimi model to moonshot-v1-8k', () async {
    SharedPreferences.setMockInitialValues({
      'llm_provider': 'kimi',
      'llm_model': 'kimi-k2-turbo-preview',
    });
    final prefs = await SharedPreferences.getInstance();
    final repo = SettingsRepository(prefs);

    await repo.migrateIfNeeded();
    final loaded = repo.load();

    expect(loaded.llmProvider, LlmProviderType.kimi);
    expect(loaded.llmModel, 'moonshot-v1-8k');
  });

  test('SettingsRepository persists models per provider', () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final repo = SettingsRepository(prefs);

    await repo.save(
      const AppSettings(
        llmProvider: LlmProviderType.openai,
        llmModel: 'gpt-4o',
      ),
      modelsByProvider: {
        LlmProviderType.openai: 'gpt-4o',
        LlmProviderType.anthropic: 'claude-3-5-haiku-latest',
        LlmProviderType.kimi: 'moonshot-v1-8k',
      },
    );

    expect(repo.loadModelFor(LlmProviderType.openai), 'gpt-4o');
    expect(
      repo.loadModelFor(LlmProviderType.anthropic),
      'claude-3-5-haiku-latest',
    );
    expect(repo.loadModelFor(LlmProviderType.kimi), 'moonshot-v1-8k');
  });

  test('LlmProviderType.fromName falls back to openai', () {
    expect(LlmProviderTypeX.fromName('kimi'), LlmProviderType.kimi);
    expect(LlmProviderTypeX.fromName('unknown'), LlmProviderType.openai);
  });

  test('provider model catalogs resolve unknown ids to recommended', () {
    expect(
      OpenAiModels.resolveForSettings('not-a-model'),
      OpenAiModels.recommended,
    );
    expect(
      AnthropicModels.resolveForSettings('not-a-model'),
      AnthropicModels.recommended,
    );
    expect(
      KimiModels.resolveForSettings('not-a-model'),
      KimiModels.recommended,
    );
    expect(
      LlmProviderModels.resolve(LlmProviderType.openai, 'gpt-4o'),
      'gpt-4o',
    );
  });
}

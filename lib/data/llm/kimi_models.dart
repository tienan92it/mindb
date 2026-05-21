import 'llm_model_option.dart';

/// Kimi (Moonshot) model IDs from https://platform.kimi.ai/docs/models
class KimiModels {
  KimiModels._();

  static const recommended = 'moonshot-v1-8k';

  /// Models available in Settings. K2 models may require a higher account tier.
  static const selectable = <LlmModelOption>[
    LlmModelOption(
      id: 'moonshot-v1-8k',
      label: 'moonshot-v1-8k (all tiers)',
    ),
    LlmModelOption(id: 'moonshot-v1-32k', label: 'moonshot-v1-32k'),
    LlmModelOption(id: 'moonshot-v1-128k', label: 'moonshot-v1-128k'),
    LlmModelOption(id: 'kimi-k2.5', label: 'kimi-k2.5'),
    LlmModelOption(id: 'kimi-k2.6', label: 'kimi-k2.6'),
    LlmModelOption(
      id: 'kimi-k2-turbo-preview',
      label: 'kimi-k2-turbo-preview (higher tier)',
    ),
  ];

  static const deprecated = {
    'kimi-latest',
    'kimi-thinking-preview',
  };

  /// Previous mindb default; not available on many API tiers.
  static const legacyAppDefault = 'kimi-k2-turbo-preview';

  static const migrationKey = 'settings_migrated_kimi_model_v1';

  static String normalize(String model) {
    final trimmed = model.trim();
    if (trimmed.isEmpty || deprecated.contains(trimmed)) {
      return recommended;
    }
    return trimmed;
  }

  static bool isKnownModel(String model) {
    return selectable.any((option) => option.id == model);
  }

  static String resolveForSettings(String model) {
    final normalized = normalize(model);
    if (isKnownModel(normalized)) {
      return normalized;
    }
    return recommended;
  }
}

import 'llm_model_option.dart';

class AnthropicModels {
  AnthropicModels._();

  static const recommended = 'claude-3-5-haiku-latest';

  static const selectable = <LlmModelOption>[
    LlmModelOption(
      id: 'claude-3-5-haiku-latest',
      label: 'claude-3-5-haiku-latest (recommended)',
    ),
    LlmModelOption(
      id: 'claude-3-5-sonnet-latest',
      label: 'claude-3-5-sonnet-latest',
    ),
    LlmModelOption(
      id: 'claude-3-7-sonnet-latest',
      label: 'claude-3-7-sonnet-latest',
    ),
    LlmModelOption(
      id: 'claude-sonnet-4-20250514',
      label: 'claude-sonnet-4-20250514',
    ),
    LlmModelOption(
      id: 'claude-opus-4-20250514',
      label: 'claude-opus-4-20250514',
    ),
  ];

  static bool isKnownModel(String model) {
    return selectable.any((option) => option.id == model);
  }

  static String resolveForSettings(String model) {
    final trimmed = model.trim();
    if (trimmed.isEmpty || !isKnownModel(trimmed)) {
      return recommended;
    }
    return trimmed;
  }
}

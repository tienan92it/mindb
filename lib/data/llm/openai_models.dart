import 'llm_model_option.dart';

class OpenAiModels {
  OpenAiModels._();

  static const recommended = 'gpt-4o-mini';

  static const selectable = <LlmModelOption>[
    LlmModelOption(id: 'gpt-4o-mini', label: 'gpt-4o-mini (recommended)'),
    LlmModelOption(id: 'gpt-4o', label: 'gpt-4o'),
    LlmModelOption(id: 'gpt-4.1-mini', label: 'gpt-4.1-mini'),
    LlmModelOption(id: 'gpt-4.1', label: 'gpt-4.1'),
    LlmModelOption(id: 'o4-mini', label: 'o4-mini'),
    LlmModelOption(id: 'o3-mini', label: 'o3-mini'),
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

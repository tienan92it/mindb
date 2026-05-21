import '../../domain/models/models.dart';
import 'anthropic_models.dart';
import 'kimi_models.dart';
import 'llm_model_option.dart';
import 'openai_models.dart';

class LlmProviderModels {
  LlmProviderModels._();

  static List<LlmModelOption> selectable(LlmProviderType provider) {
    switch (provider) {
      case LlmProviderType.openai:
        return OpenAiModels.selectable;
      case LlmProviderType.anthropic:
        return AnthropicModels.selectable;
      case LlmProviderType.kimi:
        return KimiModels.selectable
            .map((option) => LlmModelOption(id: option.id, label: option.label))
            .toList();
    }
  }

  static String resolve(LlmProviderType provider, String model) {
    switch (provider) {
      case LlmProviderType.openai:
        return OpenAiModels.resolveForSettings(model);
      case LlmProviderType.anthropic:
        return AnthropicModels.resolveForSettings(model);
      case LlmProviderType.kimi:
        return KimiModels.resolveForSettings(model);
    }
  }

  static bool isKnown(LlmProviderType provider, String model) {
    switch (provider) {
      case LlmProviderType.openai:
        return OpenAiModels.isKnownModel(model);
      case LlmProviderType.anthropic:
        return AnthropicModels.isKnownModel(model);
      case LlmProviderType.kimi:
        return KimiModels.isKnownModel(model);
    }
  }

  static String recommended(LlmProviderType provider) {
    return provider.defaultModel;
  }
}

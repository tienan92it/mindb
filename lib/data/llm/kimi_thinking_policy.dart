/// Kimi thinking-mode request policy for tool-calling sessions.
class KimiThinkingPolicy {
  KimiThinkingPolicy._();

  /// Models where thinking cannot be turned off (must round-trip [reasoning_content]).
  static bool requiresReasoningRoundTrip(String model) {
    return model == 'kimi-k2-thinking' || model.startsWith('kimi-k2-thinking-');
  }

  /// K2-family models enable thinking by default; disable for reliable tool loops.
  static Map<String, dynamic>? requestExtras(String model) {
    if (requiresReasoningRoundTrip(model)) {
      return null;
    }
    if (model.startsWith('kimi-k2')) {
      return {
        'thinking': {'type': 'disabled'},
      };
    }
    return null;
  }

  static bool shouldEncodeReasoningContent(String model) {
    return model.startsWith('kimi-k2') || model.contains('thinking');
  }
}

import 'package:flutter_test/flutter_test.dart';
import 'package:mindb/data/llm/kimi_thinking_policy.dart';

void main() {
  test('requestExtras disables thinking for kimi-k2.6', () {
    expect(
      KimiThinkingPolicy.requestExtras('kimi-k2.6'),
      {'thinking': {'type': 'disabled'}},
    );
  });

  test('requestExtras does not disable thinking for kimi-k2-thinking', () {
    expect(KimiThinkingPolicy.requestExtras('kimi-k2-thinking'), isNull);
    expect(KimiThinkingPolicy.requiresReasoningRoundTrip('kimi-k2-thinking'), isTrue);
  });

  test('shouldEncodeReasoningContent for k2 models', () {
    expect(KimiThinkingPolicy.shouldEncodeReasoningContent('kimi-k2.5'), isTrue);
    expect(KimiThinkingPolicy.shouldEncodeReasoningContent('moonshot-v1-8k'), isFalse);
  });
}

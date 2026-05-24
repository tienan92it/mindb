import 'package:flutter_test/flutter_test.dart';
import 'package:mindb/data/llm/llm_context_budget.dart';
import 'package:mindb/domain/models/models.dart';

void main() {
  group('LlmContextBudget', () {
    test('fitMessages trims oversized tool results before dropping history', () {
      final messages = [
        const ChatMessage(role: 'system', content: 'system'),
        ChatMessage(
          role: 'tool',
          content: 'x' * 200000,
          toolCallId: 'call_1',
        ),
        const ChatMessage(role: 'user', content: 'latest question'),
      ];

      final fitted = LlmContextBudget.fitMessages(
        messages: messages,
        maxMessageBytes: 50000,
      );

      expect(fitted.length, 3);
      expect(fitted.first.content, 'system');
      expect(fitted.last.content, 'latest question');
      expect(fitted[1].content.length, lessThan(200000));
      expect(fitted[1].content, contains('truncated for context limit'));
    });

    test('fitMessages leaves small payloads unchanged', () {
      final messages = [
        const ChatMessage(role: 'system', content: 'schema index'),
        const ChatMessage(role: 'user', content: 'count users'),
      ];

      final fitted = LlmContextBudget.fitMessages(
        messages: messages,
        maxMessageBytes: LlmContextBudget.kimiSafeMessageBytes,
      );

      expect(fitted.length, messages.length);
      expect(fitted[0].content, messages[0].content);
      expect(fitted[1].content, messages[1].content);
    });
  });
}

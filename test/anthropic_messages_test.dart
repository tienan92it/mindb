import 'package:flutter_test/flutter_test.dart';
import 'package:mindb/data/llm/anthropic_messages.dart';
import 'package:mindb/domain/models/models.dart';

void main() {
  group('encodeAnthropicMessages', () {
    test('assistant with toolCalls emits tool_use blocks', () {
      final encoded = encodeAnthropicMessages([
        ChatMessage(
          role: 'assistant',
          content: '',
          toolCalls: [
            LlmToolCall(
              id: 'toolu_abc',
              name: 'get_schema',
              arguments: {},
            ),
          ],
        ),
      ]);

      expect(encoded, hasLength(1));
      final content = encoded.first['content'] as List;
      expect(content, hasLength(1));
      expect(content.first['type'], 'tool_use');
      expect(content.first['id'], 'toolu_abc');
      expect(content.first['name'], 'get_schema');
      expect(content.first['input'], isEmpty);
    });

    test('tool message uses toolCallId in tool_use_id', () {
      final encoded = encodeAnthropicMessages([
        const ChatMessage(
          role: 'tool',
          content: 'schema yaml',
          toolCallId: 'toolu_xyz',
        ),
      ]);

      expect(encoded, hasLength(1));
      expect(encoded.first['role'], 'user');
      final content = encoded.first['content'] as List;
      expect(content.first['type'], 'tool_result');
      expect(content.first['tool_use_id'], 'toolu_xyz');
      expect(content.first['content'], 'schema yaml');
    });

    test('two consecutive tool messages coalesce into one user message', () {
      final encoded = encodeAnthropicMessages([
        const ChatMessage(
          role: 'tool',
          content: 'schema',
          toolCallId: 'toolu_1',
        ),
        const ChatMessage(
          role: 'tool',
          content: 'rows',
          toolCallId: 'toolu_2',
        ),
      ]);

      expect(encoded, hasLength(1));
      expect(encoded.first['role'], 'user');
      final content = encoded.first['content'] as List;
      expect(content, hasLength(2));
      expect(content[0]['tool_use_id'], 'toolu_1');
      expect(content[1]['tool_use_id'], 'toolu_2');
    });

    test('assistant with text and toolCalls includes both block types', () {
      final encoded = encodeAnthropicMessages([
        ChatMessage(
          role: 'assistant',
          content: 'Fetching schema.',
          toolCalls: [
            LlmToolCall(
              id: 'toolu_1',
              name: 'get_schema',
              arguments: {},
            ),
          ],
        ),
      ]);

      final content = encoded.first['content'] as List;
      expect(content, hasLength(2));
      expect(content[0]['type'], 'text');
      expect(content[0]['text'], 'Fetching schema.');
      expect(content[1]['type'], 'tool_use');
    });

    test('multi-round history preserves assistant tool_use for round 2', () {
      final encoded = encodeAnthropicMessages([
        const ChatMessage(role: 'user', content: 'list tables then count rows'),
        ChatMessage(
          role: 'assistant',
          content: '',
          toolCalls: [
            LlmToolCall(
              id: 'toolu_round1',
              name: 'get_schema',
              arguments: {},
            ),
          ],
        ),
        const ChatMessage(
          role: 'tool',
          content: 'tables: users',
          toolCallId: 'toolu_round1',
        ),
      ]);

      expect(encoded, hasLength(3));
      expect(encoded[0]['role'], 'user');
      expect(encoded[1]['role'], 'assistant');
      final assistantContent = encoded[1]['content'] as List;
      expect(
        assistantContent.any(
          (b) => b['type'] == 'tool_use' && b['id'] == 'toolu_round1',
        ),
        isTrue,
      );
      expect(encoded[2]['role'], 'user');
      final toolResults = encoded[2]['content'] as List;
      expect(toolResults.first['tool_use_id'], 'toolu_round1');
    });

    test('flushes tool results before next user message', () {
      final encoded = encodeAnthropicMessages([
        const ChatMessage(
          role: 'tool',
          content: 'ok',
          toolCallId: 'toolu_1',
        ),
        const ChatMessage(role: 'user', content: 'continue'),
      ]);

      expect(encoded, hasLength(2));
      expect(encoded[0]['role'], 'user');
      expect((encoded[0]['content'] as List).first['type'], 'tool_result');
      expect(encoded[1]['role'], 'user');
      expect((encoded[1]['content'] as List).first['type'], 'text');
    });
  });
}

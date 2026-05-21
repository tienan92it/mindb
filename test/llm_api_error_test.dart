import 'package:flutter_test/flutter_test.dart';
import 'package:mindb/data/llm/llm_api_error.dart';
import 'package:mindb/data/llm/openai_compatible_chat.dart';
import 'package:mindb/domain/models/models.dart';

void main() {
  test('formatLlmApiError surfaces Kimi model not found', () {
    const body = '''
{"error":{"type":"resource_not_found_error","message":"Not found the model kimi-k2-turbo-preview or Permission denied"}}
''';

    final message = formatLlmApiError(
      providerLabel: 'Kimi',
      statusCode: 404,
      body: body,
    );

    expect(message, contains('404'));
    expect(message, contains('moonshot-v1-8k'));
  });

  test('encodeOpenAiMessages preserves tool call chain', () {
    final encoded = encodeOpenAiMessages([
      const ChatMessage(role: 'user', content: 'list users'),
      ChatMessage(
        role: 'assistant',
        content: '',
        toolCalls: [
          LlmToolCall(id: 'call_1', name: 'execute_sql', arguments: {'sql': 'select 1'}),
        ],
      ),
      const ChatMessage(
        role: 'tool',
        content: 'ok',
        toolCallId: 'call_1',
      ),
    ]);

    expect(encoded[1]['tool_calls'], isNotEmpty);
    expect(encoded[2]['role'], 'tool');
    expect(encoded[2]['tool_call_id'], 'call_1');
  });

  test('encodeOpenAiMessages adds reasoning_content for Kimi tool turns', () {
    final encoded = encodeOpenAiMessages(
      [
        ChatMessage(
          role: 'assistant',
          content: '',
          reasoningContent: 'plan sql',
          toolCalls: [
            LlmToolCall(id: 'call_1', name: 'execute_sql', arguments: {'sql': 'select 1'}),
          ],
        ),
      ],
      kimiThinkingCompat: true,
    );

    expect(encoded.first['reasoning_content'], 'plan sql');
  });

  test('encodeOpenAiMessages uses placeholder reasoning_content when missing', () {
    final encoded = encodeOpenAiMessages(
      [
        ChatMessage(
          role: 'assistant',
          toolCalls: [
            LlmToolCall(id: 'call_1', name: 'get_schema', arguments: {}),
          ],
        ),
      ],
      kimiThinkingCompat: true,
    );

    expect(encoded.first['reasoning_content'], ' ');
  });
}

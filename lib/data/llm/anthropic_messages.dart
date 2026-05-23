import '../../domain/models/models.dart';

/// Encodes [ChatMessage] list into Anthropic Messages API `messages` shape.
///
/// Consecutive `tool` role messages are coalesced into one `user` message with
/// multiple `tool_result` blocks, per Anthropic's contract.
List<Map<String, dynamic>> encodeAnthropicMessages(List<ChatMessage> messages) {
  final encoded = <Map<String, dynamic>>[];
  final pendingToolResults = <Map<String, dynamic>>[];

  void flushToolResults() {
    if (pendingToolResults.isEmpty) return;
    encoded.add({
      'role': 'user',
      'content': List<Map<String, dynamic>>.from(pendingToolResults),
    });
    pendingToolResults.clear();
  }

  for (final message in messages) {
    if (message.role == 'tool') {
      pendingToolResults.add({
        'type': 'tool_result',
        'tool_use_id': message.toolCallId ?? 'tool',
        'content': message.content,
      });
      continue;
    }

    flushToolResults();

    switch (message.role) {
      case 'assistant':
        encoded.add(_encodeAssistantMessage(message));
      case 'user':
        encoded.add(_encodeUserMessage(message));
      default:
        encoded.add(_encodeUserMessage(message));
    }
  }

  flushToolResults();
  return encoded;
}

Map<String, dynamic> _encodeUserMessage(ChatMessage message) {
  return {
    'role': 'user',
    'content': [
      {'type': 'text', 'text': message.content},
    ],
  };
}

Map<String, dynamic> _encodeAssistantMessage(ChatMessage message) {
  final content = <Map<String, dynamic>>[];

  if (message.content.trim().isNotEmpty) {
    content.add({'type': 'text', 'text': message.content});
  }

  final toolCalls = message.toolCalls;
  if (toolCalls != null) {
    for (final call in toolCalls) {
      content.add({
        'type': 'tool_use',
        'id': call.id,
        'name': call.name,
        'input': call.arguments,
      });
    }
  }

  return {
    'role': 'assistant',
    'content': content,
  };
}

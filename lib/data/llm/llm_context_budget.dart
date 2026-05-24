import 'dart:convert';

import '../../domain/models/models.dart';

class LlmContextBudget {
  LlmContextBudget._();

  /// Moonshot/Kimi hard limit for serialized messages (4 MiB).
  static const kimiMaxMessageBytes = 4194304;

  /// Leave headroom for tools JSON, model name, and encoding overhead.
  static const kimiSafeMessageBytes = 3500000;

  static List<ChatMessage> fitMessages({
    required List<ChatMessage> messages,
    required int maxMessageBytes,
  }) {
    if (messages.isEmpty) {
      return messages;
    }

    final fitted = messages.map((message) => message.copyWith()).toList();
    if (_estimateBytes(fitted) <= maxMessageBytes) {
      return fitted;
    }

    for (var pass = 0; pass < 12 && _estimateBytes(fitted) > maxMessageBytes; pass++) {
      if (_truncateOldestToolResult(fitted)) {
        continue;
      }
      if (_truncateOldestNonSystemContent(fitted)) {
        continue;
      }
      if (_dropOldestHistoryTurn(fitted)) {
        continue;
      }
      break;
    }

    return fitted;
  }

  static int _estimateBytes(List<ChatMessage> messages) {
    final encoded = messages
        .map(
          (message) => {
            'role': message.role,
            'content': message.content,
            if (message.toolCallId != null) 'tool_call_id': message.toolCallId,
            if (message.toolCalls != null)
              'tool_calls': message.toolCalls!
                  .map(
                    (call) => {
                      'id': call.id,
                      'name': call.name,
                      'arguments': call.arguments,
                    },
                  )
                  .toList(),
            if (message.reasoningContent != null)
              'reasoning_content': message.reasoningContent,
          },
        )
        .toList();

    return utf8.encode(jsonEncode(encoded)).length;
  }

  static bool _truncateOldestToolResult(List<ChatMessage> messages) {
    for (var index = 0; index < messages.length - 1; index++) {
      final message = messages[index];
      if (message.role != 'tool' || message.content.length <= 2000) {
        continue;
      }

      messages[index] = message.copyWith(
        content: _truncate(message.content, message.content.length ~/ 2),
      );
      return true;
    }
    return false;
  }

  static bool _truncateOldestNonSystemContent(List<ChatMessage> messages) {
    for (var index = 0; index < messages.length - 1; index++) {
      final message = messages[index];
      if (message.role == 'system' || message.content.length <= 1000) {
        continue;
      }

      messages[index] = message.copyWith(
        content: _truncate(message.content, message.content.length ~/ 2),
      );
      return true;
    }
    return false;
  }

  static bool _dropOldestHistoryTurn(List<ChatMessage> messages) {
    if (messages.length <= 2) {
      return false;
    }

    final startIndex = messages.first.role == 'system' ? 1 : 0;
    if (startIndex >= messages.length - 1) {
      return false;
    }

    messages.removeAt(startIndex);
    return true;
  }

  static String _truncate(String value, int maxChars) {
    if (value.length <= maxChars) {
      return value;
    }
    const suffix = '\n...[truncated for context limit]';
    final keep = maxChars - suffix.length;
    if (keep <= 0) {
      return suffix.trim();
    }
    return '${value.substring(0, keep)}$suffix';
  }
}

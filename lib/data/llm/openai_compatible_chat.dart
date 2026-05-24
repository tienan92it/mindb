import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../core/app_logger.dart';
import '../../domain/models/models.dart';
import '../../domain/ports/ports.dart';
import 'llm_context_budget.dart';
import 'llm_api_error.dart';

class OpenAiCompatibleChatClient {
  OpenAiCompatibleChatClient({
    required this.client,
    this.maxRateLimitRetries = 3,
    this.maxRetryDelay = const Duration(seconds: 30),
  });

  final http.Client client;
  final int maxRateLimitRetries;
  final Duration maxRetryDelay;

  Future<LlmResponse> chat({
    required Uri endpoint,
    required Map<String, String> headers,
    required String model,
    required List<ChatMessage> messages,
    required List<LlmToolDefinition> tools,
    required String providerLabel,
    int? maxCompletionTokens,
    Map<String, dynamic>? extraPayload,
    int? maxMessageBytes,
    bool kimiThinkingCompat = false,
  }) async {
    final trimmedMessages = maxMessageBytes == null
        ? messages
        : LlmContextBudget.fitMessages(
            messages: messages,
            maxMessageBytes: maxMessageBytes,
          );

    final payload = <String, dynamic>{
      'model': model,
      'messages': encodeOpenAiMessages(
        trimmedMessages,
        kimiThinkingCompat: kimiThinkingCompat,
      ),
      'tools': tools
          .map(
            (tool) => {
              'type': 'function',
              'function': {
                'name': tool.name,
                'description': tool.description,
                'parameters': tool.parameters,
              },
            },
          )
          .toList(),
      if (maxCompletionTokens != null) 'max_completion_tokens': maxCompletionTokens,
      if (extraPayload != null) ...extraPayload,
    };

    final response = await _postWithRateLimitRetry(
      endpoint: endpoint,
      headers: headers,
      body: jsonEncode(payload),
      providerLabel: providerLabel,
    );

    if (response.statusCode >= 400) {
      appLogger.error(
        '$providerLabel error: ${response.statusCode} ${response.body}',
      );
      throw StateError(
        formatLlmApiError(
          providerLabel: providerLabel,
          statusCode: response.statusCode,
          body: response.body,
        ),
      );
    }

    return parseOpenAiChatResponse(response.body);
  }

  Future<http.Response> _postWithRateLimitRetry({
    required Uri endpoint,
    required Map<String, String> headers,
    required String body,
    required String providerLabel,
  }) async {
    http.Response? lastResponse;

    for (var attempt = 0; attempt <= maxRateLimitRetries; attempt++) {
      lastResponse = await client.post(endpoint, headers: headers, body: body);

      if (lastResponse.statusCode != 429 || attempt == maxRateLimitRetries) {
        return lastResponse;
      }

      final delay = _retryDelay(lastResponse, attempt);
      appLogger.warning(
        '$providerLabel rate limited (429). Retrying in ${delay.inSeconds}s '
        '(attempt ${attempt + 1}/$maxRateLimitRetries)',
      );
      await Future.delayed(delay);
    }

    return lastResponse!;
  }

  Duration _retryDelay(http.Response response, int attempt) {
    final retryAfter = response.headers['retry-after'];
    if (retryAfter != null) {
      final seconds = int.tryParse(retryAfter);
      if (seconds != null) {
        return Duration(seconds: seconds.clamp(1, maxRetryDelay.inSeconds));
      }
    }

    final backoffSeconds = (1 << attempt) * 2;
    return Duration(seconds: backoffSeconds.clamp(2, maxRetryDelay.inSeconds));
  }
}

List<Map<String, dynamic>> encodeOpenAiMessages(
  List<ChatMessage> messages, {
  bool kimiThinkingCompat = false,
}) {
  return messages.map((message) {
    if (message.role == 'tool') {
      return {
        'role': 'tool',
        'tool_call_id': message.toolCallId ?? 'tool',
        'content': message.content,
      };
    }

    if (message.toolCalls != null && message.toolCalls!.isNotEmpty) {
      final encoded = <String, dynamic>{
        'role': 'assistant',
        'content': message.content.isEmpty ? null : message.content,
        'tool_calls': message.toolCalls!
            .map(
              (call) => {
                'id': call.id,
                'type': 'function',
                'function': {
                  'name': call.name,
                  'arguments': jsonEncode(call.arguments),
                },
              },
            )
            .toList(),
      };
      if (kimiThinkingCompat) {
        encoded['reasoning_content'] = message.reasoningContent ?? ' ';
      }
      return encoded;
    }

    if (kimiThinkingCompat &&
        message.role == 'assistant' &&
        message.reasoningContent != null &&
        message.reasoningContent!.isNotEmpty) {
      return {
        'role': 'assistant',
        'content': message.content.isEmpty ? null : message.content,
        'reasoning_content': message.reasoningContent,
      };
    }

    return {
      'role': message.role,
      'content': message.content,
    };
  }).toList();
}

LlmResponse parseOpenAiChatResponse(String body) {
  final decoded = jsonDecode(body) as Map<String, dynamic>;
  final choice = (decoded['choices'] as List).first as Map<String, dynamic>;
  final message = choice['message'] as Map<String, dynamic>;
  final text = message['content']?.toString();
  final reasoningContent = message['reasoning_content']?.toString();

  final toolCallsRaw = message['tool_calls'] as List<dynamic>? ?? [];
  final toolCalls = toolCallsRaw.map((raw) {
    final call = raw as Map<String, dynamic>;
    final function = call['function'] as Map<String, dynamic>;
    final argsJson = function['arguments']?.toString() ?? '{}';
    final args = jsonDecode(argsJson) as Map<String, dynamic>;
    return LlmToolCall(
      id: call['id']?.toString() ?? function['name'].toString(),
      name: function['name'].toString(),
      arguments: args,
    );
  }).toList();

  return LlmResponse(
    text: text,
    toolCalls: toolCalls,
    reasoningContent: reasoningContent,
  );
}

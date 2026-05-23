import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../core/app_logger.dart';
import '../../domain/models/models.dart';
import '../../domain/ports/ports.dart';
import 'anthropic_messages.dart';

class AnthropicProvider implements LlmProvider {
  AnthropicProvider({
    required this.apiKey,
    required this.model,
    http.Client? client,
  }) : _client = client ?? http.Client();

  final String apiKey;
  final String model;
  final http.Client _client;

  @override
  LlmProviderType get providerType => LlmProviderType.anthropic;

  @override
  Future<LlmResponse> chat({
    required List<ChatMessage> messages,
    required List<LlmToolDefinition> tools,
  }) async {
    final systemMessages =
        messages.where((m) => m.role == 'system').map((m) => m.content).join('\n');
    final conversation = encodeAnthropicMessages(
      messages.where((m) => m.role != 'system').toList(),
    );

    final payload = {
      'model': model,
      'max_tokens': 4096,
      if (systemMessages.isNotEmpty) 'system': systemMessages,
      'messages': conversation,
      'tools': tools
          .map(
            (tool) => {
              'name': tool.name,
              'description': tool.description,
              'input_schema': tool.parameters,
            },
          )
          .toList(),
    };

    final response = await _client.post(
      Uri.parse('https://api.anthropic.com/v1/messages'),
      headers: {
        'x-api-key': apiKey,
        'anthropic-version': '2023-06-01',
        'Content-Type': 'application/json',
      },
      body: jsonEncode(payload),
    );

    if (response.statusCode >= 400) {
      appLogger.error(
        'Anthropic error: ${response.statusCode} ${response.body}',
      );
      throw StateError('Anthropic request failed: ${response.statusCode}');
    }

    final body = jsonDecode(response.body) as Map<String, dynamic>;
    final content = body['content'] as List<dynamic>? ?? [];

    final textParts = <String>[];
    final toolCalls = <LlmToolCall>[];

    for (final block in content) {
      final item = block as Map<String, dynamic>;
      final type = item['type']?.toString();
      if (type == 'text') {
        textParts.add(item['text']?.toString() ?? '');
      } else if (type == 'tool_use') {
        toolCalls.add(
          LlmToolCall(
            id: item['id']?.toString() ?? item['name'].toString(),
            name: item['name'].toString(),
            arguments: Map<String, dynamic>.from(
              item['input'] as Map? ?? {},
            ),
          ),
        );
      }
    }

    return LlmResponse(
      text: textParts.join('\n').trim().isEmpty ? null : textParts.join('\n'),
      toolCalls: toolCalls,
    );
  }
}

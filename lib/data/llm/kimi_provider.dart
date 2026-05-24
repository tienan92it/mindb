import 'package:http/http.dart' as http;

import '../../domain/models/models.dart';
import '../../domain/ports/ports.dart';
import 'kimi_thinking_policy.dart';
import 'llm_context_budget.dart';
import 'openai_compatible_chat.dart';

/// Kimi (Moonshot AI) — OpenAI-compatible chat completions API.
class KimiProvider implements LlmProvider {
  KimiProvider({
    required this.apiKey,
    required this.model,
    this.baseUrl = 'https://api.moonshot.ai/v1',
    http.Client? client,
  })  : _client = client ?? http.Client(),
        _chatClient = OpenAiCompatibleChatClient(client: client ?? http.Client());

  final String apiKey;
  final String model;
  final String baseUrl;
  final http.Client _client;
  final OpenAiCompatibleChatClient _chatClient;

  @override
  LlmProviderType get providerType => LlmProviderType.kimi;

  @override
  Future<LlmResponse> chat({
    required List<ChatMessage> messages,
    required List<LlmToolDefinition> tools,
  }) async {
    return _chatClient.chat(
      endpoint: Uri.parse('$baseUrl/chat/completions'),
      headers: {
        'Authorization': 'Bearer $apiKey',
        'Content-Type': 'application/json',
      },
      model: model,
      messages: messages,
      tools: tools,
      providerLabel: 'Kimi',
      maxCompletionTokens: 16384,
      maxMessageBytes: LlmContextBudget.kimiSafeMessageBytes,
      extraPayload: KimiThinkingPolicy.requestExtras(model),
      kimiThinkingCompat: KimiThinkingPolicy.shouldEncodeReasoningContent(model),
    );
  }

  void close() => _client.close();
}

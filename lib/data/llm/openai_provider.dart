import 'package:http/http.dart' as http;

import '../../domain/models/models.dart';
import '../../domain/ports/ports.dart';
import 'openai_compatible_chat.dart';

class OpenAiProvider implements LlmProvider {
  OpenAiProvider({
    required this.apiKey,
    required this.model,
    http.Client? client,
  })  : _client = client ?? http.Client(),
        _chatClient = OpenAiCompatibleChatClient(client: client ?? http.Client());

  final String apiKey;
  final String model;
  final http.Client _client;
  final OpenAiCompatibleChatClient _chatClient;

  @override
  LlmProviderType get providerType => LlmProviderType.openai;

  @override
  Future<LlmResponse> chat({
    required List<ChatMessage> messages,
    required List<LlmToolDefinition> tools,
  }) async {
    return _chatClient.chat(
      endpoint: Uri.parse('https://api.openai.com/v1/chat/completions'),
      headers: {
        'Authorization': 'Bearer $apiKey',
        'Content-Type': 'application/json',
      },
      model: model,
      messages: messages,
      tools: tools,
      providerLabel: 'OpenAI',
    );
  }

  void close() => _client.close();
}

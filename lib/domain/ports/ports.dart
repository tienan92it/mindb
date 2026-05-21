import '../models/models.dart';

abstract class DatabaseClient {
  Future<void> connect(ConnectionProfile profile, String password);

  Future<void> disconnect();

  bool get isConnected;

  Future<QueryResult> execute(String sql, {Duration? timeout});
}

abstract class CredentialStore {
  Future<void> saveConnectionPassword(String connectionId, String password);

  Future<String?> readConnectionPassword(String connectionId);

  Future<void> deleteConnectionPassword(String connectionId);

  Future<void> saveLlmApiKey(LlmProviderType provider, String apiKey);

  Future<String?> readLlmApiKey(LlmProviderType provider);

  Future<void> deleteLlmApiKey(LlmProviderType provider);
}

typedef ConfirmationHandler = Future<bool> Function(
  String sql,
  SqlClassification classification,
);

abstract class LlmProvider {
  LlmProviderType get providerType;

  Future<LlmResponse> chat({
    required List<ChatMessage> messages,
    required List<LlmToolDefinition> tools,
  });
}

class LlmToolDefinition {
  const LlmToolDefinition({
    required this.name,
    required this.description,
    required this.parameters,
  });

  final String name;
  final String description;
  final Map<String, dynamic> parameters;
}

class LlmResponse {
  const LlmResponse({
    this.text,
    this.toolCalls = const [],
    this.reasoningContent,
  });

  final String? text;
  final List<LlmToolCall> toolCalls;
  final String? reasoningContent;

  bool get hasToolCalls => toolCalls.isNotEmpty;
}

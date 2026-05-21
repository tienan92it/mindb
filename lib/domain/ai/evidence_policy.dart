/// Determines when answers must be backed by database tool results.
class EvidencePolicy {
  const EvidencePolicy._();

  static bool requiresDatabaseQuery(String userPrompt) {
    final lower = userPrompt.trim().toLowerCase();
    if (lower.isEmpty) {
      return false;
    }
    if (lower.startsWith('sql:')) {
      return false;
    }

    const conversationalOnly = [
      'hello',
      'hi',
      'hey',
      'thanks',
      'thank you',
      'help',
      'what can you do',
      'who are you',
    ];

    for (final phrase in conversationalOnly) {
      if (lower == phrase || lower.startsWith('$phrase ')) {
        return false;
      }
    }

    return true;
  }

  static bool messagesIncludeToolResults(List<({String role})> messages) {
    return messages.any((message) => message.role == 'tool');
  }

  static const noEvidenceReply =
      'Unknown — no database evidence was retrieved for this question. '
      'Ask again or prefix with sql: to run a query directly.';
}

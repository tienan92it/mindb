import 'package:flutter_test/flutter_test.dart';
import 'package:mindb/data/llm/llm_api_error.dart';
import 'package:mindb/domain/models/models.dart';
import 'package:mindb/features/session/session_providers.dart';

void main() {
  test('transcriptErrorLineForNlFailure maps 401 to ErrorLine with settings', () {
    final message = formatLlmApiError(
      providerLabel: 'OpenAI',
      statusCode: 401,
      body: '{"error":{"message":"invalid_api_key"}}',
    );
    final line = transcriptErrorLineForNlFailure(StateError(message));

    expect(line, isA<ErrorLine>());
    expect(line.message, contains('authentication'));
    expect(line.action, SessionRecoveryAction.settings);
  });
}

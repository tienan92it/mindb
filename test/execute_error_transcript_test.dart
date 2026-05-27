import 'package:flutter_test/flutter_test.dart';
import 'package:mindb/domain/models/models.dart';
import 'package:mindb/features/session/session_providers.dart';

void main() {
  test(
    'transcriptErrorLineForExecuteFailure maps read-only to ErrorLine with settings',
    () {
      final line = transcriptErrorLineForExecuteFailure(
        StateError('Read-only mode: write/destructive SQL is blocked'),
      );

      expect(line, isA<ErrorLine>());
      expect(line.message.toLowerCase(), contains('read-only'));
      expect(line.action, SessionRecoveryAction.settings);
    },
  );
}

import 'package:flutter_test/flutter_test.dart';
import 'package:mindb/domain/models/models.dart';
import 'package:mindb/features/session/session_providers.dart';

void main() {
  test('transcriptLineForSchemaDegraded maps to SystemLine with prefix', () {
    final line = transcriptLineForSchemaDegraded('permission denied');
    expect(line, isA<SystemLine>());
    expect(
      (line as SystemLine).text,
      'Schema unavailable — permission denied',
    );
  });
}

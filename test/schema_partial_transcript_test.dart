import 'package:flutter_test/flutter_test.dart';
import 'package:mindb/domain/models/models.dart';
import 'package:mindb/features/session/session_providers.dart';

void main() {
  test('transcriptLineForSchemaPartial maps to SystemLine with counts', () {
    final line = transcriptLineForSchemaPartial(
      shownTables: 10,
      totalTables: 500,
    );
    expect(line, isA<SystemLine>());
    expect(
      (line as SystemLine).text,
      contains('Schema index partial —'),
    );
    expect((line as SystemLine).text, contains('10 of 500'));
  });
}

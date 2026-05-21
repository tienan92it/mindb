import 'package:flutter_test/flutter_test.dart';
import 'package:mindb/core/log_redactor.dart';

void main() {
  group('LogRedactor', () {
    test('redacts password values', () {
      const input = 'connect password=secret123 host=localhost';
      final output = LogRedactor.redact(input);
      expect(output, contains('[REDACTED]'));
      expect(output, isNot(contains('secret123')));
    });

    test('redacts api keys', () {
      const input = 'Authorization: Bearer sk-abcdefghijklmnopqrstuvwxyz123456';
      final output = LogRedactor.redact(input);
      expect(output, isNot(contains('sk-abcdefghijklmnopqrstuvwxyz123456')));
    });

    test('redacts postgres URLs', () {
      const input = 'postgresql://user:pass@localhost:5432/db';
      final output = LogRedactor.redact(input);
      expect(output, isNot(contains('pass')));
    });
  });
}

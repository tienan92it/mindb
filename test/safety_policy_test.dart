import 'package:flutter_test/flutter_test.dart';
import 'package:mindb/domain/models/models.dart';
import 'package:mindb/domain/safety/safety_policy.dart';

void main() {
  group('SafetyPolicy', () {
    const policy = SafetyPolicy();

    test('classifies SELECT as safe', () {
      expect(policy.classify('SELECT * FROM users'), SqlClassification.safe);
    });

    test('classifies INSERT as write', () {
      expect(
        policy.classify('INSERT INTO users (name) VALUES (\'a\')'),
        SqlClassification.write,
      );
    });

    test('classifies DROP as destructive', () {
      expect(
        policy.classify('DROP TABLE users'),
        SqlClassification.destructive,
      );
    });

    test('blocks writes in read-only mode', () {
      const readOnly = SafetyPolicy(readOnlyMode: true);
      expect(readOnly.isReadOnlyAllowed('SELECT 1'), isTrue);
      expect(readOnly.isReadOnlyAllowed('DELETE FROM users'), isFalse);
    });

    test('injects LIMIT on SELECT without limit', () {
      final result = policy.injectLimit('SELECT * FROM users', 100);
      expect(result.toUpperCase(), contains('LIMIT 100'));
    });

    test('does not double inject LIMIT', () {
      final result = policy.injectLimit('SELECT * FROM users LIMIT 50', 100);
      expect(result, 'SELECT * FROM users LIMIT 50');
    });
  });
}

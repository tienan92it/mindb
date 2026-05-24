import 'package:flutter_test/flutter_test.dart';
import 'package:mindb/features/connections/onboarding_status.dart';

void main() {
  group('computeOnboardingStatus', () {
    test('canOpenSession only when connection and key present', () {
      expect(
        computeOnboardingStatus(connectionCount: 0, hasLlmKey: false)
            .canOpenSession,
        isFalse,
      );
      expect(
        computeOnboardingStatus(connectionCount: 1, hasLlmKey: false)
            .canOpenSession,
        isFalse,
      );
      expect(
        computeOnboardingStatus(connectionCount: 0, hasLlmKey: true)
            .canOpenSession,
        isFalse,
      );
      expect(
        computeOnboardingStatus(connectionCount: 2, hasLlmKey: true)
            .canOpenSession,
        isTrue,
      );
    });

    test('hasConnection reflects connection count', () {
      expect(
        computeOnboardingStatus(connectionCount: 0, hasLlmKey: true)
            .hasConnection,
        isFalse,
      );
      expect(
        computeOnboardingStatus(connectionCount: 1, hasLlmKey: false)
            .hasConnection,
        isTrue,
      );
    });

    test('hasLlmKey passes through', () {
      expect(
        computeOnboardingStatus(connectionCount: 1, hasLlmKey: true).hasLlmKey,
        isTrue,
      );
      expect(
        computeOnboardingStatus(connectionCount: 1, hasLlmKey: false).hasLlmKey,
        isFalse,
      );
    });
  });
}

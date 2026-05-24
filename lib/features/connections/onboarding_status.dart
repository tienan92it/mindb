/// Readiness for cold-install → first natural-language query.
class OnboardingStatus {
  const OnboardingStatus({
    required this.hasConnection,
    required this.hasLlmKey,
  });

  final bool hasConnection;
  final bool hasLlmKey;

  bool get canOpenSession => hasConnection && hasLlmKey;
}

OnboardingStatus computeOnboardingStatus({
  required int connectionCount,
  required bool hasLlmKey,
}) {
  return OnboardingStatus(
    hasConnection: connectionCount > 0,
    hasLlmKey: hasLlmKey,
  );
}

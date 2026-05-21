import 'dart:convert';

String formatLlmApiError({
  required String providerLabel,
  required int statusCode,
  required String body,
}) {
  final detail = _extractErrorMessage(body);

  if (statusCode == 429) {
    return '$providerLabel rate limit (429): $detail\n'
        'Wait a minute and retry, or switch to a lighter model (e.g. moonshot-v1-8k). '
        'Kimi limits RPM/TPM by account tier.';
  }

  if (statusCode == 400 && _isReasoningContentError(detail)) {
    return '$providerLabel tool-call error (400): $detail\n'
        'Try moonshot-v1-8k in Settings, or update mindb to the latest build.';
  }

  if (statusCode == 404 && _isModelNotFound(detail)) {
    return '$providerLabel model error (404): $detail\n'
        'Open Settings → pick moonshot-v1-8k (works on all tiers). '
        'K2 models require a higher Kimi API tier. '
        'Use platform.kimi.ai keys with api.moonshot.ai.';
  }

  return '$providerLabel request failed ($statusCode): $detail';
}

bool _isReasoningContentError(String detail) {
  return detail.toLowerCase().contains('reasoning_content');
}

bool _isModelNotFound(String detail) {
  final lower = detail.toLowerCase();
  return lower.contains('model') ||
      lower.contains('resource_not_found') ||
      lower.contains('permission denied');
}

String _extractErrorMessage(String body) {
  try {
    final decoded = jsonDecode(body);
    if (decoded is Map<String, dynamic>) {
      final error = decoded['error'];
      if (error is Map<String, dynamic>) {
        final type = error['type']?.toString();
        final message = error['message']?.toString();
        if (type != null && message != null) {
          return '$type — $message';
        }
        if (message != null) {
          return message;
        }
      }
      final message = decoded['message']?.toString();
      if (message != null) {
        return message;
      }
    }
  } catch (_) {
    // Fall through to raw body.
  }

  final trimmed = body.trim();
  if (trimmed.isEmpty) {
    return 'No error details returned';
  }
  return trimmed.length > 240 ? '${trimmed.substring(0, 240)}…' : trimmed;
}

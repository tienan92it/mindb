/// Redacts sensitive values from log messages before they are written.
class LogRedactor {
  static final _patterns = <RegExp>[
    RegExp(r'password\s*[=:]\s*[^\s,;]+', caseSensitive: false),
    RegExp(r'api[_-]?key\s*[=:]\s*[^\s,;]+', caseSensitive: false),
    RegExp(r'Bearer\s+[A-Za-z0-9\-._~+/]+=*', caseSensitive: false),
    RegExp(r'sk-[A-Za-z0-9]{20,}', caseSensitive: false),
    RegExp(r'postgresql://[^\s]+', caseSensitive: false),
  ];

  static String redact(String message) {
    var result = message;
    for (final pattern in _patterns) {
      result = result.replaceAllMapped(pattern, (match) {
        final text = match.group(0)!;
        final separatorIndex = text.indexOf(RegExp(r'[=:]'));
        if (separatorIndex != -1) {
          return '${text.substring(0, separatorIndex + 1)} [REDACTED]';
        }
        return '[REDACTED]';
      });
    }
    return result;
  }
}

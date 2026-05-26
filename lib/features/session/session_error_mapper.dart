import 'dart:io';

/// Where the session screen should send the user after a connect failure.
enum SessionRecoveryAction {
  none,
  settings,
  editConnection,
}

class SessionErrorMapping {
  const SessionErrorMapping({
    required this.message,
    this.action = SessionRecoveryAction.none,
  });

  final String message;
  final SessionRecoveryAction action;
}

/// Maps connect-time exceptions to short copy and recovery CTAs.
abstract final class SessionErrorMapper {
  static SessionErrorMapping mapSchemaIntrospectionFailure(Object error) {
    final text = error.toString();

    if (error is StateError) {
      final msg = error.message;
      if (msg.contains('Not connected')) {
        return const SessionErrorMapping(
          message: 'Not connected to the database.',
        );
      }
    }

    final lower = text.toLowerCase();
    if (lower.contains('permission denied') ||
        lower.contains('denied') ||
        lower.contains('42501') ||
        lower.contains('information_schema')) {
      return const SessionErrorMapping(
        message:
            'Cannot read database schema (permission denied). '
            'Natural-language answers may not match your tables.',
      );
    }

    return SessionErrorMapping(message: _shorten(text));
  }

  static SessionErrorMapping map(Object error) {
    final text = error.toString();

    if (error is StateError) {
      final msg = error.message;
      if (msg.contains('LLM API key not configured')) {
        return const SessionErrorMapping(
          message: 'LLM API key not configured. Add your key in Settings.',
          action: SessionRecoveryAction.settings,
        );
      }
      if (msg.contains('Password not stored') ||
          msg.contains('Connection not found')) {
        return SessionErrorMapping(
          message: _shorten(msg),
          action: SessionRecoveryAction.editConnection,
        );
      }
    }

    if (error is SocketException || _looksLikeNetworkFailure(text)) {
      return const SessionErrorMapping(
        message:
            'Could not reach the database host. Check host, port, and network.',
        action: SessionRecoveryAction.editConnection,
      );
    }

    return SessionErrorMapping(message: _shorten(text));
  }

  static bool _looksLikeNetworkFailure(String text) {
    final lower = text.toLowerCase();
    return lower.contains('socketexception') ||
        lower.contains('connection refused') ||
        lower.contains('connection timed out') ||
        lower.contains('failed host lookup') ||
        lower.contains('network is unreachable');
  }

  static String _shorten(String text) {
    if (text.length <= 160) return text;
    return '${text.substring(0, 157)}...';
  }
}

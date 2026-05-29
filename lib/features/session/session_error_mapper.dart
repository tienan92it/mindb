import 'dart:async';
import 'dart:io';

import '../../domain/models/models.dart';

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

  /// Maps direct SQL / `QueryExecutor` failures to transcript copy.
  static SessionErrorMapping mapExecuteFailure(Object error) {
    if (error is StateError) {
      final msg = error.message;
      if (msg.contains('Read-only mode')) {
        return const SessionErrorMapping(
          message:
              'Read-only mode is on. Turn off read-only in Settings '
              'to run write or DDL SQL.',
          action: SessionRecoveryAction.settings,
        );
      }
      if (msg.contains('Query cancelled by user')) {
        return const SessionErrorMapping(
          message: 'Query cancelled. No changes were made.',
        );
      }
      if (msg.contains('Not connected')) {
        return const SessionErrorMapping(
          message: 'Not connected to the database.',
        );
      }
      if (msg.contains('Confirmation required')) {
        return const SessionErrorMapping(
          message: 'Could not confirm this query. Reconnect and try again.',
        );
      }
    }

    if (error is TimeoutException) {
      final seconds = error.duration?.inSeconds;
      final limit = seconds != null && seconds > 0
          ? '$seconds second${seconds == 1 ? '' : 's'}'
          : 'the configured limit';
      return SessionErrorMapping(
        message:
            'Query timed out after $limit. '
            'Increase query timeout in Settings to run longer SQL.',
        action: SessionRecoveryAction.settings,
      );
    }

    final text = error.toString();
    if (error is SocketException || _looksLikeNetworkFailure(text)) {
      return const SessionErrorMapping(
        message:
            'Could not reach the database host. Check host, port, and network.',
        action: SessionRecoveryAction.editConnection,
      );
    }

    return SessionErrorMapping(message: _shorten(text));
  }

  static SessionErrorMapping mapNlFailure(Object error) {
    if (error is String) {
      return SessionErrorMapping(message: error);
    }

    final text = _nlErrorText(error);

    if (error is StateError && text.contains('LLM API key not configured')) {
      return const SessionErrorMapping(
        message: 'LLM API key not configured. Add your key in Settings.',
        action: SessionRecoveryAction.settings,
      );
    }

    if (error is SocketException || _looksLikeNetworkFailure(text)) {
      return const SessionErrorMapping(
        message:
            'Could not reach the LLM API. Check network and try again.',
        action: SessionRecoveryAction.settings,
      );
    }

    final lower = text.toLowerCase();

    if (lower.contains('401') ||
        lower.contains('invalid_api_key') ||
        lower.contains('incorrect api key') ||
        lower.contains('authentication')) {
      return const SessionErrorMapping(
        message:
            'LLM API authentication failed. Check your API key in Settings.',
        action: SessionRecoveryAction.settings,
      );
    }

    if (lower.contains('403') ||
        (lower.contains('permission') && lower.contains('api'))) {
      return const SessionErrorMapping(
        message:
            'LLM API access denied for this key. '
            'Check provider account tier in Settings.',
        action: SessionRecoveryAction.settings,
      );
    }

    if (lower.contains('429') || lower.contains('rate limit')) {
      final firstLine = text.split('\n').first.trim();
      final message = firstLine.isNotEmpty
          ? firstLine
          : 'LLM rate limit reached. Wait and retry, or choose a lighter model in Settings.';
      return SessionErrorMapping(
        message: message,
        action: SessionRecoveryAction.settings,
      );
    }

    if (error is StateError && _isFormattedLlmProviderError(text)) {
      return SessionErrorMapping(
        message: text,
        action: _nlMessageMentionsSettingsOrKey(text)
            ? SessionRecoveryAction.settings
            : SessionRecoveryAction.none,
      );
    }

    return SessionErrorMapping(message: _shorten(text));
  }

  static String _nlErrorText(Object error) {
    if (error is StateError) {
      return error.message;
    }
    return error.toString();
  }

  static bool _isFormattedLlmProviderError(String message) {
    return message.contains(' request failed (') ||
        message.contains('rate limit (429)') ||
        message.contains('context too large (400)') ||
        message.contains('model error (404)') ||
        message.contains('tool-call error (400)');
  }

  static bool _nlMessageMentionsSettingsOrKey(String message) {
    final lower = message.toLowerCase();
    return lower.contains('settings') || lower.contains('api key');
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

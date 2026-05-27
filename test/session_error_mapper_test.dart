import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:mindb/data/llm/llm_api_error.dart';
import 'package:mindb/domain/models/models.dart';
import 'package:mindb/features/session/session_error_mapper.dart';

void main() {
  group('SessionErrorMapper', () {
    test('maps missing LLM API key to settings action', () {
      final mapped = SessionErrorMapper.map(
        StateError('LLM API key not configured. Open Settings.'),
      );
      expect(mapped.message, contains('LLM API key'));
      expect(mapped.action, SessionRecoveryAction.settings);
    });

    test('maps missing password to edit connection', () {
      final mapped = SessionErrorMapper.map(
        StateError('Password not stored for this connection'),
      );
      expect(mapped.message, contains('Password not stored'));
      expect(mapped.action, SessionRecoveryAction.editConnection);
    });

    test('maps connection not found to edit connection', () {
      final mapped = SessionErrorMapper.map(StateError('Connection not found'));
      expect(mapped.action, SessionRecoveryAction.editConnection);
    });

    test('maps socket failures to host reachability message', () {
      final mapped = SessionErrorMapper.map(
        const SocketException('Connection refused'),
      );
      expect(mapped.message, contains('Could not reach'));
      expect(mapped.action, SessionRecoveryAction.editConnection);
    });

    test('maps generic network strings', () {
      final mapped = SessionErrorMapper.map(
        Exception('SocketException: Failed host lookup'),
      );
      expect(mapped.message, contains('Could not reach'));
      expect(mapped.action, SessionRecoveryAction.editConnection);
    });

    test('unknown errors use none action', () {
      final mapped = SessionErrorMapper.map(Exception('unexpected'));
      expect(mapped.action, SessionRecoveryAction.none);
      expect(mapped.message, contains('unexpected'));
    });
  });

  group('mapSchemaIntrospectionFailure', () {
    test('permission on information_schema uses permission copy', () {
      final mapped = SessionErrorMapper.mapSchemaIntrospectionFailure(
        Exception(
          'PostgresqlException: permission denied for table information_schema.columns',
        ),
      );
      expect(mapped.message, contains('permission denied'));
      expect(mapped.message, contains('Natural-language answers'));
      expect(mapped.message, isNot(contains('PostgresqlException')));
    });

    test('not connected uses short copy', () {
      final mapped = SessionErrorMapper.mapSchemaIntrospectionFailure(
        StateError('Not connected to database'),
      );
      expect(mapped.message, 'Not connected to the database.');
    });

    test('long generic errors are shortened', () {
      final mapped = SessionErrorMapper.mapSchemaIntrospectionFailure(
        Exception('x' * 200),
      );
      expect(mapped.message.length, lessThanOrEqualTo(160));
    });
  });

  group('mapNlFailure', () {
    test('maps missing LLM API key to settings action', () {
      final mapped = SessionErrorMapper.mapNlFailure(
        StateError('LLM API key not configured. Open Settings.'),
      );
      expect(mapped.message, contains('API key'));
      expect(mapped.action, SessionRecoveryAction.settings);
    });

    test('maps formatLlmApiError 401 without Bad state prefix', () {
      final message = formatLlmApiError(
        providerLabel: 'OpenAI',
        statusCode: 401,
        body: '{"error":{"message":"invalid_api_key"}}',
      );
      final mapped = SessionErrorMapper.mapNlFailure(StateError(message));
      expect(mapped.action, SessionRecoveryAction.settings);
      expect(mapped.message, isNot(contains('Bad state')));
      expect(mapped.message, contains('authentication'));
    });

    test('maps OpenAI rate limit StateError to settings', () {
      final mapped = SessionErrorMapper.mapNlFailure(
        StateError('OpenAI rate limit (429): too many requests'),
      );
      expect(mapped.action, SessionRecoveryAction.settings);
      expect(mapped.message, anyOf(contains('rate'), contains('429')));
    });

    test('maps socket failures to LLM network message', () {
      final mapped = SessionErrorMapper.mapNlFailure(
        const SocketException('Connection refused'),
      );
      expect(mapped.message, contains('LLM API'));
      expect(mapped.action, SessionRecoveryAction.settings);
    });

    test('maps generic network strings for NL path', () {
      final mapped = SessionErrorMapper.mapNlFailure(
        Exception('SocketException: Failed host lookup'),
      );
      expect(mapped.message, contains('LLM API'));
      expect(mapped.action, SessionRecoveryAction.settings);
    });

    test('maps Anthropic 401 exception to auth settings copy', () {
      final mapped = SessionErrorMapper.mapNlFailure(
        Exception('Anthropic request failed: 401'),
      );
      expect(mapped.message, contains('authentication'));
      expect(mapped.action, SessionRecoveryAction.settings);
    });

    test('preserves max tool rounds message without settings action', () {
      const message = 'Agent reached maximum tool rounds';
      final mapped = SessionErrorMapper.mapNlFailure(message);
      expect(mapped.message, message);
      expect(mapped.action, SessionRecoveryAction.none);
    });

    test('maps formatLlmApiError context message with settings when mentioned', () {
      final message = formatLlmApiError(
        providerLabel: 'Kimi',
        statusCode: 400,
        body:
            '{"error":{"message":"Invalid request: total message size exceeds limit"}}',
      );
      final mapped = SessionErrorMapper.mapNlFailure(StateError(message));
      expect(mapped.message, contains('context too large'));
      expect(mapped.action, SessionRecoveryAction.none);
    });

    test('maps formatLlmApiError model error with settings action', () {
      const body =
          '{"error":{"type":"resource_not_found_error","message":"Not found the model kimi-k2-turbo-preview"}}';
      final message = formatLlmApiError(
        providerLabel: 'Kimi',
        statusCode: 404,
        body: body,
      );
      final mapped = SessionErrorMapper.mapNlFailure(StateError(message));
      expect(mapped.message, contains('404'));
      expect(mapped.action, SessionRecoveryAction.settings);
    });

    test('unknown long errors are shortened', () {
      final mapped = SessionErrorMapper.mapNlFailure(Exception('x' * 200));
      expect(mapped.message.length, lessThanOrEqualTo(160));
      expect(mapped.action, SessionRecoveryAction.none);
    });
  });
}

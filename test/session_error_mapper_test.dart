import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
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
}

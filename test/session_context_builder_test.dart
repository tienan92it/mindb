import 'package:flutter_test/flutter_test.dart';
import 'package:mindb/domain/models/models.dart';
import 'package:mindb/domain/models/session_context.dart';
import 'package:mindb/domain/session/session_context_builder.dart';

void main() {
  final builder = SessionContextBuilder(maxVerbatimTurns: 4);

  SessionContext base(String id) => SessionContext(
        connectionId: id,
        updatedAt: DateTime.now(),
      );

  test('buildLlmHistory returns verbatim user and assistant turns', () {
    final context = base('c1').copyWith(
      turns: [
        SessionTurn(
          role: 'user',
          content: 'show users',
          createdAt: DateTime.now(),
        ),
        SessionTurn(
          role: 'assistant',
          content: 'Found 3 users',
          createdAt: DateTime.now(),
        ),
      ],
    );

    final history = builder.buildLlmHistory(context);
    expect(history.length, 2);
    expect(history.first.role, 'user');
    expect(history.last.role, 'assistant');
  });

  test('appendTurn rolls older turns into summary', () {
    var context = base('c1');
    for (var i = 0; i < 5; i++) {
      context = builder.appendTurn(
        context,
        SessionTurn(
          role: 'user',
          content: 'question $i',
          createdAt: DateTime.now(),
        ),
      );
    }

    expect(context.turns.length, lessThanOrEqualTo(4));
    expect(context.summary, contains('question 0'));
    expect(context.summary, contains('User:'));
  });

  test('extractAssistantReply prefers AgentDoneEvent', () {
    const events = [
      AgentTextEvent('partial'),
      AgentDoneEvent('final answer'),
    ];

    expect(builder.extractAssistantReply(events), 'final answer');
  });
}

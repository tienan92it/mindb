import '../models/models.dart';
import '../models/session_context.dart';

/// Builds LLM message history from persisted session context.
class SessionContextBuilder {
  SessionContextBuilder({
    this.maxVerbatimTurns = 12,
    this.maxSummaryChars = 8000,
    this.maxTurnContentChars = 4000,
  });

  final int maxVerbatimTurns;
  final int maxSummaryChars;
  final int maxTurnContentChars;

  /// Verbatim turns kept for the model plus a rolling summary of older turns.
  SessionContext appendTurn(SessionContext context, SessionTurn turn) {
    final turns = [...context.turns, turn];
    if (turns.length <= maxVerbatimTurns) {
      return context.copyWith(
        turns: turns,
        updatedAt: DateTime.now(),
      );
    }

    final overflow = turns.length - maxVerbatimTurns;
    final toSummarize = turns.sublist(0, overflow);
    final recent = turns.sublist(overflow);
    final summary = _mergeSummary(context.summary, toSummarize);

    return context.copyWith(
      summary: summary,
      turns: recent,
      updatedAt: DateTime.now(),
    );
  }

  List<ChatMessage> buildLlmHistory(SessionContext context) {
    return context.turns
        .map(
          (turn) => ChatMessage(
            role: turn.role,
            content: _truncate(turn.content, maxTurnContentChars),
          ),
        )
        .toList();
  }

  List<TranscriptLine> buildTranscriptLines(SessionContext context) {
    final lines = <TranscriptLine>[];
    if (context.summary.trim().isNotEmpty) {
      lines.add(SystemLine('— earlier context summarized —'));
    }
    for (final turn in context.turns) {
      if (turn.isUser) {
        lines.add(UserLine(turn.content));
      } else if (turn.isAssistant) {
        lines.add(AssistantLine(turn.content));
      }
    }
    return lines;
  }

  String? extractAssistantReply(List<AgentEvent> events) {
    for (final event in events.reversed) {
      if (event is AgentDoneEvent && event.finalText.trim().isNotEmpty) {
        return event.finalText.trim();
      }
    }
    final textEvents = events.whereType<AgentTextEvent>().toList();
    if (textEvents.isEmpty) {
      return null;
    }
    return textEvents.map((e) => e.text).join('\n').trim();
  }

  String _mergeSummary(String existing, List<SessionTurn> turns) {
    final buffer = StringBuffer();
    if (existing.trim().isNotEmpty) {
      buffer.writeln(existing.trim());
    }
    for (final turn in turns) {
      final label = turn.isUser ? 'User' : 'Assistant';
      buffer.writeln('$label: ${_truncate(turn.content, 500)}');
    }
    return _truncate(buffer.toString().trim(), maxSummaryChars);
  }

  String _truncate(String value, int maxChars) {
    if (value.length <= maxChars) {
      return value;
    }
    return '${value.substring(0, maxChars)}…';
  }
}

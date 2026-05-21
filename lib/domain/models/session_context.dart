class SessionTurn {
  const SessionTurn({
    required this.role,
    required this.content,
    required this.createdAt,
  });

  final String role;
  final String content;
  final DateTime createdAt;

  bool get isUser => role == 'user';
  bool get isAssistant => role == 'assistant';

  Map<String, dynamic> toJson() => {
        'role': role,
        'content': content,
        'createdAt': createdAt.toIso8601String(),
      };

  factory SessionTurn.fromJson(Map<String, dynamic> json) {
    return SessionTurn(
      role: json['role'] as String,
      content: json['content'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }
}

class SessionContext {
  const SessionContext({
    required this.connectionId,
    this.summary = '',
    this.turns = const [],
    required this.updatedAt,
  });

  final String connectionId;
  final String summary;
  final List<SessionTurn> turns;
  final DateTime updatedAt;

  SessionContext copyWith({
    String? summary,
    List<SessionTurn>? turns,
    DateTime? updatedAt,
  }) {
    return SessionContext(
      connectionId: connectionId,
      summary: summary ?? this.summary,
      turns: turns ?? this.turns,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

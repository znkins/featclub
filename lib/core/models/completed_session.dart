/// Historique de séance terminée (table `public.completed_sessions`).
///
/// `sessionTitle` est un snapshot du titre au moment de la complétion :
/// l'historique reste lisible même si la séance source est supprimée.
class CompletedSession {
  CompletedSession({
    required this.id,
    required this.studentId,
    this.studentSessionId,
    required this.sessionTitle,
    this.comment,
    required this.completedAt,
  });

  final String id;
  final String studentId;
  final String? studentSessionId;
  final String sessionTitle;
  final String? comment;
  final DateTime completedAt;

  factory CompletedSession.fromJson(Map<String, dynamic> json) {
    return CompletedSession(
      id: json['id'] as String,
      studentId: json['student_id'] as String,
      studentSessionId: json['student_session_id'] as String?,
      sessionTitle: json['session_title'] as String,
      comment: json['comment'] as String?,
      completedAt: DateTime.parse(json['completed_at'] as String),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'student_id': studentId,
        'student_session_id': studentSessionId,
        'session_title': sessionTitle,
        'comment': comment,
        'completed_at': completedAt.toIso8601String(),
      };
}

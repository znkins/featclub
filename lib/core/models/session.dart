/// Séance template (table `public.sessions`).
///
/// `is_template` est toujours `true` côté coach. Ces séances sont dupliquées
/// vers `student_sessions` lors de l'attribution à un élève.
class Session {
  Session({
    required this.id,
    required this.coachId,
    required this.title,
    this.description,
    this.durationMinutes,
    this.isTemplate = true,
    required this.createdAt,
  });

  final String id;
  final String coachId;
  final String title;
  final String? description;
  final int? durationMinutes;
  final bool isTemplate;
  final DateTime createdAt;

  factory Session.fromJson(Map<String, dynamic> json) {
    return Session(
      id: json['id'] as String,
      coachId: json['coach_id'] as String,
      title: json['title'] as String,
      description: json['description'] as String?,
      durationMinutes: json['duration_minutes'] as int?,
      isTemplate: json['is_template'] as bool? ?? true,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'coach_id': coachId,
        'title': title,
        'description': description,
        'duration_minutes': durationMinutes,
        'is_template': isTemplate,
        'created_at': createdAt.toIso8601String(),
      };
}

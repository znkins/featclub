/// Séance propre à un élève (table `public.student_sessions`).
///
/// `dayOfWeek` est une chaîne libre stockée côté DB ('monday'..'sunday')
/// et reste la seule source de vérité pour la planification. La date
/// concrète affichée à l'élève (« prochaine occurrence ») est dérivée à la
/// lecture par le service à partir du `dayOfWeek` et des complétions de la
/// semaine en cours — cf. `StudentSessionView`.
///
/// La colonne DB `assigned_date` est legacy (figée à l'écriture coach,
/// jamais recalculée) ; le code ne la lit ni ne l'écrit plus.
class StudentSession {
  StudentSession({
    required this.id,
    required this.studentProgramId,
    required this.title,
    this.description,
    this.durationMinutes,
    this.dayOfWeek,
    required this.position,
    required this.createdAt,
  });

  final String id;
  final String studentProgramId;
  final String title;
  final String? description;
  final int? durationMinutes;
  final String? dayOfWeek;
  final int position;
  final DateTime createdAt;

  factory StudentSession.fromJson(Map<String, dynamic> json) {
    return StudentSession(
      id: json['id'] as String,
      studentProgramId: json['student_program_id'] as String,
      title: json['title'] as String,
      description: json['description'] as String?,
      durationMinutes: json['duration_minutes'] as int?,
      dayOfWeek: json['day_of_week'] as String?,
      position: json['position'] as int,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'student_program_id': studentProgramId,
        'title': title,
        'description': description,
        'duration_minutes': durationMinutes,
        'day_of_week': dayOfWeek,
        'position': position,
        'created_at': createdAt.toIso8601String(),
      };
}

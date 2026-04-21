/// Séance propre à un élève (table `public.student_sessions`).
///
/// `dayOfWeek` est une chaîne libre stockée côté DB ('monday'..'sunday').
/// `assignedDate` est la prochaine occurrence concrète calculée par le coach.
class StudentSession {
  StudentSession({
    required this.id,
    required this.studentProgramId,
    required this.title,
    this.description,
    this.durationMinutes,
    this.dayOfWeek,
    this.assignedDate,
    required this.position,
    required this.createdAt,
  });

  final String id;
  final String studentProgramId;
  final String title;
  final String? description;
  final int? durationMinutes;
  final String? dayOfWeek;
  final DateTime? assignedDate;
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
      assignedDate: json['assigned_date'] != null
          ? DateTime.parse(json['assigned_date'] as String)
          : null,
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
        'assigned_date': assignedDate?.toIso8601String().split('T').first,
        'position': position,
        'created_at': createdAt.toIso8601String(),
      };
}

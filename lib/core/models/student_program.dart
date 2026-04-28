/// Programme propre à un élève (table `public.student_programs`).
///
/// Copie profonde et indépendante d'un programme template (ou créé à la main).
/// Règle métier : un seul programme actif à la fois par élève.
class StudentProgram {
  StudentProgram({
    required this.id,
    required this.studentId,
    required this.title,
    this.description,
    this.isActive = false,
    required this.createdAt,
  });

  final String id;
  final String studentId;
  final String title;
  final String? description;
  final bool isActive;
  final DateTime createdAt;

  factory StudentProgram.fromJson(Map<String, dynamic> json) {
    return StudentProgram(
      id: json['id'] as String,
      studentId: json['student_id'] as String,
      title: json['title'] as String,
      description: json['description'] as String?,
      isActive: json['is_active'] as bool? ?? false,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'student_id': studentId,
        'title': title,
        'description': description,
        'is_active': isActive,
        'created_at': createdAt.toIso8601String(),
      };
}

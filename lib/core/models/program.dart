/// Programme template (table `public.programs`, toujours `is_template = true`).
///
/// Lors de l'affectation à un élève, la RPC
/// `duplicate_program_template_for_student` crée un `student_program`
/// indépendant (copie profonde de la structure).
class Program {
  Program({
    required this.id,
    required this.coachId,
    required this.title,
    this.description,
    this.isTemplate = true,
    required this.createdAt,
  });

  final String id;
  final String coachId;
  final String title;
  final String? description;
  final bool isTemplate;
  final DateTime createdAt;

  factory Program.fromJson(Map<String, dynamic> json) {
    return Program(
      id: json['id'] as String,
      coachId: json['coach_id'] as String,
      title: json['title'] as String,
      description: json['description'] as String?,
      isTemplate: json['is_template'] as bool? ?? true,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'coach_id': coachId,
        'title': title,
        'description': description,
        'is_template': isTemplate,
        'created_at': createdAt.toIso8601String(),
      };
}

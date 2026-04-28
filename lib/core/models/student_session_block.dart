/// Bloc d'une séance élève (table `public.student_session_blocks`).
/// Copie autonome (titre, description, ordre) modifiable sans impacter
/// les blocs templates de la bibliothèque coach.
class StudentSessionBlock {
  StudentSessionBlock({
    required this.id,
    required this.studentSessionId,
    required this.title,
    this.description,
    required this.position,
  });

  final String id;
  final String studentSessionId;
  final String title;
  final String? description;
  final int position;

  factory StudentSessionBlock.fromJson(Map<String, dynamic> json) {
    return StudentSessionBlock(
      id: json['id'] as String,
      studentSessionId: json['student_session_id'] as String,
      title: json['title'] as String,
      description: json['description'] as String?,
      position: json['position'] as int,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'student_session_id': studentSessionId,
        'title': title,
        'description': description,
        'position': position,
      };
}

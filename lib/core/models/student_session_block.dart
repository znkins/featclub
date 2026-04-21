/// Bloc d'une séance élève (table `public.student_session_blocks`).
///
/// Indépendant des blocs templates : copie autonome dont le coach modifie
/// le titre et l'ordre librement.
class StudentSessionBlock {
  StudentSessionBlock({
    required this.id,
    required this.studentSessionId,
    required this.title,
    required this.position,
  });

  final String id;
  final String studentSessionId;
  final String title;
  final int position;

  factory StudentSessionBlock.fromJson(Map<String, dynamic> json) {
    return StudentSessionBlock(
      id: json['id'] as String,
      studentSessionId: json['student_session_id'] as String,
      title: json['title'] as String,
      position: json['position'] as int,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'student_session_id': studentSessionId,
        'title': title,
        'position': position,
      };
}

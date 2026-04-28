/// Exercice d'une séance élève (table `public.student_session_exercises`).
///
/// Snapshot indépendant d'un exercice template : tous les paramètres
/// (`reps`, `load`, `intensity`, `rest`, `note`) sont stockés en clair et
/// modifiables sans impact sur la bibliothèque coach.
///
/// `description` = instructions générales (snapshot du template ou édité).
/// `note` = remarque personnalisée du coach pour cet élève.
class StudentSessionExercise {
  StudentSessionExercise({
    required this.id,
    required this.studentBlockId,
    required this.title,
    this.description,
    this.videoUrl,
    this.reps,
    this.load,
    this.intensity,
    this.rest,
    this.note,
    required this.position,
  });

  final String id;
  final String studentBlockId;
  final String title;
  final String? description;
  final String? videoUrl;
  final String? reps;
  final String? load;
  final String? intensity;
  final String? rest;
  final String? note;
  final int position;

  factory StudentSessionExercise.fromJson(Map<String, dynamic> json) {
    return StudentSessionExercise(
      id: json['id'] as String,
      studentBlockId: json['student_block_id'] as String,
      title: json['title'] as String,
      description: json['description'] as String?,
      videoUrl: json['video_url'] as String?,
      reps: json['reps'] as String?,
      load: json['load'] as String?,
      intensity: json['intensity'] as String?,
      rest: json['rest'] as String?,
      note: json['note'] as String?,
      position: json['position'] as int,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'student_block_id': studentBlockId,
        'title': title,
        'description': description,
        'video_url': videoUrl,
        'reps': reps,
        'load': load,
        'intensity': intensity,
        'rest': rest,
        'note': note,
        'position': position,
      };
}

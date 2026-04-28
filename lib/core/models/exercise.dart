/// Exercice template (table `public.exercises`).
/// Brique de base de la bibliothèque coach, réutilisable dans plusieurs blocs.
class Exercise {
  Exercise({
    required this.id,
    required this.coachId,
    required this.title,
    this.description,
    this.category,
    this.videoUrl,
    required this.createdAt,
  });

  final String id;
  final String coachId;
  final String title;
  final String? description;
  final String? category;
  final String? videoUrl;
  final DateTime createdAt;

  factory Exercise.fromJson(Map<String, dynamic> json) {
    return Exercise(
      id: json['id'] as String,
      coachId: json['coach_id'] as String,
      title: json['title'] as String,
      description: json['description'] as String?,
      category: json['category'] as String?,
      videoUrl: json['video_url'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'coach_id': coachId,
        'title': title,
        'description': description,
        'category': category,
        'video_url': videoUrl,
        'created_at': createdAt.toIso8601String(),
      };
}

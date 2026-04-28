/// Bloc template (table `public.blocks`).
/// Regroupement réutilisable d'exercices, brique de composition des séances.
class Block {
  Block({
    required this.id,
    required this.coachId,
    required this.title,
    this.description,
    required this.createdAt,
  });

  final String id;
  final String coachId;
  final String title;
  final String? description;
  final DateTime createdAt;

  factory Block.fromJson(Map<String, dynamic> json) {
    return Block(
      id: json['id'] as String,
      coachId: json['coach_id'] as String,
      title: json['title'] as String,
      description: json['description'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'coach_id': coachId,
        'title': title,
        'description': description,
        'created_at': createdAt.toIso8601String(),
      };
}

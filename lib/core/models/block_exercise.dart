/// Pivot bloc <-> exercice (table `public.block_exercises`).
class BlockExercise {
  BlockExercise({
    required this.id,
    required this.blockId,
    required this.exerciseId,
    required this.position,
  });

  final String id;
  final String blockId;
  final String exerciseId;
  final int position;

  factory BlockExercise.fromJson(Map<String, dynamic> json) {
    return BlockExercise(
      id: json['id'] as String,
      blockId: json['block_id'] as String,
      exerciseId: json['exercise_id'] as String,
      position: json['position'] as int,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'block_id': blockId,
        'exercise_id': exerciseId,
        'position': position,
      };
}

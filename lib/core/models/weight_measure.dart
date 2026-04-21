/// Mesure de poids (table `public.weight_measures`).
///
/// L'insertion déclenche le trigger `update_current_weight` qui met à jour
/// `profiles.current_weight` automatiquement.
class WeightMeasure {
  WeightMeasure({
    required this.id,
    required this.studentId,
    required this.valueKg,
    required this.measuredAt,
    required this.createdAt,
  });

  final String id;
  final String studentId;
  final double valueKg;
  final DateTime measuredAt;
  final DateTime createdAt;

  factory WeightMeasure.fromJson(Map<String, dynamic> json) {
    return WeightMeasure(
      id: json['id'] as String,
      studentId: json['student_id'] as String,
      valueKg: (json['value_kg'] as num).toDouble(),
      measuredAt: DateTime.parse(json['measured_at'] as String),
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'student_id': studentId,
        'value_kg': valueKg,
        'measured_at': measuredAt.toIso8601String().split('T').first,
        'created_at': createdAt.toIso8601String(),
      };
}

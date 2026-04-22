import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/weight_measure.dart';

/// Mesures de poids (`public.weight_measures`).
///
/// L'insertion déclenche le trigger `update_current_weight` côté DB qui
/// recopie la dernière valeur dans `profiles.current_weight`.
///
/// RLS : SELECT et INSERT ouverts au coach et à l'élève concerné. Pas de
/// UPDATE ni DELETE dans le schéma actuel.
class WeightMeasureService {
  WeightMeasureService(this._client);

  final SupabaseClient _client;

  static const String _columns =
      'id, student_id, value_kg, measured_at, created_at';

  /// Liste des mesures d'un élève, plus récentes en tête.
  Future<List<WeightMeasure>> listByStudent(String studentId) async {
    final rows = await _client
        .from('weight_measures')
        .select(_columns)
        .eq('student_id', studentId)
        .order('measured_at', ascending: false)
        .order('created_at', ascending: false);
    return (rows as List)
        .map((r) => WeightMeasure.fromJson(r as Map<String, dynamic>))
        .toList();
  }

  Future<WeightMeasure> create({
    required String studentId,
    required double valueKg,
    required DateTime measuredAt,
  }) async {
    final row = await _client
        .from('weight_measures')
        .insert({
          'student_id': studentId,
          'value_kg': valueKg,
          'measured_at':
              measuredAt.toIso8601String().split('T').first,
        })
        .select(_columns)
        .single();
    return WeightMeasure.fromJson(row);
  }
}

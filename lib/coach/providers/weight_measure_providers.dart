import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/models/weight_measure.dart';
import '../../core/services/weight_measure_service.dart';
import '../../shared/providers/supabase_providers.dart';

final weightMeasureServiceProvider = Provider<WeightMeasureService>((ref) {
  return WeightMeasureService(ref.watch(supabaseClientProvider));
});

/// Toutes les mesures d'un élève, plus récentes en tête.
///
/// Source unique utilisée par la section « Mesures » : le graphique utilise
/// l'historique complet, les lignes ne montrent que les 3 dernières, et le
/// bottom sheet « Voir plus » affiche tout.
final studentWeightsProvider =
    FutureProvider.family<List<WeightMeasure>, String>((ref, studentId) async {
  return ref.watch(weightMeasureServiceProvider).listByStudent(studentId);
});

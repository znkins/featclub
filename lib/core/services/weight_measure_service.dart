import 'package:supabase_flutter/supabase_flutter.dart';

/// Mesures de poids (`public.weight_measures`).
///
/// L'insertion déclenche le trigger `update_current_weight` côté DB.
/// Squelette posé en Phase 0. Méthodes implémentées en Phase 3/4.
class WeightMeasureService {
  WeightMeasureService(this.client);

  final SupabaseClient client;

  static const String table = 'weight_measures';
}

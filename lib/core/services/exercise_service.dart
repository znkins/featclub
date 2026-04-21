import 'package:supabase_flutter/supabase_flutter.dart';

/// Bibliothèque d'exercices coach (`public.exercises`).
///
/// Squelette posé en Phase 0. Méthodes implémentées en Phase 2.
class ExerciseService {
  ExerciseService(this.client);

  final SupabaseClient client;

  static const String table = 'exercises';
}

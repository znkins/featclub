import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/models/exercise.dart';
import '../../core/services/exercise_service.dart';
import '../../shared/providers/auth_provider.dart';
import '../../shared/providers/supabase_providers.dart';

final exerciseServiceProvider = Provider<ExerciseService>((ref) {
  return ExerciseService(ref.watch(supabaseClientProvider));
});

/// Liste des exercices du coach connecté.
final coachExercisesProvider = FutureProvider<List<Exercise>>((ref) async {
  final userId = ref.watch(currentSessionProvider)?.user.id;
  if (userId == null) return const [];
  return ref.watch(exerciseServiceProvider).listByCoach(userId);
});

/// Détail d'un exercice (pour l'écran détail).
///
/// `autoDispose` : fraîcheur garantie à chaque ré-entrée dans l'écran détail.
final exerciseByIdProvider =
    FutureProvider.autoDispose.family<Exercise, String>((ref, id) async {
  return ref.watch(exerciseServiceProvider).fetchById(id);
});

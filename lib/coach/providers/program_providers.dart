import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/services/program_service.dart';
import '../../shared/providers/auth_provider.dart';
import '../../shared/providers/supabase_providers.dart';

final programServiceProvider = Provider<ProgramService>((ref) {
  return ProgramService(ref.watch(supabaseClientProvider));
});

/// Liste des programmes templates du coach connecté (avec compteur de séances).
final coachProgramsProvider =
    FutureProvider<List<ProgramListItem>>((ref) async {
  final userId = ref.watch(currentSessionProvider)?.user.id;
  if (userId == null) return const [];
  return ref.watch(programServiceProvider).listByCoach(userId);
});

/// Détail d'un programme template (entête + liaisons de séances).
final programDetailProvider =
    FutureProvider.family<ProgramDetail, String>((ref, id) async {
  return ref.watch(programServiceProvider).fetchDetail(id);
});

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/services/completed_session_service.dart';
import '../../core/services/student_program_service.dart';
import '../../core/services/weight_measure_service.dart';
import 'supabase_providers.dart';

/// Providers de services de données partagés par les rôles coach et élève.
///
/// Ces services couvrent les tables qu'un coach consulte pour ses élèves et
/// qu'un élève consulte pour lui-même — donc logiquement partagés plutôt
/// que rattachés à un seul espace.
final studentProgramServiceProvider = Provider<StudentProgramService>((ref) {
  return StudentProgramService(ref.watch(supabaseClientProvider));
});

final weightMeasureServiceProvider = Provider<WeightMeasureService>((ref) {
  return WeightMeasureService(ref.watch(supabaseClientProvider));
});

final completedSessionServiceProvider = Provider<CompletedSessionService>((
  ref,
) {
  return CompletedSessionService(ref.watch(supabaseClientProvider));
});

// Services de données partagés entre rôles (coach + élève).

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/services/completed_session_service.dart';
import '../../core/services/student_program_service.dart';
import '../../core/services/weight_measure_service.dart';
import 'supabase_providers.dart';

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

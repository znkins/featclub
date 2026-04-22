import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/services/student_program_service.dart';
import '../../shared/providers/supabase_providers.dart';

final studentProgramServiceProvider = Provider<StudentProgramService>((ref) {
  return StudentProgramService(ref.watch(supabaseClientProvider));
});

/// Liste des programmes d'un élève (plus récents en premier).
final studentProgramsProvider =
    FutureProvider.family<List<StudentProgramListItem>, String>(
        (ref, studentId) async {
  return ref.watch(studentProgramServiceProvider).listByStudent(studentId);
});

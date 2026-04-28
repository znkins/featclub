import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/services/student_program_service.dart';
import '../../shared/providers/current_profile_provider.dart';
import '../../shared/providers/data_providers.dart';

/// Programme actif + séances ordonnées de l'élève courant (FutureProvider).
/// `program == null` si aucun programme actif.
final studentActiveProgramProvider =
    FutureProvider<StudentActiveProgramDetail>((ref) async {
  final profile = await ref.watch(currentProfileProvider.future);
  if (profile == null) {
    return const StudentActiveProgramDetail(program: null, sessions: []);
  }
  return ref
      .watch(studentProgramServiceProvider)
      .fetchActiveProgramWithSessions(profile.id);
});

/// Arbre complet d'une séance élève (entête + blocs + exercices).
/// Chargé paresseusement au tap, partagé entre détail et mode d'exécution.
final studentSessionContentProvider =
    FutureProvider.family<StudentSessionContent, String>(
        (ref, sessionId) async {
  return ref
      .watch(studentProgramServiceProvider)
      .fetchStudentSessionContent(sessionId);
});

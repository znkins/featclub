import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/services/student_program_service.dart';
import '../../shared/providers/current_profile_provider.dart';
import '../../shared/providers/data_providers.dart';

/// Programme actif + séances ordonnées pour l'élève courant.
///
/// `detail.program == null` si l'élève n'a aucun programme actif.
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

/// Contenu complet d'une séance élève : entête + blocs + exercices.
///
/// Chargé paresseusement au tap sur une séance (écran détail) et réutilisé
/// par le mode d'exécution pour éviter un re-fetch.
final studentSessionContentProvider =
    FutureProvider.family<StudentSessionContent, String>(
        (ref, sessionId) async {
  return ref
      .watch(studentProgramServiceProvider)
      .fetchStudentSessionContent(sessionId);
});

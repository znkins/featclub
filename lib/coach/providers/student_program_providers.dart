import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/services/student_program_service.dart';
import '../../shared/providers/data_providers.dart';

export '../../shared/providers/data_providers.dart'
    show studentProgramServiceProvider;

/// Liste des programmes d'un élève (plus récents en premier).
final studentProgramsProvider =
    FutureProvider.family<List<StudentProgramListItem>, String>(
        (ref, studentId) async {
  return ref.watch(studentProgramServiceProvider).listByStudent(studentId);
});

/// Programme + séances ordonnées pour l'éditeur coach.
/// `autoDispose` pour garantir la fraîcheur après un `popUntil` via breadcrumb.
final studentProgramEditorDetailProvider =
    FutureProvider.autoDispose
        .family<StudentProgramEditorDetail, String>((ref, programId) async {
  return ref
      .watch(studentProgramServiceProvider)
      .fetchProgramEditorDetail(programId);
});

/// Séance + blocs ordonnés pour l'éditeur coach.
final studentSessionEditorDetailProvider =
    FutureProvider.autoDispose
        .family<StudentSessionEditorDetail, String>((ref, sessionId) async {
  return ref
      .watch(studentProgramServiceProvider)
      .fetchSessionEditorDetail(sessionId);
});

/// Bloc + exercices ordonnés pour l'éditeur coach.
final studentBlockEditorDetailProvider =
    FutureProvider.autoDispose
        .family<StudentBlockEditorDetail, String>((ref, blockId) async {
  return ref
      .watch(studentProgramServiceProvider)
      .fetchBlockEditorDetail(blockId);
});

/// Exercice élève chargé directement (pour l'éditeur d'exercice).
final studentExerciseProvider =
    FutureProvider.autoDispose.family((ref, String id) async {
  return ref.watch(studentProgramServiceProvider).fetchExerciseById(id);
});

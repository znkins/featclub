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

/// Détail éditeur d'un programme : entête + séances ordonnées (avec compteurs).
final studentProgramEditorDetailProvider =
    FutureProvider.family<StudentProgramEditorDetail, String>(
        (ref, programId) async {
  return ref
      .watch(studentProgramServiceProvider)
      .fetchProgramEditorDetail(programId);
});

/// Détail éditeur d'une séance : entête + blocs ordonnés (avec compteurs).
final studentSessionEditorDetailProvider =
    FutureProvider.family<StudentSessionEditorDetail, String>(
        (ref, sessionId) async {
  return ref
      .watch(studentProgramServiceProvider)
      .fetchSessionEditorDetail(sessionId);
});

/// Détail éditeur d'un bloc : entête + exercices ordonnés.
final studentBlockEditorDetailProvider =
    FutureProvider.family<StudentBlockEditorDetail, String>(
        (ref, blockId) async {
  return ref
      .watch(studentProgramServiceProvider)
      .fetchBlockEditorDetail(blockId);
});

/// Exercice élève (chargement direct pour l'éditeur d'exercice).
final studentExerciseProvider = FutureProvider.family((ref, String id) async {
  return ref.watch(studentProgramServiceProvider).fetchExerciseById(id);
});

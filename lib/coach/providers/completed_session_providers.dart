import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/models/completed_session.dart';
import '../../core/services/completed_session_service.dart';
import '../../shared/providers/supabase_providers.dart';

final completedSessionServiceProvider = Provider<CompletedSessionService>((ref) {
  return CompletedSessionService(ref.watch(supabaseClientProvider));
});

/// Aperçu compact : on fetch 4 pour afficher les 3 dernières et savoir s'il en
/// existe une quatrième (afin d'afficher le bouton « Voir plus » uniquement
/// quand il y a vraiment plus à voir).
final studentRecentHistoryProvider =
    FutureProvider.family<List<CompletedSession>, String>(
        (ref, studentId) async {
  return ref
      .watch(completedSessionServiceProvider)
      .listByStudent(studentId, limit: 4);
});

/// Historique complet d'un élève (écran "Voir plus").
final studentHistoryProvider =
    FutureProvider.family<List<CompletedSession>, String>(
        (ref, studentId) async {
  return ref.watch(completedSessionServiceProvider).listByStudent(studentId);
});

/// Nombre total de séances terminées par un élève (stat card fiche élève).
final studentCompletedSessionCountProvider =
    FutureProvider.family<int, String>((ref, studentId) async {
  return ref
      .watch(completedSessionServiceProvider)
      .countByStudent(studentId);
});

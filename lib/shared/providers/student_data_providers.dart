import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/models/completed_session.dart';
import '../../core/models/weight_measure.dart';
import 'data_providers.dart';

/// Providers de données liées à un élève (mesures de poids + historique)
/// partagés par le coach (fiche élève) et par l'élève (onglet progression).
///
/// Tous sont keyés sur `studentId` pour pouvoir servir les deux rôles :
/// coach passe l'id de l'élève consulté, élève passe son propre id.

/// Toutes les mesures de poids, plus récentes en tête.
///
/// Source unique utilisée par la section « Mesures » : le graphique utilise
/// l'historique complet, les lignes ne montrent que les 3 dernières, et le
/// bottom sheet « Voir plus » affiche tout.
final studentWeightsProvider =
    FutureProvider.family<List<WeightMeasure>, String>((ref, studentId) async {
  return ref.watch(weightMeasureServiceProvider).listByStudent(studentId);
});

/// Aperçu compact : 4 entrées (3 affichées + 1 pour savoir s'il faut montrer
/// le bouton « Voir plus »).
final studentRecentHistoryProvider =
    FutureProvider.family<List<CompletedSession>, String>(
        (ref, studentId) async {
  return ref
      .watch(completedSessionServiceProvider)
      .listByStudent(studentId, limit: 4);
});

/// Historique complet d'un élève (écran / sheet « Voir plus »).
final studentHistoryProvider =
    FutureProvider.family<List<CompletedSession>, String>(
        (ref, studentId) async {
  return ref.watch(completedSessionServiceProvider).listByStudent(studentId);
});

/// Nombre total de séances terminées par un élève.
final studentCompletedSessionCountProvider =
    FutureProvider.family<int, String>((ref, studentId) async {
  return ref
      .watch(completedSessionServiceProvider)
      .countByStudent(studentId);
});

// Données liées à un élève, partagées entre coach (fiche élève) et
// élève (onglet progression). Keyés sur `studentId` pour servir les deux rôles.

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/models/completed_session.dart';
import '../../core/models/weight_measure.dart';
import 'data_providers.dart';

/// Toutes les mesures de poids d'un élève (plus récentes en tête).
/// Source unique pour graphique, lignes récentes et bottom sheet « Voir plus ».
final studentWeightsProvider =
    FutureProvider.family<List<WeightMeasure>, String>((ref, studentId) async {
  return ref.watch(weightMeasureServiceProvider).listByStudent(studentId);
});

/// 4 dernières complétions (3 affichées + 1 pour décider d'afficher
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

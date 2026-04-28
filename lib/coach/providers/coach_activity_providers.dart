import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/services/completed_session_service.dart';
import '../../shared/providers/data_providers.dart';

/// Plafond de la V1 du feed d'activité coach. Phase 6 paginera proprement,
/// d'ici là on coupe pour garder une requête bornée.
const int kCoachActivityFeedLimit = 50;

/// Feed d'activité coach : dernières complétions de tous les élèves, plus
/// récentes en tête, avec le profil de l'élève embarqué.
final coachActivityFeedProvider =
    FutureProvider<List<RecentActivityItem>>((ref) async {
  return ref
      .watch(completedSessionServiceProvider)
      .listRecentWithStudent(limit: kCoachActivityFeedLimit);
});

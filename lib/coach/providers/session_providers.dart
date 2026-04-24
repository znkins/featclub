import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/services/session_service.dart';
import '../../shared/providers/auth_provider.dart';
import '../../shared/providers/supabase_providers.dart';

final sessionServiceProvider = Provider<SessionService>((ref) {
  return SessionService(ref.watch(supabaseClientProvider));
});

/// Liste des séances templates du coach connecté (avec compteur de blocs).
final coachSessionsProvider =
    FutureProvider<List<SessionListItem>>((ref) async {
  final userId = ref.watch(currentSessionProvider)?.user.id;
  if (userId == null) return const [];
  return ref.watch(sessionServiceProvider).listByCoach(userId);
});

/// Détail d'une séance template (entête + liaisons de blocs).
///
/// `autoDispose` : fraîcheur garantie à chaque ré-entrée dans l'écran détail
/// (couvre le cas du `popUntil` breadcrumb qui saute des niveaux sans
/// déclencher `didPopNext` sur les écrans traversés).
final sessionDetailProvider =
    FutureProvider.autoDispose.family<SessionDetail, String>((ref, id) async {
  return ref.watch(sessionServiceProvider).fetchDetail(id);
});

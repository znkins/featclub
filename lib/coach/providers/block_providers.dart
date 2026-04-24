import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/services/block_service.dart';
import '../../shared/providers/auth_provider.dart';
import '../../shared/providers/supabase_providers.dart';

final blockServiceProvider = Provider<BlockService>((ref) {
  return BlockService(ref.watch(supabaseClientProvider));
});

/// Liste des blocs du coach connecté (avec compteur d'exercices).
final coachBlocksProvider = FutureProvider<List<BlockListItem>>((ref) async {
  final userId = ref.watch(currentSessionProvider)?.user.id;
  if (userId == null) return const [];
  return ref.watch(blockServiceProvider).listByCoach(userId);
});

/// Détail d'un bloc (entête + liaisons d'exercices).
///
/// `autoDispose` pour garantir la fraîcheur : quand l'écran détail est
/// disposé (pop direct ou `popUntil` via breadcrumb), le cache est vidé.
/// Prochaine entrée = fetch frais, sans dépendre de `didPopNext` qui ne
/// déclenche que sur le niveau où on atterrit.
final blockDetailProvider =
    FutureProvider.autoDispose.family<BlockDetail, String>((ref, id) async {
  return ref.watch(blockServiceProvider).fetchDetail(id);
});

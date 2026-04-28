import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/services/block_service.dart';
import '../../shared/providers/auth_provider.dart';
import '../../shared/providers/supabase_providers.dart';

final blockServiceProvider = Provider<BlockService>((ref) {
  return BlockService(ref.watch(supabaseClientProvider));
});

/// Blocs templates du coach connecté (avec compteur d'exercices).
final coachBlocksProvider = FutureProvider<List<BlockListItem>>((ref) async {
  final userId = ref.watch(currentSessionProvider)?.user.id;
  if (userId == null) return const [];
  return ref.watch(blockServiceProvider).listByCoach(userId);
});

/// Détail d'un bloc (entête + exercices). `autoDispose` pour garantir un
/// fetch frais à la prochaine entrée — utile quand le breadcrumb fait un
/// `popUntil` qui saute des niveaux sans déclencher `didPopNext`.
final blockDetailProvider =
    FutureProvider.autoDispose.family<BlockDetail, String>((ref, id) async {
  return ref.watch(blockServiceProvider).fetchDetail(id);
});

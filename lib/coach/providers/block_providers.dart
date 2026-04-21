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
final blockDetailProvider =
    FutureProvider.family<BlockDetail, String>((ref, id) async {
  return ref.watch(blockServiceProvider).fetchDetail(id);
});

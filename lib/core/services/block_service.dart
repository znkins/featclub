// Service Supabase pour `blocks` + `block_exercises` (bibliothèque coach).

import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/block.dart';
import '../models/exercise.dart';

/// Bloc + nombre d'exercices liés (utilisé par la liste).
class BlockListItem {
  const BlockListItem({required this.block, required this.exerciseCount});

  final Block block;
  final int exerciseCount;
}

/// Liaison bloc ↔ exercice (ligne pivot) avec l'exercice résolu.
/// Le même exercice peut apparaître plusieurs fois dans un bloc :
/// chaque apparition est identifiée par son `linkId`.
class BlockExerciseLink {
  const BlockExerciseLink({
    required this.linkId,
    required this.exercise,
    required this.position,
  });

  final String linkId;
  final Exercise exercise;
  final int position;
}

/// Détail d'un bloc : entête + liaisons d'exercices triées par position.
class BlockDetail {
  const BlockDetail({required this.block, required this.links});

  final Block block;
  final List<BlockExerciseLink> links;
}

class BlockService {
  BlockService(this._client);

  final SupabaseClient _client;

  static const String _blockColumns =
      'id, coach_id, title, description, created_at';
  static const String _exerciseColumns =
      'id, coach_id, title, description, category, video_url, created_at';

  Future<List<BlockListItem>> listByCoach(String coachId) async {
    final rows = await _client
        .from('blocks')
        .select('$_blockColumns, block_exercises(count)')
        .eq('coach_id', coachId)
        .order('title', ascending: true);
    return (rows as List).map((r) {
      final map = r as Map<String, dynamic>;
      final agg = map['block_exercises'];
      final count = agg is List && agg.isNotEmpty
          ? ((agg.first as Map)['count'] as int? ?? 0)
          : 0;
      return BlockListItem(
        block: Block.fromJson(map),
        exerciseCount: count,
      );
    }).toList();
  }

  Future<Block> create({
    required String coachId,
    required String title,
    String? description,
  }) async {
    final row = await _client
        .from('blocks')
        .insert({
          'coach_id': coachId,
          'title': title,
          'description': _nullIfBlank(description),
        })
        .select(_blockColumns)
        .single();
    return Block.fromJson(row);
  }

  Future<Block> update({
    required String id,
    required String title,
    String? description,
  }) async {
    final row = await _client
        .from('blocks')
        .update({
          'title': title,
          'description': _nullIfBlank(description),
        })
        .eq('id', id)
        .select(_blockColumns)
        .single();
    return Block.fromJson(row);
  }

  Future<void> delete(String id) async {
    await _client.from('blocks').delete().eq('id', id);
  }

  Future<BlockDetail> fetchDetail(String blockId) async {
    final results = await Future.wait([
      _fetchById(blockId),
      listLinks(blockId),
    ]);
    return BlockDetail(
      block: results[0] as Block,
      links: results[1] as List<BlockExerciseLink>,
    );
  }

  Future<Block> _fetchById(String id) async {
    final row = await _client
        .from('blocks')
        .select(_blockColumns)
        .eq('id', id)
        .single();
    return Block.fromJson(row);
  }

  Future<List<BlockExerciseLink>> listLinks(String blockId) async {
    final rows = await _client
        .from('block_exercises')
        .select('id, position, exercise:exercises($_exerciseColumns)')
        .eq('block_id', blockId)
        .order('position', ascending: true);
    return (rows as List).map((r) {
      final map = r as Map<String, dynamic>;
      return BlockExerciseLink(
        linkId: map['id'] as String,
        position: map['position'] as int,
        exercise:
            Exercise.fromJson(map['exercise'] as Map<String, dynamic>),
      );
    }).toList();
  }

  /// Ajoute un exercice à la fin du bloc (les duplicats sont autorisés).
  Future<void> addExercise({
    required String blockId,
    required String exerciseId,
  }) async {
    final nextPosition = await _nextPosition(blockId);
    await _client.from('block_exercises').insert({
      'block_id': blockId,
      'exercise_id': exerciseId,
      'position': nextPosition,
    });
  }

  Future<void> removeLink(String linkId) async {
    await _client.from('block_exercises').delete().eq('id', linkId);
  }

  Future<void> reorderLinks({
    required String blockId,
    required List<String> linkIdsInOrder,
  }) async {
    for (var i = 0; i < linkIdsInOrder.length; i++) {
      await _client
          .from('block_exercises')
          .update({'position': i}).eq('id', linkIdsInOrder[i]);
    }
  }

  Future<int> _nextPosition(String blockId) async {
    final last = await _client
        .from('block_exercises')
        .select('position')
        .eq('block_id', blockId)
        .order('position', ascending: false)
        .limit(1);
    return (last as List).isEmpty
        ? 0
        : ((last.first as Map)['position'] as int) + 1;
  }
}

String? _nullIfBlank(String? value) {
  if (value == null) return null;
  final trimmed = value.trim();
  return trimmed.isEmpty ? null : trimmed;
}

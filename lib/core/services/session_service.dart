import 'package:supabase_flutter/supabase_flutter.dart' hide Session;

import '../models/block.dart';
import '../models/session.dart';

/// Élément de la liste des séances coach (entête + nombre de blocs liés).
class SessionListItem {
  const SessionListItem({required this.session, required this.blockCount});

  final Session session;
  final int blockCount;
}

/// Liaison séance ↔ bloc (ligne de `session_blocks`) avec le bloc résolu
/// et son nombre d'exercices (affiché dans la tuile de liste).
///
/// Le même bloc peut apparaître plusieurs fois dans une séance : chaque
/// apparition est identifiée par son `linkId` (id de la ligne pivot).
class SessionBlockLink {
  const SessionBlockLink({
    required this.linkId,
    required this.block,
    required this.position,
    required this.exerciseCount,
  });

  final String linkId;
  final Block block;
  final int position;
  final int exerciseCount;
}

/// Détail d'une séance template : entête + liaisons de blocs dans l'ordre.
class SessionDetail {
  const SessionDetail({required this.session, required this.links});

  final Session session;
  final List<SessionBlockLink> links;
}

/// Bibliothèque de séances templates (`public.sessions` + `public.session_blocks`).
///
/// `is_template = true` pour toutes les séances créées ici.
class SessionService {
  SessionService(this._client);

  final SupabaseClient _client;

  static const String _sessionColumns =
      'id, coach_id, title, description, duration_minutes, is_template, created_at';
  static const String _blockColumns =
      'id, coach_id, title, description, created_at';

  Future<List<SessionListItem>> listByCoach(String coachId) async {
    final rows = await _client
        .from('sessions')
        .select('$_sessionColumns, session_blocks(count)')
        .eq('coach_id', coachId)
        .eq('is_template', true)
        .order('title', ascending: true);
    return (rows as List).map((r) {
      final map = r as Map<String, dynamic>;
      final agg = map['session_blocks'];
      final count = agg is List && agg.isNotEmpty
          ? ((agg.first as Map)['count'] as int? ?? 0)
          : 0;
      return SessionListItem(
        session: Session.fromJson(map),
        blockCount: count,
      );
    }).toList();
  }

  Future<Session> create({
    required String coachId,
    required String title,
    String? description,
    int? durationMinutes,
  }) async {
    final row = await _client
        .from('sessions')
        .insert({
          'coach_id': coachId,
          'title': title,
          'description': _nullIfBlank(description),
          'duration_minutes': durationMinutes,
          'is_template': true,
        })
        .select(_sessionColumns)
        .single();
    return Session.fromJson(row);
  }

  Future<Session> update({
    required String id,
    required String title,
    String? description,
    int? durationMinutes,
  }) async {
    final row = await _client
        .from('sessions')
        .update({
          'title': title,
          'description': _nullIfBlank(description),
          'duration_minutes': durationMinutes,
        })
        .eq('id', id)
        .select(_sessionColumns)
        .single();
    return Session.fromJson(row);
  }

  Future<void> delete(String id) async {
    await _client.from('sessions').delete().eq('id', id);
  }

  Future<SessionDetail> fetchDetail(String sessionId) async {
    final results = await Future.wait([
      _fetchById(sessionId),
      listLinks(sessionId),
    ]);
    return SessionDetail(
      session: results[0] as Session,
      links: results[1] as List<SessionBlockLink>,
    );
  }

  Future<Session> _fetchById(String id) async {
    final row = await _client
        .from('sessions')
        .select(_sessionColumns)
        .eq('id', id)
        .single();
    return Session.fromJson(row);
  }

  Future<List<SessionBlockLink>> listLinks(String sessionId) async {
    final rows = await _client
        .from('session_blocks')
        .select(
          'id, position, '
          'block:blocks($_blockColumns, block_exercises(count))',
        )
        .eq('session_id', sessionId)
        .order('position', ascending: true);
    return (rows as List).map((r) {
      final map = r as Map<String, dynamic>;
      final blockMap = map['block'] as Map<String, dynamic>;
      final agg = blockMap['block_exercises'];
      final exerciseCount = agg is List && agg.isNotEmpty
          ? ((agg.first as Map)['count'] as int? ?? 0)
          : 0;
      return SessionBlockLink(
        linkId: map['id'] as String,
        position: map['position'] as int,
        block: Block.fromJson(blockMap),
        exerciseCount: exerciseCount,
      );
    }).toList();
  }

  /// Ajoute un bloc à la fin de la séance.
  ///
  /// Les duplicats sont autorisés : appeler plusieurs fois insère plusieurs
  /// lignes pivot distinctes.
  Future<void> addBlock({
    required String sessionId,
    required String blockId,
  }) async {
    final nextPosition = await _nextPosition(sessionId);
    await _client.from('session_blocks').insert({
      'session_id': sessionId,
      'block_id': blockId,
      'position': nextPosition,
    });
  }

  Future<void> removeLink(String linkId) async {
    await _client.from('session_blocks').delete().eq('id', linkId);
  }

  Future<void> reorderLinks({
    required String sessionId,
    required List<String> linkIdsInOrder,
  }) async {
    for (var i = 0; i < linkIdsInOrder.length; i++) {
      await _client
          .from('session_blocks')
          .update({'position': i}).eq('id', linkIdsInOrder[i]);
    }
  }

  Future<int> _nextPosition(String sessionId) async {
    final last = await _client
        .from('session_blocks')
        .select('position')
        .eq('session_id', sessionId)
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

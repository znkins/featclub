// Service Supabase pour `programs` + `program_sessions` (bibliothèque coach).

import 'package:supabase_flutter/supabase_flutter.dart' hide Session;

import '../models/program.dart';
import '../models/session.dart';

/// Programme + nombre de séances liées (utilisé par la liste).
class ProgramListItem {
  const ProgramListItem({required this.program, required this.sessionCount});

  final Program program;
  final int sessionCount;
}

/// Liaison programme ↔ séance (ligne pivot) avec la séance résolue.
/// La même séance peut apparaître plusieurs fois : chaque apparition
/// est identifiée par son `linkId`.
class ProgramSessionLink {
  const ProgramSessionLink({
    required this.linkId,
    required this.session,
    required this.position,
    required this.blockCount,
  });

  final String linkId;
  final Session session;
  final int position;
  final int blockCount;
}

/// Détail d'un programme template : entête + liaisons de séances ordonnées.
class ProgramDetail {
  const ProgramDetail({required this.program, required this.links});

  final Program program;
  final List<ProgramSessionLink> links;
}

class ProgramService {
  ProgramService(this._client);

  final SupabaseClient _client;

  static const String _programColumns =
      'id, coach_id, title, description, is_template, created_at';
  static const String _sessionColumns =
      'id, coach_id, title, description, duration_minutes, is_template, created_at';

  Future<List<ProgramListItem>> listByCoach(String coachId) async {
    final rows = await _client
        .from('programs')
        .select('$_programColumns, program_sessions(count)')
        .eq('coach_id', coachId)
        .eq('is_template', true)
        .order('title', ascending: true);
    return (rows as List).map((r) {
      final map = r as Map<String, dynamic>;
      final agg = map['program_sessions'];
      final count = agg is List && agg.isNotEmpty
          ? ((agg.first as Map)['count'] as int? ?? 0)
          : 0;
      return ProgramListItem(
        program: Program.fromJson(map),
        sessionCount: count,
      );
    }).toList();
  }

  Future<Program> create({
    required String coachId,
    required String title,
    String? description,
  }) async {
    final row = await _client
        .from('programs')
        .insert({
          'coach_id': coachId,
          'title': title,
          'description': _nullIfBlank(description),
          'is_template': true,
        })
        .select(_programColumns)
        .single();
    return Program.fromJson(row);
  }

  Future<Program> update({
    required String id,
    required String title,
    String? description,
  }) async {
    final row = await _client
        .from('programs')
        .update({
          'title': title,
          'description': _nullIfBlank(description),
        })
        .eq('id', id)
        .select(_programColumns)
        .single();
    return Program.fromJson(row);
  }

  Future<void> delete(String id) async {
    await _client.from('programs').delete().eq('id', id);
  }

  Future<ProgramDetail> fetchDetail(String programId) async {
    final results = await Future.wait([
      _fetchById(programId),
      listLinks(programId),
    ]);
    return ProgramDetail(
      program: results[0] as Program,
      links: results[1] as List<ProgramSessionLink>,
    );
  }

  Future<Program> _fetchById(String id) async {
    final row = await _client
        .from('programs')
        .select(_programColumns)
        .eq('id', id)
        .single();
    return Program.fromJson(row);
  }

  Future<List<ProgramSessionLink>> listLinks(String programId) async {
    final rows = await _client
        .from('program_sessions')
        .select(
          'id, position, session:sessions($_sessionColumns, session_blocks(count))',
        )
        .eq('program_id', programId)
        .order('position', ascending: true);
    return (rows as List).map((r) {
      final map = r as Map<String, dynamic>;
      final sessionMap = map['session'] as Map<String, dynamic>;
      final agg = sessionMap['session_blocks'];
      final count = agg is List && agg.isNotEmpty
          ? ((agg.first as Map)['count'] as int? ?? 0)
          : 0;
      return ProgramSessionLink(
        linkId: map['id'] as String,
        position: map['position'] as int,
        session: Session.fromJson(sessionMap),
        blockCount: count,
      );
    }).toList();
  }

  /// Ajoute une séance à la fin du programme (les duplicats sont autorisés).
  Future<void> addSession({
    required String programId,
    required String sessionId,
  }) async {
    final nextPosition = await _nextPosition(programId);
    await _client.from('program_sessions').insert({
      'program_id': programId,
      'session_id': sessionId,
      'position': nextPosition,
    });
  }

  Future<void> removeLink(String linkId) async {
    await _client.from('program_sessions').delete().eq('id', linkId);
  }

  Future<void> reorderLinks({
    required String programId,
    required List<String> linkIdsInOrder,
  }) async {
    for (var i = 0; i < linkIdsInOrder.length; i++) {
      await _client
          .from('program_sessions')
          .update({'position': i}).eq('id', linkIdsInOrder[i]);
    }
  }

  Future<int> _nextPosition(String programId) async {
    final last = await _client
        .from('program_sessions')
        .select('position')
        .eq('program_id', programId)
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

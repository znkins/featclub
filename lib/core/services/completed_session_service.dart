import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/completed_session.dart';

/// Historique des séances terminées (`public.completed_sessions`).
///
/// Lecture côté coach et élève, création côté élève uniquement
/// (bouton « Terminer » du détail séance ou du mode d'exécution).
class CompletedSessionService {
  CompletedSessionService(this._client);

  final SupabaseClient _client;

  static const String _columns =
      'id, student_id, student_session_id, session_title, comment, completed_at';

  /// Crée une entrée de séance terminée pour un élève.
  ///
  /// `sessionTitle` est un snapshot : l'historique reste lisible même si la
  /// séance source est supprimée. La séance n'est pas désactivée — l'élève
  /// peut la refaire plus tard.
  Future<CompletedSession> create({
    required String studentId,
    required String studentSessionId,
    required String sessionTitle,
    String? comment,
  }) async {
    final trimmed = comment?.trim();
    final row = await _client
        .from('completed_sessions')
        .insert({
          'student_id': studentId,
          'student_session_id': studentSessionId,
          'session_title': sessionTitle,
          'comment':
              trimmed == null || trimmed.isEmpty ? null : trimmed,
        })
        .select(_columns)
        .single();
    return CompletedSession.fromJson(row);
  }

  /// Nombre total de séances terminées par un élève.
  ///
  /// Requête dédiée `select('id')` pour éviter de tirer title/comment juste
  /// pour compter.
  Future<int> countByStudent(String studentId) async {
    final rows = await _client
        .from('completed_sessions')
        .select('id')
        .eq('student_id', studentId);
    return (rows as List).length;
  }

  /// Liste les séances terminées d'un élève, plus récentes en tête.
  Future<List<CompletedSession>> listByStudent(
    String studentId, {
    int? limit,
  }) async {
    var query = _client
        .from('completed_sessions')
        .select(_columns)
        .eq('student_id', studentId)
        .order('completed_at', ascending: false);
    if (limit != null) {
      final rows = await query.limit(limit);
      return (rows as List)
          .map((r) => CompletedSession.fromJson(r as Map<String, dynamic>))
          .toList();
    }
    final rows = await query;
    return (rows as List)
        .map((r) => CompletedSession.fromJson(r as Map<String, dynamic>))
        .toList();
  }
}

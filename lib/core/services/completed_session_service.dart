import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/completed_session.dart';

/// Historique des séances terminées (`public.completed_sessions`).
///
/// Lecture seule côté coach en Phase 3 (les complétions sont créées par les
/// élèves en Phase 4).
class CompletedSessionService {
  CompletedSessionService(this._client);

  final SupabaseClient _client;

  static const String _columns =
      'id, student_id, student_session_id, session_title, comment, completed_at';

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

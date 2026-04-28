// Service Supabase pour `completed_sessions` (historique des séances faites).

import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/completed_session.dart';
import '../models/profile.dart';

/// Complétion + profil de l'élève (utilisé par le feed d'activité coach).
class RecentActivityItem {
  const RecentActivityItem({required this.completion, required this.student});

  final CompletedSession completion;
  final Profile student;
}

class CompletedSessionService {
  CompletedSessionService(this._client);

  final SupabaseClient _client;

  static const String _columns =
      'id, student_id, student_session_id, session_title, comment, completed_at';
  static const String _profileColumns =
      'id, role, status, first_name, last_name, bio, birth_date, height_cm, goal, current_weight, avatar_url, created_at';

  /// Marque une séance comme terminée pour un élève.
  /// `sessionTitle` est un snapshot : l'historique reste lisible même
  /// si la séance source est supprimée plus tard.
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
  /// Requête `select('id')` pour ne pas tirer titre/commentaire inutilement.
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

  /// Feed d'activité coach paginé (curseur sur `completed_at`).
  /// Embarque le profil de l'élève pour afficher avatar + nom sans
  /// round-trip supplémentaire. Passer `before = completed_at du dernier
  /// item de la page précédente` pour charger la suite.
  Future<List<RecentActivityItem>> listRecentWithStudent({
    required int limit,
    DateTime? before,
  }) async {
    var query = _client
        .from('completed_sessions')
        .select('$_columns, student:profiles!completed_sessions_student_id_fkey($_profileColumns)');
    if (before != null) {
      query = query.lt('completed_at', before.toIso8601String());
    }
    final rows = await query
        .order('completed_at', ascending: false)
        .limit(limit);
    return (rows as List)
        .map((r) {
          final map = r as Map<String, dynamic>;
          final studentJson = map['student'] as Map<String, dynamic>?;
          if (studentJson == null) return null;
          return RecentActivityItem(
            completion: CompletedSession.fromJson(map),
            student: Profile.fromJson(studentJson),
          );
        })
        .whereType<RecentActivityItem>()
        .toList();
  }
}

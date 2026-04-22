import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/student_program.dart';

/// Programme élève avec compteur de séances (pour la liste sur la fiche élève).
class StudentProgramListItem {
  const StudentProgramListItem({
    required this.program,
    required this.sessionCount,
  });

  final StudentProgram program;
  final int sessionCount;
}

/// Contenu personnalisé d'un élève : `student_programs`, `student_sessions`,
/// `student_session_blocks`, `student_session_exercises`.
///
/// C'est ici que vit la logique de duplication template -> élève via les RPC
/// `duplicate_program_template_for_student`,
/// `duplicate_session_template_for_student` et
/// `duplicate_block_template_for_student`.
class StudentProgramService {
  StudentProgramService(this._client);

  final SupabaseClient _client;

  static const String _programColumns =
      'id, student_id, title, description, is_active, created_at';

  /// Liste les programmes d'un élève (plus récents en premier).
  Future<List<StudentProgramListItem>> listByStudent(String studentId) async {
    final rows = await _client
        .from('student_programs')
        .select('$_programColumns, student_sessions(count)')
        .eq('student_id', studentId)
        .order('created_at', ascending: false);
    return (rows as List).map((r) {
      final map = r as Map<String, dynamic>;
      final agg = map['student_sessions'];
      final count = agg is List && agg.isNotEmpty
          ? ((agg.first as Map)['count'] as int? ?? 0)
          : 0;
      return StudentProgramListItem(
        program: StudentProgram.fromJson(map),
        sessionCount: count,
      );
    }).toList();
  }

  /// Crée un programme élève vide (inactif par défaut).
  Future<StudentProgram> createEmpty({
    required String studentId,
    required String title,
    String? description,
  }) async {
    final row = await _client
        .from('student_programs')
        .insert({
          'student_id': studentId,
          'title': title,
          'description': _nullIfBlank(description),
          'is_active': false,
        })
        .select(_programColumns)
        .single();
    return StudentProgram.fromJson(row);
  }

  /// Duplique un programme template vers un élève (copie profonde via RPC).
  Future<String> duplicateFromTemplate({
    required String studentId,
    required String sourceProgramId,
  }) async {
    final result = await _client.rpc(
      'duplicate_program_template_for_student',
      params: {
        'target_student_id': studentId,
        'source_program_id': sourceProgramId,
      },
    );
    return result as String;
  }

  Future<StudentProgram> updateMetadata({
    required String id,
    required String title,
    String? description,
  }) async {
    final row = await _client
        .from('student_programs')
        .update({
          'title': title,
          'description': _nullIfBlank(description),
        })
        .eq('id', id)
        .select(_programColumns)
        .single();
    return StudentProgram.fromJson(row);
  }

  Future<void> delete(String id) async {
    await _client.from('student_programs').delete().eq('id', id);
  }

  /// Active ou désactive un programme.
  ///
  /// Contrainte DB : un seul programme actif par élève. Pour activer, on
  /// désactive d'abord les autres programmes actifs du même élève afin de
  /// respecter l'index unique partiel `idx_student_programs_one_active`.
  Future<void> setActive({
    required String studentId,
    required String programId,
    required bool active,
  }) async {
    if (active) {
      await _client
          .from('student_programs')
          .update({'is_active': false})
          .eq('student_id', studentId)
          .neq('id', programId)
          .eq('is_active', true);
      await _client
          .from('student_programs')
          .update({'is_active': true}).eq('id', programId);
    } else {
      await _client
          .from('student_programs')
          .update({'is_active': false}).eq('id', programId);
    }
  }
}

String? _nullIfBlank(String? value) {
  if (value == null) return null;
  final trimmed = value.trim();
  return trimmed.isEmpty ? null : trimmed;
}

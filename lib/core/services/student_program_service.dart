import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/student_program.dart';
import '../models/student_session.dart';
import '../models/student_session_block.dart';
import '../models/student_session_exercise.dart';
import '../utils/day_of_week.dart';

/// Programme élève avec compteur de séances (pour la liste sur la fiche élève).
class StudentProgramListItem {
  const StudentProgramListItem({
    required this.program,
    required this.sessionCount,
  });

  final StudentProgram program;
  final int sessionCount;
}

/// Séance élève + compteur de blocs (ligne de l'éditeur programme).
class StudentSessionListItem {
  const StudentSessionListItem({
    required this.session,
    required this.blockCount,
  });

  final StudentSession session;
  final int blockCount;
}

/// Bloc élève + compteur d'exercices (ligne de l'éditeur séance).
class StudentBlockListItem {
  const StudentBlockListItem({
    required this.block,
    required this.exerciseCount,
  });

  final StudentSessionBlock block;
  final int exerciseCount;
}

/// Programme élève + liste ordonnée de ses séances (avec compteurs de blocs).
class StudentProgramEditorDetail {
  const StudentProgramEditorDetail({
    required this.program,
    required this.sessions,
  });

  final StudentProgram program;
  final List<StudentSessionListItem> sessions;
}

/// Séance élève + liste ordonnée de ses blocs (avec compteurs d'exercices).
class StudentSessionEditorDetail {
  const StudentSessionEditorDetail({
    required this.session,
    required this.blocks,
  });

  final StudentSession session;
  final List<StudentBlockListItem> blocks;
}

/// Bloc élève + liste ordonnée de ses exercices.
class StudentBlockEditorDetail {
  const StudentBlockEditorDetail({
    required this.block,
    required this.exercises,
  });

  final StudentSessionBlock block;
  final List<StudentSessionExercise> exercises;
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
  static const String _sessionColumns =
      'id, student_program_id, title, description, duration_minutes, day_of_week, assigned_date, position, created_at';
  static const String _blockColumns =
      'id, student_session_id, title, description, position';
  static const String _exerciseColumns =
      'id, student_block_id, title, description, video_url, reps, load, intensity, rest, note, position';

  // ---------------------------------------------------------------------------
  // Programmes
  // ---------------------------------------------------------------------------

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

  /// Charge un programme + ses séances (avec compteurs de blocs) en ordre.
  Future<StudentProgramEditorDetail> fetchProgramEditorDetail(
    String programId,
  ) async {
    final results = await Future.wait([
      _fetchProgramById(programId),
      listSessions(programId),
    ]);
    return StudentProgramEditorDetail(
      program: results[0] as StudentProgram,
      sessions: results[1] as List<StudentSessionListItem>,
    );
  }

  Future<StudentProgram> _fetchProgramById(String id) async {
    final row = await _client
        .from('student_programs')
        .select(_programColumns)
        .eq('id', id)
        .single();
    return StudentProgram.fromJson(row);
  }

  // ---------------------------------------------------------------------------
  // Séances
  // ---------------------------------------------------------------------------

  Future<List<StudentSessionListItem>> listSessions(String programId) async {
    final rows = await _client
        .from('student_sessions')
        .select('$_sessionColumns, student_session_blocks(count)')
        .eq('student_program_id', programId)
        .order('position', ascending: true);
    return (rows as List).map((r) {
      final map = r as Map<String, dynamic>;
      final agg = map['student_session_blocks'];
      final count = agg is List && agg.isNotEmpty
          ? ((agg.first as Map)['count'] as int? ?? 0)
          : 0;
      return StudentSessionListItem(
        session: StudentSession.fromJson(map),
        blockCount: count,
      );
    }).toList();
  }

  /// Crée une séance vide à la fin du programme.
  Future<StudentSession> createEmptySession({
    required String programId,
    required String title,
    String? description,
    int? durationMinutes,
    DayOfWeek? dayOfWeek,
  }) async {
    final position = await _nextSessionPosition(programId);
    final row = await _client
        .from('student_sessions')
        .insert({
          'student_program_id': programId,
          'title': title,
          'description': _nullIfBlank(description),
          'duration_minutes': durationMinutes,
          'day_of_week': dayOfWeek?.storageValue,
          'assigned_date': dayOfWeek != null
              ? _formatDate(nextDateForDayOfWeek(dayOfWeek))
              : null,
          'position': position,
        })
        .select(_sessionColumns)
        .single();
    return StudentSession.fromJson(row);
  }

  /// Duplique une séance template à la fin d'un programme élève (RPC).
  Future<String> duplicateSessionFromTemplate({
    required String studentProgramId,
    required String sourceSessionId,
  }) async {
    final result = await _client.rpc(
      'duplicate_session_template_for_student',
      params: {
        'target_student_program_id': studentProgramId,
        'source_session_id': sourceSessionId,
      },
    );
    return result as String;
  }

  /// Duplique une séance élève existante (copie profonde dans le même
  /// programme, ajoutée à la fin) via RPC.
  Future<String> duplicateStudentSession(String sourceSessionId) async {
    final result = await _client.rpc(
      'duplicate_student_session',
      params: {'source_student_session_id': sourceSessionId},
    );
    return result as String;
  }

  Future<StudentSession> updateSessionMetadata({
    required String id,
    required String title,
    String? description,
    int? durationMinutes,
    DayOfWeek? dayOfWeek,
  }) async {
    final row = await _client
        .from('student_sessions')
        .update({
          'title': title,
          'description': _nullIfBlank(description),
          'duration_minutes': durationMinutes,
          'day_of_week': dayOfWeek?.storageValue,
          'assigned_date': dayOfWeek != null
              ? _formatDate(nextDateForDayOfWeek(dayOfWeek))
              : null,
        })
        .eq('id', id)
        .select(_sessionColumns)
        .single();
    return StudentSession.fromJson(row);
  }

  Future<void> deleteSession(String id) async {
    await _client.from('student_sessions').delete().eq('id', id);
  }

  Future<void> reorderSessions({
    required String programId,
    required List<String> sessionIdsInOrder,
  }) async {
    for (var i = 0; i < sessionIdsInOrder.length; i++) {
      await _client
          .from('student_sessions')
          .update({'position': i}).eq('id', sessionIdsInOrder[i]);
    }
  }

  Future<int> _nextSessionPosition(String programId) async {
    final last = await _client
        .from('student_sessions')
        .select('position')
        .eq('student_program_id', programId)
        .order('position', ascending: false)
        .limit(1);
    return (last as List).isEmpty
        ? 0
        : ((last.first as Map)['position'] as int) + 1;
  }

  /// Charge une séance + ses blocs (avec compteurs d'exercices).
  Future<StudentSessionEditorDetail> fetchSessionEditorDetail(
    String sessionId,
  ) async {
    final results = await Future.wait([
      _fetchSessionById(sessionId),
      listBlocks(sessionId),
    ]);
    return StudentSessionEditorDetail(
      session: results[0] as StudentSession,
      blocks: results[1] as List<StudentBlockListItem>,
    );
  }

  Future<StudentSession> _fetchSessionById(String id) async {
    final row = await _client
        .from('student_sessions')
        .select(_sessionColumns)
        .eq('id', id)
        .single();
    return StudentSession.fromJson(row);
  }

  // ---------------------------------------------------------------------------
  // Blocs
  // ---------------------------------------------------------------------------

  Future<List<StudentBlockListItem>> listBlocks(String sessionId) async {
    final rows = await _client
        .from('student_session_blocks')
        .select('$_blockColumns, student_session_exercises(count)')
        .eq('student_session_id', sessionId)
        .order('position', ascending: true);
    return (rows as List).map((r) {
      final map = r as Map<String, dynamic>;
      final agg = map['student_session_exercises'];
      final count = agg is List && agg.isNotEmpty
          ? ((agg.first as Map)['count'] as int? ?? 0)
          : 0;
      return StudentBlockListItem(
        block: StudentSessionBlock.fromJson(map),
        exerciseCount: count,
      );
    }).toList();
  }

  Future<StudentSessionBlock> createEmptyBlock({
    required String sessionId,
    required String title,
    String? description,
  }) async {
    final position = await _nextBlockPosition(sessionId);
    final row = await _client
        .from('student_session_blocks')
        .insert({
          'student_session_id': sessionId,
          'title': title,
          'description': _nullIfBlank(description),
          'position': position,
        })
        .select(_blockColumns)
        .single();
    return StudentSessionBlock.fromJson(row);
  }

  Future<String> duplicateBlockFromTemplate({
    required String studentSessionId,
    required String sourceBlockId,
  }) async {
    final result = await _client.rpc(
      'duplicate_block_template_for_student',
      params: {
        'target_student_session_id': studentSessionId,
        'source_block_id': sourceBlockId,
      },
    );
    return result as String;
  }

  /// Duplique un bloc élève existant (copie profonde dans la même séance,
  /// ajouté à la fin) via RPC.
  Future<String> duplicateStudentBlock(String sourceBlockId) async {
    final result = await _client.rpc(
      'duplicate_student_block',
      params: {'source_student_block_id': sourceBlockId},
    );
    return result as String;
  }

  Future<StudentSessionBlock> updateBlockMetadata({
    required String id,
    required String title,
    String? description,
  }) async {
    final row = await _client
        .from('student_session_blocks')
        .update({
          'title': title,
          'description': _nullIfBlank(description),
        })
        .eq('id', id)
        .select(_blockColumns)
        .single();
    return StudentSessionBlock.fromJson(row);
  }

  Future<void> deleteBlock(String id) async {
    await _client.from('student_session_blocks').delete().eq('id', id);
  }

  Future<void> reorderBlocks({
    required String sessionId,
    required List<String> blockIdsInOrder,
  }) async {
    for (var i = 0; i < blockIdsInOrder.length; i++) {
      await _client
          .from('student_session_blocks')
          .update({'position': i}).eq('id', blockIdsInOrder[i]);
    }
  }

  Future<int> _nextBlockPosition(String sessionId) async {
    final last = await _client
        .from('student_session_blocks')
        .select('position')
        .eq('student_session_id', sessionId)
        .order('position', ascending: false)
        .limit(1);
    return (last as List).isEmpty
        ? 0
        : ((last.first as Map)['position'] as int) + 1;
  }

  /// Charge un bloc + ses exercices.
  Future<StudentBlockEditorDetail> fetchBlockEditorDetail(
    String blockId,
  ) async {
    final results = await Future.wait([
      _fetchBlockById(blockId),
      listExercises(blockId),
    ]);
    return StudentBlockEditorDetail(
      block: results[0] as StudentSessionBlock,
      exercises: results[1] as List<StudentSessionExercise>,
    );
  }

  Future<StudentSessionBlock> _fetchBlockById(String id) async {
    final row = await _client
        .from('student_session_blocks')
        .select(_blockColumns)
        .eq('id', id)
        .single();
    return StudentSessionBlock.fromJson(row);
  }

  // ---------------------------------------------------------------------------
  // Exercices
  // ---------------------------------------------------------------------------

  Future<List<StudentSessionExercise>> listExercises(String blockId) async {
    final rows = await _client
        .from('student_session_exercises')
        .select(_exerciseColumns)
        .eq('student_block_id', blockId)
        .order('position', ascending: true);
    return (rows as List)
        .map((r) =>
            StudentSessionExercise.fromJson(r as Map<String, dynamic>))
        .toList();
  }

  Future<StudentSessionExercise> fetchExerciseById(String id) async {
    final row = await _client
        .from('student_session_exercises')
        .select(_exerciseColumns)
        .eq('id', id)
        .single();
    return StudentSessionExercise.fromJson(row);
  }

  /// Crée un exercice ad hoc à la fin du bloc.
  Future<StudentSessionExercise> createEmptyExercise({
    required String blockId,
    required String title,
    String? description,
    String? videoUrl,
    String? reps,
    String? load,
    String? intensity,
    String? rest,
    String? note,
  }) async {
    final position = await _nextExercisePosition(blockId);
    final row = await _client
        .from('student_session_exercises')
        .insert({
          'student_block_id': blockId,
          'title': title,
          'description': _nullIfBlank(description),
          'video_url': _nullIfBlank(videoUrl),
          'reps': _nullIfBlank(reps),
          'load': _nullIfBlank(load),
          'intensity': _nullIfBlank(intensity),
          'rest': _nullIfBlank(rest),
          'note': _nullIfBlank(note),
          'position': position,
        })
        .select(_exerciseColumns)
        .single();
    return StudentSessionExercise.fromJson(row);
  }

  /// Crée un exercice à partir d'un exercice de la bibliothèque coach.
  ///
  /// Snapshot du titre, de la description et de l'URL vidéo ; les paramètres
  /// prescriptifs (reps/load/intensity/rest/note) restent à renseigner par
  /// le coach via l'éditeur.
  Future<StudentSessionExercise> createExerciseFromLibrary({
    required String blockId,
    required String libraryExerciseId,
  }) async {
    final source = await _client
        .from('exercises')
        .select('title, description, video_url')
        .eq('id', libraryExerciseId)
        .single();
    return createEmptyExercise(
      blockId: blockId,
      title: source['title'] as String,
      description: source['description'] as String?,
      videoUrl: source['video_url'] as String?,
    );
  }

  Future<StudentSessionExercise> updateExercise({
    required String id,
    required String title,
    String? description,
    String? videoUrl,
    String? reps,
    String? load,
    String? intensity,
    String? rest,
    String? note,
  }) async {
    final row = await _client
        .from('student_session_exercises')
        .update({
          'title': title,
          'description': _nullIfBlank(description),
          'video_url': _nullIfBlank(videoUrl),
          'reps': _nullIfBlank(reps),
          'load': _nullIfBlank(load),
          'intensity': _nullIfBlank(intensity),
          'rest': _nullIfBlank(rest),
          'note': _nullIfBlank(note),
        })
        .eq('id', id)
        .select(_exerciseColumns)
        .single();
    return StudentSessionExercise.fromJson(row);
  }

  Future<void> deleteExercise(String id) async {
    await _client.from('student_session_exercises').delete().eq('id', id);
  }

  Future<void> reorderExercises({
    required String blockId,
    required List<String> exerciseIdsInOrder,
  }) async {
    for (var i = 0; i < exerciseIdsInOrder.length; i++) {
      await _client
          .from('student_session_exercises')
          .update({'position': i}).eq('id', exerciseIdsInOrder[i]);
    }
  }

  Future<int> _nextExercisePosition(String blockId) async {
    final last = await _client
        .from('student_session_exercises')
        .select('position')
        .eq('student_block_id', blockId)
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

String _formatDate(DateTime d) {
  final y = d.year.toString().padLeft(4, '0');
  final m = d.month.toString().padLeft(2, '0');
  final day = d.day.toString().padLeft(2, '0');
  return '$y-$m-$day';
}

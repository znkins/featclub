// Service Supabase pour le contenu personnalisé d'un élève :
// `student_programs`, `student_sessions`, `student_session_blocks`,
// `student_session_exercises`. C'est ici que vit la duplication
// template → élève (RPC `duplicate_*_template_for_student`).

import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/student_program.dart';
import '../models/student_session.dart';
import '../models/student_session_block.dart';
import '../models/student_session_exercise.dart';
import '../utils/day_of_week.dart';

/// Programme élève + nombre de séances (utilisé sur la fiche élève).
class StudentProgramListItem {
  const StudentProgramListItem({
    required this.program,
    required this.sessionCount,
  });

  final StudentProgram program;
  final int sessionCount;
}

/// Séance élève + nombre de blocs (ligne de l'éditeur programme).
class StudentSessionListItem {
  const StudentSessionListItem({
    required this.session,
    required this.blockCount,
  });

  final StudentSession session;
  final int blockCount;
}

/// Bloc élève + nombre d'exercices (ligne de l'éditeur séance).
class StudentBlockListItem {
  const StudentBlockListItem({
    required this.block,
    required this.exerciseCount,
  });

  final StudentSessionBlock block;
  final int exerciseCount;
}

/// Programme + ses séances pour l'éditeur coach.
class StudentProgramEditorDetail {
  const StudentProgramEditorDetail({
    required this.program,
    required this.sessions,
  });

  final StudentProgram program;
  final List<StudentSessionListItem> sessions;
}

/// Séance + ses blocs pour l'éditeur coach.
class StudentSessionEditorDetail {
  const StudentSessionEditorDetail({
    required this.session,
    required this.blocks,
  });

  final StudentSession session;
  final List<StudentBlockListItem> blocks;
}

/// Bloc + ses exercices pour l'éditeur coach.
class StudentBlockEditorDetail {
  const StudentBlockEditorDetail({
    required this.block,
    required this.exercises,
  });

  final StudentSessionBlock block;
  final List<StudentSessionExercise> exercises;
}

/// Séance élève + champs dérivés pour l'affichage côté élève.
/// `nextOccurrence` est recalculée à chaque lecture à partir du
/// `dayOfWeek` et des complétions de la semaine en cours.
class StudentSessionView {
  const StudentSessionView({
    required this.session,
    required this.nextOccurrence,
  });

  final StudentSession session;

  /// `null` si la séance n'a pas de `dayOfWeek` (non planifiée).
  final DateTime? nextOccurrence;
}

/// Programme actif d'un élève + ses séances triées pour l'app élève.
class StudentActiveProgramDetail {
  const StudentActiveProgramDetail({
    required this.program,
    required this.sessions,
  });

  /// `null` si l'élève n'a aucun programme actif.
  final StudentProgram? program;

  /// Séances avec `nextOccurrence` non nulle en premier (plus proche
  /// d'abord), puis séances sans jour assigné par date de création.
  final List<StudentSessionView> sessions;
}

/// Bloc + ses exercices ordonnés (vue lecture pour l'élève).
class StudentSessionBlockContent {
  const StudentSessionBlockContent({
    required this.block,
    required this.exercises,
  });

  final StudentSessionBlock block;
  final List<StudentSessionExercise> exercises;
}

/// Arbre complet d'une séance élève (séance + blocs + exercices).
/// Chargé d'un coup pour le détail séance et le mode d'exécution
/// (pas d'aller-retour réseau pendant la séance).
class StudentSessionContent {
  const StudentSessionContent({
    required this.session,
    required this.nextOccurrence,
    required this.blocks,
  });

  final StudentSession session;
  final DateTime? nextOccurrence;
  final List<StudentSessionBlockContent> blocks;

  int get exerciseCount =>
      blocks.fold<int>(0, (acc, b) => acc + b.exercises.length);
}

class StudentProgramService {
  StudentProgramService(this._client);

  final SupabaseClient _client;

  static const String _programColumns =
      'id, student_id, title, description, is_active, created_at';
  static const String _sessionColumns =
      'id, student_program_id, title, description, duration_minutes, day_of_week, position, created_at';
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

  /// Duplique un programme template vers un élève (RPC
  /// `duplicate_program_template_for_student`, copie profonde).
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

  /// Active ou désactive un programme. Pour activer, on désactive d'abord
  /// les autres programmes actifs du même élève (contrainte d'unicité DB :
  /// un seul programme actif à la fois par élève).
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

  /// Programme actif d'un élève. `null` si aucun n'est actif.
  Future<StudentProgram?> fetchActiveProgram(String studentId) async {
    final rows = await _client
        .from('student_programs')
        .select(_programColumns)
        .eq('student_id', studentId)
        .eq('is_active', true)
        .limit(1);
    final list = rows as List;
    if (list.isEmpty) return null;
    return StudentProgram.fromJson(list.first as Map<String, dynamic>);
  }

  /// Programme actif + séances triées pour la vue élève
  /// (séance la plus proche en tête, puis non planifiées).
  Future<StudentActiveProgramDetail> fetchActiveProgramWithSessions(
    String studentId,
  ) async {
    final program = await fetchActiveProgram(studentId);
    if (program == null) {
      return const StudentActiveProgramDetail(program: null, sessions: []);
    }
    final rows = await _client
        .from('student_sessions')
        .select(_sessionColumns)
        .eq('student_program_id', program.id);
    final sessions = (rows as List)
        .map((r) => StudentSession.fromJson(r as Map<String, dynamic>))
        .toList();

    final completedIds = sessions.isEmpty
        ? <String>{}
        : await _completedSessionIdsThisWeek(
            sessions.map((s) => s.id).toList(),
          );

    final views = sessions.map((s) {
      final day = DayOfWeek.fromStorage(s.dayOfWeek);
      return StudentSessionView(
        session: s,
        nextOccurrence: day == null
            ? null
            : nextOccurrenceForStudent(
                day,
                completedThisWeek: completedIds.contains(s.id),
              ),
      );
    }).toList()
      ..sort(_compareStudentSessionViewsForStudent);

    return StudentActiveProgramDetail(program: program, sessions: views);
  }

  /// Ids des séances ayant au moins une complétion depuis lundi 00h.
  Future<Set<String>> _completedSessionIdsThisWeek(
    List<String> sessionIds,
  ) async {
    final weekStart = currentWeekStart();
    final rows = await _client
        .from('completed_sessions')
        .select('student_session_id')
        .inFilter('student_session_id', sessionIds)
        .gte('completed_at', weekStart.toIso8601String());
    return {
      for (final r in rows as List)
        (r as Map<String, dynamic>)['student_session_id'] as String,
    };
  }

  /// Charge l'arbre complet d'une séance (entête + blocs + exercices)
  /// en une seule requête imbriquée.
  Future<StudentSessionContent> fetchStudentSessionContent(
    String sessionId,
  ) async {
    final row = await _client
        .from('student_sessions')
        .select(
          '$_sessionColumns, '
          'student_session_blocks('
          '$_blockColumns, '
          'student_session_exercises($_exerciseColumns)'
          ')',
        )
        .eq('id', sessionId)
        .single();
    final session = StudentSession.fromJson(row);
    final rawBlocks =
        (row['student_session_blocks'] as List? ?? []).cast<Map<String, dynamic>>();
    final sortedBlocks = [...rawBlocks]
      ..sort((a, b) => (a['position'] as int).compareTo(b['position'] as int));
    final blocks = sortedBlocks.map((b) {
      final rawEx = (b['student_session_exercises'] as List? ?? [])
          .cast<Map<String, dynamic>>();
      final exercises = rawEx
          .map(StudentSessionExercise.fromJson)
          .toList()
        ..sort((a, c) => a.position.compareTo(c.position));
      return StudentSessionBlockContent(
        block: StudentSessionBlock.fromJson(b),
        exercises: exercises,
      );
    }).toList();

    final day = DayOfWeek.fromStorage(session.dayOfWeek);
    DateTime? nextOccurrence;
    if (day != null) {
      final completed = await _completedSessionIdsThisWeek([sessionId]);
      nextOccurrence = nextOccurrenceForStudent(
        day,
        completedThisWeek: completed.contains(sessionId),
      );
    }

    return StudentSessionContent(
      session: session,
      nextOccurrence: nextOccurrence,
      blocks: blocks,
    );
  }

  /// Programme + ses séances ordonnées (avec compteurs de blocs).
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
          'position': position,
        })
        .select(_sessionColumns)
        .single();
    return StudentSession.fromJson(row);
  }

  /// Duplique une séance template vers un programme élève (RPC
  /// `duplicate_session_template_for_student`).
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

  /// Duplique une séance élève existante (RPC `duplicate_student_session`).
  /// La copie est ajoutée à la fin du même programme.
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

  /// Séance + ses blocs ordonnés (avec compteurs d'exercices).
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

  /// Duplique un bloc template vers une séance élève (RPC
  /// `duplicate_block_template_for_student`).
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

  /// Duplique un bloc élève existant (RPC `duplicate_student_block`).
  /// La copie est ajoutée à la fin de la même séance.
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

  /// Bloc + ses exercices ordonnés.
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

  /// Crée un exercice ad hoc à la fin du bloc (saisie libre, pas de template).
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
  /// Snapshot du titre, de la description et de l'URL vidéo. Les paramètres
  /// (reps/load/intensity/rest/note) sont à renseigner ensuite via l'éditeur.
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

int _compareStudentSessionViewsForStudent(
  StudentSessionView a,
  StudentSessionView b,
) {
  final ad = a.nextOccurrence;
  final bd = b.nextOccurrence;
  if (ad != null && bd != null) {
    final byDate = ad.compareTo(bd);
    if (byDate != 0) return byDate;
    return a.session.createdAt.compareTo(b.session.createdAt);
  }
  if (ad != null) return -1;
  if (bd != null) return 1;
  return a.session.createdAt.compareTo(b.session.createdAt);
}

String? _nullIfBlank(String? value) {
  if (value == null) return null;
  final trimmed = value.trim();
  return trimmed.isEmpty ? null : trimmed;
}

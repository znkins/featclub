import 'package:supabase_flutter/supabase_flutter.dart';

/// Contenu personnalisé d'un élève : `student_programs`, `student_sessions`,
/// `student_session_blocks`, `student_session_exercises`.
///
/// C'est ici que vit la logique de duplication template -> élève via les RPC
/// `duplicate_program_template_for_student`,
/// `duplicate_session_template_for_student` et
/// `duplicate_block_template_for_student`.
///
/// Squelette posé en Phase 0. Méthodes implémentées en Phase 3.
class StudentProgramService {
  StudentProgramService(this.client);

  final SupabaseClient client;

  static const String programsTable = 'student_programs';
  static const String sessionsTable = 'student_sessions';
  static const String blocksTable = 'student_session_blocks';
  static const String exercisesTable = 'student_session_exercises';
}

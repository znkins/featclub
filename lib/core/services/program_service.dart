import 'package:supabase_flutter/supabase_flutter.dart';

/// Bibliothèque de programmes templates (`public.programs` + `public.program_sessions`).
///
/// Squelette posé en Phase 0. Méthodes implémentées en Phase 2.
class ProgramService {
  ProgramService(this.client);

  final SupabaseClient client;

  static const String table = 'programs';
  static const String pivotTable = 'program_sessions';
}

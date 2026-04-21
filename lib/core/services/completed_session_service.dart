import 'package:supabase_flutter/supabase_flutter.dart';

/// Historique des séances terminées (`public.completed_sessions`).
///
/// Squelette posé en Phase 0. Méthodes implémentées en Phase 4 (création) et
/// Phase 5 (feed coach).
class CompletedSessionService {
  CompletedSessionService(this.client);

  final SupabaseClient client;

  static const String table = 'completed_sessions';
}

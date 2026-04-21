import 'package:supabase_flutter/supabase_flutter.dart';

/// Bibliothèque de séances templates (`public.sessions` + `public.session_blocks`).
///
/// Squelette posé en Phase 0. Méthodes implémentées en Phase 2.
class SessionService {
  SessionService(this.client);

  final SupabaseClient client;

  static const String table = 'sessions';
  static const String pivotTable = 'session_blocks';
}

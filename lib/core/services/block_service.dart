import 'package:supabase_flutter/supabase_flutter.dart';

/// Bibliothèque de blocs coach (`public.blocks` + `public.block_exercises`).
///
/// Squelette posé en Phase 0. Méthodes implémentées en Phase 2.
class BlockService {
  BlockService(this.client);

  final SupabaseClient client;

  static const String table = 'blocks';
  static const String pivotTable = 'block_exercises';
}

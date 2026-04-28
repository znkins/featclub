import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/models/admin_user_row.dart';
import '../../shared/providers/supabase_providers.dart';

/// Liste complète des utilisateurs (RPC `admin_list_users`).
///
/// Triée côté SQL par date de création décroissante. Le filtrage par texte
/// est fait côté écran.
final adminUsersProvider = FutureProvider<List<AdminUserRow>>((ref) async {
  final service = ref.watch(adminUserServiceProvider);
  return service.listUsers();
});

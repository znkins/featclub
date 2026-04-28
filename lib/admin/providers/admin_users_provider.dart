import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/models/admin_user_row.dart';
import '../../shared/providers/supabase_providers.dart';

/// Liste de tous les utilisateurs (FutureProvider).
/// Charge via la RPC `admin_list_users`. Le filtrage texte est fait côté UI.
final adminUsersProvider = FutureProvider<List<AdminUserRow>>((ref) async {
  final service = ref.watch(adminUserServiceProvider);
  return service.listUsers();
});

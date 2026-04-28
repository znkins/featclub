import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/admin_user_row.dart';
import '../utils/user_role.dart';

/// Gestion admin des comptes : liste enrichie de l'email, mise à jour
/// rôle/statut, suppression complète d'un compte élève.
///
/// Les emails sont récupérés via la RPC `admin_list_users` (SECURITY DEFINER,
/// restreinte au rôle admin). La suppression complète passe par la RPC
/// `delete_student_account` qui purge données métier + auth.users.
class AdminUserService {
  AdminUserService(this._client);

  final SupabaseClient _client;

  Future<List<AdminUserRow>> listUsers() async {
    final rows = await _client.rpc('admin_list_users');
    return (rows as List)
        .map((r) => AdminUserRow.fromJson(r as Map<String, dynamic>))
        .toList();
  }

  Future<void> updateRoleAndStatus({
    required String id,
    required UserRole role,
    required AccessStatus status,
  }) async {
    await _client
        .from('profiles')
        .update({'role': role.name, 'status': status.name})
        .eq('id', id);
  }

  Future<void> deleteStudent(String id) async {
    await _client.rpc(
      'delete_student_account',
      params: {'target_user_id': id},
    );
  }
}

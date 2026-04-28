import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/admin_user_row.dart';
import '../utils/user_role.dart';

/// Gestion admin des comptes : liste enrichie de l'email, mise à jour
/// rôle/statut, suppression d'un compte élève.
class AdminUserService {
  AdminUserService(this._client);

  final SupabaseClient _client;

  /// Appelle la RPC `admin_list_users` (SECURITY DEFINER, restreinte admin).
  /// Renvoie chaque profil enrichi de l'email lu dans `auth.users`.
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

  /// Appelle la RPC `delete_student_account` (purge données métier + auth).
  Future<void> deleteStudent(String id) async {
    await _client.rpc(
      'delete_student_account',
      params: {'target_user_id': id},
    );
  }
}

import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/profile.dart';

/// Lecture / mise à jour des profils (`public.profiles`).
class ProfileService {
  ProfileService(this._client);

  final SupabaseClient _client;

  static const String _selectColumns =
      'id, role, status, first_name, last_name, bio, birth_date, height_cm, goal, current_weight, avatar_url, created_at';

  Future<Profile?> fetchById(String id) async {
    final row = await _client
        .from('profiles')
        .select(_selectColumns)
        .eq('id', id)
        .maybeSingle();
    if (row == null) return null;
    return Profile.fromJson(row);
  }

  /// Met à jour les champs éditables par l'utilisateur lui-même.
  ///
  /// On ne touche pas à `role`, `status` (réservés à l'admin) ni à
  /// `current_weight` (calculé par le trigger `update_current_weight`).
  Future<Profile> updateOwnProfile({
    required String id,
    String? firstName,
    String? lastName,
    String? bio,
    DateTime? birthDate,
    int? heightCm,
    String? goal,
    String? avatarUrl,
  }) async {
    final payload = <String, dynamic>{
      'first_name': firstName,
      'last_name': lastName,
      'bio': bio,
      'birth_date': birthDate?.toIso8601String().split('T').first,
      'height_cm': heightCm,
      'goal': goal,
      'avatar_url': ?avatarUrl,
    };

    final row = await _client
        .from('profiles')
        .update(payload)
        .eq('id', id)
        .select(_selectColumns)
        .single();
    return Profile.fromJson(row);
  }

  /// Mise à jour réservée à l'admin (role / status).
  Future<Profile> updateRoleAndStatus({
    required String id,
    required String role,
    required String status,
  }) async {
    final row = await _client
        .from('profiles')
        .update({'role': role, 'status': status})
        .eq('id', id)
        .select(_selectColumns)
        .single();
    return Profile.fromJson(row);
  }
}

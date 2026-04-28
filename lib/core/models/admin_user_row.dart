import '../utils/user_role.dart';

/// Ligne d'utilisateur retournée par la RPC `admin_list_users`.
///
/// Variante allégée de [Profile] : identité + email + rôle + statut.
/// L'email vient de `auth.users` (les clients ne peuvent pas le lire en direct).
class AdminUserRow {
  AdminUserRow({
    required this.id,
    required this.role,
    required this.status,
    required this.email,
    this.firstName,
    this.lastName,
    this.avatarUrl,
  });

  final String id;
  final UserRole role;
  final AccessStatus status;
  final String email;
  final String? firstName;
  final String? lastName;
  final String? avatarUrl;

  String get fullName {
    final parts = [firstName, lastName]
        .whereType<String>()
        .where((s) => s.isNotEmpty);
    return parts.join(' ');
  }

  /// Nom complet, ou email en fallback si pas de prénom/nom renseigné.
  String get displayName => fullName.isEmpty ? email : fullName;

  /// Initiales (jusqu'à 2 lettres). Fallback : 1ère lettre de l'email.
  String get initials {
    final f = (firstName ?? '').trim();
    final l = (lastName ?? '').trim();
    final i1 = f.isNotEmpty ? f[0] : '';
    final i2 = l.isNotEmpty ? l[0] : '';
    final base = (i1 + i2).toUpperCase();
    if (base.isNotEmpty) return base;
    return email.isNotEmpty ? email[0].toUpperCase() : '';
  }

  factory AdminUserRow.fromJson(Map<String, dynamic> json) {
    return AdminUserRow(
      id: json['id'] as String,
      role: UserRole.fromString(json['role'] as String),
      status: AccessStatus.fromString(json['status'] as String),
      email: json['email'] as String,
      firstName: json['first_name'] as String?,
      lastName: json['last_name'] as String?,
      avatarUrl: json['avatar_url'] as String?,
    );
  }
}

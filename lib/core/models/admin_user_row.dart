import '../utils/user_role.dart';

/// Ligne d'utilisateur retournée par la RPC `admin_list_users`.
///
/// Variante allégée de [Profile] : ne contient que les champs utiles à la
/// gestion admin (identité + email + rôle + statut), enrichie de l'email
/// depuis `auth.users` que les clients ne peuvent pas lire en direct.
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

  String get displayName => fullName.isEmpty ? email : fullName;

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

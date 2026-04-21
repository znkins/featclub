import '../utils/user_role.dart';

/// Profil applicatif (table `public.profiles`).
///
/// L'`id` est partagé avec `auth.users.id`. Le profil est créé
/// automatiquement à l'inscription via le trigger `handle_new_user`.
class Profile {
  Profile({
    required this.id,
    required this.role,
    required this.status,
    this.firstName,
    this.lastName,
    this.bio,
    this.birthDate,
    this.heightCm,
    this.goal,
    this.currentWeight,
    this.avatarUrl,
    required this.createdAt,
  });

  final String id;
  final UserRole role;
  final AccessStatus status;
  final String? firstName;
  final String? lastName;
  final String? bio;
  final DateTime? birthDate;
  final int? heightCm;
  final String? goal;
  final double? currentWeight;
  final String? avatarUrl;
  final DateTime createdAt;

  String get fullName {
    final parts = [firstName, lastName].whereType<String>().where((s) => s.isNotEmpty);
    return parts.join(' ');
  }

  /// Le profil est considéré complet dès lors que le prénom est renseigné.
  bool get isComplete => (firstName ?? '').trim().isNotEmpty;

  factory Profile.fromJson(Map<String, dynamic> json) {
    return Profile(
      id: json['id'] as String,
      role: UserRole.fromString(json['role'] as String),
      status: AccessStatus.fromString(json['status'] as String),
      firstName: json['first_name'] as String?,
      lastName: json['last_name'] as String?,
      bio: json['bio'] as String?,
      birthDate: json['birth_date'] != null
          ? DateTime.parse(json['birth_date'] as String)
          : null,
      heightCm: json['height_cm'] as int?,
      goal: json['goal'] as String?,
      currentWeight: (json['current_weight'] as num?)?.toDouble(),
      avatarUrl: json['avatar_url'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'role': role.name,
        'status': status.name,
        'first_name': firstName,
        'last_name': lastName,
        'bio': bio,
        'birth_date': birthDate?.toIso8601String().split('T').first,
        'height_cm': heightCm,
        'goal': goal,
        'current_weight': currentWeight,
        'avatar_url': avatarUrl,
        'created_at': createdAt.toIso8601String(),
      };
}

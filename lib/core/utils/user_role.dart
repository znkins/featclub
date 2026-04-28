/// Rôle applicatif (mappé sur la colonne `profiles.role`).
enum UserRole {
  eleve,
  coach,
  admin;

  static UserRole fromString(String value) {
    return UserRole.values.firstWhere(
      (r) => r.name == value,
      orElse: () => UserRole.eleve,
    );
  }
}

/// Statut d'accès (mappé sur la colonne `profiles.status`).
enum AccessStatus {
  active,
  disabled;

  static AccessStatus fromString(String value) {
    return AccessStatus.values.firstWhere(
      (s) => s.name == value,
      orElse: () => AccessStatus.active,
    );
  }
}

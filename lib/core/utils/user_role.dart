/// Énumération des rôles applicatifs Featclub.
///
/// Les valeurs `name` correspondent à celles stockées dans la colonne
/// `profiles.role` (cf. schema_featclub.sql).
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

/// Statuts d'accès stockés dans `profiles.status`.
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

import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../core/utils/user_role.dart';
import '../../theme/app_radius.dart';
import '../../theme/app_spacing.dart';

/// Libellé français d'un rôle (utilisé par les pills, le picker et la
/// recherche).
String labelForRole(UserRole role) {
  switch (role) {
    case UserRole.eleve:
      return 'Élève';
    case UserRole.coach:
      return 'Coach';
    case UserRole.admin:
      return 'Admin';
  }
}

/// Icône Lucide associée à un rôle (utilisée par les pills et le picker).
IconData iconForRole(UserRole role) {
  switch (role) {
    case UserRole.eleve:
      return LucideIcons.user;
    case UserRole.coach:
      return LucideIcons.dumbbell;
    case UserRole.admin:
      return LucideIcons.shield;
  }
}

/// Pill compact pour afficher le rôle d'un utilisateur dans la liste admin.
class AdminRolePill extends StatelessWidget {
  const AdminRolePill({super.key, required this.role});

  final UserRole role;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return _Pill(
      icon: iconForRole(role),
      label: labelForRole(role),
      foreground: theme.colorScheme.primary,
      background: theme.colorScheme.primary.withValues(alpha: 0.1),
    );
  }
}

/// Pill « Désactivé » signalant un compte avec statut `disabled`.
///
/// Le statut actif n'a volontairement pas de pill : le manque de pastille
/// rouge est suffisant pour signaler l'état "ok".
class AdminDisabledPill extends StatelessWidget {
  const AdminDisabledPill({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return _Pill(
      icon: LucideIcons.ban,
      label: 'Désactivé',
      foreground: theme.colorScheme.error,
      background: theme.colorScheme.error.withValues(alpha: 0.1),
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill({
    required this.icon,
    required this.label,
    required this.foreground,
    required this.background,
  });

  final IconData icon;
  final String label;
  final Color foreground;
  final Color background;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: background,
        borderRadius: AppRadius.fullAll,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: foreground),
          const SizedBox(width: AppSpacing.xs),
          Text(
            label,
            style: theme.textTheme.labelMedium?.copyWith(
              color: foreground,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}


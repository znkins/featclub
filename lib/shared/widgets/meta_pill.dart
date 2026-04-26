import 'package:flutter/material.dart';

import '../../theme/app_radius.dart';
import '../../theme/app_spacing.dart';

/// Pastille générique « icône + libellé » sur fond primaire léger.
///
/// Pattern visuel partagé par toutes les meta info de l'app : durée,
/// date assignée, jour de la semaine, compteur de blocs, paramètres
/// d'exercice (reps, charge, intensité, repos), etc.
///
/// Les pills spécifiques (DurationPill, AssignedDatePill, etc.) délèguent
/// le rendu ici et n'encapsulent que leur formatage propre.
class MetaPill extends StatelessWidget {
  const MetaPill({super.key, required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: theme.colorScheme.primary.withValues(alpha: 0.1),
        borderRadius: AppRadius.fullAll,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: theme.colorScheme.primary),
          const SizedBox(width: AppSpacing.xs),
          Text(
            label,
            style: theme.textTheme.labelMedium?.copyWith(
              color: theme.colorScheme.primary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

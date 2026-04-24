import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../core/utils/day_of_week.dart';
import '../../theme/app_radius.dart';
import '../../theme/app_spacing.dart';

/// Pastille « jour » : icône calendrier + libellé français du jour.
///
/// Utilisée dans l'éditeur de programme élève, dans la meta row des tuiles
/// séance, pour afficher le jour d'assignation de manière cohérente avec
/// les autres pills (DurationPill, CategoryChip).
class DayOfWeekPill extends StatelessWidget {
  const DayOfWeekPill({super.key, required this.dayOfWeek});

  final DayOfWeek dayOfWeek;

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
          Icon(
            LucideIcons.calendar,
            size: 14,
            color: theme.colorScheme.primary,
          ),
          const SizedBox(width: AppSpacing.xs),
          Text(
            dayOfWeek.frenchLabel,
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

import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../core/utils/formatters.dart';
import '../../theme/app_radius.dart';
import '../../theme/app_spacing.dart';

/// Pastille « date d'assignation » : icône calendrier + libellé humain
/// ("Aujourd'hui" / "Demain" / `JJ/MM/AAAA`) sur fond primaire léger.
///
/// Variante côté élève du [DayOfWeekPill] coach : ici la séance a une date
/// concrète, pas un jour de la semaine abstrait.
class AssignedDatePill extends StatelessWidget {
  const AssignedDatePill({super.key, required this.date});

  final DateTime date;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final label = formatAssignedDateLabel(date)!;
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

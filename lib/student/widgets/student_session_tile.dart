import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../coach/widgets/duration_pill.dart';
import '../../core/services/student_program_service.dart';
import '../../theme/app_radius.dart';
import '../../theme/app_spacing.dart';
import 'assigned_date_pill.dart';

/// Carte d'une séance dans la liste du programme élève :
/// titre + pills (date dérivée + durée) + description courte.
class StudentSessionTile extends StatelessWidget {
  const StudentSessionTile({
    super.key,
    required this.view,
    required this.onTap,
  });

  final StudentSessionView view;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final session = view.session;
    final hasDate = view.nextOccurrence != null;
    final hasDuration = session.durationMinutes != null;
    final description = (session.description ?? '').trim();

    return Material(
      color: theme.colorScheme.surface,
      shape: RoundedRectangleBorder(
        side: BorderSide(color: theme.colorScheme.outline),
        borderRadius: AppRadius.lgAll,
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: AppRadius.lgAll,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      session.title,
                      style: theme.textTheme.titleMedium,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Icon(
                    LucideIcons.chevronRight,
                    size: 18,
                    color: theme.colorScheme.primary,
                  ),
                ],
              ),
              if (hasDate || hasDuration) ...[
                const SizedBox(height: AppSpacing.sm),
                Wrap(
                  spacing: AppSpacing.sm,
                  runSpacing: AppSpacing.xs,
                  children: [
                    if (hasDate) AssignedDatePill(date: view.nextOccurrence!),
                    if (hasDuration)
                      DurationPill(minutes: session.durationMinutes!),
                  ],
                ),
              ],
              if (description.isNotEmpty) ...[
                const SizedBox(height: AppSpacing.sm),
                Text(
                  description,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

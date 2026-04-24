import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../core/models/student_session.dart';
import '../../core/utils/formatters.dart';
import '../../theme/app_radius.dart';
import '../../theme/app_spacing.dart';

/// Carte d'une séance élève dans la liste du programme.
///
/// Affiche titre, date (label humain : "Aujourd'hui"/"Demain"/`JJ/MM/AAAA`),
/// durée estimée et description courte si renseignée.
class StudentSessionTile extends StatelessWidget {
  const StudentSessionTile({
    super.key,
    required this.session,
    required this.onTap,
  });

  final StudentSession session;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dateLabel = formatAssignedDateLabel(session.assignedDate);
    final duration = session.durationMinutes != null
        ? '${session.durationMinutes} min'
        : null;
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
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ],
              ),
              if (dateLabel != null || duration != null) ...[
                const SizedBox(height: AppSpacing.sm),
                Row(
                  children: [
                    if (dateLabel != null) ...[
                      Icon(
                        LucideIcons.calendar,
                        size: 16,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                      const SizedBox(width: AppSpacing.xs),
                      Text(
                        dateLabel,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                    if (dateLabel != null && duration != null)
                      const SizedBox(width: AppSpacing.md),
                    if (duration != null) ...[
                      Icon(
                        LucideIcons.clock,
                        size: 16,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                      const SizedBox(width: AppSpacing.xs),
                      Text(
                        duration,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
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


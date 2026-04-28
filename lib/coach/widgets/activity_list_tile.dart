import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../core/services/completed_session_service.dart';
import '../../core/utils/formatters.dart';
import '../../core/widgets/user_avatar.dart';
import '../../theme/app_radius.dart';
import '../../theme/app_spacing.dart';

/// Ligne du feed d'activité coach : avatar + nom élève à gauche, date à
/// droite, titre de séance en sous-ligne, commentaire éventuel dans un
/// wrapper teinté en dessous.
///
/// Variante "feed" du `CompactHistoryRow` (qui s'utilise sur la fiche élève
/// où l'identité de l'élève est déjà connue) : ici l'identité est l'info
/// principale, on pousse donc l'avatar et le nom en tête de la ligne.
class ActivityListTile extends StatelessWidget {
  const ActivityListTile({super.key, required this.item});

  final RecentActivityItem item;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final student = item.student;
    final completion = item.completion;
    final displayName =
        student.fullName.isEmpty ? 'Profil incomplet' : student.fullName;
    final comment = completion.comment?.trim() ?? '';
    final hasComment = comment.isNotEmpty;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        borderRadius: AppRadius.lgAll,
        border: Border.all(color: theme.colorScheme.outline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              UserAvatar(
                avatarUrl: student.avatarUrl,
                initials: student.initials,
                size: 40,
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      displayName,
                      style: theme.textTheme.titleMedium,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      completion.sessionTitle,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Text(
                formatDate(completion.completedAt),
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
          if (hasComment) ...[
            const SizedBox(height: AppSpacing.md),
            Padding(
              padding: const EdgeInsets.only(left: 52),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.sm,
                  vertical: AppSpacing.xs,
                ),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withValues(alpha: 0.08),
                  borderRadius: AppRadius.mdAll,
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      LucideIcons.messageSquare,
                      size: 14,
                      color: theme.colorScheme.primary,
                    ),
                    const SizedBox(width: AppSpacing.xs),
                    Expanded(
                      child: Text(
                        comment,
                        style: theme.textTheme.bodyMedium,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

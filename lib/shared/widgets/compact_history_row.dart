import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../core/models/completed_session.dart';
import '../../core/utils/formatters.dart';
import '../../theme/app_radius.dart';
import '../../theme/app_spacing.dart';

/// Ligne compacte d'une séance terminée : icône check (primaire, dans un
/// wrapper teinté) à gauche, titre au centre, date à droite.
///
/// `showComment` : si `true` et qu'un commentaire existe, affiche le
/// commentaire en-dessous dans un wrapper teinté (utilisé dans le bottom
/// sheet historique). Dans la preview compacte (3 dernières lignes sur une
/// fiche), on le laisse à `false` pour garder les tuiles courtes.
class CompactHistoryRow extends StatelessWidget {
  const CompactHistoryRow({
    super.key,
    required this.item,
    this.showComment = false,
  });

  final CompletedSession item;
  final bool showComment;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final comment = item.comment?.trim() ?? '';
    final displayComment = showComment && comment.isNotEmpty;
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.md,
      ),
      decoration: BoxDecoration(
        borderRadius: AppRadius.lgAll,
        border: Border.all(color: theme.colorScheme.outline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withValues(alpha: 0.1),
                  borderRadius: AppRadius.mdAll,
                ),
                alignment: Alignment.center,
                child: Icon(
                  LucideIcons.calendarCheck,
                  size: 20,
                  color: theme.colorScheme.primary,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Text(
                  item.sessionTitle,
                  style: theme.textTheme.titleMedium,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Text(
                formatDate(item.completedAt),
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
          if (displayComment) ...[
            const SizedBox(height: AppSpacing.sm),
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
                  crossAxisAlignment: CrossAxisAlignment.center,
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

import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../theme/app_radius.dart';
import '../../theme/app_spacing.dart';

/// Tuile générique pour les listes de contenu coach.
///
/// Carte avec bordure, titre + sous-titre optionnel + chevron (si `onTap`).
///
/// `subtitleWidget` remplace `subtitle` quand fourni (permet d'afficher
/// un badge/chip à la place d'une simple ligne de texte).
class LibraryListTile extends StatelessWidget {
  const LibraryListTile({
    super.key,
    required this.title,
    this.subtitle,
    this.subtitleWidget,
    this.leading,
    this.onTap,
  });

  final String title;
  final String? subtitle;
  final Widget? subtitleWidget;
  final Widget? leading;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasSubtitle = subtitleWidget != null ||
        (subtitle != null && subtitle!.trim().isNotEmpty);
    return Material(
      color: theme.colorScheme.surface,
      borderRadius: AppRadius.lgAll,
      child: InkWell(
        borderRadius: AppRadius.lgAll,
        onTap: onTap,
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: AppRadius.lgAll,
            border: Border.all(color: theme.colorScheme.outline),
          ),
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Row(
            children: [
              if (leading != null) ...[
                leading!,
                const SizedBox(width: AppSpacing.md),
              ],
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      title,
                      style: theme.textTheme.titleMedium,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (hasSubtitle) ...[
                      subtitleWidget ??
                          Text(
                            subtitle!,
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
              if (onTap != null) ...[
                const SizedBox(width: AppSpacing.sm),
                Icon(
                  LucideIcons.chevronRight,
                  size: 18,
                  color: theme.colorScheme.primary,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

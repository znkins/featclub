import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../theme/app_radius.dart';
import '../../theme/app_spacing.dart';

/// Tuile sélectionnable pour les écrans « picker » (ajout multiple).
/// Même structure que `LibraryListTile` avec une checkbox à droite et
/// une bordure rehaussée quand `checked` est `true`.
class LibrarySelectableTile extends StatelessWidget {
  const LibrarySelectableTile({
    super.key,
    required this.title,
    required this.leading,
    required this.checked,
    required this.onTap,
    this.subtitleWidget,
  });

  final String title;
  final Widget leading;
  final Widget? subtitleWidget;
  final bool checked;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      color: theme.colorScheme.surface,
      borderRadius: AppRadius.lgAll,
      child: InkWell(
        borderRadius: AppRadius.lgAll,
        onTap: onTap,
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: AppRadius.lgAll,
            border: Border.all(
              color: checked
                  ? theme.colorScheme.primary
                  : theme.colorScheme.outline,
              width: checked ? 2 : 1,
            ),
          ),
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Row(
            children: [
              leading,
              const SizedBox(width: AppSpacing.md),
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
                    if (subtitleWidget != null) subtitleWidget!,
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Icon(
                checked ? LucideIcons.checkSquare : LucideIcons.square,
                color: checked
                    ? theme.colorScheme.primary
                    : theme.colorScheme.onSurfaceVariant,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

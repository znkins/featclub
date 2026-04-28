import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../theme/app_radius.dart';
import '../../theme/app_sizes.dart';
import '../../theme/app_spacing.dart';

/// Rangée drag-and-drop d'un écran détail (grip + contenu + actions).
/// Structure : `[grip | titre/sous-titre | menu overflow | chevron]`.
class ReorderableLibraryRow extends StatelessWidget {
  const ReorderableLibraryRow({
    super.key,
    required this.index,
    required this.title,
    this.subtitle,
    this.subtitleWidget,
    this.onTap,
    this.onDuplicate,
    this.onRemove,
    this.removeLabel = 'Retirer',
  });

  final int index;
  final String title;
  final String? subtitle;
  final Widget? subtitleWidget;
  final VoidCallback? onTap;
  final VoidCallback? onDuplicate;
  final VoidCallback? onRemove;

  /// Libellé de l'action de retrait. Passer `'Supprimer'` pour les entités
  /// propres à l'élève (cascade réelle), `'Retirer'` pour les liens biblio
  /// (qui ne suppriment pas le contenu sous-jacent).
  final String removeLabel;

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
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
          child: Row(
            children: [
              ReorderableDragStartListener(
                index: index,
                child: Padding(
                  padding: const EdgeInsets.only(
                    left: AppSpacing.md,
                    right: AppSpacing.lg,
                  ),
                  child: Icon(
                    LucideIcons.gripVertical,
                    color: theme.colorScheme.primary,
                    size: AppSizes.iconDefault,
                  ),
                ),
              ),
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
                      const SizedBox(height: AppSpacing.xs),
                      subtitleWidget ??
                          Text(
                            subtitle!,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                            maxLines: 5,
                            overflow: TextOverflow.ellipsis,
                          ),
                    ],
                  ],
                ),
              ),
              if (onDuplicate != null && onRemove != null)
                PopupMenuButton<_RowAction>(
                  tooltip: 'Plus d\'actions',
                  icon: Icon(
                    LucideIcons.moreVertical,
                    color: theme.colorScheme.secondary,
                    size: 20,
                  ),
                  onSelected: (action) {
                    switch (action) {
                      case _RowAction.duplicate:
                        onDuplicate?.call();
                      case _RowAction.remove:
                        onRemove?.call();
                    }
                  },
                  itemBuilder: (_) => [
                    PopupMenuItem(
                      value: _RowAction.duplicate,
                      child: Row(
                        children: [
                          Icon(
                            LucideIcons.copyPlus,
                            size: 18,
                            color: theme.colorScheme.primary,
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          const Text('Dupliquer'),
                        ],
                      ),
                    ),
                    PopupMenuItem(
                      value: _RowAction.remove,
                      child: Row(
                        children: [
                          Icon(
                            LucideIcons.minusCircle,
                            size: 18,
                            color: theme.colorScheme.secondary,
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          Text(removeLabel),
                        ],
                      ),
                    ),
                  ],
                )
              else if (onRemove != null)
                // Action unique (retirer) : icône directe plutôt qu'un menu
                // overflow à un seul item.
                IconButton(
                  tooltip: removeLabel,
                  icon: Icon(
                    LucideIcons.minusCircle,
                    color: theme.colorScheme.secondary,
                    size: 20,
                  ),
                  onPressed: onRemove,
                ),
              const SizedBox(width: AppSpacing.xs),
              Padding(
                padding: const EdgeInsets.only(right: AppSpacing.md),
                child: Icon(
                  LucideIcons.chevronRight,
                  size: 18,
                  color: theme.colorScheme.primary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

enum _RowAction { duplicate, remove }

/// Enveloppe l'élément en cours de drag pour supprimer l'ombre Material
/// par défaut (rendu plat cohérent avec le style de l'app).
Widget flatProxyDecorator(Widget child, int index, Animation<double> animation) {
  return Material(
    color: Colors.transparent,
    elevation: 0,
    child: child,
  );
}

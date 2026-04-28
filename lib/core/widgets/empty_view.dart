import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../theme/app_radius.dart';
import '../../theme/app_sizes.dart';
import '../../theme/app_spacing.dart';

/// État vide standard : icône + message court + action facultative.
///
/// `wrapIcon: true` rend l'icône dans une pastille arrondie teintée en
/// couleur primaire — cohérent avec les tuiles de la bibliothèque.
class EmptyView extends StatelessWidget {
  const EmptyView({
    super.key,
    required this.icon,
    required this.message,
    this.action,
    this.wrapIcon = false,
  });

  /// Variante standard pour une recherche qui ne ramène aucun résultat.
  /// Utilisée par toutes les listes recherchables et les pickers.
  const EmptyView.noResults({super.key})
      : icon = LucideIcons.search,
        message = 'Aucun résultat',
        action = null,
        wrapIcon = false;

  final IconData icon;
  final String message;
  final Widget? action;
  final bool wrapIcon;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (wrapIcon)
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withValues(alpha: 0.1),
                  borderRadius: AppRadius.lgAll,
                ),
                alignment: Alignment.center,
                child: Icon(
                  icon,
                  size: AppSizes.iconLarge,
                  color: theme.colorScheme.primary,
                ),
              )
            else
              Icon(
                icon,
                size: AppSizes.iconLarge,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              message,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyLarge?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            if (action != null) ...[
              const SizedBox(height: AppSpacing.xl),
              action!,
            ],
          ],
        ),
      ),
    );
  }
}

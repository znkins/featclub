import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../theme/app_radius.dart';
import '../../theme/app_spacing.dart';

/// Choix d'ajout côté éditeur élève : création vide ou depuis un template.
///
/// Utilisé au niveau programme, séance et bloc. Au niveau exercice, on
/// utilise le même widget avec des libellés ajustés (« Ad hoc » / « Biblio »).
enum AddChoice { empty, template }

/// Ouvre un bottom sheet avec deux options et retourne le choix (ou null).
Future<AddChoice?> showAddChoiceSheet(
  BuildContext context, {
  required String title,
  required String emptyTitle,
  required String emptySubtitle,
  required String templateTitle,
  required String templateSubtitle,
  IconData emptyIcon = LucideIcons.filePlus,
  IconData templateIcon = LucideIcons.copyPlus,
}) {
  return showModalBottomSheet<AddChoice>(
    context: context,
    showDragHandle: true,
    builder: (_) => _AddChoiceSheet(
      title: title,
      emptyTitle: emptyTitle,
      emptySubtitle: emptySubtitle,
      templateTitle: templateTitle,
      templateSubtitle: templateSubtitle,
      emptyIcon: emptyIcon,
      templateIcon: templateIcon,
    ),
  );
}

class _AddChoiceSheet extends StatelessWidget {
  const _AddChoiceSheet({
    required this.title,
    required this.emptyTitle,
    required this.emptySubtitle,
    required this.templateTitle,
    required this.templateSubtitle,
    required this.emptyIcon,
    required this.templateIcon,
  });

  final String title;
  final String emptyTitle;
  final String emptySubtitle;
  final String templateTitle;
  final String templateSubtitle;
  final IconData emptyIcon;
  final IconData templateIcon;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg,
          0,
          AppSpacing.lg,
          AppSpacing.lg,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.md),
              child: Text(title, style: theme.textTheme.titleLarge),
            ),
            _SheetOption(
              icon: emptyIcon,
              title: emptyTitle,
              subtitle: emptySubtitle,
              onTap: () => Navigator.of(context).pop(AddChoice.empty),
            ),
            const SizedBox(height: AppSpacing.md),
            _SheetOption(
              icon: templateIcon,
              title: templateTitle,
              subtitle: templateSubtitle,
              onTap: () => Navigator.of(context).pop(AddChoice.template),
            ),
          ],
        ),
      ),
    );
  }
}

class _SheetOption extends StatelessWidget {
  const _SheetOption({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
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
            border: Border.all(color: theme.colorScheme.outline),
          ),
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Row(
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
                  icon,
                  size: 20,
                  color: theme.colorScheme.primary,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(title, style: theme.textTheme.titleMedium),
                    Text(
                      subtitle,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                LucideIcons.chevronRight,
                size: 18,
                color: theme.colorScheme.primary,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

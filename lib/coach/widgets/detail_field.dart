import 'package:flutter/material.dart';

import '../../theme/app_spacing.dart';

/// Section d'un écran de détail : libellé + valeur ou placeholder.
///
/// Si `child` est `null`, affiche `emptyLabel` en italique atténué pour indiquer
/// qu'il s'agit d'un champ à renseigner.
class DetailField extends StatelessWidget {
  const DetailField({
    super.key,
    required this.label,
    required this.child,
    this.emptyLabel = '—',
  });

  final String label;
  final Widget? child;
  final String emptyLabel;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: theme.textTheme.labelLarge?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        child ??
            Text(
              emptyLabel,
              style: theme.textTheme.bodyLarge?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                fontStyle: FontStyle.italic,
              ),
            ),
      ],
    );
  }
}

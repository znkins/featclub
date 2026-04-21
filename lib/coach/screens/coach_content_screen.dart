import 'package:flutter/material.dart';

import '../../theme/app_spacing.dart';

/// Onglet Contenu coach (placeholder Phase 1, implémenté en Phase 2).
class CoachContentScreen extends StatelessWidget {
  const CoachContentScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Center(
        child: Text(
          'Contenu — Phase 2',
          style: theme.textTheme.bodyLarge?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ),
    );
  }
}

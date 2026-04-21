import 'package:flutter/material.dart';

import '../../theme/app_spacing.dart';

/// Onglet Accueil coach (placeholder Phase 1, implémenté en Phase 5).
class CoachHomeScreen extends StatelessWidget {
  const CoachHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Center(
        child: Text(
          'Accueil coach — Phase 5',
          style: theme.textTheme.bodyLarge?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ),
    );
  }
}

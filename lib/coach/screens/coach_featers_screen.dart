import 'package:flutter/material.dart';

import '../../theme/app_spacing.dart';

/// Onglet Featers (élèves) coach (placeholder Phase 1, implémenté en Phase 3).
class CoachFeatersScreen extends StatelessWidget {
  const CoachFeatersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Center(
        child: Text(
          'Featers — Phase 3',
          style: theme.textTheme.bodyLarge?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ),
    );
  }
}

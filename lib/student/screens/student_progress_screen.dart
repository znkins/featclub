import 'package:flutter/material.dart';

import '../../theme/app_spacing.dart';

/// Onglet Progression élève (placeholder Phase 1, implémenté en Phase 4).
class StudentProgressScreen extends StatelessWidget {
  const StudentProgressScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Center(
        child: Text(
          'Progression — Phase 4',
          style: theme.textTheme.bodyLarge?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';

import '../../theme/app_spacing.dart';

/// Onglet Programme élève (placeholder Phase 1, implémenté en Phase 4).
class StudentProgramScreen extends StatelessWidget {
  const StudentProgramScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Center(
        child: Text(
          'Mon programme — Phase 4',
          style: theme.textTheme.bodyLarge?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ),
    );
  }
}

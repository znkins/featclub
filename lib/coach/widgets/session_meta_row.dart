import 'package:flutter/material.dart';

import '../../theme/app_spacing.dart';
import 'duration_pill.dart';

/// Ligne de méta-infos pour une séance : compteur de blocs + pastille de durée.
///
/// Utilisée dans la liste des séances, l'entête du détail et les pickers.
class SessionMetaRow extends StatelessWidget {
  const SessionMetaRow({
    super.key,
    this.blockCount,
    this.durationMinutes,
  });

  final int? blockCount;
  final int? durationMinutes;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final items = <Widget>[];
    if (blockCount != null) {
      final c = blockCount!;
      items.add(Text(
        '$c bloc${c > 1 ? 's' : ''}',
        style: theme.textTheme.bodyMedium?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
        ),
      ));
    }
    if (durationMinutes != null) {
      items.add(DurationPill(minutes: durationMinutes!));
    }

    if (items.isEmpty) return const SizedBox.shrink();

    return Wrap(
      spacing: AppSpacing.md,
      runSpacing: AppSpacing.xs,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: items,
    );
  }
}

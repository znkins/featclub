import 'package:flutter/material.dart';

import '../../core/utils/day_of_week.dart';
import '../../theme/app_spacing.dart';
import 'day_of_week_pill.dart';
import 'duration_pill.dart';

/// Ligne de méta-infos pour une séance : jour assigné (éditeur élève) +
/// compteur de blocs + pastille de durée.
///
/// `dayOfWeek` n'est renseigné que dans le contexte éditeur élève, où une
/// séance peut avoir un jour assigné. Côté biblio, les séances templates
/// n'ont pas de jour, le paramètre reste `null`.
class SessionMetaRow extends StatelessWidget {
  const SessionMetaRow({
    super.key,
    this.dayOfWeek,
    this.blockCount,
    this.durationMinutes,
  });

  final DayOfWeek? dayOfWeek;
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
    if (dayOfWeek != null) {
      items.add(DayOfWeekPill(dayOfWeek: dayOfWeek!));
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

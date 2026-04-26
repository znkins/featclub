import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../shared/widgets/meta_pill.dart';

/// Pastille « nombre de blocs » : icône layers + `X bloc(s)`.
///
/// Utilisée dans le header du détail de séance, à côté de
/// [AssignedDatePill] et [DurationPill].
class BlockCountPill extends StatelessWidget {
  const BlockCountPill({super.key, required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    return MetaPill(
      icon: LucideIcons.layers,
      label: '$count bloc${count > 1 ? 's' : ''}',
    );
  }
}

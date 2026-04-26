import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../shared/widgets/meta_pill.dart';

/// Pastille « durée » : ic. horloge + `X min`.
///
/// Utilisée partout où la durée d'une séance est affichée (tuiles de liste,
/// entête de détail, pickers).
class DurationPill extends StatelessWidget {
  const DurationPill({super.key, required this.minutes});

  final int minutes;

  @override
  Widget build(BuildContext context) {
    return MetaPill(icon: LucideIcons.clock, label: '$minutes min');
  }
}

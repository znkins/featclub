import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../shared/widgets/meta_pill.dart';

/// Pastille de durée d'une séance (`X min`).
class DurationPill extends StatelessWidget {
  const DurationPill({super.key, required this.minutes});

  final int minutes;

  @override
  Widget build(BuildContext context) {
    return MetaPill(icon: LucideIcons.clock, label: '$minutes min');
  }
}

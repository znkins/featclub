import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../core/utils/day_of_week.dart';
import '../../shared/widgets/meta_pill.dart';

/// Pastille « jour » : icône calendrier + libellé français du jour.
///
/// Utilisée dans l'éditeur de programme élève et la meta row des tuiles
/// séance, pour afficher le jour d'assignation de manière cohérente avec
/// les autres pills.
class DayOfWeekPill extends StatelessWidget {
  const DayOfWeekPill({super.key, required this.dayOfWeek});

  final DayOfWeek dayOfWeek;

  @override
  Widget build(BuildContext context) {
    return MetaPill(icon: LucideIcons.calendar, label: dayOfWeek.frenchLabel);
  }
}

import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../core/utils/formatters.dart';
import '../../shared/widgets/meta_pill.dart';

/// Pastille « date d'assignation » : icône calendrier + libellé humain
/// ("Aujourd'hui" / "Demain" / `JJ/MM/AAAA`).
///
/// Variante côté élève du [DayOfWeekPill] coach : ici la séance a une date
/// concrète, pas un jour de la semaine abstrait.
class AssignedDatePill extends StatelessWidget {
  const AssignedDatePill({super.key, required this.date});

  final DateTime date;

  @override
  Widget build(BuildContext context) {
    return MetaPill(
      icon: LucideIcons.calendar,
      label: formatAssignedDateLabel(date)!,
    );
  }
}

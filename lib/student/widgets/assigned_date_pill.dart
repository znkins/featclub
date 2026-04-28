import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../core/utils/formatters.dart';
import '../../shared/widgets/meta_pill.dart';

/// Pastille de la date d'une séance côté élève (« Aujourd'hui » / « Demain »
/// / nom du jour / `JJ/MM/AAAA`). Variante de `DayOfWeekPill` côté coach.
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

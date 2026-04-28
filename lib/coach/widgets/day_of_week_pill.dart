import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../core/utils/day_of_week.dart';
import '../../shared/widgets/meta_pill.dart';

/// Pastille du jour assigné d'une séance élève (« Lundi », etc.).
/// Variante côté coach (jour abstrait) du `AssignedDatePill` côté élève
/// (date concrète).
class DayOfWeekPill extends StatelessWidget {
  const DayOfWeekPill({super.key, required this.dayOfWeek});

  final DayOfWeek dayOfWeek;

  @override
  Widget build(BuildContext context) {
    return MetaPill(icon: LucideIcons.calendar, label: dayOfWeek.frenchLabel);
  }
}

import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../core/models/student_session_exercise.dart';
import '../../theme/app_spacing.dart';
import 'meta_pill.dart';

/// Wrap horizontal de pills pour les paramètres d'un exercice : reps,
/// charge, intensité, repos. Chaque champ non vide devient un `MetaPill`.
///
/// Renvoie `SizedBox.shrink()` si aucun paramètre n'est renseigné — le
/// widget peut donc être inclus inconditionnellement par l'appelant.
/// Les appelants qui ont besoin de la même information pour conditionner
/// du spacing peuvent utiliser le helper [hasContent].
class ExerciseParamsRow extends StatelessWidget {
  const ExerciseParamsRow({super.key, required this.exercise});

  final StudentSessionExercise exercise;

  /// Indique si l'exercice contient au moins un paramètre à afficher.
  static bool hasContent(StudentSessionExercise exercise) {
    return (exercise.reps ?? '').trim().isNotEmpty ||
        (exercise.load ?? '').trim().isNotEmpty ||
        (exercise.intensity ?? '').trim().isNotEmpty ||
        (exercise.rest ?? '').trim().isNotEmpty;
  }

  @override
  Widget build(BuildContext context) {
    final params = <(IconData, String)>[
      if ((exercise.reps ?? '').trim().isNotEmpty)
        (LucideIcons.repeat, exercise.reps!.trim()),
      if ((exercise.load ?? '').trim().isNotEmpty)
        (LucideIcons.dumbbell, exercise.load!.trim()),
      if ((exercise.intensity ?? '').trim().isNotEmpty)
        (LucideIcons.flame, exercise.intensity!.trim()),
      if ((exercise.rest ?? '').trim().isNotEmpty)
        (LucideIcons.timer, exercise.rest!.trim()),
    ];
    if (params.isEmpty) return const SizedBox.shrink();
    return Wrap(
      spacing: AppSpacing.sm,
      runSpacing: AppSpacing.xs,
      children: [
        for (final (icon, value) in params)
          MetaPill(icon: icon, label: value),
      ],
    );
  }
}

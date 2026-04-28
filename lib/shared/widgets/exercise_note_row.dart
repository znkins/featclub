import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../theme/app_spacing.dart';

/// Ligne « note d'exercice » : icône orange + texte. Renvoie une boîte vide
/// si la note est vide — peut être inclus inconditionnellement.
class ExerciseNoteRow extends StatelessWidget {
  const ExerciseNoteRow({
    super.key,
    required this.note,
    this.maxLines,
  });

  final String note;

  /// Borne le texte (ellipsis) dans les contextes denses (éditeur coach).
  /// `null` (défaut) = plein affichage côté élève.
  final int? maxLines;

  @override
  Widget build(BuildContext context) {
    final trimmed = note.trim();
    if (trimmed.isEmpty) return const SizedBox.shrink();
    final theme = Theme.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Icon(
          LucideIcons.stickyNote,
          size: 16,
          color: theme.colorScheme.secondary,
        ),
        const SizedBox(width: AppSpacing.xs),
        Expanded(
          child: Text(
            trimmed,
            style: theme.textTheme.bodyMedium,
            maxLines: maxLines,
            overflow: maxLines == null ? null : TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}

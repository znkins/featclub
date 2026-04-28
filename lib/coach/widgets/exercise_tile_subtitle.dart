import 'package:flutter/material.dart';

import '../../theme/app_spacing.dart';
import 'category_chip.dart';

/// Sous-titre d'une tuile exercice : description + chip catégorie.
/// Renvoie une boîte vide si ni description ni catégorie — l'appelant
/// peut alors passer `null` pour ne réserver aucun espace.
class ExerciseTileSubtitle extends StatelessWidget {
  const ExerciseTileSubtitle({
    super.key,
    required this.description,
    required this.category,
  });

  final String? description;
  final String? category;

  bool get _hasDescription =>
      description != null && description!.trim().isNotEmpty;

  bool get _hasCategory => category != null && category!.trim().isNotEmpty;

  /// `true` si le widget aurait quelque chose à afficher.
  static bool hasContent({String? description, String? category}) {
    return (description != null && description.trim().isNotEmpty) ||
        (category != null && category.trim().isNotEmpty);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    if (!_hasDescription && !_hasCategory) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (_hasDescription) ...[
          Text(
            description!,
            style: theme.textTheme.bodyMedium,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          if (_hasCategory) const SizedBox(height: AppSpacing.xs),
        ],
        if (_hasCategory)
          Align(
            alignment: Alignment.centerLeft,
            child: CategoryChip(label: category!),
          ),
      ],
    );
  }
}

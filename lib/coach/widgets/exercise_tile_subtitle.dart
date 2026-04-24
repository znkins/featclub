import 'package:flutter/material.dart';

import '../../theme/app_spacing.dart';
import 'category_chip.dart';

/// Sous-titre d'une tuile exercice : description (onSurface) + chip catégorie.
///
/// Utilisé dans la liste des exercices de la biblio et dans les exercices
/// listés sous un bloc. Renvoie `SizedBox.shrink()` si ni description ni
/// catégorie — à l'appelant de passer `null` comme subtitleWidget dans ce cas
/// pour que la tuile ne réserve aucun espace sous le titre.
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

  /// Indique si le widget aurait du contenu à afficher — pratique pour décider
  /// de passer `null` à la place.
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

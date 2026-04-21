import 'package:flutter/material.dart';

import '../../theme/app_radius.dart';

/// Icône « type » (exercice/bloc/séance/programme) dans une pastille arrondie.
///
/// Fond primaire léger (alpha 0.1), icône en couleur primaire.
/// Taille fixe pour offrir un ancrage visuel homogène dans les listes.
class LibraryTypeIcon extends StatelessWidget {
  const LibraryTypeIcon({super.key, required this.icon});

  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: theme.colorScheme.primary.withValues(alpha: 0.1),
        borderRadius: AppRadius.mdAll,
      ),
      alignment: Alignment.center,
      child: Icon(
        icon,
        size: 20,
        color: theme.colorScheme.primary,
      ),
    );
  }
}

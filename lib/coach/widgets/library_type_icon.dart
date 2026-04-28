import 'package:flutter/material.dart';

import '../../theme/app_radius.dart';

/// Pastille « icône type » (exercice/bloc/séance/programme) — fond primaire
/// léger, taille fixe, ancrage visuel homogène pour les listes.
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

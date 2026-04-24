import 'package:flutter/material.dart';

import '../../theme/app_radius.dart';
import '../../theme/app_spacing.dart';

/// Tuile regroupant plusieurs [DetailField] (ou équivalents) dans une carte
/// bordée avec séparateurs internes.
///
/// Pattern réutilisé sur les écrans de détail (exercice, bloc, séance,
/// programme) pour distinguer visuellement le bloc "infos" du bloc
/// "liste d'enfants" (exercices, blocs, séances).
class DetailInfoCard extends StatelessWidget {
  const DetailInfoCard({super.key, required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: AppRadius.lgAll,
        border: Border.all(color: theme.colorScheme.outline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (var i = 0; i < children.length; i++) ...[
            if (i > 0)
              Divider(
                height: AppSpacing.xl,
                color: theme.colorScheme.outline,
              ),
            children[i],
          ],
        ],
      ),
    );
  }
}

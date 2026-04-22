import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../core/models/weight_measure.dart';
import '../../core/utils/formatters.dart';
import '../../theme/app_radius.dart';
import '../../theme/app_spacing.dart';

/// Ligne d'une mesure de poids : pastille icône + poids + date.
///
/// Réutilisée côté coach (fiche élève + sheet "Toutes les mesures") et côté
/// élève (onglet progression).
class WeightMeasureRow extends StatelessWidget {
  const WeightMeasureRow({super.key, required this.measure});

  final WeightMeasure measure;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.md,
      ),
      decoration: BoxDecoration(
        borderRadius: AppRadius.lgAll,
        border: Border.all(color: theme.colorScheme.outline),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withValues(alpha: 0.1),
              borderRadius: AppRadius.mdAll,
            ),
            alignment: Alignment.center,
            child: Icon(
              LucideIcons.scale,
              size: 20,
              color: theme.colorScheme.primary,
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Text(
              formatWeightKg(measure.valueKg),
              style: theme.textTheme.titleMedium,
            ),
          ),
          Text(
            formatDate(measure.measuredAt),
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

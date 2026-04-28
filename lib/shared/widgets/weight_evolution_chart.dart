import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../core/models/weight_measure.dart';
import '../../core/utils/formatters.dart';
import '../../theme/app_radius.dart';
import '../../theme/app_spacing.dart';

/// Graphique d'évolution du poids partagé coach (fiche élève) et élève
/// (onglet Progression).
///
/// Affiche au moins 2 mesures. Trié chronologiquement ; tiebreaker sur
/// `createdAt` quand plusieurs mesures partagent la même date.
/// Indicateur de touch en couleur secondaire (orange) pour rester cohérent
/// avec les dots oranges du graphique.
class WeightEvolutionChart extends StatelessWidget {
  const WeightEvolutionChart({super.key, required this.measures});

  final List<WeightMeasure> measures;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final sorted = [...measures]
      ..sort((a, b) {
        final byDate = a.measuredAt.compareTo(b.measuredAt);
        if (byDate != 0) return byDate;
        return a.createdAt.compareTo(b.createdAt);
      });
    final spots = <FlSpot>[
      for (var i = 0; i < sorted.length; i++)
        FlSpot(i.toDouble(), sorted[i].valueKg),
    ];
    final values = sorted.map((m) => m.valueKg).toList();
    final minY = values.reduce((a, b) => a < b ? a : b);
    final maxY = values.reduce((a, b) => a > b ? a : b);
    final pad = (maxY - minY) < 1 ? 1.0 : (maxY - minY) * 0.2;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        borderRadius: AppRadius.lgAll,
        border: Border.all(color: theme.colorScheme.outline),
      ),
      child: SizedBox(
        height: 160,
        child: LineChart(
          LineChartData(
            minY: minY - pad,
            maxY: maxY + pad,
            gridData: const FlGridData(show: false),
            titlesData: const FlTitlesData(show: false),
            borderData: FlBorderData(show: false),
            lineTouchData: LineTouchData(
              touchTooltipData: LineTouchTooltipData(
                getTooltipColor: (_) => theme.colorScheme.inverseSurface,
                getTooltipItems: (touched) => touched.map((t) {
                  final m = sorted[t.spotIndex];
                  return LineTooltipItem(
                    '${formatDateShort(m.measuredAt)}\n${formatWeightKg(m.valueKg)}',
                    theme.textTheme.bodySmall!.copyWith(
                      color: theme.colorScheme.onInverseSurface,
                    ),
                  );
                }).toList(),
              ),
              getTouchedSpotIndicator: (barData, spotIndexes) {
                return spotIndexes
                    .map(
                      (_) => TouchedSpotIndicatorData(
                        FlLine(
                          color: theme.colorScheme.secondary,
                          strokeWidth: 2,
                        ),
                        FlDotData(
                          show: true,
                          getDotPainter: (_, _, _, _) => FlDotCirclePainter(
                            radius: 5,
                            color: theme.colorScheme.secondary,
                            strokeWidth: 0,
                          ),
                        ),
                      ),
                    )
                    .toList();
              },
            ),
            lineBarsData: [
              LineChartBarData(
                spots: spots,
                isCurved: true,
                curveSmoothness: 0.2,
                barWidth: 2.5,
                color: theme.colorScheme.primary,
                dotData: FlDotData(
                  show: true,
                  getDotPainter: (_, _, _, _) => FlDotCirclePainter(
                    radius: 4.5,
                    color: theme.colorScheme.secondary,
                    strokeWidth: 0,
                  ),
                ),
                belowBarData: BarAreaData(
                  show: true,
                  color: theme.colorScheme.primary.withValues(alpha: 0.1),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

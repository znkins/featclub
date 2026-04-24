import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../theme/app_spacing.dart';

/// Wordmark Featclub : logo à gauche, « FEATCLUB » en Contrail One couleur
/// primaire et baseline « back to basics » en Contrail One couleur secondaire
/// alignée sous le F de FEATCLUB.
///
/// Le logo occupe la hauteur complète du bloc texte (titre + gap + baseline)
/// pour un alignement vertical propre sans déformer le fichier source.
class FeatclubWordmark extends StatelessWidget {
  const FeatclubWordmark({
    super.key,
    this.titleFontSize = 52,
    this.baselineFontSize = 24,
    this.lineGap = 2,
  });

  final double titleFontSize;
  final double baselineFontSize;

  /// Espace vertical entre « FEATCLUB » et « back to basics ».
  final double lineGap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final blockHeight = titleFontSize + lineGap + baselineFontSize;
    // Le PNG du logo a un léger padding transparent à gauche qui pousse
    // visuellement le contenu vers la droite quand le Row est centré.
    // On compense par un petit shift optique à gauche.
    return Transform.translate(
      offset: const Offset(-5, 0),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Image.asset(
            'assets/images/featclub_logo.png',
            height: blockHeight,
            fit: BoxFit.contain,
          ),
          const SizedBox(width: AppSpacing.sm),
          Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'FEATCLUB',
                style: GoogleFonts.contrailOne(
                  fontSize: titleFontSize,
                  color: theme.colorScheme.primary,
                  height: 1,
                ),
              ),
              SizedBox(height: lineGap),
              Text(
                'back to basics',
                style: GoogleFonts.contrailOne(
                  fontSize: baselineFontSize,
                  color: theme.colorScheme.secondary,
                  height: 1,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

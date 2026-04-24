import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../theme/app_spacing.dart';

/// Wordmark Featclub : logo à gauche, « FEATCLUB » en Contrail One couleur
/// primaire et baseline « back to basics » en Contrail One couleur secondaire
/// alignée sous le F de FEATCLUB.
///
/// Le logo occupe la hauteur complète du bloc texte pour un alignement
/// vertical propre sans déformer le fichier source. `showBaseline: false`
/// donne une variante compacte (logo + « FEATCLUB » uniquement) utilisable
/// dans une AppBar, où la baseline serait illisible.
class FeatclubWordmark extends StatelessWidget {
  const FeatclubWordmark({
    super.key,
    this.titleFontSize = 52,
    this.baselineFontSize = 24,
    this.lineGap = 2,
    this.showBaseline = true,
    this.logoHeight,
  });

  final double titleFontSize;
  final double baselineFontSize;

  /// Espace vertical entre « FEATCLUB » et « back to basics ».
  final double lineGap;

  /// Affiche la baseline « back to basics ». Désactiver pour les contextes
  /// compacts (AppBar) où la baseline n'aurait pas une taille lisible.
  final bool showBaseline;

  /// Override la hauteur du logo. Par défaut suit la hauteur du bloc texte
  /// (titre + éventuelle baseline) — approprié pour le grand wordmark de
  /// l'auth. En variante compacte sans baseline, le logo paraît trop grand
  /// par rapport à la cap-height réelle du Contrail One : fournir une
  /// valeur explicite permet de calibrer visuellement.
  final double? logoHeight;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final blockHeight = showBaseline
        ? titleFontSize + lineGap + baselineFontSize
        : titleFontSize;
    final imageHeight = logoHeight ?? blockHeight;
    // Contrail One a une cap-height ~72% de l'em-box : le centre visuel du
    // texte est plus haut que le centre de la box. En mode compact (sans
    // baseline) où logo et texte ont ~même hauteur, on relève le logo pour
    // recoller son centre à celui des glyphes. En mode auth (avec baseline),
    // le bloc texte inclut déjà la baseline sous la ligne de base, donc
    // pas d'offset à appliquer.
    final logoVerticalOffset = showBaseline ? 0.0 : -titleFontSize * 0.12;
    // Le PNG du logo a un léger padding transparent à gauche qui pousse
    // visuellement le contenu vers la droite. Compensation optique.
    const horizontalOpticalShift = -5.0;
    final gap = showBaseline ? AppSpacing.sm : AppSpacing.xs;
    return Transform.translate(
      offset: const Offset(horizontalOpticalShift, 0),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Transform.translate(
            offset: Offset(0, logoVerticalOffset),
            child: Image.asset(
              'assets/images/featclub_logo.png',
              height: imageHeight,
              fit: BoxFit.contain,
            ),
          ),
          SizedBox(width: gap),
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
              if (showBaseline) ...[
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
            ],
          ),
        ],
      ),
    );
  }
}

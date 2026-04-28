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
///
/// `animate: true` joue une séquence d'entrée premium : le logo apparaît en
/// fade+scale, puis chaque lettre de « FEATCLUB » fait un stagger fade+slide,
/// puis la baseline fade-in. Sobre, joué une seule fois au mount du widget.
class FeatclubWordmark extends StatefulWidget {
  const FeatclubWordmark({
    super.key,
    this.titleFontSize = 52,
    this.baselineFontSize = 24,
    this.lineGap = 2,
    this.showBaseline = true,
    this.logoHeight,
    this.animate = false,
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

  /// Joue l'animation d'entrée séquencée une seule fois au mount.
  final bool animate;

  @override
  State<FeatclubWordmark> createState() => _FeatclubWordmarkState();
}

class _FeatclubWordmarkState extends State<FeatclubWordmark>
    with SingleTickerProviderStateMixin {
  static const _word = 'FEATCLUB';
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    );
    if (widget.animate) {
      _controller.forward();
    } else {
      _controller.value = 1.0;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Animation<double> _interval(double start, double end) {
    return CurvedAnimation(
      parent: _controller,
      curve: Interval(start, end, curve: Curves.easeOutCubic),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final blockHeight = widget.showBaseline
        ? widget.titleFontSize + widget.lineGap + widget.baselineFontSize
        : widget.titleFontSize;
    final imageHeight = widget.logoHeight ?? blockHeight;
    // Contrail One a une cap-height ~72% de l'em-box : le centre visuel du
    // texte est plus haut que le centre de la box. En mode compact (sans
    // baseline) où logo et texte ont ~même hauteur, on relève le logo pour
    // recoller son centre à celui des glyphes. En mode auth (avec baseline),
    // le bloc texte inclut déjà la baseline sous la ligne de base, donc
    // pas d'offset à appliquer.
    final logoVerticalOffset =
        widget.showBaseline ? 0.0 : -widget.titleFontSize * 0.12;
    // Le PNG du logo a un léger padding transparent à gauche qui pousse
    // visuellement le contenu vers la droite. Compensation optique.
    const horizontalOpticalShift = -5.0;
    final gap = widget.showBaseline ? AppSpacing.sm : AppSpacing.xs;

    final logoAnim = _interval(0.0, 0.45);
    final baselineAnim = _interval(0.65, 1.0);
    final letterDuration = 0.32;
    final letterStagger = 0.05;

    final titleStyle = GoogleFonts.contrailOne(
      fontSize: widget.titleFontSize,
      color: theme.colorScheme.primary,
      height: 1,
    );

    return Transform.translate(
      offset: const Offset(horizontalOpticalShift, 0),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          AnimatedBuilder(
            animation: logoAnim,
            builder: (_, child) {
              final t = logoAnim.value;
              return Opacity(
                opacity: t,
                child: Transform.scale(
                  scale: 0.85 + 0.15 * t,
                  child: child,
                ),
              );
            },
            child: Transform.translate(
              offset: Offset(0, logoVerticalOffset),
              child: Image.asset(
                'assets/images/featclub_logo.png',
                height: imageHeight,
                fit: BoxFit.contain,
              ),
            ),
          ),
          SizedBox(width: gap),
          Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: List.generate(_word.length, (i) {
                  final start = 0.18 + i * letterStagger;
                  final end = (start + letterDuration).clamp(0.0, 1.0);
                  final anim = _interval(start, end);
                  return AnimatedBuilder(
                    animation: anim,
                    builder: (_, child) {
                      final t = anim.value;
                      return Opacity(
                        opacity: t,
                        child: Transform.translate(
                          offset: Offset(0, (1 - t) * 8),
                          child: child,
                        ),
                      );
                    },
                    child: Text(_word[i], style: titleStyle),
                  );
                }),
              ),
              if (widget.showBaseline) ...[
                SizedBox(height: widget.lineGap),
                AnimatedBuilder(
                  animation: baselineAnim,
                  builder: (_, child) =>
                      Opacity(opacity: baselineAnim.value, child: child),
                  child: Text(
                    'back to basics',
                    style: GoogleFonts.contrailOne(
                      fontSize: widget.baselineFontSize,
                      color: theme.colorScheme.secondary,
                      height: 1,
                    ),
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

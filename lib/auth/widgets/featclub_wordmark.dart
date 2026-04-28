import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../theme/app_spacing.dart';

/// Wordmark Featclub : logo + « FEATCLUB » en Contrail One, baseline
/// optionnelle « back to basics ».
///
/// `animate: true` joue une séquence d'entrée (logo en fade+scale, lettres
/// en stagger, baseline en fade) une seule fois au mount du widget.
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
  final double lineGap;

  /// `false` pour la version compacte (AppBar) sans baseline.
  final bool showBaseline;

  /// Override de la hauteur du logo. Utile en variante compacte où le
  /// défaut (suit la hauteur du bloc texte) paraît trop grand.
  final double? logoHeight;

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
    // Contrail One a une cap-height ~72% de l'em-box : en mode compact on
    // relève le logo pour recoller son centre à celui des glyphes.
    final logoVerticalOffset =
        widget.showBaseline ? 0.0 : -widget.titleFontSize * 0.12;
    // Compense le padding transparent à gauche du PNG du logo.
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

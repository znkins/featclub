import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Construit le [TextTheme] Featclub à partir de League Spartan.
///
/// Les valeurs suivent design_rules.md :
///  - Display : 32 / 700 / 1.2
///  - H1       : 22 / 600 / 1.3
///  - H2       : 18 / 600 / 1.4
///  - Body     : 16 / 400 / 1.5
///  - Caption  : 14 / 500 / 1.4
class AppTypography {
  AppTypography._();

  static TextTheme buildTextTheme(Color textColor) {
    final base = GoogleFonts.leagueSpartanTextTheme();

    final display = base.displayMedium?.copyWith(
      fontSize: 32,
      fontWeight: FontWeight.w700,
      height: 1.2,
      color: textColor,
    );
    final h1 = base.headlineSmall?.copyWith(
      fontSize: 22,
      fontWeight: FontWeight.w600,
      height: 1.3,
      color: textColor,
    );
    final h2 = base.titleLarge?.copyWith(
      fontSize: 18,
      fontWeight: FontWeight.w600,
      height: 1.4,
      color: textColor,
    );
    final body = base.bodyLarge?.copyWith(
      fontSize: 16,
      fontWeight: FontWeight.w400,
      height: 1.5,
      color: textColor,
    );
    final caption = base.bodyMedium?.copyWith(
      fontSize: 14,
      fontWeight: FontWeight.w500,
      height: 1.4,
      color: textColor,
    );

    return base.copyWith(
      displayLarge: display,
      displayMedium: display,
      displaySmall: display,
      headlineLarge: h1,
      headlineMedium: h1,
      headlineSmall: h1,
      titleLarge: h2,
      titleMedium: h2,
      titleSmall: h2,
      bodyLarge: body,
      bodyMedium: body,
      bodySmall: caption,
      labelLarge: caption,
      labelMedium: caption,
      labelSmall: caption,
    );
  }
}

import 'package:flutter/material.dart';

/// Palette de marque Featclub (cf. design_rules.md).
///
/// Ces constantes servent de source unique pour construire les [ColorScheme]
/// du thème. Elles ne doivent pas être référencées directement dans les
/// widgets : passer toujours par `Theme.of(context).colorScheme`.
class AppColors {
  AppColors._();

  // Couleurs de marque (identiques en light et dark).
  static const Color brandPrimary = Color(0xFF1F7D6C);
  static const Color brandSecondary = Color(0xFFFC5C00);

  // Couleurs sémantiques (identiques en light et dark).
  static const Color success = Color(0xFF10B981);
  static const Color error = Color(0xFFEF4444);
  static const Color warning = Color(0xFFF59E0B);

  // Light mode.
  static const Color lightBackground = Color(0xFFF7F8FA);
  static const Color lightSurface = Color(0xFFFFFFFF);
  static const Color lightTextPrimary = Color(0xFF1A1A2E);
  static const Color lightTextSecondary = Color(0xFF6B7280);
  static const Color lightSeparator = Color(0xFFE5E7EB);

  // Dark mode.
  static const Color darkBackground = Color(0xFF0F1117);
  static const Color darkSurface = Color(0xFF1A1D28);
  static const Color darkTextPrimary = Color(0xFFF1F1F3);
  static const Color darkTextSecondary = Color(0xFF9CA3AF);
  static const Color darkSeparator = Color(0xFF2D3140);
}

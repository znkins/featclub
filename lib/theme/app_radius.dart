import 'package:flutter/material.dart';

/// Rayons standards de l'application.
class AppRadius {
  AppRadius._();

  static const double sm = 8; // inputs, petits éléments
  static const double md = 12; // boutons, snackbars
  static const double lg = 16; // cartes, modales, bottom sheets
  static const double full = 999; // badges, chips, avatars, pills

  static const BorderRadius smAll = BorderRadius.all(Radius.circular(sm));
  static const BorderRadius mdAll = BorderRadius.all(Radius.circular(md));
  static const BorderRadius lgAll = BorderRadius.all(Radius.circular(lg));
  static const BorderRadius fullAll = BorderRadius.all(Radius.circular(full));
}

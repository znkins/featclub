// Validateurs réutilisés par les formulaires d'authentification.

import 'package:flutter/widgets.dart';

class AuthValidators {
  AuthValidators._();

  static final RegExp _emailRegex =
      RegExp(r'^[\w\-.+]+@([\w-]+\.)+[\w-]{2,}$');

  static String? email(String? value) {
    final v = value?.trim() ?? '';
    if (v.isEmpty) return 'Email requis';
    if (!_emailRegex.hasMatch(v)) return 'Email invalide';
    return null;
  }

  static String? password(String? value) {
    final v = value ?? '';
    if (v.isEmpty) return 'Mot de passe requis';
    if (v.length < 6) return 'Mot de passe trop court (6 caractères min)';
    return null;
  }

  /// Validateur dynamique : compare le champ courant à la valeur de [source].
  static String? Function(String?) confirmPassword(
      TextEditingController source) {
    return (value) {
      if (value != source.text) return 'Les mots de passe ne correspondent pas';
      return null;
    };
  }

  static String? required(String? value, {String label = 'Champ'}) {
    if ((value ?? '').trim().isEmpty) return '$label requis';
    return null;
  }
}

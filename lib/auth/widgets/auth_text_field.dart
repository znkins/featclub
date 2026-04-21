import 'package:flutter/material.dart';

import '../../theme/app_spacing.dart';

/// Champ texte standardisé pour les formulaires d'authentification.
class AuthTextField extends StatelessWidget {
  const AuthTextField({
    super.key,
    required this.controller,
    required this.label,
    this.hintText,
    this.keyboardType,
    this.obscureText = false,
    this.textInputAction = TextInputAction.next,
    this.autofillHints,
    this.validator,
    this.onFieldSubmitted,
    this.enabled = true,
  });

  final TextEditingController controller;
  final String label;
  final String? hintText;
  final TextInputType? keyboardType;
  final bool obscureText;
  final TextInputAction textInputAction;
  final Iterable<String>? autofillHints;
  final String? Function(String?)? validator;
  final void Function(String)? onFieldSubmitted;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: theme.textTheme.labelLarge),
        const SizedBox(height: AppSpacing.sm),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          obscureText: obscureText,
          textInputAction: textInputAction,
          autofillHints: autofillHints,
          validator: validator,
          onFieldSubmitted: onFieldSubmitted,
          enabled: enabled,
          decoration: InputDecoration(hintText: hintText),
        ),
      ],
    );
  }
}

import 'package:flutter/material.dart';

/// Lien « Voir plus » centré sous une liste partielle.
/// Ouvre généralement un bottom sheet avec la liste complète.
class SeeMoreLink extends StatelessWidget {
  const SeeMoreLink({super.key, required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.center,
      child: TextButton(
        onPressed: onTap,
        child: const Text('Voir plus'),
      ),
    );
  }
}

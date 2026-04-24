import 'package:flutter/material.dart';

/// Lien « Voir plus » centré, placé sous une liste partielle qui ouvre
/// généralement un bottom sheet avec la liste complète.
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

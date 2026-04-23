import 'package:flutter/widgets.dart';
import 'package:url_launcher/url_launcher.dart';

import '../widgets/app_snackbar.dart';

/// Ouvre une URL vidéo dans l'application externe par défaut.
///
/// Affiche un snackbar d'erreur si l'URL est invalide ou si aucune app ne
/// peut la gérer.
Future<void> openVideoUrl(BuildContext context, String url) async {
  final uri = Uri.tryParse(url);
  if (uri == null) {
    if (!context.mounted) return;
    AppSnackbar.showError(context, 'URL invalide');
    return;
  }
  final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
  if (!ok && context.mounted) {
    AppSnackbar.showError(context, 'Impossible d\'ouvrir la vidéo');
  }
}

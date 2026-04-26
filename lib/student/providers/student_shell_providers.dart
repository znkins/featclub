import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Index de l'onglet actif dans le shell élève.
///
/// 0 = Accueil, 1 = Mon programme, 2 = Progression, 3 = Profil.
///
/// Exposé en provider plutôt qu'en state local du shell pour permettre à
/// des écrans poussés (détail/exécution séance) de revenir sur un onglet
/// précis après une action — typiquement après complétion d'une séance,
/// on `popUntil` la racine + on bascule sur l'onglet « Mon programme ».
final studentActiveTabProvider = StateProvider<int>((ref) => 0);

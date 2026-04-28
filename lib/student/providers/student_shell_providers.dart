import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Index de l'onglet actif dans le shell élève.
/// 0 = Accueil, 1 = Programme, 2 = Progression, 3 = Profil.
///
/// Exposé en provider plutôt qu'en state local du shell pour permettre
/// à un écran poussé (ex. après complétion d'une séance) de basculer
/// sur un onglet précis avant de pop la pile.
final studentActiveTabProvider = StateProvider<int>((ref) => 0);

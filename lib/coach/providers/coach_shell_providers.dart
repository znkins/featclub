import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Index de l'onglet actif dans le shell coach.
///
/// 0 = Accueil, 1 = Featers, 2 = Contenu, 3 = Profil.
///
/// Exposé en provider plutôt qu'en state local du shell pour permettre à
/// l'accueil (raccourci Featers) ou à des écrans poussés de basculer sur
/// un onglet précis sans passer par un GoRouter parent — même pattern que
/// `studentActiveTabProvider`.
final coachActiveTabProvider = StateProvider<int>((ref) => 0);

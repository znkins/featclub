import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Index de l'onglet actif dans le shell coach.
/// 0 = Activité, 1 = Featers, 2 = Contenu, 3 = Profil.
///
/// Exposé en provider plutôt qu'en state local du shell pour permettre
/// à l'accueil ou à des écrans poussés de basculer d'onglet sans router.
final coachActiveTabProvider = StateProvider<int>((ref) => 0);

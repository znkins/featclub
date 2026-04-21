import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'supabase_providers.dart';

/// Stream de l'état d'authentification Supabase.
///
/// Émet à chaque évènement (connexion, déconnexion, refresh, etc.).
final authStateChangesProvider = StreamProvider<AuthState>((ref) {
  return ref.watch(authServiceProvider).onAuthStateChange;
});

/// Session courante exposée comme valeur synchrone.
///
/// Recalculée à chaque évènement du stream Supabase.
final currentSessionProvider = Provider<Session?>((ref) {
  ref.watch(authStateChangesProvider);
  return ref.watch(supabaseClientProvider).auth.currentSession;
});

/// Indique simplement si un utilisateur est authentifié.
final isAuthenticatedProvider = Provider<bool>((ref) {
  return ref.watch(currentSessionProvider) != null;
});

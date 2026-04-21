import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/models/profile.dart';
import 'auth_provider.dart';
import 'supabase_providers.dart';

/// Profil applicatif de l'utilisateur courant.
///
/// Renvoie `null` si personne n'est connecté ou si le profil n'existe pas
/// encore (cas extrême : trigger Supabase pas encore déclenché).
final currentProfileProvider = FutureProvider<Profile?>((ref) async {
  final session = ref.watch(currentSessionProvider);
  if (session == null) return null;
  final service = ref.watch(profileServiceProvider);
  return service.fetchById(session.user.id);
});

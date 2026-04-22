import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/models/profile.dart';
import '../../shared/providers/supabase_providers.dart';

/// Liste des élèves actifs visibles par le coach.
///
/// Tri client-side : profils complétés en premier (première clé `isComplete`),
/// puis alphabétique par nom complet — cohérent avec la règle métier
/// "profil complété > non complété" (parcours 5.2).
final coachStudentsProvider = FutureProvider<List<Profile>>((ref) async {
  final service = ref.watch(profileServiceProvider);
  final all = await service.listActiveStudents();
  final sorted = [...all]..sort((a, b) {
    if (a.isComplete != b.isComplete) {
      return a.isComplete ? -1 : 1;
    }
    return a.fullName.toLowerCase().compareTo(b.fullName.toLowerCase());
  });
  return sorted;
});

/// Profil d'un élève par son id (utilisé par la fiche élève côté coach).
final studentByIdProvider =
    FutureProvider.family<Profile?, String>((ref, id) async {
  return ref.watch(profileServiceProvider).fetchById(id);
});

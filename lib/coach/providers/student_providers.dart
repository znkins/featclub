import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/models/profile.dart';
import '../../shared/providers/supabase_providers.dart';

/// Élèves actifs visibles par le coach.
/// Tri côté client : profils complétés d'abord, puis alphabétique
/// (règle métier "profil complété > non complété", parcours 5.2).
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

/// Profil d'un élève par son id (fiche élève coach).
final studentByIdProvider =
    FutureProvider.family<Profile?, String>((ref, id) async {
  return ref.watch(profileServiceProvider).fetchById(id);
});

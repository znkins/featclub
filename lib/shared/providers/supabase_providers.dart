import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/services/auth_service.dart';
import '../../core/services/profile_service.dart';
import '../../core/services/storage_service.dart';

/// Client Supabase global.
///
/// Construit à partir de l'instance singleton initialisée dans `main.dart`.
final supabaseClientProvider = Provider<SupabaseClient>((ref) {
  return Supabase.instance.client;
});

final authServiceProvider = Provider<AuthService>((ref) {
  return AuthService(ref.watch(supabaseClientProvider));
});

final profileServiceProvider = Provider<ProfileService>((ref) {
  return ProfileService(ref.watch(supabaseClientProvider));
});

final storageServiceProvider = Provider<StorageService>((ref) {
  return StorageService(ref.watch(supabaseClientProvider));
});

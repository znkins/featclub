/// Configuration de la connexion Supabase (URL projet + clé publique).
class SupabaseConfig {
  SupabaseConfig._();

  static const String url = 'https://kwsnsqcuirbbrlczysdo.supabase.co';
  static const String anonKey = 'sb_publishable_wD5O05aga3u3J9fqbH2n3A__Q-klAjZ';

  /// Bucket de stockage des avatars (créé manuellement côté Supabase).
  static const String avatarsBucket = 'avatars';
}

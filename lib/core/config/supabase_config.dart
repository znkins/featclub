/// Configuration de la connexion Supabase.
///
/// Les valeurs proviennent du projet Supabase Featclub. La clé fournie
/// est la clé `publishable` (anon), donc utilisable côté client mobile.
class SupabaseConfig {
  SupabaseConfig._();

  static const String url = 'https://kwsnsqcuirbbrlczysdo.supabase.co';
  static const String anonKey = 'sb_publishable_wD5O05aga3u3J9fqbH2n3A__Q-klAjZ';

  /// Nom du bucket de stockage des avatars (créé manuellement dans Supabase).
  static const String avatarsBucket = 'avatars';
}

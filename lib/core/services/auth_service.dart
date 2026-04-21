import 'package:supabase_flutter/supabase_flutter.dart';

/// Encapsule les appels d'authentification Supabase.
class AuthService {
  AuthService(this._client);

  final SupabaseClient _client;

  Session? get currentSession => _client.auth.currentSession;
  User? get currentUser => _client.auth.currentUser;

  Stream<AuthState> get onAuthStateChange => _client.auth.onAuthStateChange;

  /// Crée un compte Supabase. Le profil applicatif est créé automatiquement
  /// par le trigger DB `handle_new_user`.
  ///
  /// La confirmation d'email étant requise, Supabase ne renvoie pas de session
  /// à l'inscription : on force un `signOut` au cas où, pour partir d'un état
  /// propre côté client.
  Future<void> signUp({
    required String email,
    required String password,
  }) async {
    await _client.auth.signUp(email: email, password: password);
    if (_client.auth.currentSession != null) {
      await _client.auth.signOut();
    }
  }

  /// Connexion par email / mot de passe.
  ///
  /// Lève [AuthException] si l'email n'est pas confirmé ou si les
  /// identifiants sont invalides.
  Future<AuthResponse> signIn({
    required String email,
    required String password,
  }) {
    return _client.auth.signInWithPassword(email: email, password: password);
  }

  Future<void> signOut() => _client.auth.signOut();

  Future<void> sendPasswordReset(String email) {
    return _client.auth.resetPasswordForEmail(email);
  }
}

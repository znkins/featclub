import 'package:supabase_flutter/supabase_flutter.dart';

/// Encapsule les appels d'authentification Supabase.
class AuthService {
  AuthService(this._client);

  final SupabaseClient _client;

  Session? get currentSession => _client.auth.currentSession;
  User? get currentUser => _client.auth.currentUser;

  Stream<AuthState> get onAuthStateChange => _client.auth.onAuthStateChange;

  /// Crée un compte. Le profil applicatif est créé par le trigger DB
  /// `handle_new_user`. La confirmation d'email étant requise, on force
  /// un signOut pour partir d'un état propre côté client.
  Future<void> signUp({
    required String email,
    required String password,
  }) async {
    await _client.auth.signUp(email: email, password: password);
    if (_client.auth.currentSession != null) {
      await _client.auth.signOut();
    }
  }

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

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'admin/screens/admin_home_screen.dart';
import 'auth/screens/forgot_password_screen.dart';
import 'auth/screens/login_screen.dart';
import 'auth/screens/signup_screen.dart';
import 'coach/screens/coach_shell.dart';
import 'core/utils/user_role.dart';
import 'core/widgets/loading_indicator.dart';
import 'shared/providers/auth_provider.dart';
import 'shared/providers/current_profile_provider.dart';
import 'shared/providers/route_observer_provider.dart';
import 'shared/providers/supabase_providers.dart';
import 'student/screens/student_shell.dart';

/// Routes publiques accessibles sans session.
const _publicRoutes = {'/login', '/signup', '/forgot-password'};

/// Router applicatif avec redirection par rôle.
///
/// Règles :
///  - non connecté : seules `/login`, `/signup`, `/forgot-password` sont
///    accessibles ; tout le reste renvoie vers `/login`.
///  - connecté + statut `disabled` : déconnexion + retour `/login`.
///  - connecté actif : redirigé vers l'espace correspondant à son rôle
///    (`/student`, `/coach`, `/admin`).
final routerProvider = Provider<GoRouter>((ref) {
  final refreshNotifier = _AuthRefreshNotifier(ref);
  ref.onDispose(refreshNotifier.dispose);

  return GoRouter(
    initialLocation: '/login',
    refreshListenable: refreshNotifier,
    observers: [ref.read(appRouteObserverProvider)],
    redirect: (context, state) => _handleRedirect(ref, state),
    routes: [
      GoRoute(
        path: '/login',
        builder: (_, _) => const LoginScreen(),
      ),
      GoRoute(
        path: '/signup',
        builder: (_, _) => const SignupScreen(),
      ),
      GoRoute(
        path: '/forgot-password',
        builder: (_, _) => const ForgotPasswordScreen(),
      ),
      GoRoute(
        path: '/student',
        builder: (_, _) => const StudentShell(),
      ),
      GoRoute(
        path: '/coach',
        builder: (_, _) => const CoachShell(),
      ),
      GoRoute(
        path: '/admin',
        builder: (_, _) => const AdminHomeScreen(),
      ),
      GoRoute(
        path: '/loading',
        builder: (_, _) => const Scaffold(body: LoadingIndicator()),
      ),
    ],
  );
});

String? _handleRedirect(Ref ref, GoRouterState state) {
  final session = ref.read(currentSessionProvider);
  final location = state.matchedLocation;

  // Pas de session : seules les routes publiques (login/signup/forgot) sont
  // accessibles.
  if (session == null) {
    return _publicRoutes.contains(location) ? null : '/login';
  }

  // Session présente : on a besoin du profil pour connaître le rôle.
  final profileAsync = ref.read(currentProfileProvider);

  return profileAsync.when(
    loading: () => location == '/loading' ? null : '/loading',
    error: (_, _) => '/login',
    data: (profile) {
      if (profile == null) return '/login';

      // Statut désactivé : déconnexion forcée.
      if (profile.status == AccessStatus.disabled) {
        ref.read(supabaseClientProvider).auth.signOut();
        return '/login';
      }

      final destination = _routeForRole(profile.role);

      // Sur une route publique ou /loading : on bascule vers la home du rôle.
      if (_publicRoutes.contains(location) || location == '/loading') {
        return destination;
      }

      // Garde-fou : un rôle ne peut pas accéder à un espace d'un autre rôle.
      if (location.startsWith('/student') && profile.role != UserRole.eleve) {
        return destination;
      }
      if (location.startsWith('/coach') && profile.role != UserRole.coach) {
        return destination;
      }
      if (location.startsWith('/admin') && profile.role != UserRole.admin) {
        return destination;
      }

      return null;
    },
  );
}

String _routeForRole(UserRole role) {
  switch (role) {
    case UserRole.eleve:
      return '/student';
    case UserRole.coach:
      return '/coach';
    case UserRole.admin:
      return '/admin';
  }
}

/// Petit pont entre Riverpod et go_router : déclenche un refresh du router
/// dès qu'un évènement Supabase modifie la session ou que le profil change.
class _AuthRefreshNotifier extends ChangeNotifier {
  _AuthRefreshNotifier(this._ref) {
    _sessionSub = _ref.listen<dynamic>(
      authStateChangesProvider,
      (_, _) => notifyListeners(),
    );
    _profileSub = _ref.listen<dynamic>(
      currentProfileProvider,
      (_, _) => notifyListeners(),
    );
  }

  final Ref _ref;
  late final ProviderSubscription<dynamic> _sessionSub;
  late final ProviderSubscription<dynamic> _profileSub;

  @override
  void dispose() {
    _sessionSub.close();
    _profileSub.close();
    super.dispose();
  }
}

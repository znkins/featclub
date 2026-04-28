// Routeur applicatif (go_router) avec redirection par rôle.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'admin/screens/admin_home_screen.dart';
import 'auth/screens/forgot_password_screen.dart';
import 'auth/screens/login_screen.dart';
import 'auth/screens/signup_screen.dart';
import 'coach/screens/coach_shell.dart';
import 'core/utils/user_role.dart';
import 'core/widgets/app_boot_splash.dart';
import 'shared/providers/auth_provider.dart';
import 'shared/providers/current_profile_provider.dart';
import 'shared/providers/route_observer_provider.dart';
import 'shared/providers/supabase_providers.dart';
import 'student/screens/student_shell.dart';

const _publicRoutes = {'/login', '/signup', '/forgot-password'};

/// Provider du `GoRouter` global.
///
/// Règles de redirection :
/// - sans session : seules les routes publiques sont accessibles ;
/// - statut `disabled` : déconnexion forcée ;
/// - sinon : on est envoyé sur l'espace correspondant au rôle.
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
        builder: (_, _) => const AppBootSplash(),
      ),
    ],
  );
});

String? _handleRedirect(Ref ref, GoRouterState state) {
  final session = ref.read(currentSessionProvider);
  final location = state.matchedLocation;

  if (session == null) {
    return _publicRoutes.contains(location) ? null : '/login';
  }

  final profileAsync = ref.read(currentProfileProvider);

  return profileAsync.when(
    loading: () => location == '/loading' ? null : '/loading',
    error: (_, _) => '/login',
    data: (profile) {
      if (profile == null) return '/login';

      if (profile.status == AccessStatus.disabled) {
        ref.read(supabaseClientProvider).auth.signOut();
        return '/login';
      }

      final destination = _routeForRole(profile.role);

      if (_publicRoutes.contains(location) || location == '/loading') {
        return destination;
      }

      // Garde-fou : un rôle ne peut pas entrer dans l'espace d'un autre rôle.
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

/// Pont entre Riverpod et go_router : déclenche un refresh du routeur
/// dès que la session ou le profil change.
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

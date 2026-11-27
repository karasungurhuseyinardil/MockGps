import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../features/auth/auth_controller.dart';
import '../features/auth/auth_screens.dart';
import '../features/favorites/favorites_screen.dart';
import '../features/history/history_screen.dart';
import '../features/map/map_screen.dart';
import '../features/routes/routes_repository.dart';
import '../features/routes/routes_screens.dart';
import '../features/settings/settings_screen.dart';
import '../features/simulation/setup_screen.dart';
import '../features/simulation/verify_screen.dart';
import 'shell.dart';

/// Pure redirect rules (unit tested).
String? authRedirect({required bool signedIn, required bool recovery, required String location}) {
  final inAuth = location.startsWith('/auth');
  if (recovery) return location == '/auth/new-password' ? null : '/auth/new-password';
  if (!signedIn) return inAuth ? null : '/auth/sign-in';
  if (inAuth) return '/';
  return null;
}

final routerProvider = Provider<GoRouter>((ref) {
  final refresh = ValueNotifier(0);
  ref.listen(authProvider, (_, _) => refresh.value++);
  ref.onDispose(refresh.dispose);

  return GoRouter(
    initialLocation: '/',
    refreshListenable: refresh,
    redirect: (context, state) {
      final auth = ref.read(authProvider);
      return authRedirect(signedIn: auth.signedIn, recovery: auth.passwordRecovery, location: state.matchedLocation);
    },
    // Auth deep links (mockgps://auth-callback?...) are consumed by Supabase; route them home.
    onException: (context, state, router) => router.go('/'),
    routes: [
      GoRoute(path: '/auth/sign-in', builder: (_, _) => const SignInScreen()),
      GoRoute(path: '/auth/sign-up', builder: (_, _) => const SignUpScreen()),
      GoRoute(path: '/auth/forgot', builder: (_, _) => const ForgotPasswordScreen()),
      GoRoute(path: '/auth/new-password', builder: (_, _) => const NewPasswordScreen()),
      GoRoute(path: '/auth/check-email', builder: (_, s) => CheckEmailScreen(email: s.uri.queryParameters['email'] ?? '')),
      GoRoute(path: '/setup', builder: (_, _) => const SetupScreen()),
      GoRoute(path: '/verify', builder: (_, _) => const VerifyScreen()),
      GoRoute(path: '/favorites/categories', builder: (_, _) => const CategoriesScreen()),
      GoRoute(path: '/routes/new', builder: (_, _) => const RouteEditorScreen()),
      GoRoute(path: '/routes/:id', builder: (_, s) => RouteEditorScreen(route: s.extra as SavedRoute?)),
      StatefulShellRoute.indexedStack(
        builder: (_, _, shell) => AppShell(shell: shell),
        branches: [
          StatefulShellBranch(routes: [GoRoute(path: '/', builder: (_, _) => const MapScreen())]),
          StatefulShellBranch(routes: [GoRoute(path: '/favorites', builder: (_, _) => const FavoritesScreen())]),
          StatefulShellBranch(routes: [GoRoute(path: '/routes', builder: (_, _) => const RoutesScreen())]),
          StatefulShellBranch(routes: [GoRoute(path: '/history', builder: (_, _) => const HistoryScreen())]),
          StatefulShellBranch(routes: [GoRoute(path: '/settings', builder: (_, _) => const SettingsScreen())]),
        ],
      ),
    ],
  );
});

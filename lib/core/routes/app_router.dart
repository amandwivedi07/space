import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/authentication/presentation/screens/sign_in_screen.dart';
import '../../features/authentication/presentation/screens/splash_screen.dart';
import '../../features/authentication/presentation/viewmodels/auth_viewmodel.dart';
import '../../features/chat/presentation/screens/room_screen.dart';
import '../../features/home/presentation/screens/home_screen.dart';
import '../../features/profile/presentation/screens/profile_screen.dart';
import '../../features/shelf/presentation/screens/shelf_screen.dart';
import '../widgets/error_state.dart';
import 'route_names.dart';

/// go_router configuration. Splash owns the first-launch decision; the
/// redirect below guards every route once a session ends (expired refresh
/// token or sign-out) so the app can never sit on a dead screen.
final appRouterProvider = Provider<GoRouter>((ref) {
  final refresh = _AuthRefresh(ref);
  ref.onDispose(refresh.dispose);

  return GoRouter(
    initialLocation: RouteNames.splash,
    refreshListenable: refresh,
    redirect: (context, state) {
      final auth = ref.read(authViewModelProvider);
      if (auth.loading) return null; // splash decides
      final path = state.matchedLocation;
      final isAuthScreen =
          path == RouteNames.onboarding || path == RouteNames.splash;
      if (!auth.onboarded && !isAuthScreen) return RouteNames.onboarding;
      return null;
    },
    errorBuilder: (context, state) => const Scaffold(
      body: ErrorState(message: 'Page not found'),
    ),
    routes: [
      GoRoute(
        path: RouteNames.splash,
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: RouteNames.onboarding,
        builder: (context, state) => const SignInScreen(),
      ),
      GoRoute(
        path: RouteNames.home,
        builder: (context, state) => const HomeScreen(),
      ),
      GoRoute(
        path: RouteNames.profile,
        builder: (context, state) => const ProfileScreen(),
      ),
      GoRoute(
        path: '/room/:kind/:id',
        builder: (context, state) => RoomScreen(
          kind: state.pathParameters['kind'] ?? 'person',
          refId: state.pathParameters['id'] ?? '',
        ),
      ),
      GoRoute(
        path: '/shelf/:kind/:id',
        builder: (context, state) => ShelfScreen(
          kind: state.pathParameters['kind'] ?? 'person',
          refId: state.pathParameters['id'] ?? '',
        ),
      ),
    ],
  );
});

/// Notifies go_router whenever the session's existence changes.
class _AuthRefresh extends ChangeNotifier {
  _AuthRefresh(Ref ref) {
    _sub = ref.listen<bool>(
      authViewModelProvider.select((s) => s.onboarded),
      (_, _) => notifyListeners(),
    );
  }

  late final ProviderSubscription<bool> _sub;

  @override
  void dispose() {
    _sub.close();
    super.dispose();
  }
}

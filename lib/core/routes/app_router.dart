import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/authentication/presentation/screens/onboarding_screen.dart';
import '../../features/authentication/presentation/screens/splash_screen.dart';
import '../../features/chat/presentation/screens/room_screen.dart';
import '../../features/home/presentation/screens/home_screen.dart';
import '../../features/profile/presentation/screens/profile_screen.dart';
import '../../features/shelf/presentation/screens/shelf_screen.dart';
import '../widgets/error_state.dart';
import 'route_names.dart';

/// go_router configuration. Splash owns the onboarded-or-not decision.
final appRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: RouteNames.splash,
    errorBuilder: (context, state) => Scaffold(
      body: ErrorState(message: 'Page not found'),
    ),
    routes: [
      GoRoute(
        path: RouteNames.splash,
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: RouteNames.onboarding,
        builder: (context, state) => const OnboardingScreen(),
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

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'firebase_options.dart';

import 'core/constants/app_strings.dart';
import 'core/network/realtime_client.dart';
import 'core/routes/app_router.dart';
import 'core/routes/route_names.dart';
import 'core/services/push_service.dart';
import 'core/theme/app_theme.dart';
import 'features/profile/presentation/viewmodels/settings_viewmodel.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Firebase powers Apple/Google sign-in and push. If it fails to start the
  // app still runs — those features simply report themselves unavailable.
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (error) {
    debugPrint('Firebase init failed: $error');
  }
  runApp(const ProviderScope(child: SpaceApp()));
}

/// Space — an ephemeral private messenger.
class SpaceApp extends ConsumerStatefulWidget {
  const SpaceApp({super.key});

  @override
  ConsumerState<SpaceApp> createState() => _SpaceAppState();
}

class _SpaceAppState extends ConsumerState<SpaceApp>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // Push is optional: without Firebase config this is a logged no-op.
    final push = ref.read(pushServiceProvider);
    push.onOpenSpace = (spaceId, spaceKind) {
      ref.read(appRouterProvider).push(spaceKind == 'circle'
          ? RouteNames.circleRoom(spaceId)
          : RouteNames.personRoom(spaceId));
    };
    push.initialize();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  /// The server only pushes to members it believes are offline — a live socket
  /// means "they are looking at it, do not disturb them". A backgrounded app
  /// keeps its socket open for as long as the OS allows, so without this the
  /// user stayed "online" after leaving the app and every notification was
  /// suppressed. Dropping the socket on pause is what makes background push
  /// happen at all; resuming reconnects and the missed cards arrive.
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final realtime = ref.read(realtimeClientProvider);
    switch (state) {
      case AppLifecycleState.resumed:
        realtime.connect();
      case AppLifecycleState.paused:
      case AppLifecycleState.detached:
      case AppLifecycleState.hidden:
        realtime.disconnect();
      case AppLifecycleState.inactive:
        // Transient (notification shade, call banner, app switcher preview).
        // Dropping the socket here would flap on every glance.
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final router = ref.watch(appRouterProvider);
    final themeMode =
        ref.watch(settingsViewModelProvider.select((s) => s.themeMode));

    return MaterialApp.router(
      title: AppStrings.appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: themeMode,
      routerConfig: router,
    );
  }
}

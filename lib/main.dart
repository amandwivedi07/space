import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'firebase_options.dart';

import 'core/constants/app_strings.dart';
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

class _SpaceAppState extends ConsumerState<SpaceApp> {
  @override
  void initState() {
    super.initState();
    // Push is optional: without Firebase config this is a logged no-op.
    final push = ref.read(pushServiceProvider);
    push.onOpenSpace = (spaceId) {
      ref.read(appRouterProvider).push(RouteNames.personRoom(spaceId));
    };
    push.initialize();
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

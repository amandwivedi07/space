import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_assets.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/extensions/context_x.dart';
import '../../../../core/routes/route_names.dart';
import '../../../../core/theme/app_typography.dart';
import '../viewmodels/auth_viewmodel.dart';

/// Decides where a launch lands: onboarding (first run) or home.
class SplashScreen extends ConsumerWidget {
  const SplashScreen({super.key});

  void _route(BuildContext context, bool onboarded) {
    Future.microtask(() {
      if (context.mounted) {
        context.go(onboarded ? RouteNames.home : RouteNames.onboarding);
      }
    });
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Handle BOTH cases: state that settles later, and state already settled
    // before this screen built (otherwise the splash would hang forever).
    ref.listen(authViewModelProvider, (_, next) {
      if (!next.loading) _route(context, next.onboarded);
    });
    final current = ref.watch(authViewModelProvider);
    if (!current.loading) _route(context, current.onboarded);

    return Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset(
              AppAssets.logoMark,
              width: 96,
              height: 96,
              filterQuality: FilterQuality.medium,
            ),
            const SizedBox(height: 22),
            Text(AppStrings.appName,
                style: AppTypography.display(context.ink, 40)),
            const SizedBox(height: 10),
            Text(AppStrings.tagline, style: context.text.bodySmall),
          ],
        ),
      ),
    );
  }
}

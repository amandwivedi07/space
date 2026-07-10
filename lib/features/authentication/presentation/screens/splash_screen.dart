import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_strings.dart';
import '../../../../core/extensions/context_x.dart';
import '../../../../core/routes/route_names.dart';
import '../../../../core/theme/app_typography.dart';
import '../viewmodels/auth_viewmodel.dart';

/// Decides where a launch lands: onboarding (first run) or home.
class SplashScreen extends ConsumerWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.listen(authViewModelProvider, (_, next) {
      if (next.loading) return;
      final target = next.onboarded ? RouteNames.home : RouteNames.onboarding;
      Future.microtask(() {
        if (context.mounted) context.go(target);
      });
    });

    return Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
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

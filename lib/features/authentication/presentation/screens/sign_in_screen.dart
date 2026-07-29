import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/constants/app_assets.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/constants/palettes.dart';
import '../../../../core/helpers/responsive.dart';
import '../../../../core/routes/route_names.dart';
import '../../../../core/services/social_auth_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/app_toast.dart';
import '../viewmodels/auth_viewmodel.dart';
import '../widgets/social_button.dart';

/// The front door: one tap with Apple or Google. Nothing to fill in — the
/// name comes from the identity provider and everything else is editable
/// later in Profile.
class SignInScreen extends ConsumerStatefulWidget {
  const SignInScreen({super.key});

  @override
  ConsumerState<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends ConsumerState<SignInScreen> {
  _Pending _pending = _Pending.none;

  Future<void> _signIn(_Pending which) async {
    setState(() => _pending = which);
    final social = ref.read(socialAuthProvider);
    final result = which == _Pending.apple
        ? await social.signInWithApple()
        : await social.signInWithGoogle();
    if (!mounted) return;

    switch (result) {
      case SocialAuthCancelled():
        setState(() => _pending = _Pending.none);
      case SocialAuthFailed(:final message):
        setState(() => _pending = _Pending.none);
        AppToast.show(context, message);
      case SocialAuthToken(:final idToken):
        final ok = await ref
            .read(authViewModelProvider.notifier)
            .signInWithFirebase(idToken);
        if (!mounted) return;
        setState(() => _pending = _Pending.none);
        if (ok) {
          context.go(RouteNames.home);
        } else {
          AppToast.show(context,
              ref.read(authViewModelProvider).error ?? AppStrings.somethingWentWrong);
        }
    }
  }

  Future<void> _open(String url) async {
    final uri = Uri.parse(url);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      if (mounted) AppToast.show(context, "Couldn't open that link");
    }
  }

  @override
  Widget build(BuildContext context) {
    final social = ref.read(socialAuthProvider);

    return Scaffold(
      backgroundColor: AppColors.night,
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF2A211C), AppColors.night],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints:
                  BoxConstraints(maxWidth: Responsive.contentWidth(context)),
              child: ListView(
                padding: const EdgeInsets.fromLTRB(28, 32, 28, 24),
                children: [
                  const _Brand(),
                  const SizedBox(height: 44),
                  Text('Welcome back',
                      style: AppTypography.display(AppColors.inkDark, 38)),
                  const SizedBox(height: 10),
                  Text(
                    'Sign in to find the people who kept a seat for you — '
                    'conversations here are temporary, memories are intentional.',
                    style: TextStyle(
                      color: AppColors.mutedDark,
                      fontSize: 14,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 32),
                  if (social.appleAvailable) ...[
                    SocialButton(
                      label: 'Continue with Apple',
                      icon: Icons.apple,
                      busy: _pending == _Pending.apple,
                      onPressed: _pending == _Pending.none
                          ? () => _signIn(_Pending.apple)
                          : null,
                    ),
                    const SizedBox(height: 12),
                  ],
                  SocialButton(
                    label: 'Continue with Google',
                    iconWidget: const GoogleMark(),
                    busy: _pending == _Pending.google,
                    onPressed: _pending == _Pending.none
                        ? () => _signIn(_Pending.google)
                        : null,
                  ),
                  const SizedBox(height: 40),
                  const _HeroCluster(),
                  const SizedBox(height: 36),
                   _Legal(onOpen: _open),


                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

enum _Pending { none, apple, google }

class _Brand extends StatelessWidget {
  const _Brand();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Image.asset(
          AppAssets.logoMark,
          width: 36,
          height: 36,
          filterQuality: FilterQuality.medium,
        ),
        const SizedBox(width: 10),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Space',
                style: AppTypography.display(AppColors.inkDark, 18)),
            Text('CONVERSATIONS ARE TEMPORARY',
                style: AppTypography.mono(AppColors.mutedDark, 8)),
          ],
        ),
      ],
    );
  }
}

/// A calm echo of the home cluster so the screen shows what the app *is*.
class _HeroCluster extends StatelessWidget {
  const _HeroCluster();

  static const _people = [
    (SpacePalette.ember, 'E', 76.0),
    (SpacePalette.tide, 'J', 58.0),
    (SpacePalette.rose, 'N', 66.0),
    (SpacePalette.moss, 'M', 48.0),
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Wrap(
          alignment: WrapAlignment.center,
          spacing: 16,
          runSpacing: 16,
          children: [
            for (final (palette, initial, size) in _people)
              Container(
                width: size,
                height: size,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: palette.gradient,
                  boxShadow: [
                    BoxShadow(
                      color: palette.to.withValues(alpha: 0.4),
                      blurRadius: 24,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                alignment: Alignment.center,
                child: Text(initial,
                    style: AppTypography.display(Colors.white, size * 0.4)
                        .copyWith(fontStyle: FontStyle.normal)),
              ),
          ],
        ),
        const SizedBox(height: 18),
        Text('EVERY CARD FADES · KEEP WHAT MATTERS',
            style: AppTypography.mono(
                AppColors.mutedDark.withValues(alpha: 0.8), 9)),
      ],
    );
  }
}

class _Legal extends StatelessWidget {
  const _Legal({required this.onOpen});

  final void Function(String url) onOpen;

  static const _privacy = 'https://app.spacechatapp.com/privacy';
  static const _deletion = 'https://app.spacechatapp.com/account-deletion';

  @override
  Widget build(BuildContext context) {
    final base = TextStyle(color: AppColors.mutedDark, fontSize: 11, height: 1.5);
    final link = base.copyWith(
      color: AppColors.emberSoft,
      decoration: TextDecoration.underline,
      decorationColor: AppColors.emberSoft,
    );
    return Center(
      child: Text.rich(
        TextSpan(children: [
          const TextSpan(text: 'By continuing, you agree to our '),
          _tap('Privacy Policy', link, () => onOpen(_privacy)),
          const TextSpan(text: ' and '),
          _tap('Account Deletion', link, () => onOpen(_deletion)),
          const TextSpan(text: ' policy.'),
        ]),
        textAlign: TextAlign.center,
        style: base,
      ),
    );
  }

  InlineSpan _tap(String text, TextStyle style, VoidCallback onTap) =>
      WidgetSpan(
        alignment: PlaceholderAlignment.baseline,
        baseline: TextBaseline.alphabetic,
        child: GestureDetector(
          onTap: onTap,
          child: Text(text, style: style),
        ),
      );
}

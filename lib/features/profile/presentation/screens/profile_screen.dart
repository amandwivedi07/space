import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_strings.dart';
import '../../../../core/constants/palettes.dart';
import '../../../../core/extensions/context_x.dart';
import '../../../../core/helpers/responsive.dart';
import '../../../../core/routes/route_names.dart';
import '../../../../core/services/media_picker_service.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/app_avatar.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_dialog.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../../../core/widgets/app_toast.dart';
import '../../../../core/widgets/space_app_bar.dart';
import '../../../authentication/presentation/viewmodels/auth_viewmodel.dart';
import '../../../authentication/presentation/widgets/palette_picker.dart';
import '../viewmodels/settings_viewmodel.dart';
import '../widgets/default_fade_selector.dart';
import '../widgets/theme_selector.dart';

/// Your profile — identity, mood (theme) and the default fade.
class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  late final TextEditingController _name;
  late final TextEditingController _note;

  @override
  void initState() {
    super.initState();
    final user = ref.read(authViewModelProvider).user;
    _name = TextEditingController(text: user?.name ?? '');
    _note = TextEditingController(text: user?.note ?? '');
  }

  @override
  void dispose() {
    _name.dispose();
    _note.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final user = ref.read(authViewModelProvider).user;
    if (user == null) return;
    final ok = await ref.read(authViewModelProvider.notifier).updateProfile(
          user.copyWith(
            name: _name.text.trim(),
            note: _note.text.trim(),
          ),
        );
    if (ok && mounted) {
      AppToast.show(context, AppStrings.savedLocally,
          icon: Icons.check_rounded);
    }
  }

  /// Two-step confirmation: this is irreversible and Apple requires it be
  /// reachable in-app.
  Future<void> _deleteAccount() async {
    final sure = await AppDialog.confirm(
      context,
      title: 'Delete your account?',
      body: 'Your profile, spaces and every card you sent will be gone. '
          'This cannot be undone.',
      confirmLabel: 'Delete everything',
      destructive: true,
    );
    if (!sure || !mounted) return;
    final result = await ref.read(authViewModelProvider.notifier).deleteAccount();
    if (!mounted) return;
    result.when(
      success: (_) {
        context.go(RouteNames.onboarding);
        AppToast.show(context, 'Your account is gone. Take care.');
      },
      failure: (message) => AppToast.show(context, message),
    );
  }

  Future<void> _changePhoto() async {
    final path = await ref.read(mediaPickerProvider).pickImage();
    final user = ref.read(authViewModelProvider).user;
    if (path == null || user == null) return;
    await ref
        .read(authViewModelProvider.notifier)
        .updateProfile(user.copyWith(photoPath: path));
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authViewModelProvider);
    final settings = ref.watch(settingsViewModelProvider);
    final settingsVm = ref.read(settingsViewModelProvider.notifier);
    final user = auth.user;

    return Scaffold(
      appBar: SpaceAppBar(
        eyebrow: AppStrings.appName,
        title: AppStrings.yourProfile,
        onBack: () => context.pop(),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints:
              BoxConstraints(maxWidth: Responsive.contentWidth(context)),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
            children: [
              Text(AppStrings.profileSubtitle, style: context.text.bodySmall),
              const SizedBox(height: 24),
              
              Center(
                child: Column(
                  children: [
                    GestureDetector(
                      onTap: _changePhoto,
                      child: AppAvatar(
                        name: user?.name ?? '·',
                        palette: SpacePalette.byId(user?.paletteId),
                        size: 96,
                        photoPath: user?.photoPath,
                        avatarUrl: user?.avatarUrl,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextButton(
                      onPressed: _changePhoto,
                      child: Text(AppStrings.changePhoto,
                          style: context.text.bodySmall),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              AppTextField(
                  controller: _name,
                  label: AppStrings.yourName,
                  textCapitalization: TextCapitalization.words),
              const SizedBox(height: 16),
              _HandleRow(handle: user?.handle ?? ''),
              const SizedBox(height: 16),
              AppTextField(
                controller: _note,
                label: AppStrings.aShortNote,
                hint: AppStrings.noteHint,
                maxLines: 2,
                textCapitalization: TextCapitalization.sentences,
              ),
              const SizedBox(height: 20),
              if (user != null)
                PalettePicker(
                  selectedId: user.paletteId,
                  onSelect: (id) => ref
                      .read(authViewModelProvider.notifier)
                      .updateProfile(user.copyWith(paletteId: id)),
                ),
              const SizedBox(height: 12),
              AppButton(
                label: AppStrings.save,
                expanded: true,
                busy: auth.saving,
                onPressed: _save,
              ),
              const SizedBox(height: 36),
              Text(AppStrings.appearance.toUpperCase(),
                  style: AppTypography.mono(context.muted, 10)),
              const SizedBox(height: 12),
              ThemeSelector(
                mode: settings.themeMode,
                onChanged: settingsVm.setThemeMode,
              ),
              const SizedBox(height: 32),
              Text(AppStrings.defaultFade.toUpperCase(),
                  style: AppTypography.mono(context.muted, 10)),
              const SizedBox(height: 12),
              DefaultFadeSelector(
                selected: settings.defaultFade,
                onChanged: settingsVm.setDefaultFade,
              ),
              const SizedBox(height: 32),
              if (user != null)
                Center(
                  child: Text(user.email, style: context.text.bodySmall),
                ),
              const SizedBox(height: 12),
              AppButton(
                label: AppStrings.signOutButton,
                variant: AppButtonVariant.soft,
                expanded: true,
                onPressed: () async {
                  await ref.read(authViewModelProvider.notifier).signOut();
                  if (context.mounted) context.go(RouteNames.onboarding);
                },
              ),
              const SizedBox(height: 28),
              Text('DANGER', style: AppTypography.mono(context.muted, 10)),
              const SizedBox(height: 12),
              AppButton(
                label: 'Delete my account',
                variant: AppButtonVariant.danger,
                expanded: true,
                busy: auth.saving,
                onPressed: _deleteAccount,
              ),
              const SizedBox(height: 8),
              Center(
                child: Text(
                  'Deletes your spaces, cards and profile for good.',
                  textAlign: TextAlign.center,
                  style: context.text.bodySmall,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// The @handle is derived from your email address, so it is shown rather than
/// edited — it is what lets people tell you apart from someone with the same
/// display name.
class _HandleRow extends StatelessWidget {
  const _HandleRow({required this.handle});

  final String handle;

  @override
  Widget build(BuildContext context) {
    if (handle.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(AppStrings.handle.toUpperCase(),
              style: AppTypography.mono(context.muted, 10)),
          const SizedBox(height: 6),
          Text('@$handle', style: context.text.bodyLarge),
          const SizedBox(height: 4),
          Text('People find you by this. It comes from your email address.',
              style: context.text.bodySmall),
        ],
      ),
    );
  }
}

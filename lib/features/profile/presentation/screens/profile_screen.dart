import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_strings.dart';
import '../../../../core/constants/palettes.dart';
import '../../../../core/extensions/context_x.dart';
import '../../../../core/helpers/responsive.dart';
import '../../../../core/routes/route_names.dart';
import '../../../../core/utils/handle.dart';
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
  late final TextEditingController _handle;

  /// Set from the server's reply. Handles are the one field here that can be
  /// refused — for being malformed, or already taken — so the reason belongs
  /// under the field rather than in a toast that slides away.
  String? _handleError;

  @override
  void initState() {
    super.initState();
    final user = ref.read(authViewModelProvider).user;
    _name = TextEditingController(text: user?.name ?? '');
    _note = TextEditingController(text: user?.note ?? '');
    _handle = TextEditingController(text: user?.handle ?? '');
  }

  @override
  void dispose() {
    _name.dispose();
    _note.dispose();
    _handle.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final user = ref.read(authViewModelProvider).user;
    if (user == null) return;

    // Normalised the same way the server will, so the field ends up showing
    // what was actually saved rather than what was typed.
    final handle = normalizeHandle(_handle.text);
    final changingHandle = handle.isNotEmpty && handle != user.handle;

    // Checked here first so an obviously malformed handle is refused under the
    // field instead of after a round trip. The server still decides.
    final problem = changingHandle ? handleProblem(handle) : null;
    if (problem != null) {
      setState(() => _handleError = problem);
      return;
    }
    setState(() => _handleError = null);

    final ok = await ref.read(authViewModelProvider.notifier).updateProfile(
          user.copyWith(
            name: _name.text.trim(),
            note: _note.text.trim(),
            handle: handle,
          ),
        );
    if (!mounted) return;

    if (ok) {
      // The server may have folded it further; show what it kept.
      final saved = ref.read(authViewModelProvider).user?.handle ?? '';
      if (saved.isNotEmpty) _handle.text = saved;
      AppToast.show(
        context,
        // "Saved · only on this device" is true of the note and the photo, and
        // plainly false of a handle: it is how other people find you.
        changingHandle ? 'You are @$saved now' : AppStrings.savedLocally,
        icon: Icons.check_rounded,
      );
    } else {
      final message = ref.read(authViewModelProvider).error;
      if (changingHandle) {
        setState(() => _handleError = message ?? 'Could not save');
      } else if (message != null) {
        AppToast.show(context, message);
      }
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
              _HandleField(controller: _handle, error: _handleError),
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
/// The @handle, editable. It starts life derived from your email address, but
/// it is yours to change — it is how other people find you.
class _HandleField extends StatelessWidget {
  const _HandleField({required this.controller, this.error});

  final TextEditingController controller;
  final String? error;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(AppStrings.handle.toUpperCase(),
              style: AppTypography.mono(context.muted, 10)),
          const SizedBox(height: 6),
          TextField(
            controller: controller,
            maxLength: 30,
            autocorrect: false,
            enableSuggestions: false,
            keyboardType: TextInputType.text,
            textInputAction: TextInputAction.done,
            // Lowercased as you type and limited to the characters the server
            // accepts, so the field cannot show something that will be refused.
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'[A-Za-z0-9._-]')),
              TextInputFormatter.withFunction((_, next) => next.copyWith(
                    text: next.text.toLowerCase(),
                  )),
            ],
            decoration: InputDecoration(
              prefixText: '@',
              prefixStyle: context.text.bodyLarge,
              errorText: error,
              // The rule runs to two lines; the default single line cuts it at
              // "numbers, d…" and the reader never learns what is wrong.
              errorMaxLines: 3,
              counterStyle: AppTypography.mono(context.muted, 8.5),
            ),
          ),
          Text('People find you by this. Changing it means the old one stops '
              'working.',
              style: context.text.bodySmall),
        ],
      ),
    );
  }
}

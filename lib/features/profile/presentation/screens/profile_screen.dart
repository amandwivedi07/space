import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_strings.dart';
import '../../../../core/constants/palettes.dart';
import '../../../../core/extensions/context_x.dart';
import '../../../../core/helpers/responsive.dart';
import '../../../../core/services/media_picker_service.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/app_avatar.dart';
import '../../../../core/widgets/app_button.dart';
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
  late final TextEditingController _handle;
  late final TextEditingController _note;

  @override
  void initState() {
    super.initState();
    final user = ref.read(authViewModelProvider).user;
    _name = TextEditingController(text: user?.name ?? '');
    _handle = TextEditingController(text: user?.handle ?? '');
    _note = TextEditingController(text: user?.note ?? '');
  }

  @override
  void dispose() {
    _name.dispose();
    _handle.dispose();
    _note.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final user = ref.read(authViewModelProvider).user;
    if (user == null) return;
    final ok = await ref.read(authViewModelProvider.notifier).updateProfile(
          user.copyWith(
            name: _name.text.trim(),
            handle: _handle.text.trim(),
            note: _note.text.trim(),
          ),
        );
    if (ok && mounted) {
      AppToast.show(context, AppStrings.savedLocally,
          icon: Icons.check_rounded);
    }
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
              AppTextField(controller: _handle, label: AppStrings.handle),
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
              Center(
                child: Text(AppStrings.savedLocally,
                    style: context.text.bodySmall),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

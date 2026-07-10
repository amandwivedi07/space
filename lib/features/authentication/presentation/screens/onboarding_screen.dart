import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_strings.dart';
import '../../../../core/constants/palettes.dart';
import '../../../../core/extensions/context_x.dart';
import '../../../../core/helpers/responsive.dart';
import '../../../../core/helpers/validators.dart';
import '../../../../core/routes/route_names.dart';
import '../../../../core/services/media_picker_service.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/app_avatar.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../viewmodels/auth_viewmodel.dart';
import '../widgets/palette_picker.dart';

/// First-run profile setup — "Your quiet self".
class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _handle = TextEditingController();
  final _note = TextEditingController();
  String _paletteId = SpacePalette.ember.id;
  String? _photoPath;

  @override
  void dispose() {
    _name.dispose();
    _handle.dispose();
    _note.dispose();
    super.dispose();
  }

  Future<void> _pickPhoto() async {
    final path = await ref.read(mediaPickerProvider).pickImage();
    if (path != null) setState(() => _photoPath = path);
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final ok = await ref.read(authViewModelProvider.notifier).completeOnboarding(
          name: _name.text,
          handle: _handle.text,
          note: _note.text,
          paletteId: _paletteId,
          photoPath: _photoPath,
        );
    if (ok && mounted) context.go(RouteNames.home);
  }

  @override
  Widget build(BuildContext context) {
    final saving = ref.watch(authViewModelProvider.select((s) => s.saving));

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints:
                BoxConstraints(maxWidth: Responsive.contentWidth(context)),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(28, 40, 28, 28),
              children: [
                Text('A QUIET BEGINNING',
                    style: AppTypography.mono(context.muted, 10)),
                const SizedBox(height: 10),
                Text(AppStrings.yourQuietSelf,
                    style: AppTypography.display(context.ink, 30)),
                const SizedBox(height: 6),
                Text(AppStrings.onboardingSubtitle,
                    style: context.text.bodySmall),
                const SizedBox(height: 28),
                Center(
                  child: Column(
                    children: [
                      GestureDetector(
                        onTap: _pickPhoto,
                        child: AppAvatar(
                          name: _name.text.isEmpty ? '·' : _name.text,
                          palette: SpacePalette.byId(_paletteId),
                          size: 96,
                          photoPath: _photoPath,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(AppStrings.tapToUpload,
                          style: context.text.bodySmall),
                    ],
                  ),
                ),
                const SizedBox(height: 28),
                Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      AppTextField(
                        controller: _name,
                        label: AppStrings.yourName,
                        hint: 'Elena',
                        validator: Validators.name,
                        textCapitalization: TextCapitalization.words,
                        onChanged: (_) => setState(() {}),
                      ),
                      const SizedBox(height: 18),
                      AppTextField(
                        controller: _handle,
                        label: AppStrings.handle,
                        hint: '@elena',
                        validator: Validators.handle,
                      ),
                      const SizedBox(height: 18),
                      AppTextField(
                        controller: _note,
                        label: AppStrings.aShortNote,
                        hint: AppStrings.noteHint,
                        maxLines: 2,
                        textCapitalization: TextCapitalization.sentences,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                PalettePicker(
                  selectedId: _paletteId,
                  onSelect: (id) => setState(() => _paletteId = id),
                ),
                const SizedBox(height: 36),
                AppButton(
                  label: AppStrings.beginButton,
                  expanded: true,
                  busy: saving,
                  onPressed: _submit,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_strings.dart';
import '../../../../core/constants/palettes.dart';
import '../../../../core/extensions/context_x.dart';
import '../../../../core/widgets/app_avatar.dart';
import '../../../../core/widgets/app_bottom_sheet.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_chip.dart';
import '../../../../core/widgets/app_search_bar.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../../authentication/presentation/widgets/palette_picker.dart';
import '../viewmodels/new_space_viewmodel.dart';
import 'invite_contact_tile.dart';
import 'member_picker_grid.dart';

/// "Begin a new space" — one person or a small circle. Returns the route
/// to open, or null when dismissed.
class NewSpaceSheet extends ConsumerWidget {
  const NewSpaceSheet({super.key});

  static Future<String?> show(BuildContext context) =>
      AppBottomSheet.show<String>(
        context,
        eyebrow: AppStrings.aNewSpace,
        title: AppStrings.newSpaceQuestion,
        child: const NewSpaceSheet(),
      );

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(newSpaceViewModelProvider);
    final vm = ref.read(newSpaceViewModelProvider.notifier);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            AppChip(
              label: AppStrings.onePerson,
              selected: state.mode == NewSpaceMode.one,
              onTap: () => vm.setMode(NewSpaceMode.one),
            ),
            const SizedBox(width: 8),
            AppChip(
              label: AppStrings.aSmallCircle,
              selected: state.mode == NewSpaceMode.circle,
              onTap: () => vm.setMode(NewSpaceMode.circle),
            ),
          ],
        ),
        const SizedBox(height: 20),
        if (state.mode == NewSpaceMode.one)
          _OnePersonForm(state: state, vm: vm)
        else
          _CircleForm(state: state, vm: vm),
        const SizedBox(height: 24),
        AppButton(
          label: AppStrings.beginASpace,
          expanded: true,
          onPressed: !state.canCreate
              ? null
              : () {
                  final route = state.mode == NewSpaceMode.one
                      ? '/room/person/${vm.createPerson().id}'
                      : '/room/circle/${vm.createCircle().id}';
                  Navigator.of(context).pop(route);
                },
        ),
      ],
    );
  }
}

class _OnePersonForm extends StatelessWidget {
  const _OnePersonForm({required this.state, required this.vm});

  final NewSpaceState state;
  final NewSpaceViewModel vm;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: AppTextField(
                hint: 'Their name',
                onChanged: vm.setName,
                textCapitalization: TextCapitalization.words,
              ),
            ),
            const SizedBox(width: 14),
            AppAvatar(
              name: state.name.isEmpty ? '·' : state.name,
              palette: SpacePalette.byId(state.paletteId),
              size: 52,
            ),
          ],
        ),
        const SizedBox(height: 18),
        PalettePicker(selectedId: state.paletteId, onSelect: vm.setPalette),
        const SizedBox(height: 22),
        Text(AppStrings.fromYourContacts.toUpperCase(),
            style: context.text.labelSmall),
        const SizedBox(height: 4),
        for (final contact in vm.filteredContacts.take(3))
          InviteContactTile(contact: contact),
      ],
    );
  }
}

class _CircleForm extends StatelessWidget {
  const _CircleForm({required this.state, required this.vm});

  final NewSpaceState state;
  final NewSpaceViewModel vm;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppTextField(
          hint: AppStrings.circleNameHint,
          onChanged: vm.setName,
          textCapitalization: TextCapitalization.words,
        ),
        const SizedBox(height: 6),
        Text(AppStrings.circleNameHelper, style: context.text.bodySmall),
        const SizedBox(height: 16),
        AppSearchBar(hint: AppStrings.searchHint, onChanged: vm.setQuery),
        const SizedBox(height: 14),
        MemberPickerGrid(
          people: vm.filteredPeople,
          selectedIds: state.memberIds,
          onToggle: vm.toggleMember,
        ),
        const SizedBox(height: 8),
        Text(
          state.memberIds.length < 2
              ? AppStrings.chooseAtLeastTwo
              : '${state.memberIds.length} in this circle',
          style: context.text.bodySmall,
        ),
      ],
    );
  }
}

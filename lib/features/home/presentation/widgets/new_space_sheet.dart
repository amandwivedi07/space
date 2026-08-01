import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_strings.dart';
import '../../../../core/extensions/context_x.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_bottom_sheet.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_chip.dart';
import '../../../../core/widgets/app_search_bar.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../../../core/widgets/app_toast.dart';
import '../../data/models/directory_user.dart';
import '../viewmodels/new_space_viewmodel.dart';
import 'directory_result_tile.dart';
import 'member_picker_grid.dart';

/// "Begin a new space" — one person (by their Space email) or a small circle.
/// Returns the route to open, or null when dismissed.
class NewSpaceSheet extends ConsumerWidget {
  const NewSpaceSheet({super.key});

  static Future<String?> show(BuildContext context) =>
      AppBottomSheet.show<String>(
        context,
        eyebrow: AppStrings.aNewSpace,
        title: AppStrings.newSpaceQuestion,
        child: const NewSpaceSheet(),
      );

  Future<void> _create(BuildContext context, WidgetRef ref) async {
    final vm = ref.read(newSpaceViewModelProvider.notifier);
    final mode = ref.read(newSpaceViewModelProvider).mode;
    if (mode == NewSpaceMode.one) {
      final result = await vm.createDirect();
      if (!context.mounted) return;
      result.when(
        success: (person) =>
            Navigator.of(context).pop('/room/person/${person.id}'),
        failure: (message) => AppToast.show(context, message),
      );
    } else {
      final result = await vm.createCircle();
      if (!context.mounted) return;
      result.when(
        success: (circle) =>
            Navigator.of(context).pop('/room/circle/${circle.id}'),
        failure: (message) => AppToast.show(context, message),
      );
    }
  }

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
          _OnePersonForm(vm: vm)
        else
          _CircleForm(state: state, vm: vm),
        const SizedBox(height: 24),
        AppButton(
          label: AppStrings.beginASpace,
          expanded: true,
          busy: state.creating,
          onPressed: !state.canCreate ? null : () => _create(context, ref),
        ),
      ],
    );
  }
}

class _OnePersonForm extends ConsumerStatefulWidget {
  const _OnePersonForm({required this.vm});

  final NewSpaceViewModel vm;

  @override
  ConsumerState<_OnePersonForm> createState() => _OnePersonFormState();
}

class _OnePersonFormState extends ConsumerState<_OnePersonForm> {
  NewSpaceViewModel get vm => widget.vm;

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(newSpaceViewModelProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppSearchBar(
          hint: 'Their name, or their email',
          onChanged: vm.search,
        ),
        const SizedBox(height: 10),
        if (state.picked != null)
          _PickedPerson(
            user: state.picked!,
            onClear: () => vm.search(''),
          )
        else if (state.searching)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 14),
            child: Center(
              child: SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
          )
        else if (state.results.isNotEmpty)
          ...state.results.map(
            (u) => DirectoryResultTile(user: u, onTap: () => vm.pick(u)),
          )
        else
          Text(
            state.query.length < 2
                ? 'Type at least two letters to find someone on Space.'
                : 'No one on Space matches “${state.query}”.',
            style: context.text.bodySmall,
          ),
      ],
    );
  }
}

/// The confirmed choice, so it is obvious who the space will be with.
class _PickedPerson extends StatelessWidget {
  const _PickedPerson({required this.user, required this.onClear});

  final DirectoryUser user;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(Icons.check_circle_rounded, size: 18, color: AppColors.success),
        const SizedBox(width: 8),
        Expanded(
          child: Text('${user.name} is on Space',
              style: context.text.bodyMedium),
        ),
        TextButton(onPressed: onClear, child: const Text('Change')),
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

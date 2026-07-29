import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_strings.dart';
import '../../../../core/extensions/context_x.dart';
import '../../../../core/routes/route_names.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_toast.dart';
import '../../../authentication/presentation/viewmodels/auth_viewmodel.dart';
import '../../data/models/circle_space.dart';
import '../../data/models/person.dart';
import '../../data/repositories/spaces_repository.dart';
import '../viewmodels/home_viewmodel.dart';
import '../widgets/cluster_grid.dart';
import '../widgets/new_space_sheet.dart';
import '../widgets/requests_strip.dart';
import '../widgets/search_overlay.dart';

/// Home — the drifting cluster of everyone you share space with.
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  void _openPerson(BuildContext context, WidgetRef ref, Person person) {
    ref
        .read(homeViewModelProvider.notifier)
        .markRead(person.id, isCircle: false);
    context.push(RouteNames.personRoom(person.id));
  }

  void _openCircle(BuildContext context, WidgetRef ref, CircleSpace circle) {
    ref
        .read(homeViewModelProvider.notifier)
        .markRead(circle.id, isCircle: true);
    context.push(RouteNames.circleRoom(circle.id));
  }

  /// Accept or decline an invitation, then let the toast confirm what changed.
  Future<void> _answerRequest(
    BuildContext context,
    WidgetRef ref,
    Person person, {
    required bool accept,
  }) async {
    final repo = ref.read(spacesRepositoryProvider);
    final result = accept
        ? await repo.acceptRequest(person.id)
        : await repo.declineRequest(person.id);
    if (!context.mounted) return;
    result.when(
      success: (_) => AppToast.show(
        context,
        accept ? 'You and ${person.name} share a space now' : 'Declined quietly',
      ),
      failure: (message) => AppToast.show(context, message),
    );
  }

  Future<void> _beginSpace(BuildContext context) async {
    final route = await NewSpaceSheet.show(context);
    if (route != null && context.mounted) context.push(route);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(homeViewModelProvider);
    final vm = ref.read(homeViewModelProvider.notifier);
    final repo = ref.read(spacesRepositoryProvider);
    // Greet by first name — identity providers hand us the full legal name,
    // which reads far too formal in a sentence.
    final userName = ref.watch(
      authViewModelProvider.select(
        (s) => (s.user?.name ?? '').trim().split(RegExp(r'\s+')).first,
      ),
    );

    return Scaffold(
      body: SafeArea(
        child: Stack(
          children: [
            Column(
              children: [
                _Header(
                  userName: userName,
                  onSearch: () => vm.toggleSearch(true),
                  onProfile: () => context.push(RouteNames.profile),
                ),
                RequestsStrip(
                  people: state.people,
                  onAccept: (p) => _answerRequest(context, ref, p, accept: true),
                  onDecline: (p) => _answerRequest(context, ref, p, accept: false),
                ),
                Expanded(
                  child: ClusterGrid(
                    people: state.people
                        .where((p) => !p.awaitingAnswer)
                        .toList(),
                    circles: state.circles,
                    membersOf: (circle) => circle.memberIds
                        .map(repo.personById)
                        .whereType<Person>()
                        .toList(),
                    onOpenPerson: (p) => _openPerson(context, ref, p),
                    onOpenCircle: (c) => _openCircle(context, ref, c),
                  ),
                ),
              ],
            ),
            Positioned(
              left: 20,
              bottom: 20,
              child: AppButton(
                label: AppStrings.beginASpace,
                icon: Icons.add_rounded,
                onPressed: () => _beginSpace(context),
              ),
            ),
            if (state.searching)
              Positioned.fill(
                child: SearchOverlay(
                  people: state.filteredPeople,
                  circles: state.filteredCircles,
                  onQuery: vm.setQuery,
                  onClose: () => vm.toggleSearch(false),
                  onOpenPerson: (p) {
                    vm.toggleSearch(false);
                    _openPerson(context, ref, p);
                  },
                  onOpenCircle: (c) {
                    vm.toggleSearch(false);
                    _openCircle(context, ref, c);
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({
    required this.userName,
    required this.onSearch,
    required this.onProfile,
  });

  final String userName;
  final VoidCallback onSearch;
  final VoidCallback onProfile;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 16, 12, 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(AppStrings.spacesTitle.toUpperCase(),
                    style: AppTypography.mono(context.muted, 10)),
                const SizedBox(height: 6),
                Text(
                  userName.isEmpty
                      ? AppStrings.homeQuestion
                      : 'Who are you spending time with today, $userName?',
                  style: AppTypography.display(context.ink, 22),
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: AppStrings.searchPeople,
            onPressed: onSearch,
            icon: const Icon(Icons.search_rounded),
          ),
          IconButton(
            tooltip: AppStrings.yourProfile,
            onPressed: onProfile,
            icon: const Icon(Icons.face_outlined),
          ),
        ],
      ),
    );
  }
}

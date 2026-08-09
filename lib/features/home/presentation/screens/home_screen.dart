import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/extensions/context_x.dart';
import '../../../../core/routes/route_names.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/constants/palettes.dart';
import '../../../../core/constants/presence.dart';
import '../../../../core/widgets/app_avatar.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_toast.dart';
import '../../../authentication/presentation/viewmodels/auth_viewmodel.dart';
import '../../data/models/circle_space.dart';
import '../../data/models/person.dart';
import '../../data/repositories/spaces_repository.dart';
import '../viewmodels/home_viewmodel.dart';
import '../../../broadcast/presentation/broadcast_flow.dart';
import '../widgets/space_tile.dart';
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
    final me = ref.watch(authViewModelProvider).user;

    final people =
        state.people.where((p) => !p.awaitingAnswer).toList();
    // Circles and people share one ordering: most recent first.
    final entries = <Object>[...state.circles, ...people]
      ..sort((a, b) => _activityOf(b).compareTo(_activityOf(a)));
    final featured = entries.isEmpty ? null : entries.first;
    final rest = entries.length <= 1 ? const <Object>[] : entries.sublist(1);
    final hereNow = people.where((p) => p.presence == Presence.here).length +
        state.circles.where((c) => c.presence == Presence.here).length;

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Stack(
          children: [
            CustomScrollView(
              slivers: [
                SliverToBoxAdapter(
                  child: _Header(
                    userName: userName,
                    fullName: me?.name ?? '',
                    avatarUrl: me?.avatarUrl ?? '',
                    photoPath: me?.photoPath ?? '',
                    paletteId: me?.paletteId ?? 'ember',
                    hereNow: hereNow,
                    onSearch: () => vm.toggleSearch(true),
                    onProfile: () => context.push(RouteNames.profile),
                    onBroadcast: () => startBroadcast(context, ref),
                  ),
                ),
                SliverToBoxAdapter(
                  child: RequestsStrip(
                    people: state.people,
                    onAccept: (p) =>
                        _answerRequest(context, ref, p, accept: true),
                    onDecline: (p) =>
                        _answerRequest(context, ref, p, accept: false),
                  ),
                ),
                // The newest thing gets the wide slot, whether that is a
                // circle or a person. A broadcast needs no tile of its own:
                // it makes every space recent, and the most recent one rises
                // here on its own.
                if (featured != null)
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(20, 4, 20, 14),
                    sliver: SliverToBoxAdapter(
                      child: _entryTile(context, ref, repo, featured,
                          featuredWidth: true),
                    ),
                  ),
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
                  sliver: SliverGrid(
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      mainAxisSpacing: 14,
                      crossAxisSpacing: 14,
                      childAspectRatio: 0.86,
                    ),
                    delegate: SliverChildBuilderDelegate(
                      (context, i) => _entryTile(
                          context, ref, repo, rest[i], featuredWidth: false),
                      childCount: rest.length,
                    ),
                  ),
                ),
                // Clears the floating "start a space" pill.
                const SliverToBoxAdapter(child: SizedBox(height: 120)),
              ],
            ),
            Positioned(
              left: 0,
              right: 0,
              bottom: 28,
              child: Center(
                  child: AppButton(
                label: AppStrings.beginASpace,
                icon: Icons.add_rounded,
                onPressed: () => _beginSpace(context),
              )),
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

/// When a space last had something happen in it — the single key both kinds
/// of entry are ordered by.
DateTime _activityOf(Object entry) => switch (entry) {
      CircleSpace(:final lastActivity) => lastActivity,
      Person(:final lastActivity) => lastActivity,
      _ => DateTime.fromMillisecondsSinceEpoch(0),
    };

class _Header extends StatelessWidget {
  const _Header({
    required this.userName,
    required this.fullName,
    required this.avatarUrl,
    required this.photoPath,
    required this.paletteId,
    required this.hereNow,
    required this.onSearch,
    required this.onProfile,
    required this.onBroadcast,
  });

  final String userName;
  final String fullName;
  final String avatarUrl;
  final String photoPath;
  final String paletteId;
  final int hereNow;
  final VoidCallback onSearch;
  final VoidCallback onProfile;
  final VoidCallback onBroadcast;

  @override
  Widget build(BuildContext context) {
    final date = DateFormat('EEEE d MMM').format(DateTime.now()).toUpperCase();
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Text(date,
                    style: AppTypography.mono(context.muted, 10)),
              ),
              // Filled, not outlined: it is the one control here that speaks
              // to everybody at once, and it should not be mistaken for the
              // quiet pair beside it.
              _RoundButton(
                onTap: onBroadcast,
                tooltip: 'Broadcast to everyone',
                filled: true,
                child: const Icon(Icons.campaign_rounded,
                    size: 20, color: Colors.white),
              ),
              const SizedBox(width: 10),
              _RoundButton(
                onTap: onSearch,
                tooltip: AppStrings.searchPeople,
                child: Icon(Icons.search_rounded, size: 20, color: context.ink),
              ),
              const SizedBox(width: 10),
              // Your own face, not a generic mask.
              _RoundButton(
                onTap: onProfile,
                tooltip: AppStrings.yourProfile,
                padded: false,
                child: AppAvatar(
                  name: fullName.isEmpty ? userName : fullName,
                  palette: SpacePalette.byId(paletteId),
                  avatarUrl: avatarUrl,
                  photoPath: photoPath,
                  size: 44,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          // Three lines, the middle one in the accent — the question is the
          // largest thing on the screen because it is the only thing being
          // asked of you.
          RichText(
            text: TextSpan(
              style: AppTypography.display(context.ink, 40),
              children: [
                const TextSpan(text: 'who\u2019s\n'),
                TextSpan(
                  text: 'in your space\n',
                  style: TextStyle(color: context.colors.primary),
                ),
                const TextSpan(text: 'today?'),
              ],
            ),
          ),
          if (AppConstants.showPresence && hereNow > 0) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
              decoration: BoxDecoration(
                color: context.ink.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(999),
                border:
                    Border.all(color: context.ink.withValues(alpha: 0.08)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 7,
                    height: 7,
                    decoration: const BoxDecoration(
                      color: Color(0xFF5FD08A),
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 9),
                  Text('$hereNow HERE NOW',
                      style: AppTypography.mono(context.muted, 9)),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// The header's circular controls — a hairline ring on the background rather
/// than a filled button, so they sit quietly beside the headline.
class _RoundButton extends StatelessWidget {
  const _RoundButton({
    required this.child,
    required this.onTap,
    required this.tooltip,
    this.padded = true,
    this.filled = false,
  });

  final Widget child;
  final VoidCallback onTap;
  final String tooltip;
  final bool padded;
  final bool filled;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: 44,
          height: 44,
          alignment: Alignment.center,
          decoration: filled
              ? BoxDecoration(
                  shape: BoxShape.circle,
                  color: context.colors.primary,
                )
              : padded
                  ? BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                          color: context.ink.withValues(alpha: 0.16)),
                    )
                  : null,
          child: child,
        ),
      ),
    );
  }
}



/// One entry, as either the wide featured tile or a grid tile. Circles always
/// show their members' faces; a person shows their own.
Widget _entryTile(
  BuildContext context,
  WidgetRef ref,
  SpacesRepository repo,
  Object entry, {
  required bool featuredWidth,
}) {
  if (entry is CircleSpace) {
    final members = entry.memberIds
        .map(repo.personById)
        .whereType<Person>()
        .toList();
    return CircleTile(
      name: entry.name,
      faces: [for (final m in members) (m.name, m.paletteId, m.avatarUrl)],
      presence: entry.presence,
      unread: entry.unread,
      lastActivity: entry.lastActivity,
      featured: featuredWidth,
      onTap: () {
        ref.read(homeViewModelProvider.notifier).markRead(entry.id, isCircle: true);
        context.push(RouteNames.circleRoom(entry.id));
      },
    );
  }
  final person = entry as Person;
  return PersonTile(
    name: person.name,
    paletteId: person.paletteId,
    presence: person.presence,
    unread: person.unread,
    lastActivity: person.lastActivity,
    avatarUrl: person.avatarUrl,
    // The featured slot is a landscape band; the grid ones are portrait.
    height: featuredWidth ? 240 : 200,
    onTap: () {
      ref.read(homeViewModelProvider.notifier).markRead(person.id, isCircle: false);
      context.push(RouteNames.personRoom(person.id));
    },
  );
}

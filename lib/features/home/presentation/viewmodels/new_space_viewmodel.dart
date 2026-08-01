import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/utils/result.dart';
import '../../data/models/circle_space.dart';
import '../../data/models/directory_user.dart';
import '../../data/models/person.dart';
import '../../data/repositories/spaces_repository.dart';

enum NewSpaceMode { one, circle }

/// State for the "Begin a new space" sheet.
class NewSpaceState {
  const NewSpaceState({
    this.mode = NewSpaceMode.one,
    this.name = '',
    this.memberIds = const {},
    this.query = '',
    this.creating = false,
    this.results = const [],
    this.searching = false,
    this.picked,
  });

  final NewSpaceMode mode;
  final String name; // circle name
  final Set<String> memberIds; // selected Person ids (direct-space partners)
  final String query;
  final bool creating;
  final List<DirectoryUser> results; // directory matches for the one-person tab
  final bool searching;
  final DirectoryUser? picked; // the person chosen from those matches

  bool get canCreate => switch (mode) {
        NewSpaceMode.one => picked != null,
        NewSpaceMode.circle => memberIds.length >= 2,
      };

  NewSpaceState copyWith({
    NewSpaceMode? mode,
    String? name,
    Set<String>? memberIds,
    String? query,
    bool? creating,
    List<DirectoryUser>? results,
    bool? searching,
    DirectoryUser? picked,
    bool clearPicked = false,
  }) =>
      NewSpaceState(
        mode: mode ?? this.mode,
        name: name ?? this.name,
        memberIds: memberIds ?? this.memberIds,
        query: query ?? this.query,
        creating: creating ?? this.creating,
        results: results ?? this.results,
        searching: searching ?? this.searching,
        picked: clearPicked ? null : (picked ?? this.picked),
      );
}

class NewSpaceViewModel extends AutoDisposeNotifier<NewSpaceState> {
  SpacesRepository get _repo => ref.read(spacesRepositoryProvider);

  @override
  NewSpaceState build() => const NewSpaceState();

  void setMode(NewSpaceMode mode) => state = state.copyWith(mode: mode);
  void setName(String name) => state = state.copyWith(name: name);
  void setQuery(String query) => state = state.copyWith(query: query);

  void toggleMember(String id) {
    final next = Set<String>.from(state.memberIds);
    next.contains(id) ? next.remove(id) : next.add(id);
    state = state.copyWith(memberIds: next);
  }

  List<Person> get filteredPeople {
    final q = state.query.trim().toLowerCase();
    final all = _repo.people.toList();
    if (q.isEmpty) return all;
    return all.where((p) => p.name.toLowerCase().contains(q)).toList();
  }


  /// Search the people directory. Debounced by [_searchToken] so a slow
  /// response for an old query can never overwrite a newer one.
  Future<void> search(String query) async {
    final q = query.trim();
    state = state.copyWith(query: q, clearPicked: true);
    if (q.length < 2) {
      state = state.copyWith(results: const [], searching: false);
      return;
    }
    final token = ++_searchToken;
    state = state.copyWith(searching: true);
    final result = await _repo.searchDirectory(q);
    if (token != _searchToken) return; // a newer query already went out
    state = state.copyWith(
      searching: false,
      results: result.dataOrNull ?? const [],
    );
  }

  int _searchToken = 0;

  void pick(DirectoryUser user) => state = state.copyWith(picked: user);

  /// Direct space with whoever was picked from the directory. [canCreate]
  /// guarantees a pick exists before this runs.
  Future<Result<Person>> createDirect() async {
    state = state.copyWith(creating: true);
    final result = await _repo.createDirect(state.picked!.id);
    state = state.copyWith(creating: false);
    return result;
  }

  /// Circle from selected direct-space partners (their user ids).
  Future<Result<CircleSpace>> createCircle() async {
    state = state.copyWith(creating: true);
    final userIds = _repo.people
        .where((p) => state.memberIds.contains(p.id) && p.userId.isNotEmpty)
        .map((p) => p.userId)
        .toList();
    final result =
        await _repo.createCircle(name: state.name, memberUserIds: userIds);
    state = state.copyWith(creating: false);
    return result;
  }

}

final newSpaceViewModelProvider =
    AutoDisposeNotifierProvider<NewSpaceViewModel, NewSpaceState>(
        NewSpaceViewModel.new);

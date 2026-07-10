import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/circle_space.dart';
import '../../data/models/person.dart';
import '../../data/repositories/spaces_repository.dart';

/// Home cluster state: everyone you share space with, plus search.
class HomeState {
  const HomeState({
    this.people = const [],
    this.circles = const [],
    this.query = '',
    this.searching = false,
  });

  final List<Person> people;
  final List<CircleSpace> circles;
  final String query;
  final bool searching;

  List<Person> get filteredPeople {
    final q = query.trim().toLowerCase();
    if (q.isEmpty) return people;
    return people.where((p) => p.name.toLowerCase().contains(q)).toList();
  }

  List<CircleSpace> get filteredCircles {
    final q = query.trim().toLowerCase();
    if (q.isEmpty) return circles;
    return circles.where((c) => c.name.toLowerCase().contains(q)).toList();
  }

  int get totalUnread =>
      people.fold(0, (sum, p) => sum + p.unread) +
      circles.fold(0, (sum, c) => sum + c.unread);

  HomeState copyWith({
    List<Person>? people,
    List<CircleSpace>? circles,
    String? query,
    bool? searching,
  }) =>
      HomeState(
        people: people ?? this.people,
        circles: circles ?? this.circles,
        query: query ?? this.query,
        searching: searching ?? this.searching,
      );
}

class HomeViewModel extends Notifier<HomeState> {
  SpacesRepository get _repo => ref.read(spacesRepositoryProvider);

  @override
  HomeState build() {
    final repo = ref.watch(spacesRepositoryProvider);
    final peopleSub =
        repo.watchPeople().listen((p) => state = state.copyWith(people: p));
    final circlesSub =
        repo.watchCircles().listen((c) => state = state.copyWith(circles: c));
    ref.onDispose(() {
      peopleSub.cancel();
      circlesSub.cancel();
    });
    return HomeState(people: repo.people, circles: repo.circles);
  }

  void setQuery(String query) => state = state.copyWith(query: query);

  void toggleSearch([bool? open]) => state =
      state.copyWith(searching: open ?? !state.searching, query: '');

  void markRead(String id, {required bool isCircle}) =>
      _repo.markRead(id, isCircle: isCircle);
}

final homeViewModelProvider =
    NotifierProvider<HomeViewModel, HomeState>(HomeViewModel.new);

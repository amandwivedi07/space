import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/palettes.dart';
import '../../data/models/circle_space.dart';
import '../../data/models/contact.dart';
import '../../data/models/person.dart';
import '../../data/repositories/spaces_repository.dart';

/// State for the "Begin a new space" sheet.
class NewSpaceState {
  const NewSpaceState({
    this.mode = NewSpaceMode.one,
    this.name = '',
    this.paletteId = 'ember',
    this.memberIds = const {},
    this.query = '',
  });

  final NewSpaceMode mode;
  final String name;
  final String paletteId;
  final Set<String> memberIds;
  final String query;

  bool get canCreate => switch (mode) {
        NewSpaceMode.one => name.trim().isNotEmpty,
        NewSpaceMode.circle => memberIds.length >= 2,
      };

  NewSpaceState copyWith({
    NewSpaceMode? mode,
    String? name,
    String? paletteId,
    Set<String>? memberIds,
    String? query,
  }) =>
      NewSpaceState(
        mode: mode ?? this.mode,
        name: name ?? this.name,
        paletteId: paletteId ?? this.paletteId,
        memberIds: memberIds ?? this.memberIds,
        query: query ?? this.query,
      );
}

enum NewSpaceMode { one, circle }

class NewSpaceViewModel extends AutoDisposeNotifier<NewSpaceState> {
  SpacesRepository get _repo => ref.read(spacesRepositoryProvider);

  @override
  NewSpaceState build() =>
      NewSpaceState(paletteId: SpacePalette.all.first.id);

  void setMode(NewSpaceMode mode) => state = state.copyWith(mode: mode);
  void setName(String name) => state = state.copyWith(name: name);
  void setPalette(String id) => state = state.copyWith(paletteId: id);
  void setQuery(String query) => state = state.copyWith(query: query);

  void toggleMember(String id) {
    final next = Set<String>.from(state.memberIds);
    next.contains(id) ? next.remove(id) : next.add(id);
    state = state.copyWith(memberIds: next);
  }

  List<Person> get filteredPeople {
    final q = state.query.trim().toLowerCase();
    final all = _repo.people;
    if (q.isEmpty) return all;
    return all.where((p) => p.name.toLowerCase().contains(q)).toList();
  }

  List<Contact> get filteredContacts {
    final q = state.query.trim().toLowerCase();
    final all = _repo.contacts.where((c) => !c.onSpace).toList();
    if (q.isEmpty) return all;
    return all
        .where((c) =>
            c.name.toLowerCase().contains(q) ||
            c.phone.replaceAll(RegExp(r'\D'), '').contains(q))
        .toList();
  }

  Person createPerson() => _repo.createPerson(
      name: state.name, paletteId: state.paletteId);

  CircleSpace createCircle() => _repo.createCircle(
      name: state.name, memberIds: state.memberIds.toList());

  Person invitePending(Contact contact) => _repo.createPerson(
        name: contact.name,
        paletteId: state.paletteId,
        phone: contact.phone,
        pending: true,
      );
}

final newSpaceViewModelProvider =
    AutoDisposeNotifierProvider<NewSpaceViewModel, NewSpaceState>(
        NewSpaceViewModel.new);

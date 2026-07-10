import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/presence.dart';
import '../../../../core/extensions/string_x.dart';
import '../../../../core/utils/id_generator.dart';
import '../datasources/spaces_mock_datasource.dart';
import '../models/circle_space.dart';
import '../models/contact.dart';
import '../models/person.dart';

/// Spaces contract: people, circles, contacts.
abstract class SpacesRepository {
  List<Person> get people;
  List<CircleSpace> get circles;
  List<Contact> get contacts;
  Stream<List<Person>> watchPeople();
  Stream<List<CircleSpace>> watchCircles();
  Person? personById(String id);
  CircleSpace? circleById(String id);
  Person createPerson({required String name, required String paletteId, String? phone, bool pending});
  CircleSpace createCircle({required String name, required List<String> memberIds});
  void markRead(String id, {required bool isCircle});
}

class MockSpacesRepository implements SpacesRepository {
  MockSpacesRepository(this._source);

  final SpacesMockDataSource _source;

  @override
  List<Person> get people => _source.people;
  @override
  List<CircleSpace> get circles => _source.circles;
  @override
  List<Contact> get contacts => _source.contacts;
  @override
  Stream<List<Person>> watchPeople() => _source.watchPeople();
  @override
  Stream<List<CircleSpace>> watchCircles() => _source.watchCircles();
  @override
  Person? personById(String id) => _source.personById(id);
  @override
  CircleSpace? circleById(String id) => _source.circleById(id);

  @override
  Person createPerson({
    required String name,
    required String paletteId,
    String? phone,
    bool pending = false,
  }) {
    final spot = _source.nextFreeSpot();
    final person = Person(
      id: IdGenerator.uniqueSlug(
          name.slug.isEmpty ? 'friend' : name.slug, people.map((p) => p.id)),
      name: name.trim(),
      paletteId: paletteId,
      sizeKey: 'md',
      x: spot.x,
      y: spot.y,
      lastActivity: DateTime.now(),
      phone: phone,
      pending: pending,
    );
    _source.upsertPerson(person);
    return person;
  }

  @override
  CircleSpace createCircle(
      {required String name, required List<String> memberIds}) {
    final title = name.isBlank ? 'A small circle' : name.trim();
    final spot = _source.nextFreeSpot();
    final circle = CircleSpace(
      id: IdGenerator.uniqueSlug(title.slug, circles.map((c) => c.id)),
      name: title,
      memberIds: memberIds,
      sizeKey: memberIds.length >= 4 ? 'xl' : 'lg',
      x: spot.x,
      y: spot.y,
      lastActivity: DateTime.now(),
    );
    _source.upsertCircle(circle);
    return circle;
  }

  @override
  void markRead(String id, {required bool isCircle}) {
    if (isCircle) {
      final circle = circleById(id);
      if (circle != null && circle.unread > 0) {
        _source.upsertCircle(circle.copyWith(unread: 0));
      }
    } else {
      final person = personById(id);
      if (person != null && person.unread > 0) {
        _source.upsertPerson(
            person.copyWith(unread: 0, presence: Presence.here));
      }
    }
  }
}

final spacesDataSourceProvider = Provider<SpacesMockDataSource>((ref) {
  final source = SpacesMockDataSource();
  ref.onDispose(source.dispose);
  return source;
});

final spacesRepositoryProvider = Provider<SpacesRepository>(
  (ref) => MockSpacesRepository(ref.watch(spacesDataSourceProvider)),
);

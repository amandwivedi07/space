import 'dart:async';
import 'dart:math';

import '../models/circle_space.dart';
import '../models/contact.dart';
import '../models/person.dart';
import 'spaces_seed_data.dart';

/// In-memory reactive store of spaces. The API-backed datasource will expose
/// the same streams fed by WebSocket/push instead of local mutation.
class SpacesMockDataSource {
  SpacesMockDataSource()
      : _people = SpacesSeedData.people(),
        _circles = SpacesSeedData.circles();

  final _random = Random();
  List<Person> _people;
  List<CircleSpace> _circles;

  final _peopleCtrl = StreamController<List<Person>>.broadcast();
  final _circlesCtrl = StreamController<List<CircleSpace>>.broadcast();

  List<Person> get people => List.unmodifiable(_people);
  List<CircleSpace> get circles => List.unmodifiable(_circles);
  List<Contact> get contacts => SpacesSeedData.contacts();

  Stream<List<Person>> watchPeople() => _peopleCtrl.stream;
  Stream<List<CircleSpace>> watchCircles() => _circlesCtrl.stream;

  void _emit() {
    _peopleCtrl.add(people);
    _circlesCtrl.add(circles);
  }

  /// Least-crowded spot on the 0–100 canvas for a new bubble.
  ({double x, double y}) nextFreeSpot() {
    var best = (x: 50.0, y: 50.0);
    var bestDist = -1.0;
    final taken = [
      ..._people.map((p) => (x: p.x, y: p.y)),
      ..._circles.map((c) => (x: c.x, y: c.y)),
    ];
    for (var i = 0; i < 40; i++) {
      final x = 18 + _random.nextDouble() * 68;
      final y = 14 + _random.nextDouble() * 74;
      final dist = taken.fold<double>(double.infinity, (min, p) {
        final d = sqrt(pow(p.x - x, 2) + pow(p.y - y, 2));
        return d < min ? d : min;
      });
      if (dist > bestDist) {
        bestDist = dist;
        best = (x: x, y: y);
      }
    }
    return best;
  }

  void upsertPerson(Person person) {
    _people = [..._people.where((p) => p.id != person.id), person];
    _emit();
  }

  void upsertCircle(CircleSpace circle) {
    _circles = [..._circles.where((c) => c.id != circle.id), circle];
    _emit();
  }

  Person? personById(String id) =>
      _people.where((p) => p.id == id).firstOrNull;

  CircleSpace? circleById(String id) =>
      _circles.where((c) => c.id == id).firstOrNull;

  void dispose() {
    _peopleCtrl.close();
    _circlesCtrl.close();
  }
}

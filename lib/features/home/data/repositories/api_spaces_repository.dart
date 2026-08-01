import 'dart:async';

import '../../../../core/constants/presence.dart';
import '../../../../core/network/api_exception.dart';
import '../../../../core/services/logger_service.dart';
import '../../../../core/utils/result.dart';
import '../datasources/spaces_remote_datasource.dart';
import '../models/circle_space.dart';
import '../models/directory_user.dart';
import '../models/person.dart';
import 'spaces_repository.dart';

/// Backend-backed spaces: GET /spaces polled every 5s.
/// Direct spaces surface as Person bubbles (id = space id); circles as
/// CircleSpace. Member stubs let circles resolve names/palettes.
class ApiSpacesRepository implements SpacesRepository {
  ApiSpacesRepository(this._remote, {Stream<Map<String, dynamic>>? events}) {
    // WebSocket events drive updates; polling is only a 30s safety net.
    _timer = Timer.periodic(const Duration(seconds: 30), (_) => refresh());
    _eventsSub = events?.listen((event) {
      if (event['type'] == 'spaces.changed' || event['type'] == 'hello') {
        refresh();
      }
    });
    // No refresh() here: the provider calls it once `myUserId` is known,
    // otherwise "who is the other person" cannot be resolved.
  }

  final SpacesRemoteDataSource _remote;

  List<Person> _people = [];
  List<CircleSpace> _circles = [];
  final Map<String, Person> _memberStubs = {}; // by user id, for circles

  final _peopleCtrl = StreamController<List<Person>>.broadcast();
  final _circlesCtrl = StreamController<List<CircleSpace>>.broadcast();
  Timer? _timer;
  StreamSubscription<Map<String, dynamic>>? _eventsSub;

  // ---- polling ----

  Future<void> refresh() async {
    if (myUserId.isEmpty) return; // identity unknown — nothing to resolve yet
    try {
      final spaces = await _remote.listSpaces();
      final people = <Person>[];
      final circles = <CircleSpace>[];
      for (final space in spaces) {
        final rawMembers = space['members'];
        if (rawMembers is! List) continue; // skip malformed entries
        final members = rawMembers.cast<Map<String, dynamic>>();
        for (final m in members) {
          _memberStubs[m['user_id'] as String] = _stub(m);
        }
        if (space['type'] == 'direct') {
          final person = _toPerson(space, members);
          if (person != null) people.add(person);
        } else {
          circles.add(_toCircle(space, members));
        }
      }
      _people = people;
      _circles = circles;
      _peopleCtrl.add(this.people);
      _circlesCtrl.add(this.circles);
    } on ApiException catch (e) {
      Log.w('spaces refresh failed: $e'); // keep last known state
    } catch (e) {
      Log.w('spaces refresh: unexpected payload: $e');
    }
  }

  Person _stub(Map<String, dynamic> m) => Person(
    id: 'u:${m['user_id']}',
    userId: m['user_id'] as String,
    name: m['name'] as String? ?? 'Someone',
    handle: m['handle'] as String? ?? '',
    avatarUrl: m['avatar_url'] as String? ?? '',
    paletteId: m['palette_id'] as String? ?? 'ember',
    presence: Presence.fromId(m['presence'] as String?),
    lastActivity: DateTime.now(),
  );

  Person? _toPerson(
    Map<String, dynamic> space,
    List<Map<String, dynamic>> members,
  ) {
    // The counterpart is whichever member isn't me.
    final notMe = members.where((m) => m['user_id'] != myUserId).toList();
    if (notMe.isEmpty) return null;
    final counterpart = notMe.first;

    final activity =
        DateTime.tryParse(space['last_activity_at'] as String? ?? '') ??
        DateTime.now();
    // A pending space is an invitation; which way it points decides whether
    // this person can answer it or is the one waiting.
    final pendingRequest = space['status'] == 'pending';
    final requestedBy = space['requested_by'] as String? ?? '';
    final request = !pendingRequest
        ? SpaceRequest.none
        : requestedBy == myUserId
        ? SpaceRequest.outgoing
        : SpaceRequest.incoming;

    return Person(
      id: space['id'] as String,
      userId: counterpart['user_id'] as String,
      name: counterpart['name'] as String? ?? 'Someone',
      paletteId: counterpart['palette_id'] as String? ?? 'ember',
      sizeKey: _sizeFor(activity),
      unread: (space['unread'] as num?)?.toInt() ?? 0,
      presence: Presence.fromId(counterpart['presence'] as String?),
      lastActivity: activity,
      request: request,
      handle: counterpart['handle'] as String? ?? '',
      avatarUrl: counterpart['avatar_url'] as String? ?? '',
    );
  }

  CircleSpace _toCircle(
    Map<String, dynamic> space,
    List<Map<String, dynamic>> members,
  ) {
    final activity =
        DateTime.tryParse(space['last_activity_at'] as String? ?? '') ??
        DateTime.now();
    final presences = members.map(
      (m) => Presence.fromId(m['presence'] as String?),
    );
    return CircleSpace(
      id: space['id'] as String,
      name: space['name'] as String? ?? 'A small circle',
      memberIds: members
          .where((m) => m['user_id'] != myUserId)
          .map((m) => 'u:${m['user_id']}')
          .toList(),
      unread: (space['unread'] as num?)?.toInt() ?? 0,
      presence: presences.contains(Presence.here)
          ? Presence.here
          : presences.contains(Presence.recent)
          ? Presence.recent
          : Presence.away,
      sizeKey: members.length >= 5 ? 'xl' : 'lg',
      lastActivity: activity,
    );
  }

  String _sizeFor(DateTime activity) {
    final age = DateTime.now().difference(activity);
    if (age.inMinutes < 10) return 'xl';
    if (age.inHours < 1) return 'lg';
    if (age.inHours < 24) return 'md';
    return 'sm';
  }

  /// Set by the auth layer after login (see spacesRepositoryProvider wiring).
  String myUserId = '';

  // ---- SpacesRepository ----

  @override
  List<Person> get people => List.unmodifiable(_people);
  @override
  List<CircleSpace> get circles => List.unmodifiable(_circles);
  @override
  Stream<List<Person>> watchPeople() => _peopleCtrl.stream;
  @override
  Stream<List<CircleSpace>> watchCircles() => _circlesCtrl.stream;

  @override
  Person? personById(String id) {
    for (final p in _people) {
      if (p.id == id) return p;
    }
    if (id.startsWith('u:')) return _memberStubs[id.substring(2)];
    return _memberStubs[id];
  }

  @override
  CircleSpace? circleById(String id) {
    for (final c in _circles) {
      if (c.id == id) return c;
    }
    return null;
  }

  @override
  Future<Result<Person>> createDirect(String userId) async {
    try {
      final space = await _remote.createDirect(userId);
      await refresh();
      final person = personById(space['id'] as String);
      if (person != null) return Success(person);
      return const Failure(
        'Space created but not visible yet — pull to refresh',
      );
    } on ApiException catch (e) {
      return Failure(e.message);
    }
  }

  @override
  Future<Result<CircleSpace>> createCircle({
    required String name,
    required List<String> memberUserIds,
  }) async {
    try {
      final space = await _remote.createCircle(name, memberUserIds);
      await refresh();
      final circle = circleById(space['id'] as String);
      if (circle != null) return Success(circle);
      return const Failure('Circle created but not visible yet');
    } on ApiException catch (e) {
      return Failure(e.message);
    }
  }

  @override
  Future<void> leave(String spaceId) async {
    try {
      await _remote.leave(spaceId);
      await refresh();
    } on ApiException catch (e) {
      Log.w('leave failed: $e');
    }
  }

  @override
  Future<Result<void>> acceptRequest(String spaceId) async =>
      _answer(() => _remote.acceptRequest(spaceId));

  @override
  Future<Result<void>> declineRequest(String spaceId) async =>
      _answer(() => _remote.declineRequest(spaceId));

  Future<Result<void>> _answer(Future<void> Function() call) async {
    try {
      await call();
      await refresh();
      return const Success(null);
    } on ApiException catch (e) {
      return Failure(e.message);
    }
  }

  @override
  Future<Result<List<DirectoryUser>>> searchDirectory(String query) async {
    try {
      final rows = await _remote.searchDirectory(query);
      return Success(
        rows.cast<Map<String, dynamic>>().map(DirectoryUser.fromJson).toList(),
      );
    } on ApiException catch (e) {
      return Failure(e.message);
    }
  }

  @override
  void markRead(String id, {required bool isCircle}) {
    // The room marks cards seen; nudge the server + refresh softly.
    _remote.markSeen(id).then((_) => refresh()).catchError((_) {});
  }

  /// Drop everything on sign-out so the next account starts clean.
  void clearLocal() {
    _people = [];
    _circles = [];
    _memberStubs.clear();
    _peopleCtrl.add(const []);
    _circlesCtrl.add(const []);
  }

  void dispose() {
    _timer?.cancel();
    _eventsSub?.cancel();
    _peopleCtrl.close();
    _circlesCtrl.close();
  }
}

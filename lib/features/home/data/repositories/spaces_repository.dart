import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/api_client.dart';
import '../../../../core/network/realtime_client.dart';
import '../../../../core/utils/result.dart';
import '../../../authentication/presentation/viewmodels/auth_viewmodel.dart';
import '../datasources/spaces_remote_datasource.dart';
import '../models/circle_space.dart';
import '../models/directory_user.dart';
import '../models/person.dart';
import 'api_spaces_repository.dart';

/// Spaces contract: the people and circles you share a space with.
abstract class SpacesRepository {
  List<Person> get people;
  List<CircleSpace> get circles;
  Stream<List<Person>> watchPeople();
  Stream<List<CircleSpace>> watchCircles();
  Person? personById(String id);
  CircleSpace? circleById(String id);

  /// Send a request to open a direct space with someone from the directory.
  /// It stays pending until they accept.
  Future<Result<Person>> createDirect(String userId);

  Future<Result<CircleSpace>> createCircle(
      {required String name, required List<String> memberUserIds});

  void markRead(String id, {required bool isCircle});

  /// Leave a space quietly (server removes membership). Returns a Result
  /// because leaving is destructive: a silent failure would leave someone
  /// believing they are out of a group they are still in.
  Future<Result<void>> leave(String spaceId);

  /// Answer an incoming request. Declining removes the space entirely.
  Future<Result<void>> acceptRequest(String spaceId);
  Future<Result<void>> declineRequest(String spaceId);


  /// Find people by name, or by an exact email address.
  Future<Result<List<DirectoryUser>>> searchDirectory(String query);
}

/// Live view of your direct spaces. Any screen can watch this to react when a
/// space changes underneath it — a request being accepted, for instance —
/// rather than reading a cached snapshot once.
final peopleProvider = StreamProvider<List<Person>>(
  (ref) => ref.watch(spacesRepositoryProvider).watchPeople(),
);

final spacesRepositoryProvider = Provider<SpacesRepository>((ref) {
  final realtime = ref.watch(realtimeClientProvider);
  final repo = ApiSpacesRepository(
    SpacesRemoteDataSource(ref.watch(apiClientProvider)),
    events: realtime.events,
  );
  // Tell the repo who "me" is, now and whenever the session changes;
  // the socket lives exactly as long as a session exists.
  repo.myUserId = ref.read(authViewModelProvider).user?.id ?? '';
  if (repo.myUserId.isNotEmpty) {
    realtime.connect();
    repo.refresh();
  }
  // Identity changes only — a profile save or a `saving` toggle must not
  // tear down the socket.
  ref.listen(authViewModelProvider.select((s) => s.user?.id ?? ''), (prev, id) {
    if (prev == id) return;
    repo.myUserId = id;
    if (id.isEmpty) {
      realtime.disconnect();
      repo.clearLocal();
    } else {
      realtime.connect();
      repo.refresh();
    }
  });
  ref.onDispose(repo.dispose);
  return repo;
});

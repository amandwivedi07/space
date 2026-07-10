import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../chat/data/models/space_card.dart';
import '../../data/repositories/shelf_repository.dart';

/// Kept cards for one room's shelf.
class ShelfViewModel
    extends AutoDisposeFamilyNotifier<List<SpaceCard>, String> {
  ShelfRepository get _repo => ref.read(shelfRepositoryProvider);

  @override
  List<SpaceCard> build(String arg) {
    final repo = ref.watch(shelfRepositoryProvider);
    final sub = repo.watchShelf(arg).listen((cards) => state = cards);
    ref.onDispose(sub.cancel);
    return repo.keptFor(arg);
  }

  void unkeep(SpaceCard card) => _repo.unkeep(arg, card.id);

  void deleteForEveryone(SpaceCard card) =>
      _repo.deleteForEveryone(arg, card.id);
}

final shelfViewModelProvider = AutoDisposeNotifierProviderFamily<
    ShelfViewModel, List<SpaceCard>, String>(ShelfViewModel.new);

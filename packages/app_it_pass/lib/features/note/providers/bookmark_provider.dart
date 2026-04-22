import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../repository/local_bookmark_repository.dart';

final bookmarkProvider =
    AsyncNotifierProvider<BookmarkNotifier, Set<String>>(BookmarkNotifier.new);

class BookmarkNotifier extends AsyncNotifier<Set<String>> {
  final _repo = LocalBookmarkRepository();

  @override
  Future<Set<String>> build() => _repo.loadAll();

  Future<void> toggle(String eraId, int no) async {
    final key = LocalBookmarkRepository.storageKey(eraId, no);
    final current = await future;
    if (current.contains(key)) {
      await _repo.remove(key);
      state = AsyncData(Set.from(current)..remove(key));
    } else {
      await _repo.add(key);
      state = AsyncData({...current, key});
    }
  }
}

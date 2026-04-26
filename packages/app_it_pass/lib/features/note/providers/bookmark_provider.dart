import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../repository/local_bookmark_repository.dart';

part 'bookmark_provider.g.dart';

@Riverpod(keepAlive: true)
class BookmarkNotifier extends _$BookmarkNotifier {
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

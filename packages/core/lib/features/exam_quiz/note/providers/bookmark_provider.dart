import 'package:core/config/brand/brand_config.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../repository/local_bookmark_repository.dart';

part 'bookmark_provider.g.dart';

@Riverpod(keepAlive: true)
class BookmarkNotifier extends _$BookmarkNotifier {
  late final LocalBookmarkRepository _repo;

  @override
  Future<Set<String>> build() {
    final prefix = ref.watch(brandConfigProvider).analyticsBrandKey;
    _repo = LocalBookmarkRepository(prefsPrefix: prefix);
    return _repo.loadAll();
  }

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

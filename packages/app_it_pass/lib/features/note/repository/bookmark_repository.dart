abstract class BookmarkRepository {
  Future<Set<String>> loadAll();
  Future<void> add(String key);
  Future<void> remove(String key);
}

import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import 'bookmark_repository.dart';

class LocalBookmarkRepository implements BookmarkRepository {
  static const _prefsKey = 'it_pass_bookmarks_v1';

  static String storageKey(String eraId, int no) => '${eraId}_$no';

  @override
  Future<Set<String>> loadAll() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_prefsKey);
    if (raw == null || raw.isEmpty) return {};
    final list = jsonDecode(raw) as List<dynamic>;
    return list.map((e) => e as String).toSet();
  }

  @override
  Future<void> add(String key) async {
    final all = await loadAll();
    all.add(key);
    await _save(all);
  }

  @override
  Future<void> remove(String key) async {
    final all = await loadAll();
    all.remove(key);
    await _save(all);
  }

  Future<void> _save(Set<String> bookmarks) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefsKey, jsonEncode(bookmarks.toList()));
  }

  Future<void> saveAll(Set<String> bookmarks) => _save(bookmarks);
}

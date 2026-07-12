import 'dart:convert';

import 'package:core/config/brand/brand_config.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../model/quiz_history_record.dart';

part 'local_quiz_history_repository.g.dart';

class LocalQuizHistoryRepository {
  LocalQuizHistoryRepository({required String prefsPrefix})
      : _prefix = prefsPrefix;

  final String _prefix;

  String get _prefsKey => '${_prefix}_quiz_history_v1';
  static const defaultDisplayLimit = 50;

  Future<void> saveAnswer({
    required String eraId,
    required int no,
    required String selectedLabel,
    required bool isCorrect,
    required DateTime answeredAt,
  }) async {
    final all = await loadAll();
    all.add(QuizHistoryRecord(
      eraId: eraId,
      no: no,
      selectedLabel: selectedLabel,
      isCorrect: isCorrect,
      answeredAt: answeredAt,
    ));
    await _saveAll(all);
  }

  Future<List<QuizHistoryRecord>> loadRecent({
    int limit = defaultDisplayLimit,
  }) async {
    final all = await loadAll();
    all.sort((a, b) => b.answeredAt.compareTo(a.answeredAt));
    return all.take(limit).toList();
  }

  Future<void> deleteAll() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_prefsKey);
  }

  Future<List<QuizHistoryRecord>> loadAll() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_prefsKey);
    if (raw == null || raw.isEmpty) return [];
    try {
      final list = jsonDecode(raw) as List<dynamic>;
      return list
          .cast<Map<String, dynamic>>()
          .map(QuizHistoryRecord.fromJson)
          .toList();
    } on Object {
      return [];
    }
  }

  Future<void> _saveAll(List<QuizHistoryRecord> records) async {
    final prefs = await SharedPreferences.getInstance();
    final encoded = jsonEncode(records.map((r) => r.toJson()).toList());
    await prefs.setString(_prefsKey, encoded);
  }
}

@Riverpod(keepAlive: true)
LocalQuizHistoryRepository localQuizHistoryRepository(Ref ref) {
  final prefix = ref.watch(brandConfigProvider).analyticsBrandKey;
  return LocalQuizHistoryRepository(prefsPrefix: prefix);
}

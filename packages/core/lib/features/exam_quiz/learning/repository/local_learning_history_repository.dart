import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../model/leitner_box.dart';
import '../model/question_learning_stats.dart';
import 'learning_history_repository.dart';

class LocalLearningHistoryRepository implements LearningHistoryRepository {
  LocalLearningHistoryRepository({required String prefsPrefix})
      : _prefix = prefsPrefix;

  final String _prefix;

  String get _prefsKey => '${_prefix}_learning_history_v1';

  static String storageKey(String eraId, int no) => '${eraId}_$no';

  @override
  Future<Map<String, QuestionLearningStats>> loadAll() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_prefsKey);
    if (raw == null || raw.isEmpty) return {};
    final decoded = jsonDecode(raw) as Map<String, dynamic>;
    return decoded.map(
      (k, v) =>
          MapEntry(k, QuestionLearningStats.fromJson(v as Map<String, dynamic>)),
    );
  }

  Future<void> _save(Map<String, QuestionLearningStats> map) async {
    final prefs = await SharedPreferences.getInstance();
    final encoded = jsonEncode(map.map((k, v) => MapEntry(k, v.toJson())));
    await prefs.setString(_prefsKey, encoded);
  }

  Future<void> saveAll(Map<String, QuestionLearningStats> map) => _save(map);

  @override
  Future<void> deleteAll() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_prefsKey);
  }

  @override
  Future<void> recordAnswer({
    required String eraId,
    required int no,
    required bool isCorrect,
    required DateTime at,
    required String selectedLabel,
  }) async {
    final key = storageKey(eraId, no);
    final all = await loadAll();
    final prev = all[key] ?? const QuestionLearningStats();
    final nextBox = advance(prev.box ?? (prev.correctCount + prev.wrongCount == 0 ? null : boxFromLegacyStats(prev)), isCorrect: isCorrect);
    final next = prev.copyWith(
      correctCount: prev.correctCount + (isCorrect ? 1 : 0),
      wrongCount: prev.wrongCount + (isCorrect ? 0 : 1),
      lastAnsweredAt: at,
      lastWasCorrect: isCorrect,
      lastSelectedLabel: selectedLabel,
      box: nextBox,
    );
    all[key] = next;
    await _save(all);
  }
}

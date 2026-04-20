import 'dart:convert';

import 'package:anki_games/apps/it_pass/features/learning/model/question_learning_stats.dart';
import 'package:anki_games/apps/it_pass/features/learning/repository/learning_history_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LocalLearningHistoryRepository implements LearningHistoryRepository {
  static const _prefsKey = 'it_pass_learning_history_v1';

  static String storageKey(String eraId, int no) => '${eraId}_$no';

  @override
  Future<Map<String, QuestionLearningStats>> loadAll() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_prefsKey);
    if (raw == null || raw.isEmpty) {
      return {};
    }
    final decoded = jsonDecode(raw) as Map<String, dynamic>;
    return decoded.map(
      (k, v) => MapEntry(
        k,
        QuestionLearningStats.fromJson(v as Map<String, dynamic>),
      ),
    );
  }

  Future<void> _save(Map<String, QuestionLearningStats> map) async {
    final prefs = await SharedPreferences.getInstance();
    final encoded = jsonEncode(
      map.map((k, v) => MapEntry(k, v.toJson())),
    );
    await prefs.setString(_prefsKey, encoded);
  }

  @override
  Future<void> recordAnswer({
    required String eraId,
    required int no,
    required bool isCorrect,
    required DateTime at,
  }) async {
    final key = storageKey(eraId, no);
    final all = await loadAll();
    final prev = all[key] ?? const QuestionLearningStats();
    final next = prev.copyWith(
      correctCount: prev.correctCount + (isCorrect ? 1 : 0),
      wrongCount: prev.wrongCount + (isCorrect ? 0 : 1),
      lastAnsweredAt: at,
      lastWasCorrect: isCorrect,
    );
    all[key] = next;
    await _save(all);
  }
}

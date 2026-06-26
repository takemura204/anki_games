import 'dart:convert';

import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../model/daily_study_log.dart';

part 'local_daily_study_log_repository.g.dart';

class LocalDailyStudyLogRepository {
  static const _prefsKey = 'daily_study_log_v1';

  Future<List<DailyStudyLog>> loadAll() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_prefsKey);
    if (raw == null || raw.isEmpty) return [];
    try {
      final list = jsonDecode(raw) as List<dynamic>;
      return list
          .cast<Map<String, dynamic>>()
          .map(DailyStudyLog.fromJson)
          .toList();
    } on Object {
      return [];
    }
  }

  Future<DailyStudyLog> loadToday() async {
    final date = todayKey();
    final all = await loadAll();
    return all.firstWhere(
      (l) => l.date == date,
      orElse: () => DailyStudyLog(date: date),
    );
  }

  Future<void> addStudySeconds(int seconds) async {
    if (seconds <= 0) return;
    await _updateToday(
      (log) => log.copyWith(studySeconds: log.studySeconds + seconds),
    );
  }

  Future<void> incrementNewReview() async {
    await _updateToday(
      (log) => log.copyWith(newReviewCount: log.newReviewCount + 1),
    );
  }

  Future<void> incrementAnswered({required bool isCorrect}) async {
    await _updateToday(
      (log) => log.copyWith(
        answeredCount: log.answeredCount + 1,
        correctCount: log.correctCount + (isCorrect ? 1 : 0),
      ),
    );
  }

  Future<void> _updateToday(DailyStudyLog Function(DailyStudyLog) update) async {
    final date = todayKey();
    final all = await loadAll();
    final idx = all.indexWhere((l) => l.date == date);
    if (idx < 0) {
      all.add(update(DailyStudyLog(date: date)));
    } else {
      all[idx] = update(all[idx]);
    }
    await _saveAll(all);
  }

  Future<void> saveAll(List<DailyStudyLog> logs) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _prefsKey,
      jsonEncode(logs.map((l) => l.toJson()).toList()),
    );
  }

  Future<void> _saveAll(List<DailyStudyLog> logs) => saveAll(logs);

  static String todayKey() {
    final now = DateTime.now();
    final y = now.year.toString();
    final m = now.month.toString().padLeft(2, '0');
    final d = now.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }
}

@Riverpod(keepAlive: true)
LocalDailyStudyLogRepository localDailyStudyLogRepository(Ref ref) =>
    LocalDailyStudyLogRepository();

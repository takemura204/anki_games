import 'dart:math' show min;

import 'package:flutter/material.dart' show DateUtils;
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../daily_study_log/repository/local_daily_study_log_repository.dart';
import '../../learning/repository/local_learning_history_repository.dart';
import '../../note/repository/local_quiz_history_repository.dart';
import '../model/report_stats.dart';

final reportStatsProvider = FutureProvider<ReportStats>((ref) async {
  final historyRepo = LocalQuizHistoryRepository();
  final dailyLogRepo = LocalDailyStudyLogRepository();

  final learningStats = await LocalLearningHistoryRepository().loadAll();

  final (allHistory, allLogs) = await (
    historyRepo.loadAll(),
    dailyLogRepo.loadAll(),
  ).wait;

  final today = DateUtils.dateOnly(DateTime.now());
  final todayKey = LocalDailyStudyLogRepository.todayKey();

  final todayHistory =
      allHistory.where((r) => DateUtils.dateOnly(r.answeredAt) == today);
  final todayLog = allLogs.where((l) => l.date == todayKey).firstOrNull;

  final answeredByDate = <String, int>{};
  final correctByDate = <String, int>{};
  for (final r in allHistory) {
    final key = _dateKey(DateUtils.dateOnly(r.answeredAt));
    answeredByDate[key] = (answeredByDate[key] ?? 0) + 1;
    if (r.isCorrect) {
      correctByDate[key] = (correctByDate[key] ?? 0) + 1;
    }
  }

  final allDateKeys = {
    ...allLogs.map((l) => l.date),
    ...answeredByDate.keys,
  };
  const kMaxDays = 30;
  final int kDays;
  if (allDateKeys.isEmpty) {
    kDays = 1;
  } else {
    final sorted = allDateKeys.toList()..sort();
    final earliest = DateTime.parse(sorted.first);
    kDays = min(today.difference(earliest).inDays + 1, kMaxDays);
  }

  final logByDate = {for (final l in allLogs) l.date: l};

  List<double> daily(double Function(String key) getValue) =>
      List<double>.generate(kDays, (i) {
        final date = today.subtract(Duration(days: kDays - 1 - i));
        return getValue(_dateKey(date));
      });

  return ReportStats(
    totalAnswered: allHistory.length,
    todayAnswered: todayHistory.length,
    totalCorrect: allHistory.where((r) => r.isCorrect).length,
    todayCorrect: todayHistory.where((r) => r.isCorrect).length,
    reviewCount: learningStats.values.where((s) => s.wrongCount > 0).length,
    todayNewReview: todayLog?.newReviewCount ?? 0,
    totalStudySec: allLogs.fold(0, (s, l) => s + l.studySeconds),
    todayStudySec: todayLog?.studySeconds ?? 0,
    studyTimeDaily: daily((k) => (logByDate[k]?.studySeconds ?? 0) / 60.0),
    answeredDaily: daily((k) => (answeredByDate[k] ?? 0).toDouble()),
    correctDaily: daily((k) => (correctByDate[k] ?? 0).toDouble()),
    newReviewDaily:
        daily((k) => (logByDate[k]?.newReviewCount ?? 0).toDouble()),
  );
});

String _dateKey(DateTime date) =>
    '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

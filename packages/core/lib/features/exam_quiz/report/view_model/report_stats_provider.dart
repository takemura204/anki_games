import 'dart:math' show min;

import 'package:core/features/exam_quiz/daily_study_log/repository/local_daily_study_log_repository.dart';
import 'package:core/features/exam_quiz/learning/providers/learning_history_provider.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../model/report_stats.dart';

part 'report_stats_provider.g.dart';

@riverpod
Future<ReportStats> reportStats(Ref ref) async {
  final dailyLogRepo = LocalDailyStudyLogRepository();

  final learningStats =
      await ref.watch(learningHistoryRepositoryProvider.future).then((r) => r.loadAll());

  final allLogs = await dailyLogRepo.loadAll();

  final today = DateTime.now();
  final todayKey = LocalDailyStudyLogRepository.todayKey();
  final todayLog = allLogs.where((l) => l.date == todayKey).firstOrNull;

  const kMaxDays = 30;
  final int kDays;
  if (allLogs.isEmpty) {
    kDays = 1;
  } else {
    final sorted = allLogs.map((l) => l.date).toList()..sort();
    final earliest = DateTime.parse(sorted.first);
    kDays = min(
      DateTime(today.year, today.month, today.day)
              .difference(earliest)
              .inDays +
          1,
      kMaxDays,
    );
  }

  final logByDate = {for (final l in allLogs) l.date: l};

  List<double> daily(double Function(String key) getValue) =>
      List<double>.generate(kDays, (i) {
        final date = DateTime(today.year, today.month, today.day)
            .subtract(Duration(days: kDays - 1 - i));
        return getValue(_dateKey(date));
      });

  return ReportStats(
    totalAnswered: allLogs.fold(0, (s, l) => s + l.answeredCount),
    todayAnswered: todayLog?.answeredCount ?? 0,
    totalCorrect: allLogs.fold(0, (s, l) => s + l.correctCount),
    todayCorrect: todayLog?.correctCount ?? 0,
    reviewCount: learningStats.values.where((s) => s.wrongCount > 0).length,
    todayNewReview: todayLog?.newReviewCount ?? 0,
    totalStudySec: allLogs.fold(0, (s, l) => s + l.studySeconds),
    todayStudySec: todayLog?.studySeconds ?? 0,
    studyTimeDaily: daily((k) => (logByDate[k]?.studySeconds ?? 0) / 60.0),
    answeredDaily: daily((k) => (logByDate[k]?.answeredCount ?? 0).toDouble()),
    correctDaily: daily((k) => (logByDate[k]?.correctCount ?? 0).toDouble()),
    newReviewDaily:
        daily((k) => (logByDate[k]?.newReviewCount ?? 0).toDouble()),
  );
}

String _dateKey(DateTime date) =>
    '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

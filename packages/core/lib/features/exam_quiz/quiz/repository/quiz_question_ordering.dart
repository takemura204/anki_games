import 'dart:math';

import 'package:core/features/exam_quiz/filter/model/quiz_filter.dart';
import 'package:core/features/exam_quiz/filter/model/quiz_order_mode.dart';
import 'package:core/features/exam_quiz/learning/model/leitner_box.dart';
import 'package:core/features/exam_quiz/learning/model/question_learning_stats.dart';
import 'package:core/features/exam_quiz/learning/repository/local_learning_history_repository.dart';
import 'package:core/features/exam_quiz/model/question.dart';

class QuizQuestionOrdering {
  QuizQuestionOrdering._();

  static List<Question> apply(
    List<Question> filtered,
    QuizFilter filter,
    Map<String, QuestionLearningStats> stats, {
    required List<String> eraIdOrder,
    DateTime? now,
  }) {
    switch (filter.quizOrderMode) {
      case QuizOrderMode.sequential:
        return _sequential(filtered, eraIdOrder);
      case QuizOrderMode.random:
        return _random(filtered);
      case QuizOrderMode.optimized:
        return _optimized(filtered, stats, now: now ?? DateTime.now());
    }
  }

  static List<Question> _sequential(
    List<Question> questions,
    List<String> eraIdOrder,
  ) {
    final index = <String, int>{
      for (var i = 0; i < eraIdOrder.length; i++) eraIdOrder[i]: i,
    };
    final sorted = [...questions]..sort((a, b) {
        final ai = index[a.eraId] ?? 0;
        final bi = index[b.eraId] ?? 0;
        final c = ai.compareTo(bi);
        if (c != 0) return c;
        return a.no.compareTo(b.no);
      });
    return sorted;
  }

  static List<Question> _random(List<Question> questions) {
    return [...questions]..shuffle(Random());
  }

  /// due ベースの優先順:
  ///   1. 復習期限到来(due): 箱番号が小さいほど上、同箱は超過日数が大きいほど上
  ///   2. 未学習(unseen)
  ///   3. 期限外: 期限が近いほど上（埋め草）
  /// 同点は乱数でシャッフル。
  static List<Question> _optimized(
    List<Question> questions,
    Map<String, QuestionLearningStats> stats, {
    required DateTime now,
  }) {
    final rnd = Random();

    // 優先度を (group, tiebreaker, noise) で表現してソートする。
    // group: 0=due, 1=unseen, 2=not-yet-due (小さいほど高優先)
    final scored = <({Question q, int group, double secondary, double noise})>[
      for (final q in questions)
        () {
          final key = LocalLearningHistoryRepository.storageKey(q.eraId, q.no);
          final s = stats[key];
          if (s == null || s.correctCount + s.wrongCount == 0) {
            return (q: q, group: 1, secondary: 0.0, noise: rnd.nextDouble());
          }
          final box = resolvedBox(s);
          final last = s.lastAnsweredAt;
          if (last == null) {
            return (q: q, group: 1, secondary: 0.0, noise: rnd.nextDouble());
          }
          final due = dueAt(box, last);
          if (!now.isBefore(due)) {
            // 期限到来: 箱が小さい(苦手寄り)ほど優先、同じ箱は超過日数が大きいほど優先
            final overdueDays = now.difference(due).inDays.toDouble();
            return (
              q: q,
              group: 0,
              secondary: box * 1000.0 - overdueDays, // 小さいほど優先
              noise: rnd.nextDouble(),
            );
          } else {
            // 期限外: 期限が近いほど優先
            final daysUntilDue = due.difference(now).inDays.toDouble();
            return (q: q, group: 2, secondary: daysUntilDue, noise: rnd.nextDouble());
          }
        }(),
    ]..sort((a, b) {
        final gc = a.group.compareTo(b.group);
        if (gc != 0) return gc;
        final sc = a.secondary.compareTo(b.secondary);
        if (sc != 0) return sc;
        return a.noise.compareTo(b.noise);
      });

    return scored.map((e) => e.q).toList();
  }
}

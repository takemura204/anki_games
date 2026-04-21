import 'dart:math';

import '../../filter/model/quiz_filter.dart';
import '../../filter/model/quiz_order_mode.dart';
import '../../learning/model/question_learning_stats.dart';
import '../../learning/repository/local_learning_history_repository.dart';
import '../model/exam_meta.dart';
import '../model/question.dart';

/// 試験対策向け重み付き出題の係数（調整しやすいようここに集約）
const _kBase = 1.0;
const _kUnseenBoost = 4.0;
const _kPerWrong = 1.5;
const _kPerCorrect = -0.35;
const _kDaysCap = 30;
const _kPerDay = 0.08;
const _kLastWrongBoost = 2.0;

class QuizQuestionOrdering {
  QuizQuestionOrdering._();

  static final _eraOrderIndex = <String, int>{
    for (var i = 0; i < ExamMeta.all.length; i++) ExamMeta.all[i].eraId: i,
  };

  static List<Question> apply(
    List<Question> filtered,
    QuizFilter filter,
    Map<String, QuestionLearningStats> stats,
  ) {
    switch (filter.quizOrderMode) {
      case QuizOrderMode.sequential:
        return _sequential(filtered);
      case QuizOrderMode.random:
        return _random(filtered);
      case QuizOrderMode.optimized:
        return _weighted(filtered, stats);
    }
  }

  static List<Question> _sequential(List<Question> questions) {
    final sorted = [...questions]..sort((a, b) {
        final ai = _eraOrderIndex[a.eraId] ?? 0;
        final bi = _eraOrderIndex[b.eraId] ?? 0;
        final c = ai.compareTo(bi);
        if (c != 0) {
          return c;
        }
        return a.no.compareTo(b.no);
      });
    return sorted;
  }

  static List<Question> _random(List<Question> questions) {
    final list = [...questions]..shuffle(Random());
    return list;
  }

  static double _priority(
    Question q,
    Map<String, QuestionLearningStats> stats,
  ) {
    final key = LocalLearningHistoryRepository.storageKey(q.eraId, q.no);
    final s = stats[key];
    if (s == null) {
      return _kBase + _kUnseenBoost;
    }
    var p = _kBase;
    p += s.wrongCount * _kPerWrong;
    p += s.correctCount * _kPerCorrect;
    final last = s.lastAnsweredAt;
    final dayCount = last == null
        ? _kDaysCap
        : DateTime.now().difference(last).inDays.clamp(0, _kDaysCap);
    p += dayCount * _kPerDay;
    if (s.lastWasCorrect == false) {
      p += _kLastWrongBoost;
    }
    return p;
  }

  static List<Question> _weighted(
    List<Question> questions,
    Map<String, QuestionLearningStats> stats,
  ) {
    final rnd = Random();
    final scored = <({Question q, double pr, double tie})>[
      for (final q in questions)
        (
          q: q,
          pr: _priority(q, stats),
          tie: rnd.nextDouble(),
        ),
    ]..sort((a, b) {
        final c = b.pr.compareTo(a.pr);
        if (c != 0) {
          return c;
        }
        return a.tie.compareTo(b.tie);
      });
    return scored.map((e) => e.q).toList();
  }
}

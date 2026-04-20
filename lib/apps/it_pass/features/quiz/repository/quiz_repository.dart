import 'dart:convert';

import 'package:anki_games/apps/it_pass/features/filter/model/quiz_filter.dart';
import 'package:anki_games/apps/it_pass/features/learning/model/learning_level.dart';
import 'package:anki_games/apps/it_pass/features/learning/model/question_learning_stats.dart';
import 'package:anki_games/apps/it_pass/features/learning/repository/local_learning_history_repository.dart';
import 'package:anki_games/apps/it_pass/features/quiz/model/exam_meta.dart';
import 'package:anki_games/apps/it_pass/features/quiz/model/question.dart';
import 'package:anki_games/apps/it_pass/features/quiz/services/quiz_question_ordering.dart';
import 'package:flutter/services.dart';

class QuizRepository {
  /// 1 セッションあたりの最大出題数（それ以下なら全件）
  static const maxQuestionsPerSession = 10;

  /// 出題順を適用する前の、条件一致問題一覧（件数検証用にも使う）
  Future<List<Question>> loadFilteredQuestions(
    QuizFilter filter,
    Map<String, QuestionLearningStats> learningStats,
  ) async {
    final all = <Question>[];

    for (final meta in ExamMeta.all) {
      if (!filter.selectedEraIds.contains(meta.eraId)) {
        continue;
      }
      final raw = await rootBundle.loadString(meta.assetPath);
      final json = jsonDecode(raw) as Map<String, dynamic>;
      final questions = (json['questions'] as List<dynamic>)
          .map(
            (e) => Question.fromJson(
              e as Map<String, dynamic>,
              eraId: meta.eraId,
              examDisplayName: meta.displayName,
            ),
          )
          .toList();
      all.addAll(questions);
    }

    var filtered = all.where((q) {
      if (filter.selectedSystems.isNotEmpty &&
          !filter.selectedSystems.contains(q.system)) {
        return false;
      }
      if (filter.selectedMajors.isNotEmpty &&
          !filter.selectedMajors.contains(q.major)) {
        return false;
      }
      return true;
    }).toList();

    if (filter.selectedLearningLevels.isNotEmpty) {
      filtered = filtered.where((q) {
        final key = LocalLearningHistoryRepository.storageKey(q.eraId, q.no);
        final level = LearningLevel.fromStats(learningStats[key]);
        return filter.selectedLearningLevels.contains(level);
      }).toList();
    }

    return filtered;
  }

  Future<List<Question>> loadSession(
    QuizFilter filter,
    Map<String, QuestionLearningStats> learningStats,
  ) async {
    final filtered = await loadFilteredQuestions(filter, learningStats);
    final ordered =
        QuizQuestionOrdering.apply(filtered, filter, learningStats);
    if (ordered.length <= maxQuestionsPerSession) {
      return ordered;
    }
    return ordered.sublist(0, maxQuestionsPerSession);
  }
}

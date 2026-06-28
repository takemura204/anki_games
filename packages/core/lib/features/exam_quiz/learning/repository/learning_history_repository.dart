import '../model/question_learning_stats.dart';

abstract class LearningHistoryRepository {
  Future<Map<String, QuestionLearningStats>> loadAll();

  Future<void> recordAnswer({
    required String eraId,
    required int no,
    required bool isCorrect,
    required DateTime at,
    required String selectedLabel,
  });

  Future<void> deleteAll();
}

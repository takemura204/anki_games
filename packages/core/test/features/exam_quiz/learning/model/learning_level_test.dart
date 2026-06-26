import 'package:core/features/exam_quiz/learning/model/learning_level.dart';
import 'package:core/features/exam_quiz/learning/model/question_learning_stats.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('LearningLevel.fromStats', () {
    test('null のとき unseen を返す', () {
      expect(LearningLevel.fromStats(null), LearningLevel.unseen);
    });

    test('試行回数 0 のとき unseen を返す', () {
      const stats = QuestionLearningStats();
      expect(LearningLevel.fromStats(stats), LearningLevel.unseen);
    });

    test('誤答 > 正答のとき weak を返す', () {
      const stats = QuestionLearningStats(correctCount: 1, wrongCount: 3);
      expect(LearningLevel.fromStats(stats), LearningLevel.weak);
    });

    test('誤答 = 正答のとき weak にならない（fuzzy 以上）', () {
      const stats = QuestionLearningStats(correctCount: 2, wrongCount: 2);
      expect(LearningLevel.fromStats(stats), isNot(LearningLevel.weak));
    });

    test('4回以上・正答率85%以上・直前正解のとき mastered を返す', () {
      const stats = QuestionLearningStats(
        correctCount: 4,
        lastWasCorrect: true,
      );
      expect(LearningLevel.fromStats(stats), LearningLevel.mastered);
    });

    test('4回以上・正答率85%以上でも直前不正解なら mastered にならない', () {
      const stats = QuestionLearningStats(
        correctCount: 4,
        lastWasCorrect: false,
      );
      expect(LearningLevel.fromStats(stats), isNot(LearningLevel.mastered));
    });

    test('試行回数が3回以下では mastered にならない', () {
      const stats = QuestionLearningStats(
        correctCount: 3,
        lastWasCorrect: true,
      );
      expect(LearningLevel.fromStats(stats), isNot(LearningLevel.mastered));
    });

    test('正答率 65% 以上・正答 > 誤答のとき familiar を返す', () {
      // correctCount=3, wrongCount=1 → acc=0.75
      const stats = QuestionLearningStats(correctCount: 3, wrongCount: 1);
      expect(LearningLevel.fromStats(stats), LearningLevel.familiar);
    });

    test('mastered 条件を満たさず familiar にも届かないとき fuzzy を返す', () {
      // correctCount=1, wrongCount=1 → acc=0.5 < 0.65
      const stats = QuestionLearningStats(correctCount: 1, wrongCount: 1);
      expect(LearningLevel.fromStats(stats), LearningLevel.fuzzy);
    });
  });
}

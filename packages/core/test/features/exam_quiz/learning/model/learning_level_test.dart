import 'package:core/features/exam_quiz/learning/model/learning_level.dart';
import 'package:core/features/exam_quiz/learning/model/question_learning_stats.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('LearningLevel.fromBox', () {
    test('box1 → weak', () {
      expect(LearningLevel.fromBox(1), LearningLevel.weak);
    });

    test('box2 → fuzzy', () {
      expect(LearningLevel.fromBox(2), LearningLevel.fuzzy);
    });

    test('box3 → familiar', () {
      expect(LearningLevel.fromBox(3), LearningLevel.familiar);
    });

    test('box4 → mastered', () {
      expect(LearningLevel.fromBox(4), LearningLevel.mastered);
    });
  });

  group('LearningLevel.fromStats', () {
    test('null → unseen', () {
      expect(LearningLevel.fromStats(null), LearningLevel.unseen);
    });

    test('試行回数 0 → unseen', () {
      const stats = QuestionLearningStats();
      expect(LearningLevel.fromStats(stats), LearningLevel.unseen);
    });

    test('box フィールドあり → box から導出', () {
      const stats = QuestionLearningStats(correctCount: 1, box: 3);
      expect(LearningLevel.fromStats(stats), LearningLevel.familiar);
    });

    test('box なし・旧データ → legacyStats から推定(誤答多 → weak)', () {
      const stats = QuestionLearningStats(correctCount: 1, wrongCount: 3);
      expect(LearningLevel.fromStats(stats), LearningLevel.weak);
    });

    test('box なし・旧データ → legacyStats から推定(4回以上・高正答率・直前正解 → mastered)', () {
      const stats = QuestionLearningStats(
        correctCount: 4,
        lastWasCorrect: true,
      );
      expect(LearningLevel.fromStats(stats), LearningLevel.mastered);
    });

    test('box なし・旧データ → legacyStats から推定(正答率高 → familiar)', () {
      const stats = QuestionLearningStats(correctCount: 3, wrongCount: 1);
      expect(LearningLevel.fromStats(stats), LearningLevel.familiar);
    });

    test('box なし・旧データ → legacyStats から推定(中程度 → fuzzy)', () {
      const stats = QuestionLearningStats(correctCount: 1, wrongCount: 1);
      expect(LearningLevel.fromStats(stats), LearningLevel.fuzzy);
    });
  });
}

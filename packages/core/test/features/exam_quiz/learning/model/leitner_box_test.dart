import 'package:core/features/exam_quiz/learning/model/leitner_box.dart';
import 'package:core/features/exam_quiz/learning/model/question_learning_stats.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('advance', () {
    test('未学習から正解 → box2', () {
      expect(advance(null, isCorrect: true), 2);
    });

    test('未学習から不正解 → box1', () {
      expect(advance(null, isCorrect: false), 1);
    });

    test('正解で箱が +1 される', () {
      expect(advance(1, isCorrect: true), 2);
      expect(advance(2, isCorrect: true), 3);
      expect(advance(3, isCorrect: true), 4);
    });

    test('box4 で正解しても上限は box4', () {
      expect(advance(4, isCorrect: true), 4);
    });

    test('不正解で box1 にリセット', () {
      expect(advance(3, isCorrect: false), 1);
      expect(advance(4, isCorrect: false), 1);
    });
  });

  group('dueAt / isDue', () {
    final base = DateTime(2025, 1, 10);

    test('box1 は当日(0日後)が期限', () {
      expect(dueAt(1, base), base);
      expect(isDue(1, base, now: base), isTrue);
    });

    test('box2 は翌日が期限', () {
      expect(dueAt(2, base), DateTime(2025, 1, 11));
      expect(isDue(2, base, now: DateTime(2025, 1, 11)), isTrue);
      expect(isDue(2, base, now: DateTime(2025, 1, 10)), isFalse);
    });

    test('box3 は 3 日後が期限', () {
      expect(isDue(3, base, now: DateTime(2025, 1, 13)), isTrue);
      expect(isDue(3, base, now: DateTime(2025, 1, 12)), isFalse);
    });

    test('box4 は 7 日後が期限', () {
      expect(isDue(4, base, now: DateTime(2025, 1, 17)), isTrue);
      expect(isDue(4, base, now: DateTime(2025, 1, 16)), isFalse);
    });
  });

  group('boxFromLegacyStats', () {
    test('試行数 0 → box1', () {
      const stats = QuestionLearningStats();
      expect(boxFromLegacyStats(stats), 1);
    });

    test('誤答 > 正答 → box1(苦手)', () {
      const stats = QuestionLearningStats(correctCount: 1, wrongCount: 3);
      expect(boxFromLegacyStats(stats), 1);
    });

    test('4回以上・正答率85%以上・直前正解 → box4(完璧)', () {
      const stats = QuestionLearningStats(
        correctCount: 4,
        lastWasCorrect: true,
      );
      expect(boxFromLegacyStats(stats), 4);
    });

    test('正答率65%以上・正答>誤答 → box3(得意)', () {
      const stats = QuestionLearningStats(correctCount: 3, wrongCount: 1);
      expect(boxFromLegacyStats(stats), 3);
    });

    test('それ以外 → box2(うろ覚え)', () {
      const stats = QuestionLearningStats(correctCount: 1, wrongCount: 1);
      expect(boxFromLegacyStats(stats), 2);
    });
  });

  group('resolvedBox', () {
    test('box が設定されていればそのまま返す', () {
      const stats = QuestionLearningStats(
        correctCount: 1,
        wrongCount: 1,
        box: 3,
      );
      expect(resolvedBox(stats), 3);
    });

    test('box が null のとき旧データから推定', () {
      const stats = QuestionLearningStats(
        correctCount: 4,
        lastWasCorrect: true,
      );
      expect(resolvedBox(stats), 4);
    });
  });
}

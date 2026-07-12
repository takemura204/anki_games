import 'package:core/features/exam_quiz/learning/model/question_learning_stats.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('QuestionLearningStats.fromJson', () {
    test('全フィールドが正しくデシリアライズされる', () {
      final json = {
        'correctCount': 5,
        'wrongCount': 2,
        'lastAnsweredAt': '2026-06-01T10:00:00.000',
        'lastWasCorrect': true,
        'lastSelectedLabel': 'ア',
      };

      final stats = QuestionLearningStats.fromJson(json);

      expect(stats.correctCount, 5);
      expect(stats.wrongCount, 2);
      expect(stats.lastAnsweredAt, DateTime(2026, 6, 1, 10));
      expect(stats.lastWasCorrect, true);
      expect(stats.lastSelectedLabel, 'ア');
    });

    test('フィールドが null のとき安全にデフォルト値を返す', () {
      final stats = QuestionLearningStats.fromJson({});

      expect(stats.correctCount, 0);
      expect(stats.wrongCount, 0);
      expect(stats.lastAnsweredAt, isNull);
      expect(stats.lastWasCorrect, isNull);
      expect(stats.lastSelectedLabel, isNull);
    });

    test('不正な日付文字列のとき lastAnsweredAt が null になる', () {
      final json = {'lastAnsweredAt': 'not-a-date'};
      final stats = QuestionLearningStats.fromJson(json);

      expect(stats.lastAnsweredAt, isNull);
    });
  });

  group('QuestionLearningStats.toJson', () {
    test('fromJson → toJson のラウンドトリップで値が保持される', () {
      final original = QuestionLearningStats(
        correctCount: 3,
        wrongCount: 1,
        lastAnsweredAt: DateTime(2026, 6, 15, 9, 30),
        lastWasCorrect: false,
        lastSelectedLabel: 'イ',
      );

      final json = original.toJson();
      final restored = QuestionLearningStats.fromJson(json);

      expect(restored.correctCount, original.correctCount);
      expect(restored.wrongCount, original.wrongCount);
      expect(restored.lastAnsweredAt, original.lastAnsweredAt);
      expect(restored.lastWasCorrect, original.lastWasCorrect);
      expect(restored.lastSelectedLabel, original.lastSelectedLabel);
    });

    test('lastAnsweredAt が null のとき JSON の値も null になる', () {
      const stats = QuestionLearningStats();
      expect(stats.toJson()['lastAnsweredAt'], isNull);
    });
  });

  group('QuestionLearningStats.copyWith', () {
    test('指定したフィールドだけ上書きされる', () {
      const original = QuestionLearningStats(correctCount: 2, wrongCount: 1);

      final copied = original.copyWith(correctCount: 5);

      expect(copied.correctCount, 5);
      expect(copied.wrongCount, 1);
    });

    test('引数なしで呼ぶと全フィールドが保持される', () {
      final dt = DateTime(2026, 6);
      final original = QuestionLearningStats(
        correctCount: 4,
        wrongCount: 2,
        lastAnsweredAt: dt,
        lastWasCorrect: true,
        lastSelectedLabel: 'ウ',
      );

      final copied = original.copyWith();

      expect(copied.correctCount, original.correctCount);
      expect(copied.wrongCount, original.wrongCount);
      expect(copied.lastAnsweredAt, original.lastAnsweredAt);
      expect(copied.lastWasCorrect, original.lastWasCorrect);
      expect(copied.lastSelectedLabel, original.lastSelectedLabel);
    });
  });
}

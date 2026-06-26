import 'package:core/features/exam_quiz/filter/model/quiz_filter.dart';
import 'package:core/features/exam_quiz/filter/model/quiz_order_mode.dart';
import 'package:core/features/exam_quiz/learning/model/question_learning_stats.dart';
import 'package:core/features/exam_quiz/learning/repository/local_learning_history_repository.dart';
import 'package:core/features/exam_quiz/model/question.dart';
import 'package:core/features/exam_quiz/quiz/repository/quiz_question_ordering.dart';
import 'package:flutter_test/flutter_test.dart';

Question _q(String eraId, int no) => Question(
      eraId: eraId,
      no: no,
      title: '',
      body: const QuestionBody(text: '', subItems: [], images: []),
      choices: const [],
      answer: 'ア',
      explanationText: '',
      explanationImages: const [],
      explanationChoiceComments: const [],
      categoryRaw: '',
      system: '',
      major: '',
      minor: '',
    );

QuizFilter _filter(QuizOrderMode mode) => QuizFilter(
      selectedEraIds: const {'era1', 'era2'},
      quizOrderMode: mode,
    );

void main() {
  group('QuizQuestionOrdering', () {
    final questions = [
      _q('era2', 3),
      _q('era1', 2),
      _q('era1', 1),
      _q('era2', 1),
    ];
    const eraIdOrder = ['era1', 'era2'];

    group('sequential モード', () {
      test('eraIdOrder に従い年度昇順・問題番号昇順に並ぶ', () {
        final result = QuizQuestionOrdering.apply(
          questions,
          _filter(QuizOrderMode.sequential),
          {},
          eraIdOrder: eraIdOrder,
        );

        expect(result[0].eraId, 'era1');
        expect(result[0].no, 1);
        expect(result[1].eraId, 'era1');
        expect(result[1].no, 2);
        expect(result[2].eraId, 'era2');
        expect(result[2].no, 1);
        expect(result[3].eraId, 'era2');
        expect(result[3].no, 3);
      });

      test('入力リストを破壊しない（元の順序が変わらない）', () {
        final original = [...questions];
        QuizQuestionOrdering.apply(
          questions,
          _filter(QuizOrderMode.sequential),
          {},
          eraIdOrder: eraIdOrder,
        );
        expect(questions, original);
      });
    });

    group('random モード', () {
      test('要素数が変わらない', () {
        final result = QuizQuestionOrdering.apply(
          questions,
          _filter(QuizOrderMode.random),
          {},
          eraIdOrder: eraIdOrder,
        );
        expect(result.length, questions.length);
      });

      test('元のリストと同じ要素を含む', () {
        final result = QuizQuestionOrdering.apply(
          questions,
          _filter(QuizOrderMode.random),
          {},
          eraIdOrder: eraIdOrder,
        );
        for (final q in questions) {
          expect(result.any((r) => r.eraId == q.eraId && r.no == q.no), isTrue);
        }
      });
    });

    group('optimized モード — 優先度スコア', () {
      test('未学習（stats なし）が学習済みより高優先になる', () {
        final seen = _q('era1', 1);
        final unseen = _q('era1', 2);
        final stats = {
          LocalLearningHistoryRepository.storageKey('era1', 1):
              const QuestionLearningStats(correctCount: 3),
        };

        final result = QuizQuestionOrdering.apply(
          [seen, unseen],
          _filter(QuizOrderMode.optimized),
          stats,
          eraIdOrder: eraIdOrder,
        );

        expect(result.first.no, 2);
      });

      test('誤答が多い問題が正答が多い問題より高優先になる', () {
        final weak = _q('era1', 1);
        final strong = _q('era1', 2);
        final stats = {
          LocalLearningHistoryRepository.storageKey('era1', 1):
              const QuestionLearningStats(correctCount: 1, wrongCount: 5),
          LocalLearningHistoryRepository.storageKey('era1', 2):
              const QuestionLearningStats(correctCount: 5),
        };

        final result = QuizQuestionOrdering.apply(
          [strong, weak],
          _filter(QuizOrderMode.optimized),
          stats,
          eraIdOrder: eraIdOrder,
        );

        expect(result.first.no, 1);
      });

      test('直前の回答が不正解の問題がブーストされる', () {
        final lastWrong = _q('era1', 1);
        final lastCorrect = _q('era1', 2);
        final now = DateTime.now();
        final stats = {
          LocalLearningHistoryRepository.storageKey('era1', 1):
              QuestionLearningStats(
            correctCount: 2,
            wrongCount: 2,
            lastAnsweredAt: now,
            lastWasCorrect: false,
          ),
          LocalLearningHistoryRepository.storageKey('era1', 2):
              QuestionLearningStats(
            correctCount: 2,
            wrongCount: 2,
            lastAnsweredAt: now,
            lastWasCorrect: true,
          ),
        };

        final result = QuizQuestionOrdering.apply(
          [lastCorrect, lastWrong],
          _filter(QuizOrderMode.optimized),
          stats,
          eraIdOrder: eraIdOrder,
        );

        expect(result.first.no, 1);
      });

      test('要素数が変わらない', () {
        final result = QuizQuestionOrdering.apply(
          questions,
          _filter(QuizOrderMode.optimized),
          {},
          eraIdOrder: eraIdOrder,
        );
        expect(result.length, questions.length);
      });

      test('空リストを渡すと空リストが返る', () {
        final result = QuizQuestionOrdering.apply(
          [],
          _filter(QuizOrderMode.optimized),
          {},
          eraIdOrder: eraIdOrder,
        );
        expect(result, isEmpty);
      });
    });
  });
}

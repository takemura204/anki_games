import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../filter/repository/filter_repository.dart';
import '../../learning/providers/it_pass_learning_stats_provider.dart';
import '../../learning/repository/learning_history_repository.dart';
import '../../learning/repository/local_learning_history_repository.dart';
import '../model/quiz_session.dart';
import '../repository/quiz_repository.dart';

sealed class QuizState {
  const QuizState();
}

class QuizReady extends QuizState {
  const QuizReady(this.session);
  final QuizSession session;
}

class QuizError extends QuizState {
  const QuizError(this.message);
  final String message;
}

final AsyncNotifierProvider<QuizViewModel, QuizState> quizViewModelProvider =
    AsyncNotifierProvider.autoDispose<QuizViewModel, QuizState>(
  QuizViewModel.new,
);

class QuizViewModel extends AsyncNotifier<QuizState> {
  final _repository = QuizRepository();
  final _filterRepo = FilterRepository();
  final LearningHistoryRepository _learningRepo =
      LocalLearningHistoryRepository();

  @override
  Future<QuizState> build() async {
    try {
      // filter と learning stats を並列ロード
      final (filter, stats) = await (
        _filterRepo.load(),
        _learningRepo.loadAll(),
      ).wait;

      if (!filter.isValid) {
        return const QuizError('出題範囲が選択されていません');
      }
      final questions = await _repository.loadSession(filter, stats);
      if (questions.isEmpty) {
        return const QuizError('条件に合う問題がありません');
      }
      return QuizReady(QuizSession(
        questions: questions,
        setStartTime: DateTime.now(),
      ));
    } on Object catch (e, st) {
      if (kDebugMode) {
        debugPrint('[QuizViewModel] クイズ読み込みに失敗しました: $e');
        debugPrint('$st');
      }
      rethrow;
    }
  }

  Future<void> answer(String label) async {
    final current = state.value;
    if (current is! QuizReady) {
      return;
    }
    final session = current.session;
    if (session.isAnswered) {
      return;
    }

    final isCorrect = label == session.currentQuestion.answer;
    await HapticFeedback.mediumImpact();

    final q = session.currentQuestion;
    try {
      await _learningRepo.recordAnswer(
        eraId: q.eraId,
        no: q.no,
        isCorrect: isCorrect,
        at: DateTime.now(),
      );
    } on Object {
      // 履歴保存失敗でも解答表示は継続
    }

    final result = QuestionResult(
      question: q,
      isCorrect: isCorrect,
      selectedLabel: label,
    );

    state = AsyncData(
      QuizReady(
        session.copyWith(
          selectedLabel: label,
          answerState: isCorrect ? AnswerState.correct : AnswerState.incorrect,
          showExplanation: true,
          currentSetAnswers: [...session.currentSetAnswers, result],
        ),
      ),
    );
  }

  void nextQuestion() {
    final current = state.value;
    if (current is! QuizReady) {
      return;
    }
    final session = current.session;
    final nextIndex = session.currentIndex + 1;
    // 最後の問題の次はリザルトページへ遷移するため、インデックスは増やさない
    if (nextIndex >= session.totalCount) {
      return;
    }

    state = AsyncData(
      QuizReady(
        QuizSession(
          questions: session.questions,
          currentIndex: nextIndex,
          currentSetAnswers: session.currentSetAnswers,
          setStartTime: session.setStartTime,
        ),
      ),
    );
    ref.invalidate(itPassLearningStatsProvider);
  }
}

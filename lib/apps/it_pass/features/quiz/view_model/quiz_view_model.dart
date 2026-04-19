import 'package:anki_games/apps/it_pass/features/quiz/model/quiz_session.dart';
import 'package:anki_games/apps/it_pass/features/quiz/repository/filter_repository.dart';
import 'package:anki_games/apps/it_pass/features/quiz/repository/quiz_repository.dart';
import 'package:flutter/services.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

sealed class QuizState {
  const QuizState();
}

class QuizLoading extends QuizState {
  const QuizLoading();
}

class QuizReady extends QuizState {
  const QuizReady(this.session);
  final QuizSession session;
}

class QuizError extends QuizState {
  const QuizError(this.message);
  final String message;
}

final AutoDisposeAsyncNotifierProvider<QuizViewModel, QuizState>
    quizViewModelProvider =
    AsyncNotifierProvider.autoDispose<QuizViewModel, QuizState>(
  QuizViewModel.new,
);

class QuizViewModel extends AutoDisposeAsyncNotifier<QuizState> {
  final _repository = QuizRepository();
  final _filterRepo = FilterRepository();

  @override
  Future<QuizState> build() async {
    final filter = await _filterRepo.load();
    if (!filter.isValid) {
      return const QuizError('出題範囲が選択されていません');
    }
    final questions = await _repository.loadSession(filter);
    if (questions.isEmpty) {
      return const QuizError('条件に合う問題がありません');
    }
    return QuizReady(QuizSession(questions: questions));
  }

  void answer(String label) {
    final current = state.valueOrNull;
    if (current is! QuizReady) {
      return;
    }
    final session = current.session;
    if (session.isAnswered) {
      return;
    }

    final isCorrect = label == session.currentQuestion.answer;
    HapticFeedback.mediumImpact();

    state = AsyncData(
      QuizReady(
        session.copyWith(
          selectedLabel: label,
          answerState: isCorrect ? AnswerState.correct : AnswerState.incorrect,
          showExplanation: true,
        ),
      ),
    );
  }

  void nextQuestion() {
    final current = state.valueOrNull;
    if (current is! QuizReady) {
      return;
    }
    final session = current.session;
    final nextIndex = session.currentIndex + 1;

    if (nextIndex >= session.totalCount) {
      state = AsyncData(QuizReady(session.copyWith(isFinished: true)));
      return;
    }

    state = AsyncData(
      QuizReady(
        QuizSession(
          questions: session.questions,
          currentIndex: nextIndex,
        ),
      ),
    );
  }
}

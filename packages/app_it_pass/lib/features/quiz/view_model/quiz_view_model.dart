import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../daily_study_log/repository/local_daily_study_log_repository.dart';
import '../../filter/repository/filter_repository.dart';
import '../../learning/model/learning_level.dart';
import '../../learning/providers/it_pass_learning_stats_provider.dart';
import '../../learning/repository/learning_history_repository.dart';
import '../../learning/repository/local_learning_history_repository.dart';
import '../../note/repository/local_quiz_history_repository.dart';
import '../../streak/view_model/streak_view_model.dart';
import '../model/exam_meta.dart';
import '../model/quiz_session.dart';
import '../repository/quiz_repository.dart';
import '../../report/view_model/progress_dashboard_provider.dart';
import '../../report/view_model/report_stats_provider.dart';

part 'quiz_view_model.g.dart';

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

@riverpod
class QuizViewModel extends _$QuizViewModel {
  final _repository = QuizRepository();
  final _filterRepo = FilterRepository();
  final LearningHistoryRepository _learningRepo =
      LocalLearningHistoryRepository();
  final _quizHistoryRepo = LocalQuizHistoryRepository();
  final _dailyLogRepo = LocalDailyStudyLogRepository();

  /// 直前の解答時刻。解答ごとのギャップから学習時間を積算するために使用。
  DateTime? _lastAnswerTime;

  @override
  Future<QuizState> build() async {

    try {
      // filter と learning stats を並列ロード
      final (rawFilter, stats) = await (
        _filterRepo.load(),
        _learningRepo.loadAll(),
      ).wait;

      // 旧保存フィルター互換: 空の selectedSystems / selectedLearningLevels は全選択扱い
      final filter = rawFilter.copyWith(
        selectedSystems: rawFilter.selectedSystems.isEmpty
            ? ExamMeta.categoryTree.keys.toSet()
            : null,
        selectedMajors: rawFilter.selectedSystems.isEmpty
            ? ExamMeta.categoryTree.values.expand((m) => m).toSet()
            : null,
        selectedLearningLevels: rawFilter.selectedLearningLevels.isEmpty
            ? LearningLevel.values.toSet()
            : null,
      );

      if (!filter.isValid) {
        return const QuizError('出題範囲が選択されていません');
      }
      final allQuestions = await _repository.loadSession(filter, stats);
      if (allQuestions.isEmpty) {
        return const QuizError('条件に合う問題がありません');
      }
      return QuizReady(QuizSession(
        allQuestions: allQuestions,
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
    if (current is! QuizReady) return;
    final session = current.session;
    if (session.isAnswered) return;

    final isCorrect = label == session.currentQuestion.answer;
    await HapticFeedback.mediumImpact();

    final q = session.currentQuestion;
    final now = DateTime.now();

    // 直前の解答からのギャップ（5分以内）を学習時間として積算
    final last = _lastAnswerTime;
    if (last != null) {
      final gapSec = now.difference(last).inSeconds;
      if (gapSec > 0 && gapSec <= 300) {
        _dailyLogRepo.addStudySeconds(gapSec);
      }
    }
    _lastAnswerTime = now;

    // 今日初めて不正解になる問題かを解答記録前に判定
    final statsSnapshot = ref.read(itPassLearningStatsProvider).value ?? {};
    final statKey = LocalLearningHistoryRepository.storageKey(q.eraId, q.no);
    final isFirstWrong =
        !isCorrect && (statsSnapshot[statKey]?.wrongCount ?? 0) == 0;

    try {
      await Future.wait([
        _learningRepo.recordAnswer(
          eraId: q.eraId,
          no: q.no,
          isCorrect: isCorrect,
          at: now,
          selectedLabel: label,
        ),
        _quizHistoryRepo.saveAnswer(
          eraId: q.eraId,
          no: q.no,
          selectedLabel: label,
          isCorrect: isCorrect,
          answeredAt: now,
        ),
        ref.read(streakViewModelProvider.notifier).recordStudy(),
        // 不正解時は「覚えた」除外フラグを解除して復習リストに再登録させる
        if (!isCorrect) _learningRepo.unmarkMastered(q.eraId, q.no),
        if (isFirstWrong) _dailyLogRepo.incrementNewReview(),
      ]);
      ref.invalidate(reportStatsProvider);
      ref.invalidate(progressDashboardProvider);
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
    if (current is! QuizReady) return;
    final session = current.session;
    final nextIndex = session.currentIndex + 1;
    // 最後の問題の次はリザルトページへ遷移するため、インデックスは増やさない
    if (nextIndex >= session.totalCount) return;

    state = AsyncData(
      QuizReady(
        QuizSession(
          allQuestions: session.allQuestions,
          currentSetIndex: session.currentSetIndex,
          currentIndex: nextIndex,
          currentSetAnswers: session.currentSetAnswers,
          setStartTime: session.setStartTime,
        ),
      ),
    );
    ref.invalidate(itPassLearningStatsProvider);
  }

  /// 次のセット（10問）へ進む。[QuizSession.hasNextSet] が true のときのみ有効。
  void nextSet() {
    final current = state.value;
    if (current is! QuizReady) return;
    final session = current.session;
    if (!session.hasNextSet) return;

    state = AsyncData(
      QuizReady(
        QuizSession(
          allQuestions: session.allQuestions,
          currentSetIndex: session.currentSetIndex + 1,
          setStartTime: DateTime.now(),
        ),
      ),
    );
  }
}

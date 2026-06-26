import 'package:core/features/exam_quiz/auth/auth_user_provider.dart';
import 'package:core/features/exam_quiz/backup/service/backup_service.dart';
import 'package:core/features/exam_quiz/config/exam_config.dart';
import 'package:core/features/exam_quiz/daily_study_log/repository/local_daily_study_log_repository.dart';
import 'package:core/features/exam_quiz/filter/repository/filter_repository.dart';
import 'package:core/features/exam_quiz/learning/model/learning_level.dart';
import 'package:core/features/exam_quiz/learning/providers/it_pass_learning_stats_provider.dart';
import 'package:core/features/exam_quiz/learning/providers/learning_history_provider.dart';
import 'package:core/features/exam_quiz/learning/repository/learning_history_repository.dart';
import 'package:core/features/exam_quiz/learning/repository/local_learning_history_repository.dart'
    show LocalLearningHistoryRepository;
import 'package:core/features/exam_quiz/model/question.dart';
import 'package:core/features/exam_quiz/note/repository/local_quiz_history_repository.dart';
import 'package:core/features/exam_quiz/quiz/model/quiz_session.dart';
import 'package:core/features/exam_quiz/quiz/repository/quiz_repository.dart';
import 'package:core/features/exam_quiz/quiz/repository/quiz_resume_repository.dart';
import 'package:core/features/exam_quiz/quiz/sync/quiz_sync_notifier.dart';
import 'package:core/features/exam_quiz/report/view_model/progress_dashboard_provider.dart';
import 'package:core/features/exam_quiz/report/view_model/report_stats_provider.dart';
import 'package:core/features/exam_quiz/streak/view_model/streak_view_model.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'quiz_view_model.g.dart';

const _autoBackupInterval = 5;

sealed class QuizState {
  const QuizState();
}

class QuizReady extends QuizState {
  const QuizReady(this.session);
  final QuizSession session;
}

enum QuizErrorType {
  /// フィルターで出題範囲が未選択
  noFilter,

  /// フィルター条件に合う問題がない
  noQuestions,

  /// データ読み込み・解析に失敗
  loadFailed,
}

class QuizError extends QuizState {
  const QuizError(this.message, {this.type = QuizErrorType.loadFailed});
  final String message;
  final QuizErrorType type;
}

@riverpod
class QuizViewModel extends _$QuizViewModel {
  QuizRepository get _repository => ref.read(quizRepositoryProvider);
  FilterRepository get _filterRepo => ref.read(filterRepositoryProvider);
  LocalQuizHistoryRepository get _quizHistoryRepo =>
      ref.read(localQuizHistoryRepositoryProvider);
  LocalDailyStudyLogRepository get _dailyLogRepo =>
      ref.read(localDailyStudyLogRepositoryProvider);
  QuizResumeRepository get _resumeRepo => ref.read(quizResumeRepositoryProvider);

  LearningHistoryRepository get _learningRepo =>
      ref.read(learningHistoryRepositoryProvider).requireValue;

  int _answeredSinceLastBackup = 0;

  /// 現在のセッションで使用しているフィルターハッシュ。resume 保存時に付与。
  String? _currentFilterHash;

  @override
  Future<QuizState> build() async {
    try {
      // sync が完了するまで待つ（初回DL完了 or キャッシュあり即返却）
      final syncState = await ref.watch(quizSyncProvider.future);
      if (syncState is QuizSyncError) {
        return QuizError(syncState.message);
      }

      final examConfig = ref.watch(examConfigProvider);
      final allEraIds = examConfig.examList.map((m) => m.eraId).toSet();
      final learningRepo = await ref.watch(learningHistoryRepositoryProvider.future);
      // filter と learning stats を並列ロード
      final (rawFilter, stats) = await (
        _filterRepo.load(allEraIds: allEraIds),
        learningRepo.loadAll(),
      ).wait;

      // 旧保存フィルター互換: 空の selectedSystems / selectedLearningLevels は全選択扱い
      final filter = rawFilter.copyWith(
        selectedSystems: rawFilter.selectedSystems.isEmpty
            ? examConfig.categoryTree.keys.toSet()
            : null,
        selectedMajors: rawFilter.selectedSystems.isEmpty
            ? examConfig.categoryTree.values.expand((m) => m).toSet()
            : null,
        selectedLearningLevels: rawFilter.selectedLearningLevels.isEmpty
            ? LearningLevel.values.toSet()
            : null,
      );

      if (!filter.isValid) {
        return const QuizError(
          '出題範囲が選択されていません',
          type: QuizErrorType.noFilter,
        );
      }

      final allQuestions = await _repository.loadSession(
        filter,
        stats,
        examConfig: examConfig,
      );
      if (allQuestions.isEmpty) {
        return const QuizError(
          '条件に合う問題がありません',
          type: QuizErrorType.noQuestions,
        );
      }

      _currentFilterHash = filter.hash;

      // 前回の中断位置を復元できるか試みる
      final resumeData = await _resumeRepo.load();
      if (resumeData != null && resumeData.filterHash == filter.hash) {
        final restored = _tryRestore(allQuestions, resumeData);
        if (restored != null) return restored;
      }

      // フレッシュスタート: 先頭位置で保存
      _saveResume(
        questions: allQuestions,
        setIndex: 0,
        questionIndex: 0,
      );
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

  /// 保存された問題 ID 順で [allQuestions] を並べ直し、中断位置を復元する。
  /// フィルター変更などで一致しない場合は null を返す。
  QuizReady? _tryRestore(
    List<Question> allQuestions,
    QuizResumeData resumeData,
  ) {
    final questionMap = {
      for (final q in allQuestions) '${q.eraId}:${q.no}': q,
    };

    final restored = <Question>[];
    for (final id in resumeData.questionIds) {
      final q = questionMap[id];
      if (q == null) return null; // フィルター変更で問題が除外された
      restored.add(q);
    }

    final setStart = resumeData.setIndex * QuizSession.setSize;
    final setEnd = ((resumeData.setIndex + 1) * QuizSession.setSize)
        .clamp(0, restored.length);
    if (setStart >= restored.length) return null;
    if (resumeData.questionIndex < 0 ||
        resumeData.questionIndex >= setEnd - setStart) {
      return null;
    }

    return QuizReady(
      QuizSession(
        allQuestions: restored,
        currentSetIndex: resumeData.setIndex,
        currentIndex: resumeData.questionIndex,
        setStartTime: DateTime.now(),
      ),
    );
  }

  /// 現在の中断位置を SharedPreferences に非同期で保存する（fire-and-forget）。
  void _saveResume({
    required List<Question> questions,
    required int setIndex,
    required int questionIndex,
  }) {
    final hash = _currentFilterHash;
    if (hash == null) return;
    final ids = questions.map((q) => '${q.eraId}:${q.no}').toList();
    _resumeRepo
        .save(
          setIndex: setIndex,
          questionIndex: questionIndex,
          questionIds: ids,
          filterHash: hash,
        )
        .ignore();
  }

  /// セッション完了時に resume データを削除する（SessionEnd ページ到達時に呼ぶ）。
  Future<void> clearResume() => _resumeRepo.clear();

  Future<void> answer(String label) async {
    final current = state.value;
    if (current is! QuizReady) return;
    final session = current.session;
    if (session.isAnswered) return;

    final isCorrect = label == session.currentQuestion.answer;
    final q = session.currentQuestion;
    final now = DateTime.now();

    final statsSnapshot = ref.read(itPassLearningStatsProvider).value ?? {};
    final statKey = LocalLearningHistoryRepository.storageKey(q.eraId, q.no);
    final isFirstWrong =
        !isCorrect && (statsSnapshot[statKey]?.wrongCount ?? 0) == 0;

    final result = QuestionResult(
      question: q,
      isCorrect: isCorrect,
      selectedLabel: label,
    );

    // await より前に state を更新することで、連打による多重呼び出しを防ぐ。
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

    await HapticFeedback.mediumImpact();
    await _persistAnswer(
      q: q,
      label: label,
      isCorrect: isCorrect,
      isFirstWrong: isFirstWrong,
      now: now,
    );
  }

  Future<void> _persistAnswer({
    required Question q,
    required String label,
    required bool isCorrect,
    required bool isFirstWrong,
    required DateTime now,
  }) async {
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
        _dailyLogRepo.incrementAnswered(isCorrect: isCorrect),
        ref.read(streakViewModelProvider.notifier).recordStudy(),
        if (!isCorrect) _learningRepo.unmarkMastered(q.eraId, q.no),
        if (isFirstWrong) _dailyLogRepo.incrementNewReview(),
      ]);
      ref
        ..invalidate(reportStatsProvider)
        ..invalidate(progressDashboardProvider);

      _answeredSinceLastBackup++;
      if (_answeredSinceLastBackup >= _autoBackupInterval) {
        _answeredSinceLastBackup = 0;
        _triggerSilentBackup();
      }
    } on Object {
      // 履歴保存失敗でも解答表示は継続
    }
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

    _saveResume(
      questions: session.allQuestions,
      setIndex: session.currentSetIndex,
      questionIndex: nextIndex,
    );
  }

  void _triggerSilentBackup() {    final isSync = ref.read(isSyncEnabledProvider);
    if (!isSync) return;
    final uid = ref.read(authUserProvider).asData?.value?.uid;
    if (uid == null) return;
    BackupService(uid: uid).upload().ignore();
  }

  /// 次のセット（10問）へ進む。[QuizSession.hasNextSet] が true のときのみ有効。
  void nextSet() {
    final current = state.value;
    if (current is! QuizReady) return;
    final session = current.session;
    if (!session.hasNextSet) return;

    final nextSetIndex = session.currentSetIndex + 1;
    state = AsyncData(
      QuizReady(
        QuizSession(
          allQuestions: session.allQuestions,
          currentSetIndex: nextSetIndex,
          setStartTime: DateTime.now(),
        ),
      ),
    );

    _saveResume(
      questions: session.allQuestions,
      setIndex: nextSetIndex,
      questionIndex: 0,
    );
  }

  /// セット完了時に呼ぶ。リザルト画面で表示した解答時間をそのまま学習時間として記録する。
  Future<void> recordSetElapsed(Duration elapsed) async {
    final sec = elapsed.inSeconds;
    if (sec <= 0) return;
    await _dailyLogRepo.addStudySeconds(sec);
    ref.invalidate(reportStatsProvider);
  }

  /// バックグラウンドから復帰した際に呼ぶ。
  /// セット解答時間からバックグラウンド滞在時間を除外する。
  void handleResumed(Duration bgDuration) {
    final current = state.value;
    if (current is! QuizReady) return;
    final session = current.session;
    state = AsyncData(
      QuizReady(
        session.copyWith(
          setStartTime: session.setStartTime.add(bgDuration),
        ),
      ),
    );
  }

  Future<int> loadTodayAnsweredCount() async {    final records = await _quizHistoryRepo.loadRecent(limit: 1000);
    final today = DateTime.now();
    return records.where((r) {
      return r.answeredAt.year == today.year &&
          r.answeredAt.month == today.month &&
          r.answeredAt.day == today.day;
    }).length;
  }
}

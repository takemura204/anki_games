import 'dart:math';

import 'package:anki_games/common/features/purchase/view_model/premium_view_model.dart';
import 'package:anki_games/common/features/quiz/datasource/csv_word_datasource.dart';
import 'package:anki_games/common/features/quiz/db/app_database.dart';
import 'package:anki_games/common/features/quiz/model/quiz_result.dart';
import 'package:anki_games/common/features/quiz/model/quiz_word.dart';
import 'package:anki_games/common/features/quiz/repository/local_word_record_repository.dart';
import 'package:anki_games/common/features/quiz/repository/word_record_repository.dart';
import 'package:drift/drift.dart' show Value;
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shared_preferences/shared_preferences.dart';

part 'quiz_view_model.freezed.dart';
part 'quiz_view_model.g.dart';

/// スワイプ方向の列挙型。
enum SwipeDirection {
  /// 上スワイプ。
  up,

  /// 下スワイプ。
  down,

  /// 左スワイプ。
  left,

  /// 右スワイプ。
  right,
}

/// 出題方向モード（後方互換のため保持）。
enum QuizDirectionMode {
  /// 英語を見て日本語を選ぶ。
  enToJa,

  /// 日本語を見て英語を選ぶ。
  jaToEn,

  /// 問題ごとにランダムで決定。
  random,
}

/// 問題形式。ステージによって自動決定される。
enum QuizFormat {
  /// 英語を見て日本語を4択から選ぶ（ステージ0〜2）。
  enToJaChoice,

  /// 日本語を見て英語を4択から選ぶ（現在未使用・後方互換のため保持）。
  jaToEnChoice,

  /// 日本語を見てスペルをタップ入力する（ステージ3）。
  letterTap,

  /// 日本語を見て英語をタイピングする（ステージ4）。
  jaToEnTyping,
}

/// 出題の並び順（ホームのクイズ開始ボトムシートで選択）。
enum QuizOrderMode {
  /// 従来の SRS・重み付きランダム（おまかせ）。
  auto,

  /// 記憶度が低い順: ステージ昇順、同ステージ内は重み降順。
  masteryLowToHigh,

  /// 記憶度が高い順: ステージ降順、同ステージ内は重み昇順。
  masteryHighToLow,
}

/// 学習範囲（習熟度）フィルター。択一選択。
enum MasteryRangeFilter {
  /// すべての単語。
  all,

  /// 苦手（stage 1）＋未学習（stage 0）。
  weakAndNew,

  /// 苦手のみ（stage 1）。
  weakOnly,
}

/// 資格レベルフィルター。複数選択可。
enum LevelFilter {
  /// 英検5級レベル。
  eiken5,

  /// 英検4級レベル。
  eiken4,

  /// 英検3級レベル。
  eiken3,

  /// 英検準2級レベル。
  eikenPre2,

  /// 英検2級レベル。
  eiken2,

  /// TOEIC 600点レベル。
  toeic600,

  /// TOEIC 700点レベル。
  toeic700,

  /// TOEIC 800点レベル。
  toeic800,

  /// TOEIC 900点レベル。
  toeic900,

  /// 開発・デバッグ用レベル（デバッグビルドのみ表示）。
  debug,
}

/// 単語とそのステージ・重みを組み合わせた表示用モデル。
@freezed
abstract class WordEntry with _$WordEntry {
  /// [WordEntry] を作成する。
  const factory WordEntry({
    /// 単語データ。
    required QuizWord word,

    /// 現在の学習ステージ（0=未学習〜5=習得済み）。
    required int stage,

    /// 現在の出題重み。
    required double weight,
  }) = _WordEntry;
}

/// 習熟度5段階の内訳カウント（表示用）。
@freezed
abstract class MasteryBreakdown with _$MasteryBreakdown {
  /// [MasteryBreakdown] を作成する。
  const factory MasteryBreakdown({
    /// 未学習（stage 0）の単語数。
    @Default(0) int newWords,

    /// 苦手（stage 1）の単語数。
    @Default(0) int hard,

    /// 学習中（stage 2）の単語数。
    @Default(0) int learning,

    /// 得意（stage 3）の単語数。
    @Default(0) int good,

    /// 完璧（stage 4）の単語数。
    @Default(0) int perfect,
  }) = _MasteryBreakdown;
}

/// 1方向に表示される選択肢チップのデータ。
@freezed
abstract class QuizChoice with _$QuizChoice {
  /// [QuizChoice] を作成する。
  const factory QuizChoice({
    /// 表示テキスト（日本語訳または英単語）。
    required String text,

    /// この選択肢が割り当てられた方向。
    required SwipeDirection direction,

    /// この選択肢が正解かどうか。
    required bool isCorrect,
  }) = _QuizChoice;
}

/// 1問のクイズ設問データ。
@freezed
abstract class QuizQuestion with _$QuizQuestion {
  /// [QuizQuestion] を作成する。
  const factory QuizQuestion({
    /// 出題対象の単語。
    required QuizWord word,

    /// カード上に表示するテキスト（英語または日本語）。
    required String displayText,

    /// 4方向の選択肢リスト（タイピング・letterTap形式では空）。
    required List<QuizChoice> choices,

    /// 問題形式（ステージに応じて自動決定）。
    required QuizFormat format,

    /// 出題時点のステージ（ラベル表示用）。
    @Default(0) int stage,

    /// スペルタップ形式の各スロット選択肢（letterTap形式のみ使用）。
    /// 外側リスト = スペルの各文字、内側リスト = シャッフル済み選択肢（4文字）。
    @Default([]) List<List<String>> letterSlots,
  }) = _QuizQuestion;
}

/// クイズ画面の状態。
@freezed
abstract class QuizViewState with _$QuizViewState {
  /// [QuizViewState] を作成する。
  const factory QuizViewState({
    /// CSVとDBのロード中かどうか。
    @Default(true) bool isLoading,

    /// 現在ラウンドの3問リスト。
    @Default([]) List<QuizQuestion> questions,

    /// 現在回答済みの問数（0〜3）。
    @Default(0) int answeredCount,

    /// 回答済みの結果リスト。
    @Default([]) List<QuizAnswerResult> answers,

    /// 直前の回答結果（正誤表示アニメーション用）。nullなら非表示。
    QuizAnswerResult? lastAnswer,

    /// 3問全て回答済みかどうか。
    @Default(false) bool isComplete,

    /// 出題方向モード（後方互換のため保持。問題形式はステージで決定）。
    @Default(QuizDirectionMode.enToJa) QuizDirectionMode directionMode,

    /// 学習範囲（習熟度）フィルター。択一選択。
    @Default(MasteryRangeFilter.all) MasteryRangeFilter masteryFilter,

    /// 選択中の資格レベルフィルター。空集合 = 全レベル対象。
    @Default(<LevelFilter>{}) Set<LevelFilter> selectedLevels,

    /// フィルター別の習熟度内訳。キーは MasteryRangeFilter.name または LevelFilter.name。
    @Default({}) Map<String, MasteryBreakdown> masteryBreakdowns,

    /// 現在の組み合わせフィルターで絞り込んだ単語数。
    @Default(0) int filteredWordCount,

    /// 全単語のステージ情報付きリスト（単語一覧・ランキング用）。
    @Default([]) List<WordEntry> wordEntries,

    /// 得意単語 TOP 5（選択レベルで絞り込み済み）。
    @Default([]) List<WordEntry> topBestWords,

    /// 苦手単語 TOP 5（選択レベルで絞り込み済み）。
    @Default([]) List<WordEntry> topWorstWords,

    /// 品詞フィルター（null = すべて）。
    @Default(null) String? selectedPos,

    /// 品詞グループインデックス（null = 品詞内の全単語, 0-based）。
    @Default(null) int? selectedPosGroupIndex,

    /// テーマフィルター（空集合 = すべて）。
    @Default(<String>{}) Set<String> selectedThemes,

    /// ステージグループフィルター（null=すべて, 0=未学習, 1=苦手, 2=得意, 4=完璧）。
    @Default(null) int? selectedStageGroup,

    /// テーマ別の単語数（現在のレベルフィルターを適用した件数）。
    @Default({}) Map<String, int> themeWordCounts,

    /// 品詞別の単語数（現在のレベルフィルターを適用した件数）。
    @Default({}) Map<String, int> posWordCounts,

    /// 翌24時間以内に復習期限を迎える単語数（ゲームオーバー翌日フック用）。
    @Default(0) int tomorrowReviewCount,

    /// 現在レビュー期限を迎えている単語数（ホーム画面の今日の学習状況表示用）。
    @Default(0) int todayDueCount,

    /// 出題の並び順（永続化）。
    @Default(QuizOrderMode.auto) QuizOrderMode quizOrderMode,
  }) = _QuizViewState;
}

const _masteryFilterKey = 'quiz_mastery_filter';
const _selectedLevelsKey = 'quiz_selected_levels';
const _quizOrderModeKey = 'quiz_order_mode';

const _correctWeightMultiplier = 0.7;
const _incorrectWeightMultiplier = 1.5;
const _minWeight = 0.1;
const _maxWeight = 5.0;
const _maxStage = 4;

// SRS インターバル（ステージ昇格後、単位: 時間）
// stage0: 1h, stage1: 4h, stage2: 24h, stage3: 72h(3日), stage4: 240h(10日)
const _srsBaseIntervalHours = [
  1.0,
  4.0,
  24.0,
  72.0,
  240.0,
];
const _srsIntervalMultMin = 0.3;
const _srsIntervalMultMax = 4.0;

// effectiveWeight のブースト係数上限（1語が出題確率を独占するのを防ぐ）
const _effectiveWeightMaxBoost = 5.0;

// 期限超過の urgency 係数（1日超過で effectiveWeight × 2）
const _overdueUrgencyFactor = 1.0;

// 不正解率の影響係数
const _histDifficultyFactor = 0.5;

// バッファ語（not-due）の重み係数
const _bufferWeightFactor = 0.3;

// セッション内不正解語の effectiveWeight ブースト係数
const _missedBoostFactor = 2.0;

/// クイズ機能の ViewModel。
///
/// CSV ロード・重み付きランダム選出・正誤判定・学習データ更新を担当する。
/// 問題形式（4択 / タイピング）はステージに応じて自動決定される。
@riverpod
class QuizViewModel extends _$QuizViewModel {
  final _rng = Random();
  late final WordRecordRepository _repo;
  List<QuizWord> _allWords = [];

  /// セッション内で正解した単語 ID（同セッション中に再出題しない）。
  final _sessionCorrectIds = <int>{};

  /// セッション内で不正解した単語 ID（高優先度で再出題する）。
  final _sessionIncorrectIds = <int>{};

  /// 直近のプール構築時に取得した nextReviewAt キャッシュ（同期overdueBonus計算用）。
  final _nextReviewAtCache = <int, DateTime?>{};

  /// セッション内で出題済みの due 語 ID（ラウンドロビン用）。
  final _sessionShownDueIds = <int>{};

  /// セッション内で出題済みの new 語 ID（ラウンドロビン用）。
  final _sessionShownNewIds = <int>{};

  /// 3問完了後にまとめて DB 更新するための一時バッファ。
  final _pendingUpdates = <({int wordId, bool isCorrect})>[];

  @override
  QuizViewState build() {
    _repo = LocalWordRecordRepository(ref.read(appDatabaseProvider));
    Future<void>.microtask(_initialize);
    return const QuizViewState();
  }

  // ── 初期化 ───────────────────────────────────────────────────

  Future<void> _initialize() async {
    final prefs = await SharedPreferences.getInstance();

    final savedMastery = prefs.getString(_masteryFilterKey);
    final masteryFilter = MasteryRangeFilter.values.firstWhere(
      (f) => f.name == savedMastery,
      orElse: () => MasteryRangeFilter.all,
    );

    final savedLevels = prefs.getStringList(_selectedLevelsKey) ?? [];
    final selectedLevels = savedLevels
        .map(
          (s) => LevelFilter.values.where((f) => f.name == s).firstOrNull,
        )
        .whereType<LevelFilter>()
        .toSet();

    final savedOrder = prefs.getString(_quizOrderModeKey);
    final quizOrderMode = QuizOrderMode.values.firstWhere(
      (m) => m.name == savedOrder,
      orElse: () => QuizOrderMode.auto,
    );

    state = state.copyWith(
      masteryFilter: masteryFilter,
      selectedLevels: selectedLevels,
      quizOrderMode: quizOrderMode,
    );
    _allWords = await CsvWordDatasource().load();
    await _loadMasteryBreakdowns();
    await _startNewRound();
    state = state.copyWith(isLoading: false);
  }

  // ── ラウンド開始 ─────────────────────────────────────────────

  /// 新しい3問ラウンドを開始する。
  Future<void> startNewRound() async {
    if (_pendingUpdates.isNotEmpty) {
      await _flushPendingUpdates();
    }
    state = state.copyWith(
      isLoading: true,
      answeredCount: 0,
      answers: const [],
      lastAnswer: null,
      isComplete: false,
    );
    await _startNewRound();
    state = state.copyWith(isLoading: false);
  }

  Future<void> _startNewRound() async {
    final questions = await _pickQuestions(3);
    state = state.copyWith(questions: questions);
  }

  /// Block Puzzle インラインクイズ用に1問だけ生成する。
  ///
  /// stage 0-2 は3択形式、stage 3 は letterTap、stage 4+ はタイピング形式で出題する。
  Future<void> startSingleQuestion() async {
    if (_pendingUpdates.isNotEmpty) {
      await _flushPendingUpdates();
    }
    state = state.copyWith(
      isLoading: true,
      answeredCount: 0,
      answers: const [],
      lastAnswer: null,
      isComplete: false,
    );
    if (_allWords.isEmpty) {
      state = state.copyWith(isLoading: false);
      return;
    }
    final questions = await _pickQuestions(1, inlineMode: true);
    state = state.copyWith(isLoading: false, questions: questions);
  }

  // ── 回答処理 ─────────────────────────────────────────────────

  /// [questionIndex] 番目の問題に [direction] でスワイプして回答する（4択形式）。
  Future<void> answer(int questionIndex, SwipeDirection direction) async {
    if (questionIndex >= state.questions.length) {
      return;
    }
    final question = state.questions[questionIndex];
    final choice = question.choices.firstWhere(
      (c) => c.direction == direction,
    );
    final isCorrect = choice.isCorrect;
    _trackSession(question.word.id, isCorrect: isCorrect);
    _pendingUpdates.add((wordId: question.word.id, isCorrect: isCorrect));
    final result = QuizAnswerResult(
      word: question.word,
      isCorrect: isCorrect,
      correctAnswer: question.choices.firstWhere((c) => c.isCorrect).text,
      overdueBonus: _calcOverdueBonusSync(question.word.id, isCorrect),
    );
    _applyResult(questionIndex, result);
    if (state.isComplete) {
      await _flushPendingUpdates();
    }
  }

  /// [questionIndex] 番目の問題に letterTap 形式で回答する。
  ///
  /// [isCorrect] は全スロットを初回正解で完了したかどうか（UI側で判定）。
  Future<void> answerLetterTap(
    int questionIndex, {
    required bool isCorrect,
  }) async {
    if (questionIndex >= state.questions.length) {
      return;
    }
    final question = state.questions[questionIndex];
    _trackSession(question.word.id, isCorrect: isCorrect);
    _pendingUpdates.add((wordId: question.word.id, isCorrect: isCorrect));
    final result = QuizAnswerResult(
      word: question.word,
      isCorrect: isCorrect,
      correctAnswer: question.word.en,
      overdueBonus: _calcOverdueBonusSync(question.word.id, isCorrect),
    );
    _applyResult(questionIndex, result);
    if (state.isComplete) {
      await _flushPendingUpdates();
    }
  }

  /// [questionIndex] 番目の問題に [text] をタイピングして回答する（タイピング形式）。
  Future<void> answerWithText(int questionIndex, String text) async {
    if (questionIndex >= state.questions.length) {
      return;
    }
    final question = state.questions[questionIndex];
    final isCorrect =
        text.trim().toLowerCase() == question.word.en.toLowerCase();
    _trackSession(question.word.id, isCorrect: isCorrect);
    _pendingUpdates.add((wordId: question.word.id, isCorrect: isCorrect));
    final result = QuizAnswerResult(
      word: question.word,
      isCorrect: isCorrect,
      correctAnswer: question.word.en,
      overdueBonus: _calcOverdueBonusSync(question.word.id, isCorrect),
    );
    _applyResult(questionIndex, result);
    if (state.isComplete) {
      await _flushPendingUpdates();
    }
  }

  /// 3問完了時に pending な DB 更新をまとめて実行し、ダッシュボードを更新する。
  Future<void> _flushPendingUpdates() async {
    for (final u in _pendingUpdates) {
      await _updateRecord(u.wordId, isCorrect: u.isCorrect);
    }
    _pendingUpdates.clear();
    await _loadMasteryBreakdowns();
  }

  /// キャッシュを使って同期的に overdueBonus を計算する。
  int _calcOverdueBonusSync(int wordId, bool isCorrect) {
    if (!isCorrect) {
      return 0;
    }
    final nextReviewAt = _nextReviewAtCache[wordId];
    if (nextReviewAt == null) {
      return 0;
    }
    final now = DateTime.now();
    if (!now.isAfter(nextReviewAt)) {
      return 0;
    }
    final overdueDays = now.difference(nextReviewAt).inHours / 24.0;
    return (overdueDays * 10).clamp(10.0, 100.0).round();
  }

  void _trackSession(int wordId, {required bool isCorrect}) {
    if (isCorrect) {
      _sessionCorrectIds.add(wordId);
      _sessionIncorrectIds.remove(wordId);
    } else {
      _sessionIncorrectIds.add(wordId);
    }
  }

  void _applyResult(int questionIndex, QuizAnswerResult result) {
    final newAnswers = [...state.answers, result];
    final newCount = state.answeredCount + 1;
    state = state.copyWith(
      answeredCount: newCount,
      answers: newAnswers,
      lastAnswer: result,
      isComplete: newCount >= state.questions.length,
    );
  }

  /// 直前の正誤表示をクリアする（アニメーション完了後に呼ぶ）。
  void clearLastAnswer() {
    state = state.copyWith(lastAnswer: null);
  }

  // ── 設定 ────────────────────────────────────────────────────

  /// 学習範囲（習熟度）フィルターを変更して保存する。
  Future<void> setMasteryFilter(MasteryRangeFilter filter) async {
    state = state.copyWith(masteryFilter: filter);
    await _updateFilteredWordCount();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_masteryFilterKey, filter.name);
  }

  /// 資格レベルフィルターをトグルする。
  Future<void> toggleLevelFilter(LevelFilter level) async {
    final current = Set<LevelFilter>.from(state.selectedLevels);
    if (current.contains(level)) {
      current.remove(level);
    } else {
      current.add(level);
    }
    state = state.copyWith(selectedLevels: current);
    await _updateFilteredWordCount();
    await _saveSelectedLevels(current);
  }

  /// 全レベルを選択状態にする（selectedLevels を空集合にする）。
  Future<void> selectAllLevels() async {
    state = state.copyWith(selectedLevels: const <LevelFilter>{});
    await _updateFilteredWordCount();
    await _saveSelectedLevels(const {});
  }

  /// 資格レベルを1つだけ選択する（ホーム画面のシングル選択用）。
  Future<void> setLevelFilter(LevelFilter level) async {
    final levels = {level};
    state = state.copyWith(selectedLevels: levels);
    await _updateFilteredWordCount();
    await _saveSelectedLevels(levels);
  }

  /// 品詞フィルターを設定する（null = すべて）。
  /// ステージグループフィルターを変更する（null = すべて）。
  Future<void> setStageGroupFilter(int? group) async {
    state = state.copyWith(
      selectedStageGroup: group,
      masteryFilter: MasteryRangeFilter.all,
    );
    await _updateFilteredWordCount();
  }

  Future<void> setPosFilter(String? pos, [int? groupIndex]) async {
    state = state.copyWith(
      selectedPos: pos,
      selectedPosGroupIndex: groupIndex,
    );
    await _updateFilteredWordCount();
  }

  /// 出題の並び順を設定して保存する。
  Future<void> setQuizOrderMode(QuizOrderMode mode) async {
    state = state.copyWith(quizOrderMode: mode);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_quizOrderModeKey, mode.name);
  }

  /// テーマフィルターをトグルする（加算式）。
  /// 空集合 = 全単語対象。タップで追加、再タップで解除。
  Future<void> toggleThemeFilter(String theme) async {
    final Set<String> next;
    if (state.selectedThemes.contains(theme)) {
      final removed = Set<String>.from(state.selectedThemes)..remove(theme);
      next = removed;
    } else {
      next = Set<String>.from(state.selectedThemes)..add(theme);
    }
    state = state.copyWith(
      selectedThemes: next,
      selectedPos: null,
      selectedPosGroupIndex: null,
    );
    await _updateFilteredWordCount();
  }

  /// セッション内の出題履歴をリセットする（新しいクイズゲーム開始時に呼ぶ）。
  void resetSession() {
    _sessionCorrectIds.clear();
    _sessionIncorrectIds.clear();
    _sessionShownDueIds.clear();
    _sessionShownNewIds.clear();
    _pendingUpdates.clear();
  }

  /// 全単語の学習データを削除してダッシュボードを再ロードする。
  Future<void> deleteAllLearningData() async {
    resetSession();
    await _repo.deleteAll();
    await _loadMasteryBreakdowns();
    await _updateFilteredWordCount();
  }

  /// 単語のステージを手動で更新する（単語一覧からのステータス変更）。
  Future<void> updateWordStage(int wordId, int newStage) async {
    final record = await _repo.getById(wordId);
    await _repo.upsert(
      WordRecordsCompanion(
        id: Value(wordId),
        weight: Value(record?.weight ?? 1.0),
        correctCount: Value(record?.correctCount ?? 0),
        incorrectCount: Value(record?.incorrectCount ?? 0),
        lastSeenAt: Value(record?.lastSeenAt),
        stage: Value(newStage),
        consecutiveStreak: const Value(0),
        nextReviewAt: const Value(null),
        intervalHours: const Value(4),
      ),
    );
    await _loadMasteryBreakdowns();
  }

  // ── 内部ロジック ─────────────────────────────────────────────

  /// 全フィルターの習熟度内訳を計算して state を更新する。
  Future<void> _loadMasteryBreakdowns() async {
    final records = await _repo.getAll();
    final stageMap = {for (final r in records) r.id: r.stage};
    final weightMap = {for (final r in records) r.id: r.weight};

    MasteryBreakdown calcBreakdown(List<QuizWord> words) {
      var newW = 0;
      var hard = 0;
      var learning = 0;
      var good = 0;
      var perfect = 0;
      for (final w in words) {
        final stage = stageMap[w.id] ?? 0;
        switch (stage) {
          case 0:
            newW++;
          case 1:
            hard++;
          case 2:
            learning++;
          case 3:
            good++;
          default:
            perfect++;
        }
      }
      return MasteryBreakdown(
        newWords: newW,
        hard: hard,
        learning: learning,
        good: good,
        perfect: perfect,
      );
    }

    final breakdowns = <String, MasteryBreakdown>{};

    for (final filter in MasteryRangeFilter.values) {
      final filtered = _applyMasteryFilter(_allWords, filter, stageMap);
      breakdowns[filter.name] = calcBreakdown(filtered);
    }

    for (final level in LevelFilter.values) {
      final filtered =
          _allWords.where((w) => w.level == _levelToString(level)).toList();
      breakdowns[level.name] = calcBreakdown(filtered);
    }

    // 全単語エントリー（ステージ・重み付き）
    final entries = _allWords
        .map(
          (w) => WordEntry(
            word: w,
            stage: stageMap[w.id] ?? 0,
            weight: weightMap[w.id] ?? 1.0,
          ),
        )
        .toList();

    // 選択レベルで絞り込み
    final levelFiltered = state.selectedLevels.isEmpty
        ? entries
        : entries
            .where(
              (e) => state.selectedLevels
                  .map(_levelToString)
                  .contains(e.word.level),
            )
            .toList();

    // 得意TOP5: stage >= 3、stage降順
    final bestSorted = levelFiltered.where((e) => e.stage >= 3).toList()
      ..sort((a, b) => b.stage.compareTo(a.stage));
    final topBest = bestSorted.take(5).toList();

    // 苦手TOP5: stage == 1、weight降順（重みが高い = 苦手度高）
    final worstSorted = levelFiltered.where((e) => e.stage == 1).toList()
      ..sort((a, b) => b.weight.compareTo(a.weight));
    final topWorst = worstSorted.take(5).toList();

    final now = DateTime.now();
    final tomorrow = now.add(const Duration(hours: 24));
    final tomorrowCount = records
        .where(
          (r) =>
              r.nextReviewAt != null &&
              r.nextReviewAt!.isAfter(now) &&
              !r.nextReviewAt!.isAfter(tomorrow),
        )
        .length;

    final dueCount = records
        .where(
          (r) =>
              r.nextReviewAt == null ||
              !DateTime.now().isBefore(r.nextReviewAt!),
        )
        .length;

    state = state.copyWith(
      masteryBreakdowns: breakdowns,
      wordEntries: entries,
      topBestWords: topBest,
      topWorstWords: topWorst,
      tomorrowReviewCount: tomorrowCount,
      todayDueCount: dueCount,
    );
    await _updateFilteredWordCount();
  }

  /// 習熟度内訳を再読み込みして公開する（学習範囲選択画面から呼ぶ）。
  Future<void> loadMasteryStats() => _loadMasteryBreakdowns();

  Future<void> _updateFilteredWordCount() async {
    if (_allWords.isEmpty) {
      return;
    }
    final records = await _repo.getAll();
    final stageMap = {for (final r in records) r.id: r.stage};
    final weightMap = {for (final r in records) r.id: r.weight};
    final filtered = _applyFilters(_allWords, weightMap, stageMap);

    // テーマ別件数: レベルフィルターのみ適用（テーマ選択前の件数を表示するため）
    var levelFiltered = _allWords;
    if (state.selectedLevels.isNotEmpty) {
      final levelStrings = state.selectedLevels.map(_levelToString).toSet();
      levelFiltered =
          _allWords.where((w) => levelStrings.contains(w.level)).toList();
    }
    final counts = <String, int>{
      'frequent': levelFiltered.where((w) => w.isFrequent).length,
    };
    for (final w in levelFiltered) {
      counts[w.theme] = (counts[w.theme] ?? 0) + 1;
    }

    final posCounts = <String, int>{};
    for (final w in levelFiltered) {
      posCounts[w.pos] = (posCounts[w.pos] ?? 0) + 1;
    }

    state = state.copyWith(
      filteredWordCount: filtered.length,
      themeWordCounts: counts,
      posWordCounts: posCounts,
    );
  }

  Future<void> _saveSelectedLevels(Set<LevelFilter> levels) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(
      _selectedLevelsKey,
      levels.map((f) => f.name).toList(),
    );
  }

  /// 習熟度フィルターのみ適用（stage ベース）。
  List<QuizWord> _applyMasteryFilter(
    List<QuizWord> words,
    MasteryRangeFilter filter,
    Map<int, int> stageMap,
  ) =>
      switch (filter) {
        MasteryRangeFilter.all => words,
        MasteryRangeFilter.weakAndNew => words.where((w) {
            final stage = stageMap[w.id] ?? 0;
            return stage <= 1;
          }).toList(),
        MasteryRangeFilter.weakOnly => words.where((w) {
            final stage = stageMap[w.id];
            return stage != null && stage == 1;
          }).toList(),
      };

  /// 習熟度・レベル・品詞・テーマフィルターを AND で適用する。
  List<QuizWord> _applyFilters(
    List<QuizWord> words,
    Map<int, double> weightMap,
    Map<int, int> stageMap,
  ) {
    var filtered = _applyMasteryFilter(words, state.masteryFilter, stageMap);
    if (state.selectedLevels.isNotEmpty) {
      final levelStrings = state.selectedLevels.map(_levelToString).toSet();
      filtered = filtered.where((w) => levelStrings.contains(w.level)).toList();
    }
    if (state.selectedPos != null) {
      const posGroupSize = 100;
      if (state.selectedPosGroupIndex != null) {
        final posWords = filtered
            .where((w) => w.pos == state.selectedPos)
            .toList()
          ..sort((a, b) => a.id.compareTo(b.id));
        final start = state.selectedPosGroupIndex! * posGroupSize;
        final end = (start + posGroupSize).clamp(0, posWords.length);
        final groupIds = posWords.sublist(start, end).map((w) => w.id).toSet();
        filtered = filtered.where((w) => groupIds.contains(w.id)).toList();
      } else {
        filtered = filtered.where((w) => w.pos == state.selectedPos).toList();
      }
    }
    final isPremium =
        ref.read(premiumViewModelProvider).valueOrNull?.isPremium ?? false;
    if (!isPremium) {
      filtered = filtered.where((w) => w.isFrequent).toList();
    } else if (state.selectedThemes.isNotEmpty) {
      filtered = filtered.where((w) {
        return state.selectedThemes.any((String t) {
          return t == 'frequent' ? w.isFrequent : w.theme == t;
        });
      }).toList();
    }
    if (state.selectedStageGroup != null) {
      final g = state.selectedStageGroup!;
      filtered = filtered.where((w) {
        final stage = stageMap[w.id] ?? 0;
        return switch (g) {
          0 => stage == 0,
          1 => stage == 1,
          2 => stage == 2,
          3 => stage == 3,
          _ => stage >= 4,
        };
      }).toList();
    }
    return filtered;
  }

  String _levelToString(LevelFilter level) => switch (level) {
        LevelFilter.eiken5 => 'eiken5',
        LevelFilter.eiken4 => 'eiken4',
        LevelFilter.eiken3 => 'eiken3',
        LevelFilter.eikenPre2 => 'eiken2pre',
        LevelFilter.eiken2 => 'eiken2',
        LevelFilter.toeic600 => 'toeic600',
        LevelFilter.toeic700 => 'toeic700',
        LevelFilter.toeic800 => 'toeic800',
        LevelFilter.toeic900 => 'toeic900',
        LevelFilter.debug => 'debug',
      };

  /// ステージに対応する問題形式を返す。
  ///
  /// stage 0,1 → EN→JA 4択、stage 2 → JA→EN 4択、stage 3 → スペルタップ、stage 4 → タイピング
  QuizFormat _formatForStage(int stage) => switch (stage) {
        0 || 1 => QuizFormat.enToJaChoice,
        2 => QuizFormat.jaToEnChoice,
        3 => QuizFormat.letterTap,
        _ => QuizFormat.jaToEnTyping,
      };

  /// ステージ昇格に必要な連続正解数を返す。
  ///
  /// stage1→2: 2回、stage2→3: 2回、stage3→4: 3回
  int _advancementThreshold(int stage) => switch (stage) {
        1 => 2,
        2 => 2,
        3 => 3,
        _ => 999,
      };

  /// フィルター・クールダウン適用後の単語プールを構築する。
  Future<List<({QuizWord word, WordRecord? record})>> _buildWordPool() async {
    final records = await _repo.getAll();
    final recordMap = {for (final r in records) r.id: r};
    final weightMap = {for (final r in records) r.id: r.weight};
    final stageMap = {for (final r in records) r.id: r.stage};

    final filtered = _applyFilters(_allWords, weightMap, stageMap);

    // 正解済みは同セッション中に再出題しない
    var pool =
        filtered.where((w) => !_sessionCorrectIds.contains(w.id)).toList();
    if (pool.length < 3) {
      // 正解済み語が多くpool不足: セッションをリセットして全語を再出題対象に
      _sessionCorrectIds.clear();
      _sessionIncorrectIds.clear();
      _sessionShownDueIds.clear();
      _sessionShownNewIds.clear();
      pool = filtered;
    }

    final entries =
        pool.map((w) => (word: w, record: recordMap[w.id])).toList();
    for (final e in entries) {
      _nextReviewAtCache[e.word.id] = e.record?.nextReviewAt;
    }
    return entries;
  }

  /// プールを due / buffer / new に分類する。
  ///
  /// - stage-0 でセッション不正解済み → due（即再出題）
  /// - stage-0 で nextReviewAt > now → buffer（インターバル中）
  /// - stage-0 でそれ以外 → newWords
  /// - stage ≥ 1 で nextReviewAt <= now → due
  /// - stage ≥ 1 で nextReviewAt > now → buffer
  ({
    List<({QuizWord word, WordRecord? record})> due,
    List<({QuizWord word, WordRecord? record})> buffer,
    List<({QuizWord word, WordRecord? record})> newWords,
  }) _categorizePool(
    List<({QuizWord word, WordRecord? record})> pool,
  ) {
    final now = DateTime.now();
    final due = <({QuizWord word, WordRecord? record})>[];
    final buffer = <({QuizWord word, WordRecord? record})>[];
    final newWords = <({QuizWord word, WordRecord? record})>[];

    for (final entry in pool) {
      final stage = entry.record?.stage ?? 0;
      final nextReviewAt = entry.record?.nextReviewAt;
      final isMissed = _sessionIncorrectIds.contains(entry.word.id);

      if (stage == 0) {
        if (isMissed) {
          // セッション内不正解の stage-0 語は即再出題
          due.add(entry);
        } else if (nextReviewAt != null && now.isBefore(nextReviewAt)) {
          // 正解済みでインターバル中の stage-0 語は buffer へ
          buffer.add(entry);
        } else {
          newWords.add(entry);
        }
      } else {
        if (nextReviewAt == null || !now.isBefore(nextReviewAt)) {
          due.add(entry);
        } else {
          buffer.add(entry);
        }
      }
    }
    return (due: due, buffer: buffer, newWords: newWords);
  }

  /// 単語 1 件の effectiveWeight を計算する。
  double _computeEffectiveWeight(({QuizWord word, WordRecord? record}) entry) {
    final r = entry.record;
    final baseWeight = r?.weight ?? 1.0;
    final correct = r?.correctCount ?? 0;
    final incorrect = r?.incorrectCount ?? 0;
    final nextReviewAt = r?.nextReviewAt;

    final histDiff = incorrect / (correct + incorrect + 1);
    final now = DateTime.now();
    final overdueDays = nextReviewAt != null && now.isAfter(nextReviewAt)
        ? now.difference(nextReviewAt).inHours / 24.0
        : 0.0;
    final missedBoost =
        _sessionIncorrectIds.contains(entry.word.id) ? _missedBoostFactor : 0.0;

    final boost = ((1 + overdueDays * _overdueUrgencyFactor) *
            (1 + histDiff * _histDifficultyFactor) *
            (1 + missedBoost))
        .clamp(1.0, _effectiveWeightMaxBoost);
    return baseWeight * boost;
  }

  /// 重み付きランダム選出ユーティリティ。
  ({QuizWord word, WordRecord? record})? _weightedPick(
    List<({QuizWord word, WordRecord? record})> candidates,
    double Function(({QuizWord word, WordRecord? record})) weightFn,
  ) {
    if (candidates.isEmpty) {
      return null;
    }
    final weights = candidates.map(weightFn).toList();
    final total = weights.fold<double>(0, (s, w) => s + w);
    if (total <= 0) {
      return candidates[_rng.nextInt(candidates.length)];
    }
    var rand = _rng.nextDouble() * total;
    for (var i = 0; i < candidates.length; i++) {
      rand -= weights[i];
      if (rand <= 0) {
        return candidates[i];
      }
    }
    return candidates.last;
  }

  /// テーマ重複チェック・バッファからの差し替え。
  void _applyThemeVariety(
    List<({QuizWord word, WordRecord? record})> picked,
    List<({QuizWord word, WordRecord? record})> altPool,
  ) {
    if (picked.length < 3) {
      return;
    }
    final themeCounts = <String, int>{};
    for (final e in picked) {
      final t = e.word.theme;
      themeCounts[t] = (themeCounts[t] ?? 0) + 1;
    }
    final dupTheme = themeCounts.entries
        .where((e) => e.value >= 2)
        .map((e) => e.key)
        .firstOrNull;
    if (dupTheme == null) {
      return;
    }

    final pickedIds = picked.map((e) => e.word.id).toSet();
    final alt = altPool.firstWhere(
      (e) => e.word.theme != dupTheme && !pickedIds.contains(e.word.id),
      orElse: () => altPool.firstWhere(
        (e) => !pickedIds.contains(e.word.id),
        orElse: () => picked.last,
      ),
    );
    if (alt.word.id == picked.last.word.id) {
      return;
    }

    final replaceIdx = picked.lastIndexWhere(
      (e) => e.word.theme == dupTheme,
    );
    if (replaceIdx >= 0) {
      picked[replaceIdx] = alt;
    }
  }

  /// [count] 件の問題を選出・構築する。
  ///
  /// [inlineMode] が true の場合、stage 3/4 でも4択形式を使用する（ゲーム内インラインクイズ専用）。
  Future<List<QuizQuestion>> _pickQuestions(
    int count, {
    bool inlineMode = false,
  }) async {
    if (_allWords.isEmpty) {
      return [];
    }
    if (state.quizOrderMode != QuizOrderMode.auto) {
      return _pickQuestionsByMasteryOrder(count, inlineMode: inlineMode);
    }
    return _pickQuestionsAuto(count, inlineMode: inlineMode);
  }

  /// 記憶度（ステージ＋重み）に基づく固定順で選出する。ラウンド内はシャッフルしない。
  Future<List<QuizQuestion>> _pickQuestionsByMasteryOrder(
    int count, {
    bool inlineMode = false,
  }) async {
    for (var attempt = 0; attempt < 2; attempt++) {
      final pool = await _buildWordPool();
      if (pool.isEmpty) {
        return [];
      }
      final sorted = [...pool];
      int stageOf(({QuizWord word, WordRecord? record}) e) =>
          e.record?.stage ?? 0;
      double weightOf(({QuizWord word, WordRecord? record}) e) =>
          e.record?.weight ?? 1.0;

      if (state.quizOrderMode == QuizOrderMode.masteryLowToHigh) {
        sorted.sort((a, b) {
          final sc = stageOf(a).compareTo(stageOf(b));
          if (sc != 0) {
            return sc;
          }
          return weightOf(b).compareTo(weightOf(a));
        });
      } else {
        sorted.sort((a, b) {
          final sc = stageOf(b).compareTo(stageOf(a));
          if (sc != 0) {
            return sc;
          }
          return weightOf(a).compareTo(weightOf(b));
        });
      }

      final picked = <({QuizWord word, WordRecord? record})>[];
      for (final e in sorted) {
        if (_sessionCorrectIds.contains(e.word.id)) {
          continue;
        }
        picked.add(e);
        if (picked.length >= count) {
          break;
        }
      }

      if (picked.length >= count || attempt == 1) {
        return picked
            .map(
              (e) => _buildQuestion(
                e.word,
                e.record?.stage ?? 0,
                inlineMode: inlineMode,
              ),
            )
            .toList();
      }
      _sessionCorrectIds.clear();
      _sessionIncorrectIds.clear();
      _sessionShownDueIds.clear();
      _sessionShownNewIds.clear();
    }
    return [];
  }

  /// SRS 3スロット方式で [count] 件の問題を選出・構築する（おまかせ）。
  Future<List<QuizQuestion>> _pickQuestionsAuto(
    int count, {
    bool inlineMode = false,
  }) async {
    final pool = await _buildWordPool();
    if (pool.isEmpty) {
      return [];
    }

    final categorized = _categorizePool(pool);
    final due = categorized.due;
    final buffer = categorized.buffer;
    final newWords = categorized.newWords;

    final picked = <({QuizWord word, WordRecord? record})>[];
    final pickedIds = <int>{};

    List<({QuizWord word, WordRecord? record})> avail(
      List<({QuizWord word, WordRecord? record})> src,
    ) =>
        src.where((e) => !pickedIds.contains(e.word.id)).toList();

    void addPick(({QuizWord word, WordRecord? record}) entry) {
      picked.add(entry);
      pickedIds.add(entry.word.id);
    }

    // ラウンドロビン: 未出題 due 語を優先。全語出題済みならサイクルをリセット。
    // 不正解語は _sessionIncorrectIds に含まれるため常に優先候補に残る。
    {
      final allDue = avail(due);
      final unshownDue = allDue
          .where(
            (e) =>
                !_sessionShownDueIds.contains(e.word.id) ||
                _sessionIncorrectIds.contains(e.word.id),
          )
          .toList();
      if (unshownDue.isEmpty && allDue.isNotEmpty) {
        _sessionShownDueIds
          ..removeWhere((id) => allDue.any((e) => e.word.id == id))
          ..removeWhere(_sessionIncorrectIds.contains);
      }
    }

    // Slots A and B: due 語からラウンドロビン選出
    for (var i = 0; i < 2; i++) {
      final allDue = avail(due);
      final preferred = allDue
          .where(
            (e) =>
                !_sessionShownDueIds.contains(e.word.id) ||
                _sessionIncorrectIds.contains(e.word.id),
          )
          .toList();
      final candidates = preferred.isNotEmpty ? preferred : allDue;
      if (candidates.isEmpty) {
        break;
      }
      final pick = _weightedPick(candidates, _computeEffectiveWeight);
      if (pick != null) {
        addPick(pick);
      }
    }

    // A/B がデュー語で埋まらなければバッファで補填
    while (picked.length < 2) {
      final a = avail(buffer);
      if (a.isEmpty) {
        break;
      }
      final pick = _weightedPick(
        a,
        (e) => (e.record?.weight ?? 1.0) * _bufferWeightFactor,
      );
      if (pick == null) {
        break;
      }
      addPick(pick);
    }

    // Slot C: new 語をラウンドロビン選出（制限なし）。なければバッファで補填。
    {
      final allNew = avail(newWords);
      if (allNew.isNotEmpty) {
        final unshownNew = allNew
            .where((e) => !_sessionShownNewIds.contains(e.word.id))
            .toList();
        if (unshownNew.isEmpty) {
          _sessionShownNewIds
              .removeWhere((id) => allNew.any((e) => e.word.id == id));
        }
        final newCandidates = unshownNew.isNotEmpty ? unshownNew : allNew;
        final pick = _weightedPick(newCandidates, (_) => 1.0);
        if (pick != null) {
          addPick(pick);
        }
      }
    }
    if (picked.length < count) {
      final a = avail(buffer);
      final pick = _weightedPick(
        a,
        (e) => (e.record?.weight ?? 1.0) * _bufferWeightFactor,
      );
      if (pick != null) {
        addPick(pick);
      }
    }

    // 不足している場合はプール残余から必要数を補填
    while (picked.length < count) {
      final remain = avail(pool);
      if (remain.isEmpty) {
        break;
      }
      final pick = _weightedPick(remain, _computeEffectiveWeight);
      if (pick == null) {
        break;
      }
      addPick(pick);
    }

    // テーマ多様化
    _applyThemeVariety(picked, [...avail(buffer), ...avail(due)]);

    picked.shuffle(_rng);

    // ラウンドロビン追跡を更新
    for (final id in pickedIds) {
      if (due.any((e) => e.word.id == id)) {
        _sessionShownDueIds.add(id);
      } else if (newWords.any((e) => e.word.id == id)) {
        _sessionShownNewIds.add(id);
      }
    }

    return picked
        .map(
          (e) => _buildQuestion(
            e.word,
            e.record?.stage ?? 0,
            inlineMode: inlineMode,
          ),
        )
        .toList();
  }

  /// インラインクイズ（ゲーム内）用のステージ→フォーマット変換。
  ///
  /// stage 3/4 でも letterTap/typing ではなく4択形式を使用する。
  QuizFormat _formatForStageInline(int stage) => switch (stage) {
        0 || 1 => QuizFormat.enToJaChoice,
        2 => QuizFormat.jaToEnChoice,
        _ => _formatForStage(stage),
      };

  /// 1問分の [QuizQuestion] を構築する。ステージから問題形式を決定する。
  ///
  /// [inlineMode] が true の場合は [_formatForStageInline] を使用し、
  /// stage 0-2 は3択形式、stage 3 は letterTap、stage 4+ はタイピングで出題する。
  QuizQuestion _buildQuestion(
    QuizWord word,
    int stage, {
    bool inlineMode = false,
  }) {
    final format =
        inlineMode ? _formatForStageInline(stage) : _formatForStage(stage);

    // letterTap 形式: 各文字スロットの選択肢を生成して返す（インラインモードでは使用しない）
    if (format == QuizFormat.letterTap) {
      return _buildLetterTapQuestion(word, stage);
    }

    final isEnToJa = format == QuizFormat.enToJaChoice;
    final isTyping = format == QuizFormat.jaToEnTyping;

    final display = isEnToJa ? word.en : word.ja;
    final correctText = isEnToJa ? word.ja : word.en;

    final choices = <QuizChoice>[];
    if (!isTyping) {
      if (inlineMode) {
        // 4択（インラインクイズ用）: 正解1 + デコイ3
        final decoys = _pickUniqueDecoyChoiceTexts(
          answerWord: word,
          allWords: _allWords,
          isEnToJa: isEnToJa,
          rng: _rng,
        );
        final texts = [
          correctText,
          decoys.isNotEmpty ? decoys[0] : '???',
          decoys.length > 1 ? decoys[1] : '???',
          decoys.length > 2 ? decoys[2] : '???',
        ]..shuffle(_rng);

        final dirs = [
          SwipeDirection.up,
          SwipeDirection.down,
          SwipeDirection.left,
          SwipeDirection.right,
        ]..shuffle(_rng);

        choices.addAll([
          for (var i = 0; i < texts.length; i++)
            QuizChoice(
              text: texts[i],
              direction: dirs[i],
              isCorrect: texts[i] == correctText,
            ),
        ]);
      } else {
        // 4択（ワードモード用）: 正解1 + デコイ3
        final decoys = _pickUniqueDecoyChoiceTexts(
          answerWord: word,
          allWords: _allWords,
          isEnToJa: isEnToJa,
          rng: _rng,
        );

        // 長い2つを上下・短い2つを左右に割り当てる
        final texts = [
          correctText,
          decoys.isNotEmpty ? decoys[0] : '???',
          decoys.length > 1 ? decoys[1] : '???',
          decoys.length > 2 ? decoys[2] : '???',
        ]..sort((a, b) => b.length.compareTo(a.length));

        final verticalDirs = [SwipeDirection.up, SwipeDirection.down]
          ..shuffle(_rng);
        final horizontalDirs = [SwipeDirection.left, SwipeDirection.right]
          ..shuffle(_rng);
        final assignedDirs = [
          verticalDirs[0],
          verticalDirs[1],
          horizontalDirs[0],
          horizontalDirs[1],
        ];

        choices.addAll([
          for (var i = 0; i < texts.length; i++)
            QuizChoice(
              text: texts[i],
              direction: assignedDirs[i],
              isCorrect: texts[i] == correctText,
            ),
        ]);
      }
    }

    return QuizQuestion(
      word: word,
      displayText: display,
      choices: choices,
      format: format,
      stage: stage,
    );
  }

  /// letterTap 形式の問題を構築する。
  ///
  /// 各文字スロットに正解文字 + ダミー3文字（計4択）をシャッフルして格納する。
  QuizQuestion _buildLetterTapQuestion(QuizWord word, int stage) {
    const alphabet = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ';
    final alphabetList = alphabet.split('');
    final targetLetters = word.en.toUpperCase().split('');

    final slots = targetLetters.map((correct) {
      final decoys = (alphabetList.where((l) => l != correct).toList()
            ..shuffle(_rng))
          .take(3)
          .toList();
      return ([correct, ...decoys]..shuffle(_rng));
    }).toList();

    return QuizQuestion(
      word: word,
      displayText: word.ja,
      choices: const [],
      format: QuizFormat.letterTap,
      stage: stage,
      letterSlots: slots,
    );
  }

  /// 正誤に応じて単語の重み・ステージ・ストリーク・SRS インターバルを更新する。
  ///
  /// 5段階ステージルール:
  /// - stage 0: 正解で stage 2 へ昇格、不正解で stage 1（苦手）へ降格
  /// - stage 1: 不正解は降格なし（底）、3連続正解で stage 2 へ
  /// - stage 2: 不正解で即 stage 1 へ、4連続正解で stage 3 へ
  /// - stage 3: 不正解で即 stage 2 へ、5連続正解で stage 4 へ
  /// - stage 4: 1回目の不正解は streak=-1 (警告)、2回目で stage 3 へ
  Future<void> _updateRecord(int wordId, {required bool isCorrect}) async {
    final record = await _repo.getById(wordId);
    final currentWeight = record?.weight ?? 1.0;
    final currentStage = record?.stage ?? 0;
    final currentStreak = record?.consecutiveStreak ?? 0;
    final now = DateTime.now();

    final newWeight = isCorrect
        ? (currentWeight * _correctWeightMultiplier)
            .clamp(_minWeight, _maxWeight)
        : (currentWeight * _incorrectWeightMultiplier)
            .clamp(_minWeight, _maxWeight);

    var newStage = currentStage;
    var newStreak = currentStreak;

    if (currentStage == 0 && isCorrect) {
      // 初回正解: stage 2 へ昇格（苦手をスキップ）
      newStage = 2;
      newStreak = 0;
    } else if (currentStage == 0) {
      // 初回不正解: stage 1（苦手）へ降格
      newStage = 1;
      newStreak = 0;
    } else if (isCorrect) {
      newStreak = currentStreak < 0 ? 1 : currentStreak + 1;
      if (newStreak >= _advancementThreshold(currentStage) &&
          currentStage < _maxStage) {
        newStage = currentStage + 1;
        newStreak = 0;
      }
    } else {
      switch (currentStage) {
        case 1:
          newStreak = 0;
        case 2:
          newStage = 1;
          newStreak = 0;
        case 3:
          newStage = 2;
          newStreak = 0;
        case 4:
          if (currentStreak < 0) {
            newStage = 3;
            newStreak = 0;
          } else {
            newStreak = -1;
          }
      }
    }

    // SRS インターバル計算（エビングハウス忘却曲線に基づくステージ別間隔）
    final intervalMult =
        (1.0 / newWeight).clamp(_srsIntervalMultMin, _srsIntervalMultMax);
    final stageIdx = newStage.clamp(0, _srsBaseIntervalHours.length - 1);
    final baseInterval = _srsBaseIntervalHours[stageIdx];
    final nextIntervalHours = baseInterval * intervalMult;
    final nextReviewAt =
        isCorrect ? now.add(Duration(hours: nextIntervalHours.round())) : now;

    await _repo.upsert(
      WordRecordsCompanion(
        id: Value(wordId),
        weight: Value(newWeight),
        correctCount: Value((record?.correctCount ?? 0) + (isCorrect ? 1 : 0)),
        incorrectCount:
            Value((record?.incorrectCount ?? 0) + (isCorrect ? 0 : 1)),
        lastSeenAt: Value(now),
        stage: Value(newStage),
        consecutiveStreak: Value(newStreak),
        nextReviewAt: Value(nextReviewAt),
        intervalHours: Value(nextIntervalHours),
      ),
    );
  }

  /// 現在ラウンドの結果をまとめて返す。
  QuizResult get currentResult => QuizResult(answers: state.answers);
}

/// 4択スワイプ用ダミー: 正解と表示テキストが完全一致する語はスキップする。
///
/// 候補は同テーマ＋同品詞 → 同テーマ＋異品詞 → 異テーマの順（各群は [rng] でシャッフル）。
List<String> _pickUniqueDecoyChoiceTexts({
  required QuizWord answerWord,
  required List<QuizWord> allWords,
  required bool isEnToJa,
  required Random rng,
  int count = 3,
}) {
  String textOnCard(QuizWord w) => isEnToJa ? w.ja : w.en;
  final correctText = textOnCard(answerWord);
  final used = <String>{correctText};
  final decoys = <String>[];

  void collectFrom(List<QuizWord> pool) {
    for (final w in pool) {
      if (decoys.length >= count) {
        return;
      }
      if (w.id == answerWord.id) {
        continue;
      }
      final t = textOnCard(w);
      if (used.contains(t)) {
        continue;
      }
      used.add(t);
      decoys.add(t);
    }
  }

  final sameThemeAndPos = allWords
      .where(
        (w) =>
            w.id != answerWord.id &&
            w.theme == answerWord.theme &&
            w.pos == answerWord.pos,
      )
      .toList()
    ..shuffle(rng);

  final sameTheme = allWords
      .where(
        (w) =>
            w.id != answerWord.id &&
            w.theme == answerWord.theme &&
            w.pos != answerWord.pos,
      )
      .toList()
    ..shuffle(rng);

  final others = allWords
      .where((w) => w.id != answerWord.id && w.theme != answerWord.theme)
      .toList()
    ..shuffle(rng);

  collectFrom(sameThemeAndPos);
  collectFrom(sameTheme);
  collectFrom(others);
  return decoys;
}

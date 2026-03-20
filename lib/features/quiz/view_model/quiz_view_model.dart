import 'dart:math';

import 'package:drift/drift.dart' show Value;
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:mono_games/features/quiz/datasource/csv_word_datasource.dart';
import 'package:mono_games/features/quiz/db/app_database.dart';
import 'package:mono_games/features/quiz/model/quiz_result.dart';
import 'package:mono_games/features/quiz/model/quiz_word.dart';
import 'package:mono_games/features/quiz/repository/local_word_record_repository.dart';
import 'package:mono_games/features/quiz/repository/word_record_repository.dart';
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

/// 出題方向モード。
enum QuizDirectionMode {
  /// 英語を見て日本語を選ぶ。
  enToJa,

  /// 日本語を見て英語を選ぶ。
  jaToEn,

  /// 問題ごとにランダムで決定。
  random,
}

/// 学習範囲フィルター。
enum WordRangeFilter {
  /// すべての単語。
  all,

  /// 苦手（weight≥2.0）＋未学習（DB未登録）。
  weakAndNew,

  /// 苦手のみ（weight≥2.0）。
  weakOnly,

  /// 英検5級レベル。
  eiken5,

  /// 英検4級レベル。
  eiken4,

  /// 英検3級レベル。
  eiken3,

  /// TOEIC基礎レベル。
  toiecBasic,
}

/// 習熟度4段階の内訳カウント。
@freezed
abstract class MasteryBreakdown with _$MasteryBreakdown {
  /// [MasteryBreakdown] を作成する。
  const factory MasteryBreakdown({
    /// 未学習（DB未登録）の単語数。
    @Default(0) int newWords,

    /// 苦手（weight≥2.0）の単語数。
    @Default(0) int hard,

    /// 得意（0.5≤weight<2.0）の単語数。
    @Default(0) int good,

    /// 完璧（weight<0.5かつDB登録済み）の単語数。
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

    /// 4方向の選択肢リスト。
    required List<QuizChoice> choices,
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

    /// 出題方向モード。
    @Default(QuizDirectionMode.enToJa) QuizDirectionMode directionMode,

    /// 学習範囲フィルター。
    @Default(WordRangeFilter.all) WordRangeFilter wordRangeFilter,

    /// フィルター別の習熟度内訳。キーは WordRangeFilter.name。
    @Default({}) Map<String, MasteryBreakdown> masteryBreakdowns,
  }) = _QuizViewState;
}

const _quizDirectionKey = 'quiz_direction_mode';
const _wordRangeFilterKey = 'word_range_filter';

// SRS重みの閾値・係数
const _hardThreshold = 2.0;
const _perfectThreshold = 0.5;
const _correctWeightMultiplier = 0.7;
const _incorrectWeightMultiplier = 1.5;
const _minWeight = 0.1;
const _maxWeight = 5.0;

/// クイズ機能の ViewModel。
///
/// CSV ロード・重み付きランダム選出・正誤判定・学習データ更新を担当する。
@riverpod
class QuizViewModel extends _$QuizViewModel {
  final _rng = Random();
  late final WordRecordRepository _repo;
  List<QuizWord> _allWords = [];

  /// セッション内で不正解だった単語 ID（次ラウンドで weight を一時増幅するため保持）。
  final _sessionMissedIds = <int>{};

  @override
  QuizViewState build() {
    _repo = LocalWordRecordRepository(AppDatabase());
    Future<void>.microtask(_initialize);
    return const QuizViewState();
  }

  // ── 初期化 ───────────────────────────────────────────────────

  Future<void> _initialize() async {
    final prefs = await SharedPreferences.getInstance();
    final savedDirection = prefs.getString(_quizDirectionKey);
    final directionMode = QuizDirectionMode.values.firstWhere(
      (m) => m.name == savedDirection,
      orElse: () => QuizDirectionMode.enToJa,
    );
    final savedFilter = prefs.getString(_wordRangeFilterKey);
    final wordRangeFilter = WordRangeFilter.values.firstWhere(
      (f) => f.name == savedFilter,
      orElse: () => WordRangeFilter.all,
    );
    state = state.copyWith(
      directionMode: directionMode,
      wordRangeFilter: wordRangeFilter,
    );
    _allWords = await CsvWordDatasource().load();
    await _loadMasteryBreakdowns();
    await _startNewRound();
    state = state.copyWith(isLoading: false);
  }

  // ── ラウンド開始 ─────────────────────────────────────────────

  /// 新しい3問ラウンドを開始する。
  Future<void> startNewRound() async {
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
    final words = await _pickWeightedWords(3);
    final questions = words.map(_buildQuestion).toList();
    state = state.copyWith(questions: questions);
  }

  // ── 回答処理 ─────────────────────────────────────────────────

  /// [questionIndex] 番目の問題に [direction] でスワイプして回答する。
  Future<void> answer(int questionIndex, SwipeDirection direction) async {
    if (questionIndex >= state.questions.length) {
      return;
    }
    final question = state.questions[questionIndex];
    final choice = question.choices.firstWhere(
      (c) => c.direction == direction,
    );
    final isCorrect = choice.isCorrect;
    final result = QuizAnswerResult(
      word: question.word,
      isCorrect: isCorrect,
      correctAnswer: question.choices.firstWhere((c) => c.isCorrect).text,
    );

    final newAnswers = [...state.answers, result];
    final newCount = state.answeredCount + 1;

    state = state.copyWith(
      answeredCount: newCount,
      answers: newAnswers,
      lastAnswer: result,
      isComplete: newCount >= 3,
    );

    if (!isCorrect) {
      _sessionMissedIds.add(question.word.id);
    }
    await _updateWeight(question.word.id, isCorrect: isCorrect);
  }

  /// 直前の正誤表示をクリアする（アニメーション完了後に呼ぶ）。
  void clearLastAnswer() {
    state = state.copyWith(lastAnswer: null);
  }

  // ── 設定 ────────────────────────────────────────────────────

  /// 学習範囲フィルターを変更して保存する。
  Future<void> setWordRangeFilter(WordRangeFilter filter) async {
    state = state.copyWith(wordRangeFilter: filter);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_wordRangeFilterKey, filter.name);
  }

  /// 出題方向モードを変更して保存する。
  Future<void> setDirectionMode(QuizDirectionMode mode) async {
    state = state.copyWith(directionMode: mode);
    // 問題テキストを再構築（各問題から元の単語を取り出してビルド）
    final questions = state.questions
        .map((QuizQuestion q) => _buildQuestion(q.word))
        .toList();
    // クイズ中に方向変更した場合は回答済み状態もリセットして整合性を保つ
    state = state.copyWith(
      questions: questions,
      answeredCount: 0,
      answers: const [],
      lastAnswer: null,
      isComplete: false,
    );
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_quizDirectionKey, mode.name);
  }

  // ── 内部ロジック ─────────────────────────────────────────────

  /// 全フィルターの習熟度内訳を計算して state を更新する。
  Future<void> _loadMasteryBreakdowns() async {
    final records = await _repo.getAll();
    final weightMap = {for (final r in records) r.id: r.weight};

    MasteryBreakdown calcBreakdown(List<QuizWord> words) {
      var newW = 0;
      var hard = 0;
      var good = 0;
      var perfect = 0;
      for (final w in words) {
        final weight = weightMap[w.id];
        if (weight == null) {
          newW++;
        } else if (weight >= _hardThreshold) {
          hard++;
        } else if (weight < _perfectThreshold) {
          perfect++;
        } else {
          good++;
        }
      }
      return MasteryBreakdown(
        newWords: newW,
        hard: hard,
        good: good,
        perfect: perfect,
      );
    }

    final breakdowns = <String, MasteryBreakdown>{};
    for (final filter in WordRangeFilter.values) {
      final filtered = _applyRangeFilter(_allWords, filter, weightMap);
      breakdowns[filter.name] = calcBreakdown(filtered);
    }
    state = state.copyWith(masteryBreakdowns: breakdowns);
  }

  /// 習熟度内訳を再読み込みして公開する（学習範囲選択画面から呼ぶ）。
  Future<void> loadMasteryStats() => _loadMasteryBreakdowns();

  /// セッション内の不正解履歴をリセットする（新しいクイズゲーム開始時に呼ぶ）。
  void resetSession() => _sessionMissedIds.clear();

  /// [filter] に基づいて単語リストを絞り込む。
  List<QuizWord> _applyRangeFilter(
    List<QuizWord> words,
    WordRangeFilter filter,
    Map<int, double> weightMap,
  ) =>
      switch (filter) {
        WordRangeFilter.all => words,
        WordRangeFilter.weakAndNew => words.where((w) {
            final weight = weightMap[w.id];
            return weight == null || weight >= _hardThreshold;
          }).toList(),
        WordRangeFilter.weakOnly => words.where((w) {
            final weight = weightMap[w.id];
            return weight != null && weight >= _hardThreshold;
          }).toList(),
        WordRangeFilter.eiken5 =>
          words.where((w) => w.level == 'eiken5').toList(),
        WordRangeFilter.eiken4 =>
          words.where((w) => w.level == 'eiken4').toList(),
        WordRangeFilter.eiken3 =>
          words.where((w) => w.level == 'eiken3').toList(),
        WordRangeFilter.toiecBasic =>
          words.where((w) => w.level == 'toeic_basic').toList(),
      };

  /// 重み付きランダムで [count] 件の単語を選出する。
  Future<List<QuizWord>> _pickWeightedWords(int count) async {
    if (_allWords.isEmpty) {
      return [];
    }
    final records = await _repo.getAll();
    final weightMap = {for (final r in records) r.id: r.weight};

    final filtered =
        _applyRangeFilter(_allWords, state.wordRangeFilter, weightMap);
    if (filtered.isEmpty) {
      return [];
    }

    // セッション内で不正解だった単語は weight を2倍に一時増幅して優先出題
    final weights = filtered.map((w) {
      final base = weightMap[w.id] ?? 1.0;
      return _sessionMissedIds.contains(w.id) ? base * 2 : base;
    }).toList();

    final picked = <QuizWord>[];
    final available = List<QuizWord>.from(filtered);
    final availableWeights = List<double>.from(weights);

    final pickCount = min(count, available.length);
    for (var i = 0; i < pickCount; i++) {
      final t = availableWeights.fold<double>(0, (s, w) => s + w);
      var rand = _rng.nextDouble() * t;
      var idx = 0;
      for (var j = 0; j < availableWeights.length; j++) {
        rand -= availableWeights[j];
        if (rand <= 0) {
          idx = j;
          break;
        }
      }
      picked.add(available[idx]);
      available.removeAt(idx);
      availableWeights.removeAt(idx);
    }
    return picked;
  }

  /// 1問分の [QuizQuestion] を構築する（4択チップ + 正解方向ランダム割り当て）。
  QuizQuestion _buildQuestion(QuizWord word) {
    final isEnToJa = switch (state.directionMode) {
      QuizDirectionMode.enToJa => true,
      QuizDirectionMode.jaToEn => false,
      QuizDirectionMode.random => _rng.nextBool(),
    };
    final display = isEnToJa ? word.en : word.ja;
    final correctText = isEnToJa ? word.ja : word.en;

    // デコイ: 同カテゴリ優先、不足時は他カテゴリから補完
    final sameCategory = _allWords
        .where((w) => w.id != word.id && w.category == word.category)
        .toList()
      ..shuffle(_rng);
    final others = _allWords
        .where((w) => w.id != word.id && w.category != word.category)
        .toList()
      ..shuffle(_rng);
    final decoyCandidates = [...sameCategory, ...others];
    final decoys = decoyCandidates
        .take(3)
        .map((w) => isEnToJa ? w.ja : w.en)
        .toList();

    final directions = List<SwipeDirection>.from(SwipeDirection.values)
      ..shuffle(_rng);
    final correctDir = directions[0];
    final choices = [
      QuizChoice(text: correctText, direction: correctDir, isCorrect: true),
      for (var i = 0; i < 3; i++)
        QuizChoice(
          text: decoys.length > i ? decoys[i] : '???',
          direction: directions[i + 1],
          isCorrect: false,
        ),
    ];

    return QuizQuestion(
      word: word,
      displayText: display,
      choices: choices,
    );
  }

  /// 正誤に応じて単語の重みを更新する。
  Future<void> _updateWeight(int wordId, {required bool isCorrect}) async {
    final record = await _repo.getById(wordId);
    final currentWeight = record?.weight ?? 1.0;
    final newWeight = isCorrect
        ? (currentWeight * _correctWeightMultiplier)
            .clamp(_minWeight, _maxWeight)
        : (currentWeight * _incorrectWeightMultiplier)
            .clamp(_minWeight, _maxWeight);

    await _repo.upsert(
      WordRecordsCompanion(
        id: Value(wordId),
        weight: Value(newWeight),
        correctCount: Value((record?.correctCount ?? 0) + (isCorrect ? 1 : 0)),
        incorrectCount:
            Value((record?.incorrectCount ?? 0) + (isCorrect ? 0 : 1)),
        lastSeenAt: Value(DateTime.now()),
      ),
    );
  }

  /// 現在ラウンドの結果をまとめて返す。
  QuizResult get currentResult => QuizResult(answers: state.answers);
}

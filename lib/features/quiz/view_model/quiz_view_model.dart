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
  }) = _QuizViewState;
}

const _quizDirectionKey = 'quiz_direction_mode';

/// クイズ機能の ViewModel。
///
/// CSV ロード・重み付きランダム選出・正誤判定・学習データ更新を担当する。
@riverpod
class QuizViewModel extends _$QuizViewModel {
  final _rng = Random();
  late final WordRecordRepository _repo;
  List<QuizWord> _allWords = [];

  @override
  QuizViewState build() {
    _repo = LocalWordRecordRepository(AppDatabase());
    // 非同期で初期化
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
    state = state.copyWith(directionMode: directionMode);
    _allWords = await CsvWordDatasource().load();
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

    await _updateWeight(question.word.id, isCorrect: isCorrect);
  }

  /// 直前の正誤表示をクリアする（アニメーション完了後に呼ぶ）。
  void clearLastAnswer() {
    state = state.copyWith(lastAnswer: null);
  }

  // ── 設定 ────────────────────────────────────────────────────

  /// 出題方向モードを変更して保存する。
  Future<void> setDirectionMode(QuizDirectionMode mode) async {
    state = state.copyWith(directionMode: mode);
    // 問題テキストを再構築（各問題から元の単語を取り出してビルド）
    final questions = state.questions
        .map((QuizQuestion q) => _buildQuestion(q.word))
        .toList();
    state = state.copyWith(questions: questions);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_quizDirectionKey, mode.name);
  }

  // ── 内部ロジック ─────────────────────────────────────────────

  /// 重み付きランダムで [count] 件の単語を選出する。
  Future<List<QuizWord>> _pickWeightedWords(int count) async {
    if (_allWords.isEmpty) {
      return [];
    }
    final records = await _repo.getAll();
    final weightMap = {for (final r in records) r.id: r.weight};

    // 各単語の重みを取得（DBに未登録なら初期値 1.0）
    final weights = _allWords
        .map((w) => weightMap[w.id] ?? 1.0)
        .toList();

    final picked = <QuizWord>[];
    final available = List<QuizWord>.from(_allWords);
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

    // 4方向をシャッフルして割り当て
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
    const minWeight = 0.1;
    const maxWeight = 5.0;

    final record = await _repo.getById(wordId);
    final currentWeight = record?.weight ?? 1.0;
    final newWeight = isCorrect
        ? (currentWeight * 0.7).clamp(minWeight, maxWeight)
        : (currentWeight * 1.5).clamp(minWeight, maxWeight);

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

import 'dart:async';
import 'dart:math';

import 'package:anki_games/apps/block_puzzle/features/block_puzzle/model/board.dart';
import 'package:anki_games/apps/block_puzzle/features/block_puzzle/model/piece.dart';
import 'package:anki_games/apps/block_puzzle/features/block_puzzle/model/piece_generator.dart';
import 'package:anki_games/common/features/quiz/model/quiz_word.dart';
import 'package:anki_games/common/features/quiz/view_model/quiz_view_model.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shared_preferences/shared_preferences.dart';

part 'block_puzzle_view_model.freezed.dart';
part 'block_puzzle_view_model.g.dart';

const _highScoreKey = 'block_puzzle_high_score';
const _classicBoardKey = 'block_puzzle_classic_board';
const _classicPiecesKey = 'block_puzzle_classic_pieces';
const _classicScoreKey = 'block_puzzle_classic_score';
const _classicComboKey = 'block_puzzle_classic_combo';
const _classicNonClearTurnsKey = 'block_puzzle_classic_non_clear_turns';
const _classicIsGameOverKey = 'block_puzzle_classic_is_game_over';
const _classicCanContinueKey = 'block_puzzle_classic_can_continue';

// レベル別クイズキー（v2: レベルごとに独立したセーブスロット）
String _quizBoardKeyFor(String level) => 'block_puzzle_quiz_board_v2_$level';
String _quizPiecesKeyFor(String level) => 'block_puzzle_quiz_pieces_v2_$level';
String _quizScoreKeyFor(String level) => 'block_puzzle_quiz_score_v2_$level';
String _quizComboKeyFor(String level) => 'block_puzzle_quiz_combo_v2_$level';
String _quizNonClearTurnsKeyFor(String level) =>
    'block_puzzle_quiz_non_clear_turns_v2_$level';
String _quizIsGameOverKeyFor(String level) =>
    'block_puzzle_quiz_is_game_over_v2_$level';
String _quizIsQuizPhaseKeyFor(String level) =>
    'block_puzzle_quiz_is_quiz_phase_v2_$level';
String _levelHighScoreKeyFor(String level) =>
    'block_puzzle_high_score_v2_$level';

typedef _QuizModeCache = ({
  List<List<bool>> board,
  List<Piece?> pieces,
  int score,
  int combo,
  int nonClearTurns,
  bool isGameOver,
  bool isQuizPhase,
});

typedef _ClassicCache = ({
  List<List<bool>> board,
  List<Piece?> pieces,
  int score,
  int combo,
  int nonClearTurns,
  bool isGameOver,
  bool canContinue,
});

/// 直前のライン消去情報（アニメーション用）。
@freezed
abstract class ClearResult with _$ClearResult {
  /// ライン消去結果を作成する。
  const factory ClearResult({
    /// 消去されたライン数。
    required int linesCleared,

    /// この配置で獲得した合計ポイント。
    required int pointsEarned,

    /// 現在のコンボ倍率。
    required int combo,

    /// 消去されたセルの集合。
    required Set<(int, int)> cells,

    /// ピースが配置された行。
    required int placementRow,

    /// ピースが配置された列。
    required int placementCol,

    /// 消去された行番号の集合。
    required Set<int> clearedRows,

    /// 消去された列番号の集合。
    required Set<int> clearedCols,
  }) = _ClearResult;
}

/// Noir Mindパズルゲームの状態。
@freezed
abstract class BlockPuzzleState with _$BlockPuzzleState {
  /// ゲーム状態を作成する。
  const factory BlockPuzzleState({
    /// 8x8ボードのセルグリッド。`true` = 配置済み。
    required List<List<bool>> board,

    /// 現在の3ピースセット。`null` = 使用済み。
    required List<Piece?> pieces,

    /// 消去アニメーション中のセル。
    @Default(<(int, int)>{}) Set<(int, int)> clearingCells,

    /// 現在のスコア。
    @Default(0) int score,

    /// 歴代ハイスコア。
    @Default(0) int highScore,

    /// 現在のコンボ数（連続消去回数）。
    @Default(0) int combo,

    /// ライン消去なしの連続ターン数。
    @Default(0) int consecutiveNonClearTurns,

    /// ゲームオーバーかどうか。
    @Default(false) bool isGameOver,

    /// 直前の消去情報（アニメーション用）。nullなら消去なし。
    @Default(null) ClearResult? lastClearResult,

    /// 直前に配置されたセル（バウンスアニメーション用）。
    @Default(<(int, int)>{}) Set<(int, int)> lastPlacedCells,

    /// ハイスコアを更新したかどうか。
    @Default(false) bool isNewHighScore,

    /// リワード広告でコンティニュー可能かどうか（クラシックモード専用・1回限り）。
    @Default(true) bool canContinue,

    /// 再開可能なクラシックゲームが保存されているかどうか。
    @Default(false) bool hasSavedClassicGame,

    /// クイズ連動モードかどうか。
    @Default(false) bool isQuizMode,

    /// ボード上フラッシュ用: null=なし, true=正解, false=不正解。
    @Default(null) bool? quizAnswerCorrect,

    /// ボードフラッシュ対象セル。
    @Default(<(int, int)>{}) Set<(int, int)> quizFeedbackCells,

    /// 直前に配置されたスロットインデックス（クイズ選択判定用）。
    @Default(null) int? lastPlacedSlotIndex,

    /// 4択: 選択中の選択肢インデックス（null = 未選択）。
    @Default(null) int? quizSelectedChoiceIndex,

    /// letterTap 正誤結果（null = 未回答）。
    @Default(null) bool? quizInputIsCorrect,

    /// タイピング入力テキスト（null = 未入力）。
    @Default(null) String? quizTypedText,

    /// フィードバックバナー表示中かどうか。
    @Default(false) bool quizFeedbackShowing,

    /// フィードバックバナー正誤。
    @Default(false) bool quizFeedbackIsCorrect,

    /// フィードバックバナー: 不正解時の正解テキスト（正解時は空文字）。
    @Default('') String quizFeedbackCorrectAnswer,

    /// クイズセッション中に正解した単語リスト（ゲームオーバー時の表示用）。
    @Default([]) List<QuizWord> sessionCorrectWords,

    /// クイズセッション中に不正解だった単語リスト（ゲームオーバー時の表示用）。
    @Default([]) List<QuizWord> sessionIncorrectWords,

    /// レベルごとのハイスコア。キーは LevelFilter.name。
    @Default(<String, int>{}) Map<String, int> levelHighScores,

    /// レベルごとに途中のゲームが保存されているか（ゲームオーバーでないもの）。
    @Default(<String, bool>{}) Map<String, bool> levelHasSavedGame,
  }) = _BlockPuzzleState;
}

/// Noir Mindパズルゲームのビューモデル。
@riverpod
class BlockPuzzleViewModel extends _$BlockPuzzleViewModel {
  final _rng = Random();
  final _persistedDataLoaded = Completer<void>();

  // 起動時に読み込んだセーブデータのインメモリキャッシュ。
  // resumeClassicGame で同期的に復元するために使用。
  _ClassicCache? _classicCache;

  // レベル別クイズキャッシュ。キーは LevelFilter.name。
  final _quizModeCaches = <String, _QuizModeCache>{};

  // 現在プレイ中のレベルキー（startQuizMode で設定）。
  String? _currentLevelKey;


  @override
  BlockPuzzleState build() {
    // BottomSheet の pop から BlockPuzzleScreen の push の間にリスナーが
    // 一時的に 0 になっても破棄されないよう永続化する。
    ref.keepAlive();
    Future<void>.microtask(_loadPersistedData);
    final emptyBoard =
        List.generate(Board.size, (_) => List.filled(Board.size, false));
    return BlockPuzzleState(
      board: emptyBoard,
      pieces: generatePieces(emptyBoard, _rng),
    );
  }

  /// 起動時の保存データ読み込み完了を待機する。
  Future<void> ensurePersistedDataLoaded() => _persistedDataLoaded.future;

  /// [pieceIndex]番目のピースを([row], [col])に配置する。
  /// 配置成功なら`true`を返す。
  bool placePiece(int pieceIndex, int row, int col) {
    final piece = state.pieces[pieceIndex];
    if (piece == null) {
      return false;
    }

    final board = Board.from(state.board);
    if (!board.canPlace(piece, row, col)) {
      return false;
    }

    board.place(piece, row, col);

    // バウンスアニメーション用に配置セルを記録
    final placedCells = <(int, int)>{};
    for (final (dr, dc) in piece.offsets) {
      placedCells.add((row + dr, col + dc));
    }

    final newPieces = [...state.pieces];
    newPieces[pieceIndex] = null;

    // 基本スコア: セル数 × 1pt
    var pointsEarned = piece.offsets.length;

    // ライン消去チェック（ボード状態は変更しない）
    final clearResult = board.checkClearLines();

    Board finalBoard;
    if (clearResult.clearedCells.isNotEmpty) {
      final actualClearCells = clearResult.clearedCells;

      // ラインをクリア
      finalBoard = board.clearCells(actualClearCells);

      // コンボを加算（同時消去ライン数分）
      final newCombo = state.combo + clearResult.linesCleared;

      // ライン消去スコア: 10 × ライン数²
      final lineScore =
          10 * clearResult.linesCleared * clearResult.linesCleared;
      // コンボ倍率: 増加前の combo + 1（初回は必ず 1×、2連続で 2×）
      final comboMultiplier = state.combo + 1;
      pointsEarned += lineScore * comboMultiplier;

      final newScore = state.score + pointsEarned;
      final isNewHigh = newScore > state.highScore;
      final newHighScore = isNewHigh ? newScore : state.highScore;

      if (isNewHigh) {
        _saveHighScore(newHighScore);
      }

      // 消去済みボードで状態を更新（参照共有を防ぐためディープコピー）
      final boardCopy = [
        for (final r in finalBoard.cells) [...r]
      ];

      state = state.copyWith(
        board: boardCopy,
        pieces: newPieces,
        clearingCells: actualClearCells,
        score: newScore,
        highScore: newHighScore,
        levelHighScores: isNewHigh
            ? _updatedLevelHighScores(newHighScore)
            : state.levelHighScores,
        combo: newCombo,
        consecutiveNonClearTurns: 0,
        lastClearResult: ClearResult(
          linesCleared: clearResult.linesCleared,
          pointsEarned: pointsEarned,
          combo: newCombo,
          cells: actualClearCells,
          placementRow: row,
          placementCol: col,
          clearedRows: clearResult.clearedRows,
          clearedCols: clearResult.clearedCols,
        ),
        lastPlacedCells: placedCells,
        lastPlacedSlotIndex: pieceIndex,
        isNewHighScore: isNewHigh,
      );
      // 配置直後に状態を永続化（アニメーション前でも最新スコアを保存）
      _saveGame();
      // クリア完了はビュー側のアニメーション終了時に completeClearAnimation()
      // で通知する。
    } else {
      finalBoard = board;

      final nonClearTurns = state.consecutiveNonClearTurns + 1;
      final newCombo = nonClearTurns >= 3 ? 0 : state.combo;
      final newScore = state.score + pointsEarned;
      final isNewHigh = newScore > state.highScore;
      final newHighScore = isNewHigh ? newScore : state.highScore;

      if (isNewHigh) {
        _saveHighScore(newHighScore);
      }

      state = state.copyWith(
        board: [
          for (final row in finalBoard.cells) [...row]
        ],
        pieces: newPieces,
        score: newScore,
        highScore: newHighScore,
        levelHighScores: isNewHigh
            ? _updatedLevelHighScores(newHighScore)
            : state.levelHighScores,
        combo: newCombo,
        consecutiveNonClearTurns: nonClearTurns,
        lastClearResult: null,
        lastPlacedCells: placedCells,
        lastPlacedSlotIndex: pieceIndex,
        isNewHighScore: isNewHigh,
      );
      _saveGame();

      // 配置アニメーション終了後にクリア
      Future<void>.delayed(const Duration(milliseconds: 200), () {
        state = state.copyWith(lastPlacedCells: const {});
        _checkRefillAndGameOver();
      });
    }

    return true;
  }

  /// ビュー側の消去アニメーション完了後に呼び出す。
  /// clearingCells / lastClearResult をクリアしてゲームオーバー判定を行う。
  void completeClearAnimation() {
    state = state.copyWith(
      clearingCells: const {},
      lastClearResult: null,
      lastPlacedCells: const {},
    );
    _checkRefillAndGameOver();
  }

  /// [pieceIndex]番目のピースを([row], [col])に配置可能か判定する。
  bool canPlace(int pieceIndex, int row, int col) {
    final piece = state.pieces[pieceIndex];
    if (piece == null) {
      return false;
    }

    final board = Board.from(state.board);
    return board.canPlace(piece, row, col);
  }

  /// ゲームをリセットして新しいラウンドを開始する（クラシックモード）。
  void resetGame() {
    final emptyBoard =
        List.generate(Board.size, (_) => List.filled(Board.size, false));
    state = BlockPuzzleState(
      board: emptyBoard,
      pieces: generatePieces(emptyBoard, _rng),
      highScore: state.highScore,
      hasSavedClassicGame: true,
    );
    _saveClassicGame();
  }

  /// 保存済みクラシックゲームをキャッシュから同期的に復元する。
  void resumeClassicGame() {
    final cache = _classicCache;
    if (cache == null) {
      resetGame();
      return;
    }
    state = BlockPuzzleState(
      board: cache.board,
      pieces: cache.pieces,
      score: cache.score,
      combo: cache.combo,
      consecutiveNonClearTurns: cache.nonClearTurns,
      highScore: state.highScore,
      isGameOver: cache.isGameOver,
      canContinue: cache.canContinue,
      hasSavedClassicGame: state.hasSavedClassicGame,
    );
  }

  /// リワード広告視聴後にゲームを継続する（クラシックモード専用）。
  ///
  /// 3ピースを全て小さいピースに差し替え、ゲームオーバー状態を解除する。
  /// コンティニューフラグを false に設定して以降の再使用を無効化する。
  void continueGame() {
    const smallPieces = [
      PieceDefinitions.dot,
      PieceDefinitions.dominoH,
      PieceDefinitions.dominoV,
      PieceDefinitions.triominoH,
      PieceDefinitions.triominoV,
      PieceDefinitions.cornerA,
      PieceDefinitions.cornerB,
      PieceDefinitions.cornerC,
      PieceDefinitions.cornerD,
    ];
    final shuffled = [...smallPieces]..shuffle(_rng);
    final newPieces = <Piece?>[shuffled[0], shuffled[1], shuffled[2]];
    state = state.copyWith(
      isGameOver: false,
      canContinue: false,
      pieces: newPieces,
      hasSavedClassicGame: true,
    );
    _saveGame();
  }

  /// ピース補充とゲームオーバー判定を行う。
  void _checkRefillAndGameOver() {
    // フィードバック表示中は次問の準備をスキップ（recordInlineQuizAnswer後に再実行）
    if (state.quizAnswerCorrect != null) {
      return;
    }

    var piecesToCheck = state.pieces;
    if (piecesToCheck.every((p) => p == null)) {
      if (state.isQuizMode) {
        // インラインクイズモード: 空リストにして画面側リスナーが次問を生成するのを待つ
        state = state.copyWith(pieces: []);
        _saveGame();
        return;
      }
      final newPieces = generatePieces(state.board, _rng);
      state = state.copyWith(pieces: newPieces);
      piecesToCheck = newPieces;
    }

    if (piecesToCheck.isEmpty) {
      _saveGame();
      return;
    }

    final board = Board.from(state.board);
    if (!board.canPlaceAny(piecesToCheck)) {
      final levelKey = _currentLevelKey;
      var newHasSaved = state.levelHasSavedGame;
      if (levelKey != null) {
        newHasSaved = Map<String, bool>.from(state.levelHasSavedGame)
          ..[levelKey] = false;
      }
      state = state.copyWith(
        isGameOver: true,
        hasSavedClassicGame: false,
        levelHasSavedGame: newHasSaved,
      );
    }
    _saveGame();
  }

  // ── クイズモード ─────────────────────────────────────────────

  /// クイズモードを開始する。[level] のセーブデータがあれば自動復元する。
  void startQuizMode(LevelFilter level) {
    _currentLevelKey = level.name;
    final levelKey = level.name;
    final cache = _quizModeCaches[levelKey];
    if (cache != null && !cache.isGameOver) {
      state = BlockPuzzleState(
        board: [
          for (final row in cache.board) [...row]
        ],
        pieces: [],
        score: cache.score,
        combo: cache.combo,
        consecutiveNonClearTurns: cache.nonClearTurns,
        isQuizMode: true,
        highScore: state.levelHighScores[levelKey] ?? 0,
        hasSavedClassicGame: state.hasSavedClassicGame,
        levelHighScores: state.levelHighScores,
        levelHasSavedGame: state.levelHasSavedGame,
        sessionCorrectWords: [],
        sessionIncorrectWords: [],
      );
      return;
    }
    final emptyBoard =
        List.generate(Board.size, (_) => List.filled(Board.size, false));
    final newHasSaved = Map<String, bool>.from(state.levelHasSavedGame)
      ..[levelKey] = true;
    state = BlockPuzzleState(
      board: emptyBoard,
      pieces: [],
      highScore: state.levelHighScores[levelKey] ?? 0,
      isQuizMode: true,
      hasSavedClassicGame: state.hasSavedClassicGame,
      levelHighScores: state.levelHighScores,
      levelHasSavedGame: newHasSaved,
      sessionCorrectWords: [],
      sessionIncorrectWords: [],
    );
    // 新規ゲーム開始直後に保存しておく（アプリ強制終了時の復元用）。
    _saveGame();
  }

  /// 現在プレイ中のクイズモードを同じレベル・フィルターのままリスタートする。
  ///
  /// ボードとスコアをリセットし、同じレベルで新規ゲームを開始する。
  /// クイズの単語セットは同じ範囲で引き直される。
  Future<void> restartCurrentQuizMode() async {
    final levelKey = _currentLevelKey;
    if (levelKey == null) {
      return;
    }
    final level = LevelFilter.values.firstWhere(
      (l) => l.name == levelKey,
      orElse: () => LevelFilter.values.first,
    );
    await resetAndStartQuizMode(level);
  }

  /// クイズデータをリセットして [level] を新規ゲームで開始する。
  ///
  /// ボードとスコアをリセットし、SharedPreferences の当該レベルのデータを削除する。
  Future<void> resetAndStartQuizMode(LevelFilter level) async {
    final levelKey = level.name;
    _quizModeCaches.remove(levelKey);

    final prefs = await SharedPreferences.getInstance();
    await Future.wait([
      prefs.remove(_quizBoardKeyFor(levelKey)),
      prefs.remove(_quizPiecesKeyFor(levelKey)),
      prefs.remove(_quizScoreKeyFor(levelKey)),
      prefs.remove(_quizComboKeyFor(levelKey)),
      prefs.remove(_quizNonClearTurnsKeyFor(levelKey)),
      prefs.remove(_quizIsGameOverKeyFor(levelKey)),
      prefs.remove(_quizIsQuizPhaseKeyFor(levelKey)),
    ]);

    // hasSavedGame を false に更新してから新規ゲームを開始する。
    final newHasSaved = Map<String, bool>.from(state.levelHasSavedGame)
      ..[levelKey] = false;
    state = state.copyWith(levelHasSavedGame: newHasSaved);

    startQuizMode(level);
  }

  /// インラインクイズの問題に対してブロックをトレイに準備する。
  ///
  /// 選択形式（stage 0-2）: 同一形状のピースを4スロット表示する。
  /// 入力形式（stage 3-4）: 空スロットで待機し、入力完了後に1ブロックを出現させる。
  void prepareQuizBlocks(QuizQuestion question) {
    final board = Board.from(state.board);
    final piece = _bestFitFromPool(PieceDefinitions.quizEasyPool, board, {});

    if (!board.canPlaceAny([piece])) {
      final levelKey = _currentLevelKey;
      var newHasSaved = state.levelHasSavedGame;
      if (levelKey != null) {
        newHasSaved = Map<String, bool>.from(state.levelHasSavedGame)
          ..[levelKey] = false;
      }
      state = state.copyWith(
        isGameOver: true,
        hasSavedClassicGame: false,
        levelHasSavedGame: newHasSaved,
      );
      _saveGame();
      return;
    }

    final isChoiceFormat = question.format == QuizFormat.enToJaChoice ||
        question.format == QuizFormat.jaToEnChoice;

    state = state.copyWith(
      pieces: isChoiceFormat ? <Piece?>[piece] : [],
      quizSelectedChoiceIndex: null,
    );
    _saveGame();
  }

  /// stage 3/4: 入力完了後にトレイへ1ブロックを出現させる。
  void _revealInputBlock() {
    final board = Board.from(state.board);
    final piece = _bestFitFromPool(PieceDefinitions.quizEasyPool, board, {});
    if (board.canPlaceAny([piece])) {
      state = state.copyWith(pieces: <Piece?>[piece]);
    }
  }

  // ── クイズ UI 状態 ───────────────────────────────────────────

  /// 4択: 選択肢インデックスを更新する（ブロックは準備時に既出現済み）。
  void selectQuizChoice(int index) {
    state = state.copyWith(quizSelectedChoiceIndex: index);
  }

  /// letterTap 完了を記録し、トレイに1ブロックを出現させる。
  void completeLetterTapInput({required bool isCorrect}) {
    state = state.copyWith(quizInputIsCorrect: isCorrect);
    _revealInputBlock();
  }

  /// タイピング完了を記録し、トレイに1ブロックを出現させる。
  void completeTypingInput(String text) {
    state = state.copyWith(quizTypedText: text);
    _revealInputBlock();
  }

  /// ボードフラッシュ用フィードバックをセットする。
  void setQuizAnswerFeedback({required bool isCorrect}) {
    state = state.copyWith(
      quizAnswerCorrect: isCorrect,
      quizFeedbackCells: state.lastPlacedCells.isNotEmpty
          ? state.lastPlacedCells
          : state.quizFeedbackCells,
    );
  }

  /// ボードフラッシュをクリアする。
  void clearQuizAnswerFeedback() {
    state = state.copyWith(
      quizAnswerCorrect: null,
      quizFeedbackCells: const <(int, int)>{},
    );
  }

  /// フィードバックバナーを表示する。
  void showQuizFeedback({
    required bool isCorrect,
    required String correctAnswer,
  }) {
    state = state.copyWith(
      quizFeedbackShowing: true,
      quizFeedbackIsCorrect: isCorrect,
      quizFeedbackCorrectAnswer: correctAnswer,
    );
  }

  /// フィードバックバナーを閉じて入力状態をリセットする。
  void hideQuizFeedback() {
    state = state.copyWith(
      quizFeedbackShowing: false,
      quizFeedbackIsCorrect: false,
      quizFeedbackCorrectAnswer: '',
      quizSelectedChoiceIndex: null,
      quizInputIsCorrect: null,
      quizTypedText: null,
    );
  }

  /// クイズ回答結果を記録し、残りのブロックスロットをクリアする。
  void recordInlineQuizAnswer(
    int slot, {
    required bool isCorrect,
    QuizWord? word,
    int overdueBonus = 0,
  }) {
    final clearedPieces = List<Piece?>.filled(state.pieces.length, null);
    final newCorrect = word != null && isCorrect
        ? [...state.sessionCorrectWords, word]
        : state.sessionCorrectWords;
    final newIncorrect = word != null && !isCorrect
        ? [...state.sessionIncorrectWords, word]
        : state.sessionIncorrectWords;

    state = state.copyWith(
      pieces: clearedPieces,
      score: state.score + overdueBonus,
      sessionCorrectWords: newCorrect,
      sessionIncorrectWords: newIncorrect,
    );
    _checkRefillAndGameOver();
  }

/// [pool] 内のピースから盤面に最も有利なピースを返す。
  ///
  /// スコア = 最大ライン消去数 × 100 + 配置可能位置数
  /// 同スコアの候補からはランダムに1つ選ぶ。
  /// 配置可能なピースがない場合は quizEasyPool → dot にフォールバック。
  Piece _bestFitFromPool(
    List<Piece> pool,
    Board board,
    Set<Piece> excluded,
  ) {
    var bestScore = -1;
    final bestCandidates = <Piece>[];

    for (final piece in pool) {
      if (excluded.contains(piece)) {
        continue;
      }
      var maxLineClear = 0;
      var placementCount = 0;
      var maxAdjacency = 0;

      for (var r = 0; r < Board.size; r++) {
        for (var c = 0; c < Board.size; c++) {
          if (!board.canPlace(piece, r, c)) {
            continue;
          }
          placementCount++;
          final sim = board.copy()..place(piece, r, c);
          final lines = sim.checkClearLines().linesCleared;
          if (lines > maxLineClear) {
            maxLineClear = lines;
          }

          // 密集エリアへのフィット度: ピース周囲の既存セル数を計測
          var adj = 0;
          for (final (dr, dc) in piece.offsets) {
            final pr = r + dr;
            final pc = c + dc;
            for (final (nr, nc) in [
              (pr - 1, pc),
              (pr + 1, pc),
              (pr, pc - 1),
              (pr, pc + 1),
            ]) {
              if (nr >= 0 &&
                  nr < Board.size &&
                  nc >= 0 &&
                  nc < Board.size &&
                  board.cells[nr][nc]) {
                adj++;
              }
            }
          }
          if (adj > maxAdjacency) {
            maxAdjacency = adj;
          }
        }
      }

      if (placementCount == 0) {
        continue;
      }

      final score = maxLineClear * 100 + placementCount + maxAdjacency * 10;
      if (score > bestScore) {
        bestScore = score;
        bestCandidates
          ..clear()
          ..add(piece);
      } else if (score == bestScore) {
        bestCandidates.add(piece);
      }
    }

    if (bestCandidates.isNotEmpty) {
      return bestCandidates[_rng.nextInt(bestCandidates.length)];
    }
    final fallback = PieceDefinitions.quizEasyPool
        .where((p) => board.canPlaceAny([p]))
        .toList()
      ..shuffle(_rng);
    return fallback.isNotEmpty ? fallback.first : PieceDefinitions.dot;
  }

  // ── ゲーム状態の永続化 ──────────────────────────────────────

  /// 全データを一括ロードし、キャッシュとスコアを初期化する。
  Future<void> _loadPersistedData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _migrateOldSave(prefs);

      final highScore = prefs.getInt(_highScoreKey) ?? 0;

      final classicBoardStr = prefs.getString(_classicBoardKey);
      if (classicBoardStr != null) {
        try {
          final board = _boardFromString(classicBoardStr);
          if (board.length == Board.size &&
              board.every((r) => r.length == Board.size)) {
            _classicCache = (
              board: board,
              pieces: _piecesFromString(
                prefs.getString(_classicPiecesKey) ?? '',
              ),
              score: prefs.getInt(_classicScoreKey) ?? 0,
              combo: prefs.getInt(_classicComboKey) ?? 0,
              nonClearTurns: prefs.getInt(_classicNonClearTurnsKey) ?? 0,
              isGameOver: prefs.getBool(_classicIsGameOverKey) ?? false,
              canContinue: prefs.getBool(_classicCanContinueKey) ?? true,
            );
          }
        } on Exception catch (_) {
          // データ破損時はキャッシュなし
        }
      }

      // 全レベルのクイズデータをロードする。
      final levelHighScores = <String, int>{};
      final levelHasSavedGame = <String, bool>{};
      for (final level in LevelFilter.values) {
        final key = level.name;
        levelHighScores[key] = prefs.getInt(_levelHighScoreKeyFor(key)) ?? 0;

        final boardStr = prefs.getString(_quizBoardKeyFor(key));
        if (boardStr == null) {
          levelHasSavedGame[key] = false;
          continue;
        }
        try {
          final board = _boardFromString(boardStr);
          if (board.length == Board.size &&
              board.every((r) => r.length == Board.size)) {
            final isGameOver =
                prefs.getBool(_quizIsGameOverKeyFor(key)) ?? false;
            _quizModeCaches[key] = (
              board: board,
              pieces: _piecesFromString(
                prefs.getString(_quizPiecesKeyFor(key)) ?? '',
              ),
              score: prefs.getInt(_quizScoreKeyFor(key)) ?? 0,
              combo: prefs.getInt(_quizComboKeyFor(key)) ?? 0,
              nonClearTurns: prefs.getInt(_quizNonClearTurnsKeyFor(key)) ?? 0,
              isGameOver: isGameOver,
              isQuizPhase: prefs.getBool(_quizIsQuizPhaseKeyFor(key)) ?? false,
            );
            levelHasSavedGame[key] = !isGameOver;
          } else {
            levelHasSavedGame[key] = false;
          }
        } on Exception catch (_) {
          levelHasSavedGame[key] = false;
        }
      }

      final classicCache = _classicCache;
      final hasSavedClassic = classicCache != null && !classicCache.isGameOver;

      state = state.copyWith(
        highScore: highScore,
        hasSavedClassicGame: hasSavedClassic,
        levelHighScores: levelHighScores,
        levelHasSavedGame: levelHasSavedGame,
      );
    } finally {
      if (!_persistedDataLoaded.isCompleted) {
        _persistedDataLoaded.complete();
      }
    }
  }

  /// 現在のゲーム状態を保存する。
  void _saveGame() {
    if (state.isQuizMode) {
      _saveQuizGame();
    } else {
      _saveClassicGame();
    }
  }

  void _saveClassicGame() {
    final s = state;
    // インメモリキャッシュを更新（resume で同期的に使用）
    _classicCache = (
      board: [
        for (final row in s.board) [...row]
      ],
      pieces: [...s.pieces],
      score: s.score,
      combo: s.combo,
      nonClearTurns: s.consecutiveNonClearTurns,
      isGameOver: s.isGameOver,
      canContinue: s.canContinue,
    );
    final shouldSave = !s.isGameOver;
    if (state.hasSavedClassicGame != shouldSave) {
      state = state.copyWith(hasSavedClassicGame: shouldSave);
    }
    SharedPreferences.getInstance().then((prefs) {
      prefs
        ..setString(_classicBoardKey, _boardToString(s.board))
        ..setString(_classicPiecesKey, _piecesToString(s.pieces))
        ..setInt(_classicScoreKey, s.score)
        ..setInt(_classicComboKey, s.combo)
        ..setInt(_classicNonClearTurnsKey, s.consecutiveNonClearTurns)
        ..setBool(_classicIsGameOverKey, s.isGameOver)
        ..setBool(_classicCanContinueKey, s.canContinue);
    });
  }

  void _saveQuizGame() {
    final levelKey = _currentLevelKey;
    if (levelKey == null) {
      return;
    }
    final s = state;
    _quizModeCaches[levelKey] = (
      board: [
        for (final row in s.board) [...row]
      ],
      pieces: [...s.pieces],
      score: s.score,
      combo: s.combo,
      nonClearTurns: s.consecutiveNonClearTurns,
      isGameOver: s.isGameOver,
      isQuizPhase: false,
    );
    SharedPreferences.getInstance().then((prefs) {
      prefs
        ..setString(_quizBoardKeyFor(levelKey), _boardToString(s.board))
        ..setString(_quizPiecesKeyFor(levelKey), _piecesToString(s.pieces))
        ..setInt(_quizScoreKeyFor(levelKey), s.score)
        ..setInt(_quizComboKeyFor(levelKey), s.combo)
        ..setInt(_quizNonClearTurnsKeyFor(levelKey), s.consecutiveNonClearTurns)
        ..setBool(_quizIsGameOverKeyFor(levelKey), s.isGameOver)
        ..setBool(_quizIsQuizPhaseKeyFor(levelKey), false);
    });
  }

  void _saveHighScore(int score) {
    final levelKey = _currentLevelKey;
    if (levelKey == null) {
      return;
    }
    SharedPreferences.getInstance()
        .then((prefs) => prefs.setInt(_levelHighScoreKeyFor(levelKey), score));
  }

  /// [newHigh] を現在レベルの `levelHighScores` に反映したマップを返す。
  Map<String, int> _updatedLevelHighScores(int newHigh) {
    final key = _currentLevelKey;
    if (key == null) {
      return state.levelHighScores;
    }
    return Map<String, int>.from(state.levelHighScores)..[key] = newHigh;
  }

  /// 旧フォーマット（単一スロット）のセーブデータを新フォーマットへ移行する。
  void _migrateOldSave(SharedPreferences prefs) {
    const oldBoardKey = 'block_puzzle_saved_board';
    final oldBoard = prefs.getString(oldBoardKey);
    if (oldBoard == null) {
      return;
    }

    const oldPiecesKey = 'block_puzzle_saved_pieces';
    const oldScoreKey = 'block_puzzle_saved_score';
    const oldComboKey = 'block_puzzle_saved_combo';
    const oldNonClearKey = 'block_puzzle_saved_non_clear_turns';
    const oldIsQuestKey = 'block_puzzle_saved_is_quest_mode';

    final isQuest = prefs.getBool(oldIsQuestKey) ?? false;

    if (!isQuest && prefs.getString(_classicBoardKey) == null) {
      prefs
        ..setString(_classicBoardKey, oldBoard)
        ..setString(
          _classicPiecesKey,
          prefs.getString(oldPiecesKey) ?? '',
        )
        ..setInt(_classicScoreKey, prefs.getInt(oldScoreKey) ?? 0)
        ..setInt(_classicComboKey, prefs.getInt(oldComboKey) ?? 0)
        ..setInt(
          _classicNonClearTurnsKey,
          prefs.getInt(oldNonClearKey) ?? 0,
        )
        ..setBool(_classicIsGameOverKey, false)
        ..setBool(_classicCanContinueKey, true);
    }

    prefs
      ..remove(oldBoardKey)
      ..remove(oldPiecesKey)
      ..remove(oldScoreKey)
      ..remove(oldComboKey)
      ..remove(oldNonClearKey)
      ..remove(oldIsQuestKey)
      ..remove('block_puzzle_saved_quest_level')
      ..remove('block_puzzle_saved_target_score')
      ..remove('block_puzzle_saved_is_quest_complete');
  }

  // ── シリアライズヘルパー ──────────────────────────────────────

  static String _boardToString(List<List<bool>> board) =>
      board.map((row) => row.map((c) => c ? '1' : '0').join()).join(',');

  static List<List<bool>> _boardFromString(String s) => s
      .split(',')
      .map((row) => row.split('').map((c) => c == '1').toList())
      .toList();

  static String _piecesToString(List<Piece?> pieces) => pieces
      .map(
        (p) =>
            p == null ? '-1' : PieceDefinitions.allPieces.indexOf(p).toString(),
      )
      .join(',');

  static List<Piece?> _piecesFromString(String s) =>
      s.split(',').map((idx) {
        final i = int.tryParse(idx) ?? -1;
        if (i < 0 || i >= PieceDefinitions.allPieces.length) {
          return null;
        }
        return PieceDefinitions.allPieces[i];
      }).toList();
}

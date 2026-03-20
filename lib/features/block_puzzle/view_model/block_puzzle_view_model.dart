import 'dart:async';
import 'dart:math';

import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:mono_games/features/block_puzzle/model/board.dart';
import 'package:mono_games/features/block_puzzle/model/piece.dart';
import 'package:mono_games/features/block_puzzle/model/piece_generator.dart';
import 'package:mono_games/features/block_puzzle/model/quest_board_generator.dart';
import 'package:mono_games/features/quiz/model/quiz_word.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shared_preferences/shared_preferences.dart';

part 'block_puzzle_view_model.freezed.dart';
part 'block_puzzle_view_model.g.dart';

const _highScoreKey = 'block_puzzle_high_score';
const _timeAttackHighScoreKey = 'block_puzzle_ta_high_score';
const _classicBoardKey = 'block_puzzle_classic_board';
const _classicPiecesKey = 'block_puzzle_classic_pieces';
const _classicScoreKey = 'block_puzzle_classic_score';
const _classicComboKey = 'block_puzzle_classic_combo';
const _classicNonClearTurnsKey = 'block_puzzle_classic_non_clear_turns';
const _classicIsGameOverKey = 'block_puzzle_classic_is_game_over';
const _classicCanContinueKey = 'block_puzzle_classic_can_continue';
const _quizBoardKey = 'block_puzzle_quiz_board';
const _quizPiecesKey = 'block_puzzle_quiz_pieces';
const _quizScoreKey = 'block_puzzle_quiz_score';
const _quizComboKey = 'block_puzzle_quiz_combo';
const _quizNonClearTurnsKey = 'block_puzzle_quiz_non_clear_turns';
const _quizMultiplierKey = 'block_puzzle_quiz_multiplier';
const _quizIsGameOverKey = 'block_puzzle_quiz_is_game_over';
const _quizIsQuizPhaseKey = 'block_puzzle_quiz_is_quiz_phase';
const _questMaxLevelKey = 'block_puzzle_quest_max_level';
const _questBoardKey = 'block_puzzle_quest_board';
const _questPiecesKey = 'block_puzzle_quest_pieces';
const _questScoreKey = 'block_puzzle_quest_score';
const _questComboKey = 'block_puzzle_quest_combo';
const _questNonClearTurnsKey = 'block_puzzle_quest_non_clear_turns';
const _questLevelKey = 'block_puzzle_quest_level';
const _questTargetScoreKey = 'block_puzzle_quest_target_score';
const _questIsGameOverKey = 'block_puzzle_quest_is_game_over';
const _questIsCompleteKey = 'block_puzzle_quest_is_complete';
const _questNoiseBoardKey = 'block_puzzle_quest_noise_board';

const _streakToMedium = 3;
const _streakToHard = 6;

typedef _QuizModeCache = ({
  List<List<bool>> board,
  List<Piece?> pieces,
  int score,
  int combo,
  int nonClearTurns,
  int quizMultiplier,
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

typedef _QuestCache = ({
  List<List<bool>> board,
  List<Piece?> pieces,
  int score,
  int combo,
  int nonClearTurns,
  int questLevel,
  int targetScore,
  bool isGameOver,
  bool isQuestComplete,
  List<List<int>> noiseBoard,
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

    /// クエストモードかどうか。
    @Default(false) bool isQuestMode,

    /// クエストの現在レベル（1始まり）。
    @Default(1) int questLevel,

    /// クエスト達成目標スコア（0 = クラシックモード）。
    @Default(0) int targetScore,

    /// クエスト達成済みかどうか。
    @Default(false) bool isQuestComplete,

    /// タイムアタックモードかどうか。
    @Default(false) bool isTimeAttackMode,

    /// タイムアタックの残り秒数（90秒スタート。ライン消去で+3秒回復）。
    @Default(90) int timeAttackRemainingSeconds,

    /// タイムアタック完了フラグ（タイマー終了時にtrue）。
    @Default(false) bool isTimeAttackComplete,

    /// タイムアタックのベストスコア。
    @Default(0) int timeAttackHighScore,

    /// リワード広告でコンティニュー可能かどうか（クラシックモード専用・1回限り）。
    @Default(true) bool canContinue,

    /// 再開可能なクラシックゲームが保存されているかどうか。
    @Default(false) bool hasSavedClassicGame,

    /// 再開可能なクエストゲームが保存されているかどうか。
    @Default(false) bool hasSavedQuestGame,

    /// クエストモードの解放済み最大レベル（1始まり）。
    @Default(1) int maxUnlockedLevel,

    /// ノイズブロックHP盤面（0=通常, 1-5=HP）。クエストモード専用。
    @Default(<List<int>>[]) List<List<int>> noiseBoard,

    /// ダメージを受けたノイズセル（フラッシュアニメーション用）。
    @Default(<(int, int)>{}) Set<(int, int)> damagedNoiseCells,

    /// タイムアタックカウントダウン中かどうか。
    @Default(false) bool isTimeAttackCountingDown,

    /// カウントダウンの残り秒数（3→2→1→0）。
    @Default(0) int timeAttackCountdownSeconds,

    /// クイズ連動モードかどうか。
    @Default(false) bool isQuizMode,

    /// クイズフェーズ（3ピース配置完了→カードスワイプ中）かどうか。
    @Default(false) bool isQuizPhase,

    /// クイズ連続全問正解による得点倍率（デフォルト1、全問正解のたびに+1）。
    @Default(1) int quizMultiplier,

    /// クイズセッション中に正解した単語リスト（ゲームオーバー時の表示用）。
    @Default([]) List<QuizWord> sessionCorrectWords,

    /// クイズセッション中に不正解だった単語リスト（ゲームオーバー時の表示用）。
    @Default([]) List<QuizWord> sessionIncorrectWords,
  }) = _BlockPuzzleState;
}

/// Noir Mindパズルゲームのビューモデル。
@riverpod
class BlockPuzzleViewModel extends _$BlockPuzzleViewModel {
  final _rng = Random();
  Timer? _timeAttackTimer;

  // 起動時に読み込んだセーブデータのインメモリキャッシュ。
  // resumeClassicGame / resumeQuestGame で同期的に復元するために使用。
  _ClassicCache? _classicCache;
  _QuestCache? _questCache;
  _QuizModeCache? _quizModeCache;

  // クイズモード用バッグ（全ピースを1巡してからリフィル）
  final _quizEasyBag = <Piece>[];
  final _quizMediumBag = <Piece>[];
  final _quizHardBag = <Piece>[];

  // 連続正解ストリーク（クイズモード内で管理）
  var _quizCorrectStreak = 0;

  @override
  BlockPuzzleState build() {
    Future<void>.microtask(_loadPersistedData);
    ref.onDispose(() => _timeAttackTimer?.cancel());
    final emptyBoard =
        List.generate(Board.size, (_) => List.filled(Board.size, false));
    return BlockPuzzleState(
      board: emptyBoard,
      pieces: generatePieces(emptyBoard, _rng),
    );
  }

  /// [pieceIndex]番目のピースを([row], [col])に配置する。
  /// 配置成功なら`true`を返す。
  bool placePiece(int pieceIndex, int row, int col) {
    if (state.isTimeAttackCountingDown) {
      return false;
    }
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

    final scoreMultiplier = state.quizMultiplier;

    // 基本スコア: セル数 × 1pt（コンボ倍率を適用）
    var pointsEarned = piece.offsets.length * scoreMultiplier;

    // ライン消去チェック（ボード状態は変更しない）
    final clearResult = board.checkClearLines();

    Board finalBoard;
    if (clearResult.clearedCells.isNotEmpty) {
      // ── ノイズセルのHP処理（クエストモードのみ） ──────────────
      final newNoiseBoard = state.noiseBoard.isNotEmpty
          ? [
              for (final r in state.noiseBoard) [...r]
            ]
          : <List<int>>[];
      final damagedNoise = <(int, int)>{};
      final Set<(int, int)> actualClearCells;

      if (newNoiseBoard.isNotEmpty) {
        final mutable = <(int, int)>{};
        for (final (r, c) in clearResult.clearedCells) {
          final hp = newNoiseBoard[r][c];
          if (hp > 0) {
            final newHp = hp - 1;
            newNoiseBoard[r][c] = newHp;
            if (newHp == 0) {
              mutable.add((r, c)); // HP=0 → 完全クリア
            } else {
              damagedNoise.add((r, c)); // HP残存 → ダメージのみ
            }
          } else {
            mutable.add((r, c)); // 通常セル → クリア
          }
        }

        actualClearCells = mutable;
      } else {
        actualClearCells = clearResult.clearedCells;
      }

      // ラインをクリア（ノイズ生存セルは除外）
      finalBoard = board.clearCells(actualClearCells);

      // 同時消去ライン数分だけコンボを加算（複数行消去でコンボが加速する）
      final newCombo = state.combo + clearResult.linesCleared;

      // クイズモードではライン消去のたびに倍率を+1（最大10）
      final newMultiplier = state.isQuizMode
          ? (state.quizMultiplier + 1).clamp(1, 10)
          : state.quizMultiplier;

      // ライン消去スコア: 10 × ライン数²
      final lineScore =
          10 * clearResult.linesCleared * clearResult.linesCleared;
      // コンボ倍率を適用（クイズコンボ倍率も乗算）
      pointsEarned += lineScore * newCombo * newMultiplier;

      final newScore = state.score + pointsEarned;
      final isNewHigh = !state.isTimeAttackMode && newScore > state.highScore;
      final newHighScore = isNewHigh ? newScore : state.highScore;

      // クエスト達成: 全ノイズブロックHP=0
      final questComplete = state.isQuestMode &&
          !state.isQuestComplete &&
          newNoiseBoard.isNotEmpty &&
          newNoiseBoard.every((r) => r.every((hp) => hp == 0));

      if (isNewHigh) {
        _saveHighScore(newHighScore);
      }

      // タイムアタック: ライン消去ごとに+2秒回復
      final newTimeRemaining = state.isTimeAttackMode
          ? state.timeAttackRemainingSeconds + clearResult.linesCleared * 2
          : state.timeAttackRemainingSeconds;

      // 消去済みボードで状態を更新（参照共有を防ぐためディープコピー）
      final boardCopy = [
        for (final r in finalBoard.cells) [...r]
      ];

      state = state.copyWith(
        board: boardCopy,
        noiseBoard: newNoiseBoard,
        damagedNoiseCells: damagedNoise,
        pieces: newPieces,
        clearingCells: actualClearCells,
        score: newScore,
        highScore: newHighScore,
        combo: newCombo,
        consecutiveNonClearTurns: 0,
        timeAttackRemainingSeconds: newTimeRemaining,
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
        quizMultiplier: newMultiplier,
        lastPlacedCells: placedCells,
        isNewHighScore: isNewHigh,
        isQuestComplete: questComplete,
        // クエスト達成でセーブ不要になる
        hasSavedQuestGame: !questComplete && state.hasSavedQuestGame,
      );
      // 配置直後に状態を永続化（アニメーション前でも最新スコアを保存）
      _saveGame();
      // クリア完了はビュー側のアニメーション終了時に completeClearAnimation()
      // で通知する。
    } else {
      finalBoard = board;

      final nonClearTurns = state.consecutiveNonClearTurns + 1;
      final newCombo = nonClearTurns >= 3 ? 0 : state.combo;
      final newMultiplier =
          state.isQuizMode && nonClearTurns >= 3 ? 1 : state.quizMultiplier;
      final newScore = state.score + pointsEarned;
      final isNewHigh = !state.isTimeAttackMode && newScore > state.highScore;
      final newHighScore = isNewHigh ? newScore : state.highScore;
      // クエストモードではスコアによるクリアなし（ノイズ消去のみ）
      const questComplete = false;

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
        combo: newCombo,
        quizMultiplier: newMultiplier,
        consecutiveNonClearTurns: nonClearTurns,
        lastClearResult: null,
        lastPlacedCells: placedCells,
        isNewHighScore: isNewHigh,
        isQuestComplete: questComplete,
        // クエスト達成でセーブ不要になる
        hasSavedQuestGame: !questComplete && state.hasSavedQuestGame,
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
  /// clearingCells / lastClearResult / damagedNoiseCells をクリアして
  /// ゲームオーバー判定を行う。
  void completeClearAnimation() {
    state = state.copyWith(
      clearingCells: const {},
      lastClearResult: null,
      lastPlacedCells: const {},
      damagedNoiseCells: const {},
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
    _timeAttackTimer?.cancel();
    final emptyBoard =
        List.generate(Board.size, (_) => List.filled(Board.size, false));
    state = BlockPuzzleState(
      board: emptyBoard,
      pieces: generatePieces(emptyBoard, _rng),
      highScore: state.highScore,
      timeAttackHighScore: state.timeAttackHighScore,
      hasSavedQuestGame: state.hasSavedQuestGame,
      hasSavedClassicGame: true,
      maxUnlockedLevel: state.maxUnlockedLevel,
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
      timeAttackHighScore: state.timeAttackHighScore,
      isGameOver: cache.isGameOver,
      canContinue: cache.canContinue,
      hasSavedClassicGame: state.hasSavedClassicGame,
      hasSavedQuestGame: state.hasSavedQuestGame,
      maxUnlockedLevel: state.maxUnlockedLevel,
    );
  }

  /// クエストモードで指定レベルを開始する。
  void startQuestLevel(int level) {
    _timeAttackTimer?.cancel();
    final result = generateQuestBoardAndNoise(level);
    state = BlockPuzzleState(
      board: result.board,
      noiseBoard: result.noiseBoard,
      pieces: generatePieces(result.board, _rng),
      highScore: state.highScore,
      timeAttackHighScore: state.timeAttackHighScore,
      isQuestMode: true,
      questLevel: level,
      hasSavedClassicGame: state.hasSavedClassicGame,
      hasSavedQuestGame: true,
      maxUnlockedLevel: state.maxUnlockedLevel,
    );
    _saveQuestGame();
  }

  /// 保存済みクエストゲームをキャッシュから同期的に復元する。
  void resumeQuestGame() {
    final cache = _questCache;
    if (cache == null) {
      startQuestLevel(1);
      return;
    }
    state = BlockPuzzleState(
      board: cache.board,
      noiseBoard: cache.noiseBoard,
      pieces: cache.pieces,
      score: cache.score,
      combo: cache.combo,
      consecutiveNonClearTurns: cache.nonClearTurns,
      highScore: state.highScore,
      timeAttackHighScore: state.timeAttackHighScore,
      isQuestMode: true,
      questLevel: cache.questLevel,
      isQuestComplete: cache.isQuestComplete,
      isGameOver: cache.isGameOver,
      hasSavedClassicGame: state.hasSavedClassicGame,
      hasSavedQuestGame: state.hasSavedQuestGame,
      maxUnlockedLevel: state.maxUnlockedLevel,
    );
  }

  /// 現在のクエストレベルをリトライする。
  void retryQuestLevel() {
    startQuestLevel(state.questLevel);
  }

  /// 指定レベルをクリアし、次のレベルを解放する。
  Future<void> completeQuestLevel(int level) async {
    final next = level + 1;
    if (next > state.maxUnlockedLevel) {
      state = state.copyWith(maxUnlockedLevel: next);
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_questMaxLevelKey, next);
    }
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
    var piecesToCheck = state.pieces;
    if (piecesToCheck.every((p) => p == null)) {
      // クイズモードではクイズフェーズへ切り替えてピーストレイをクリア
      if (state.isQuizMode) {
        state = state.copyWith(
          isQuizPhase: true,
          pieces: [null, null, null],
        );
        _saveGame();
        return;
      }
      final newPieces = generatePieces(state.board, _rng);
      state = state.copyWith(pieces: newPieces);
      piecesToCheck = newPieces;
    }

    final board = Board.from(state.board);
    if (!board.canPlaceAny(piecesToCheck)) {
      _timeAttackTimer?.cancel();
      // タイムアタックの手詰まりは即終了→結果オーバーレイを表示
      final isNewBest =
          state.isTimeAttackMode && state.score > state.timeAttackHighScore;
      final newBest = isNewBest ? state.score : state.timeAttackHighScore;
      if (isNewBest) {
        _saveTimeAttackHighScore(newBest);
      }
      state = state.copyWith(
        isGameOver: true,
        isTimeAttackComplete: state.isTimeAttackMode,
        timeAttackHighScore: newBest,
        isNewHighScore: isNewBest,
        // ゲームオーバーで該当モードは再開不可
        hasSavedClassicGame: state.isQuestMode && state.hasSavedClassicGame,
        hasSavedQuestGame: !state.isQuestMode && state.hasSavedQuestGame,
      );
    }
    _saveGame();
  }

  // ── クイズモード ─────────────────────────────────────────────

  /// クイズモードを開始する。保存済みデータがあれば自動復元する。
  void startQuizMode() {
    _timeAttackTimer?.cancel();
    _quizCorrectStreak = 0;
    _quizEasyBag.clear();
    _quizMediumBag.clear();
    _quizHardBag.clear();
    final cache = _quizModeCache;
    if (cache != null && !cache.isGameOver) {
      // キャッシュからリストアする。全ピース未配置（全null）ならクイズフェーズへ。
      // isQuizPhase=falseで保存された旧データも pieces.every(null) で救済する。
      final restoreAsQuizPhase =
          cache.isQuizPhase || cache.pieces.every((p) => p == null);
      state = BlockPuzzleState(
        board: [
          for (final row in cache.board) [...row]
        ],
        pieces: restoreAsQuizPhase
            ? List.filled(3, null)
            : [...cache.pieces],
        score: cache.score,
        combo: cache.combo,
        consecutiveNonClearTurns: cache.nonClearTurns,
        quizMultiplier: cache.quizMultiplier,
        isQuizMode: true,
        isQuizPhase: restoreAsQuizPhase,
        highScore: state.highScore,
        hasSavedClassicGame: state.hasSavedClassicGame,
        hasSavedQuestGame: state.hasSavedQuestGame,
        maxUnlockedLevel: state.maxUnlockedLevel,
        timeAttackHighScore: state.timeAttackHighScore,
      );
      return;
    }
    final emptyBoard =
        List.generate(Board.size, (_) => List.filled(Board.size, false));
    state = BlockPuzzleState(
      board: emptyBoard,
      pieces: generatePieces(emptyBoard, _rng),
      highScore: state.highScore,
      isQuizMode: true,
      hasSavedClassicGame: state.hasSavedClassicGame,
      hasSavedQuestGame: state.hasSavedQuestGame,
      maxUnlockedLevel: state.maxUnlockedLevel,
      timeAttackHighScore: state.timeAttackHighScore,
      sessionCorrectWords: [],
      sessionIncorrectWords: [],
    );
  }

  /// クイズフェーズを終了してボード配置モードに戻る。
  ///
  /// [comboActive] が true の場合、得点倍率を+1する。
  /// false の場合は1にリセットする。
  void endQuizPhase({bool comboActive = false}) {
    final newMultiplier = comboActive
        ? (state.quizMultiplier + 1).clamp(1, 10)
        : state.quizMultiplier;
    state = state.copyWith(isQuizPhase: false, quizMultiplier: newMultiplier);
    final board = Board.from(state.board);
    if (!board.canPlaceAny(state.pieces)) {
      state = state.copyWith(isGameOver: true);
    }
    _saveGame();
  }

  /// クイズ1問の回答結果から[slot]番スロットにピースを追加する。
  ///
  /// ストリーク × 充填率 の2軸でピースを選択:
  /// - 充填率 >= 75%: 常にEasy（サバイバル優先）
  /// - 不正解: streak リセット。充填率 < 65% なら Hard、65%以上なら Medium
  /// - 正解 streak 0-2: Easy / 3-5: Medium / 6+: Hard
  ///
  /// 各ティア内はバッグ方式（全ピースを1巡してからリフィル）で重複を抑制する。
  void addQuizPiece(
    int slot, {
    required bool isCorrect,
    QuizWord? word,
  }) {
    if (isCorrect) {
      _quizCorrectStreak++;
    } else {
      _quizCorrectStreak = 0;
    }

    final board = Board.from(state.board);
    final fillRate = _boardFillRate(board);
    final Piece piece;

    if (fillRate >= 0.75) {
      piece = _drawFromQuizBag(
        _quizEasyBag, PieceDefinitions.quizEasyPool, board,
      );
    } else if (!isCorrect) {
      piece = fillRate < 0.65
          ? _drawFromQuizBag(
              _quizHardBag, PieceDefinitions.quizHardPool, board,
            )
          : _drawFromQuizBag(
              _quizMediumBag, PieceDefinitions.quizMediumPool, board,
            );
    } else if (_quizCorrectStreak >= _streakToHard) {
      piece = _drawFromQuizBag(
        _quizHardBag, PieceDefinitions.quizHardPool, board,
      );
    } else if (_quizCorrectStreak >= _streakToMedium) {
      piece = _drawFromQuizBag(
        _quizMediumBag, PieceDefinitions.quizMediumPool, board,
      );
    } else {
      piece = _drawFromQuizBag(
        _quizEasyBag, PieceDefinitions.quizEasyPool, board,
      );
    }

    final newPieces = List<Piece?>.from(state.pieces);
    newPieces[slot] = piece;

    final newCorrect = word != null && isCorrect
        ? [...state.sessionCorrectWords, word]
        : state.sessionCorrectWords;
    final newIncorrect = word != null && !isCorrect
        ? [...state.sessionIncorrectWords, word]
        : state.sessionIncorrectWords;

    state = state.copyWith(
      pieces: newPieces,
      sessionCorrectWords: newCorrect,
      sessionIncorrectWords: newIncorrect,
    );
    _saveGame();
  }

  /// [bag]からピースを1枚引く（バッグが空なら[pool]でリフィル）。
  ///
  /// バッグ内で配置可能な先頭ピースを返す。
  /// バッグに配置可能なピースがない場合はeasyPoolにフォールバック。
  Piece _drawFromQuizBag(
    List<Piece> bag,
    List<Piece> pool,
    Board board,
  ) {
    if (bag.isEmpty) {
      bag
        ..addAll(pool)
        ..shuffle(_rng);
    }
    final idx = bag.indexWhere((p) => board.canPlaceAny([p]));
    if (idx != -1) {
      return bag.removeAt(idx);
    }
    // フォールバック: easyPool から配置可能なピースを選ぶ
    final fallback = PieceDefinitions.quizEasyPool
        .where((p) => board.canPlaceAny([p]))
        .toList()
      ..shuffle(_rng);
    return fallback.isNotEmpty ? fallback.first : PieceDefinitions.dot;
  }

  double _boardFillRate(Board board) {
    const total = Board.size * Board.size;
    final filled = board.cells.expand((r) => r).where((c) => c).length;
    return filled / total;
  }

  // ── タイムアタック ──────────────────────────────────────────

  /// タイムアタックモードを開始する（3秒カウントダウン → 90秒ゲーム開始）。
  void startTimeAttack() {
    _timeAttackTimer?.cancel();
    final emptyBoard =
        List.generate(Board.size, (_) => List.filled(Board.size, false));
    state = BlockPuzzleState(
      board: emptyBoard,
      pieces: generatePieces(emptyBoard, _rng),
      highScore: state.highScore,
      isTimeAttackMode: true,
      isTimeAttackCountingDown: true,
      timeAttackCountdownSeconds: 3,
      timeAttackHighScore: state.timeAttackHighScore,
      hasSavedClassicGame: state.hasSavedClassicGame,
      hasSavedQuestGame: state.hasSavedQuestGame,
      maxUnlockedLevel: state.maxUnlockedLevel,
    );
    _startCountdownTimer();
  }

  /// タイムアタックをリトライする。
  void retryTimeAttack() => startTimeAttack();

  /// 3秒カウントダウンを行い、0になったらゲームタイマーを起動する。
  void _startCountdownTimer() {
    _timeAttackTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      final cd = state.timeAttackCountdownSeconds - 1;
      if (cd <= 0) {
        _timeAttackTimer?.cancel();
        state = state.copyWith(
          isTimeAttackCountingDown: false,
          timeAttackCountdownSeconds: 0,
        );
        _startTimeAttackTimer();
      } else {
        state = state.copyWith(timeAttackCountdownSeconds: cd);
      }
    });
  }

  void _startTimeAttackTimer() {
    _timeAttackTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!state.isTimeAttackMode) {
        _timeAttackTimer?.cancel();
        return;
      }
      final remaining = state.timeAttackRemainingSeconds - 1;
      if (remaining <= 0) {
        _timeAttackTimer?.cancel();
        final isNewBest = state.score > state.timeAttackHighScore;
        final newBest = isNewBest ? state.score : state.timeAttackHighScore;
        if (isNewBest) {
          _saveTimeAttackHighScore(newBest);
        }
        state = state.copyWith(
          timeAttackRemainingSeconds: 0,
          isTimeAttackComplete: true,
          timeAttackHighScore: newBest,
          isNewHighScore: isNewBest,
        );
      } else {
        state = state.copyWith(timeAttackRemainingSeconds: remaining);
      }
    });
  }

  // ── ゲーム状態の永続化 ──────────────────────────────────────

  /// 全データを一括ロードし、キャッシュとスコアを初期化する。
  Future<void> _loadPersistedData() async {
    final prefs = await SharedPreferences.getInstance();
    _migrateOldSave(prefs);

    final highScore = prefs.getInt(_highScoreKey) ?? 0;
    final taHighScore = prefs.getInt(_timeAttackHighScoreKey) ?? 0;

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

    final questBoardStr = prefs.getString(_questBoardKey);
    if (questBoardStr != null) {
      try {
        final board = _boardFromString(questBoardStr);
        if (board.length == Board.size &&
            board.every((r) => r.length == Board.size)) {
          _questCache = (
            board: board,
            pieces: _piecesFromString(
              prefs.getString(_questPiecesKey) ?? '',
            ),
            score: prefs.getInt(_questScoreKey) ?? 0,
            combo: prefs.getInt(_questComboKey) ?? 0,
            nonClearTurns: prefs.getInt(_questNonClearTurnsKey) ?? 0,
            questLevel: prefs.getInt(_questLevelKey) ?? 1,
            targetScore: prefs.getInt(_questTargetScoreKey) ?? 0,
            isGameOver: prefs.getBool(_questIsGameOverKey) ?? false,
            isQuestComplete: prefs.getBool(_questIsCompleteKey) ?? false,
            noiseBoard: _noiseBoardFromString(
              prefs.getString(_questNoiseBoardKey) ?? '',
            ),
          );
        }
      } on Exception catch (_) {
        // データ破損時はキャッシュなし
      }
    }

    final quizBoardStr = prefs.getString(_quizBoardKey);
    if (quizBoardStr != null) {
      try {
        final board = _boardFromString(quizBoardStr);
        if (board.length == Board.size &&
            board.every((r) => r.length == Board.size)) {
          _quizModeCache = (
            board: board,
            pieces: _piecesFromString(
              prefs.getString(_quizPiecesKey) ?? '',
            ),
            score: prefs.getInt(_quizScoreKey) ?? 0,
            combo: prefs.getInt(_quizComboKey) ?? 0,
            nonClearTurns: prefs.getInt(_quizNonClearTurnsKey) ?? 0,
            quizMultiplier: prefs.getInt(_quizMultiplierKey) ?? 1,
            isGameOver: prefs.getBool(_quizIsGameOverKey) ?? false,
            isQuizPhase: prefs.getBool(_quizIsQuizPhaseKey) ?? false,
          );
        }
      } on Exception catch (_) {
        // データ破損時はキャッシュなし
      }
    }

    final classicCache = _classicCache;
    final questCache = _questCache;
    final hasSavedClassic = classicCache != null && !classicCache.isGameOver;
    final hasSavedQuest = questCache != null &&
        !questCache.isGameOver &&
        !questCache.isQuestComplete;
    final savedMaxLevel = prefs.getInt(_questMaxLevelKey) ?? 1;

    state = state.copyWith(
      highScore: highScore,
      timeAttackHighScore: taHighScore,
      hasSavedClassicGame: hasSavedClassic,
      hasSavedQuestGame: hasSavedQuest,
      maxUnlockedLevel: savedMaxLevel > state.maxUnlockedLevel
          ? savedMaxLevel
          : state.maxUnlockedLevel,
    );
  }

  /// 現在のゲーム状態を保存する。タイムアタックは永続化しない。
  void _saveGame() {
    if (state.isTimeAttackMode) {
      return;
    }
    if (state.isQuestMode) {
      _saveQuestGame();
    } else if (state.isQuizMode) {
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

  void _saveQuestGame() {
    final s = state;
    // インメモリキャッシュを更新（resume で同期的に使用）
    _questCache = (
      board: [
        for (final row in s.board) [...row]
      ],
      pieces: [...s.pieces],
      score: s.score,
      combo: s.combo,
      nonClearTurns: s.consecutiveNonClearTurns,
      questLevel: s.questLevel,
      targetScore: s.targetScore,
      isGameOver: s.isGameOver,
      isQuestComplete: s.isQuestComplete,
      noiseBoard: [
        for (final row in s.noiseBoard) [...row]
      ],
    );
    final canResume = !s.isGameOver && !s.isQuestComplete;
    if (state.hasSavedQuestGame != canResume) {
      state = state.copyWith(hasSavedQuestGame: canResume);
    }
    SharedPreferences.getInstance().then((prefs) {
      prefs
        ..setString(_questBoardKey, _boardToString(s.board))
        ..setString(_questPiecesKey, _piecesToString(s.pieces))
        ..setInt(_questScoreKey, s.score)
        ..setInt(_questComboKey, s.combo)
        ..setInt(_questNonClearTurnsKey, s.consecutiveNonClearTurns)
        ..setInt(_questLevelKey, s.questLevel)
        ..setInt(_questTargetScoreKey, s.targetScore)
        ..setBool(_questIsGameOverKey, s.isGameOver)
        ..setBool(_questIsCompleteKey, s.isQuestComplete)
        ..setString(_questNoiseBoardKey, _noiseBoardToString(s.noiseBoard));
    });
  }

  void _saveQuizGame() {
    final s = state;
    _quizModeCache = (
      board: [
        for (final row in s.board) [...row]
      ],
      pieces: [...s.pieces],
      score: s.score,
      combo: s.combo,
      nonClearTurns: s.consecutiveNonClearTurns,
      quizMultiplier: s.quizMultiplier,
      isGameOver: s.isGameOver,
      isQuizPhase: s.isQuizPhase,
    );
    SharedPreferences.getInstance().then((prefs) {
      prefs
        ..setString(_quizBoardKey, _boardToString(s.board))
        ..setString(_quizPiecesKey, _piecesToString(s.pieces))
        ..setInt(_quizScoreKey, s.score)
        ..setInt(_quizComboKey, s.combo)
        ..setInt(_quizNonClearTurnsKey, s.consecutiveNonClearTurns)
        ..setInt(_quizMultiplierKey, s.quizMultiplier)
        ..setBool(_quizIsGameOverKey, s.isGameOver)
        ..setBool(_quizIsQuizPhaseKey, s.isQuizPhase);
    });
  }

  void _saveHighScore(int score) {
    SharedPreferences.getInstance()
        .then((prefs) => prefs.setInt(_highScoreKey, score));
  }

  void _saveTimeAttackHighScore(int score) {
    SharedPreferences.getInstance()
        .then((prefs) => prefs.setInt(_timeAttackHighScoreKey, score));
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
    const oldQuestLevelKey = 'block_puzzle_saved_quest_level';
    const oldTargetScoreKey = 'block_puzzle_saved_target_score';
    const oldIsQuestCompleteKey = 'block_puzzle_saved_is_quest_complete';

    final isQuest = prefs.getBool(oldIsQuestKey) ?? false;

    if (isQuest && prefs.getString(_questBoardKey) == null) {
      prefs
        ..setString(_questBoardKey, oldBoard)
        ..setString(
          _questPiecesKey,
          prefs.getString(oldPiecesKey) ?? '',
        )
        ..setInt(_questScoreKey, prefs.getInt(oldScoreKey) ?? 0)
        ..setInt(_questComboKey, prefs.getInt(oldComboKey) ?? 0)
        ..setInt(
          _questNonClearTurnsKey,
          prefs.getInt(oldNonClearKey) ?? 0,
        )
        ..setInt(
          _questLevelKey,
          prefs.getInt(oldQuestLevelKey) ?? 1,
        )
        ..setInt(
          _questTargetScoreKey,
          prefs.getInt(oldTargetScoreKey) ?? 0,
        )
        ..setBool(_questIsGameOverKey, false)
        ..setBool(
          _questIsCompleteKey,
          prefs.getBool(oldIsQuestCompleteKey) ?? false,
        );
    } else if (!isQuest && prefs.getString(_classicBoardKey) == null) {
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
      ..remove(oldQuestLevelKey)
      ..remove(oldTargetScoreKey)
      ..remove(oldIsQuestCompleteKey);
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

  /// ノイズボードを文字列にシリアライズする。例: "00010000,00000020,..."
  static String _noiseBoardToString(List<List<int>> nb) {
    if (nb.isEmpty) {
      return '';
    }
    return nb.map((row) => row.join()).join(',');
  }

  /// 文字列からノイズボードをデシリアライズする。
  static List<List<int>> _noiseBoardFromString(String s) {
    if (s.isEmpty) {
      return [];
    }
    try {
      final rows = s
          .split(',')
          .map(
            (row) => row.split('').map((c) => int.tryParse(c) ?? 0).toList(),
          )
          .toList();
      if (rows.length == Board.size &&
          rows.every((r) => r.length == Board.size)) {
        return rows;
      }
    } on Exception catch (_) {
      // データ破損時は空を返す
    }
    return [];
  }
}

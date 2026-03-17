import 'dart:async';
import 'dart:math';

import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:mono_games/features/block_puzzle/model/board.dart';
import 'package:mono_games/features/block_puzzle/model/piece.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shared_preferences/shared_preferences.dart';

part 'block_puzzle_view_model.freezed.dart';
part 'block_puzzle_view_model.g.dart';

const _highScoreKey = 'block_puzzle_high_score';
const _timeAttackHighScoreKey = 'block_puzzle_ta_high_score';

// クラシックモードの永続化キー
const _classicBoardKey = 'block_puzzle_classic_board';
const _classicPiecesKey = 'block_puzzle_classic_pieces';
const _classicScoreKey = 'block_puzzle_classic_score';
const _classicComboKey = 'block_puzzle_classic_combo';
const _classicNonClearTurnsKey = 'block_puzzle_classic_non_clear_turns';
const _classicIsGameOverKey = 'block_puzzle_classic_is_game_over';
const _classicCanContinueKey = 'block_puzzle_classic_can_continue';

// クエストモードの永続化キー
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

// クラシックゲームのインメモリキャッシュ型
typedef _ClassicCache = ({
  List<List<bool>> board,
  List<Piece?> pieces,
  int score,
  int combo,
  int nonClearTurns,
  bool isGameOver,
  bool canContinue,
});

// クエストゲームのインメモリキャッシュ型
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

  @override
  BlockPuzzleState build() {
    final highScore = _loadHighScore();
    final taHighScore = _loadTimeAttackHighScore();
    _loadSavedGames();
    final emptyBoard =
        List.generate(Board.size, (_) => List.filled(Board.size, false));
    ref.onDispose(() => _timeAttackTimer?.cancel());
    return BlockPuzzleState(
      board: emptyBoard,
      pieces: _generatePieces(emptyBoard),
      highScore: highScore,
      timeAttackHighScore: taHighScore,
    );
  }

  /// [pieceIndex]番目のピースを([row], [col])に配置する。
  /// 配置成功なら`true`を返す。
  bool placePiece(int pieceIndex, int row, int col) {
    // カウントダウン中は配置不可
    if (state.isTimeAttackCountingDown) {
      return false;
    }
    final piece = state.pieces[pieceIndex];
    if (piece == null) {
      return false;
    }

    // ボードを複製して配置可能か判定
    final board = Board.from(state.board);
    if (!board.canPlace(piece, row, col)) {
      return false;
    }

    // ピースを配置
    board.place(piece, row, col);

    // バウンスアニメーション用に配置セルを記録
    final placedCells = <(int, int)>{};
    for (final (dr, dc) in piece.offsets) {
      placedCells.add((row + dr, col + dc));
    }

    // ピースを使用済みにする
    final newPieces = [...state.pieces];
    newPieces[pieceIndex] = null;

    // 基本スコア: セル数 × 1pt
    var pointsEarned = piece.offsets.length;

    // ライン消去チェック（ボード状態は変更しない）
    final clearResult = board.checkClearLines();

    // 最終ボード状態を準備
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

      // ライン消去スコア: 10 × ライン数²
      final lineScore =
          10 * clearResult.linesCleared * clearResult.linesCleared;
      // コンボ倍率を適用
      pointsEarned += lineScore * newCombo;

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
      // ライン消去なし — 配置済みボードをそのまま使用
      finalBoard = board;

      final nonClearTurns = state.consecutiveNonClearTurns + 1;
      final newCombo = nonClearTurns >= 3 ? 0 : state.combo;
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
        consecutiveNonClearTurns: nonClearTurns,
        lastClearResult: null,
        lastPlacedCells: placedCells,
        isNewHighScore: isNewHigh,
        isQuestComplete: questComplete,
        // クエスト達成でセーブ不要になる
        hasSavedQuestGame: !questComplete && state.hasSavedQuestGame,
      );
      // 配置直後に状態を永続化
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
      pieces: _generatePieces(emptyBoard),
      highScore: state.highScore,
      timeAttackHighScore: state.timeAttackHighScore,
      // クエストのセーブフラグを引き継ぐ
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
    final result = _generateQuestBoardAndNoise(level);
    state = BlockPuzzleState(
      board: result.board,
      noiseBoard: result.noiseBoard,
      pieces: _generatePieces(result.board),
      highScore: state.highScore,
      timeAttackHighScore: state.timeAttackHighScore,
      isQuestMode: true,
      questLevel: level,
      // クラシックのセーブフラグを引き継ぐ
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

  /// レベルに応じたノイズブロックのHP値リストを計算する。
  ///
  /// 設計:
  ///   noiseCount = min(10, level)
  ///   maxHp     = min(5, 1 + (level-1) ÷ 8)  // HP2@L9, HP3@L17, ...
  ///   totalHp   = min(level, noiseCount × maxHp)
  ///   HP分布: base = totalHp ÷ noiseCount, extras = totalHp % noiseCount
  ///           → extras 個は HP(base+1)、残りは HP(base)
  ///
  /// 例: L1  → [1]
  ///     L11 → [2,1,1,1,1,1,1,1,1,1]  (HP2が1個だけ登場)
  ///     L20 → [2,2,2,2,2,2,2,2,2,2]  (全HP2)
  ///     L30 → [3,3,3,3,3,3,3,3,3,3]  (全HP3)
  static List<int> _computeNoiseHPs(int level) {
    final noiseCount = min(10, level);
    final maxHp = min(5, 1 + (level - 1) ~/ 8);
    final totalHp = min(level, noiseCount * maxHp);
    final base = totalHp ~/ noiseCount;
    final extras = totalHp % noiseCount;
    return [
      for (var i = 0; i < noiseCount; i++)
        if (i < extras) base + 1 else base,
    ];
  }

  /// ノイズブロック数別のアイコン形状パターン。
  ///
  /// (dr, dc) はパターン左上からの相対オフセット。
  /// 各カウントに複数バリアントを用意し、(level-1) % variants.length でサイクル。
  ///
  /// ```text
  ///   count=1:  ● dot
  ///   count=2:  | vertical, — horizontal
  ///   count=3:  ┃ line, ∧ chevron, ⌐ corner
  ///   count=4:  ■ square, L-shape, S/Z
  ///   count=5:  + plus, × X, ✓ checkmark
  ///   count=6:  [ bracket, Z/S, ◇ diamond-outline
  ///   count=7:  ◆ diamond-solid, ✳ cross, ⊓ U-shape
  ///   count=8:  ✕ bigX, ○ square-frame, ⊕ cross-circle
  ///   count=9:  ❤ heart, ✿ flower, ⚡ lightning
  ///   count=10: ♣ club, ⬛ bigblock, ✦ star
  /// ```
  static const _noiseIconShapes = <int, List<List<(int, int)>>>{
    1: [
      [(0, 0)],
    ],
    2: [
      [(0, 0), (1, 0)],
      [(0, 0), (0, 1)],
    ],
    3: [
      [(0, 0), (1, 0), (2, 0)],
      [(0, 0), (1, 1), (2, 0)],
      [(0, 0), (0, 1), (1, 0)],
    ],
    4: [
      [(0, 0), (0, 1), (1, 0), (1, 1)],
      [(0, 0), (1, 0), (2, 0), (2, 1)],
      [(0, 1), (1, 0), (1, 1), (2, 0)],
    ],
    5: [
      [(0, 1), (1, 0), (1, 1), (1, 2), (2, 1)],
      [(0, 0), (0, 2), (1, 1), (2, 0), (2, 2)],
      [(0, 0), (1, 1), (2, 0), (2, 1), (2, 2)],
    ],
    6: [
      [(0, 0), (0, 1), (1, 0), (2, 0), (3, 0), (3, 1)],
      [(0, 1), (0, 2), (1, 0), (1, 1), (2, 0), (2, 1)],
      [(0, 1), (1, 0), (1, 2), (2, 0), (2, 2), (3, 1)],
    ],
    7: [
      [(0, 1), (1, 0), (1, 2), (2, 0), (2, 1), (2, 2), (3, 1)],
      [(0, 0), (0, 2), (1, 0), (1, 1), (1, 2), (2, 0), (2, 2)],
      [(0, 0), (0, 2), (1, 0), (1, 2), (2, 0), (2, 1), (2, 2)],
    ],
    8: [
      [(0, 0), (0, 3), (1, 1), (1, 2), (2, 1), (2, 2), (3, 0), (3, 3)],
      [(0, 0), (0, 1), (0, 2), (1, 0), (1, 2), (2, 0), (2, 1), (2, 2)],
      [(0, 1), (1, 0), (1, 2), (2, 0), (2, 1), (2, 2), (3, 0), (3, 2)],
    ],
    9: [
      [(0, 0), (0, 2), (1, 0), (1, 1), (1, 2), (2, 0), (2, 1), (2, 2), (3, 1)],
      [(0, 1), (1, 0), (1, 1), (1, 2), (2, 0), (2, 2), (3, 0), (3, 1), (3, 2)],
      [(0, 1), (0, 2), (1, 1), (1, 2), (2, 0), (2, 1), (2, 2), (3, 0), (3, 1)],
    ],
    10: [
      [
        (0, 1), (1, 0), (1, 1), (1, 2), (2, 0), (2, 1),
        (2, 2), (3, 0), (3, 1), (3, 2),
      ],
      [
        (0, 0), (0, 1), (0, 2), (0, 3), (1, 1), (1, 2),
        (2, 1), (2, 2), (3, 1), (3, 2),
      ],
      [
        (0, 2), (1, 1), (1, 3), (2, 0), (2, 1), (2, 2),
        (2, 3), (2, 4), (3, 1), (3, 3),
      ],
    ],
  };

  /// クエスト用の盤面とノイズブロック配置を生成する。
  ///
  /// アイコン形状パターンでノイズブロックを配置し、
  /// 同じレベルは常に同じ配置になる（シード固定）。
  /// 普通ブロックはノイズを消すための最小限の補助のみ配置する。
  ///
  /// アイコンパターン: _noiseIconShapes を参照。
  ({List<List<bool>> board, List<List<int>> noiseBoard})
      _generateQuestBoardAndNoise(int level) {
    final rng = Random(level * 1337 + 42);
    final board =
        List.generate(Board.size, (_) => List.filled(Board.size, false));
    final noiseBoard =
        List.generate(Board.size, (_) => List.filled(Board.size, 0));

    // ── デュアルゾーン計算 ──────────────────────────────────────
    // アクティブ列数: L1=2, L4=3, L7=4, L10=5, L13=6, L16=7, L19+=8
    final activeCols = min(Board.size, 2 + (level - 1) ~/ 3);
    // 中央寄せで配置
    final colStart = (Board.size - activeCols) ~/ 2;
    final colEnd = colStart + activeCols; // exclusive

    // アクティブ行数: L1=3行, L5=4行, L9=5行, L13=6行, L17=7行, L21+=8行（下から）
    final activeRows = min(Board.size, 3 + (level - 1) ~/ 4);
    final rowStart = Board.size - activeRows; // inclusive

    // ── ノイズHP計算 ────────────────────────────────────────────
    final noiseHPs = _computeNoiseHPs(level);
    final noiseCount = noiseHPs.length;

    // ── アイコン形状でノイズ配置セルを生成 ────────────────────────
    final noisePositions = <(int, int)>[];

    final shapes = _noiseIconShapes[noiseCount]!;
    final shape = shapes[(level - 1) % shapes.length];
    final patternRows = shape.map((p) => p.$1).reduce(max) + 1;
    final patternCols = shape.map((p) => p.$2).reduce(max) + 1;

    if (patternRows <= activeRows && patternCols <= activeCols) {
      // パターンをアクティブゾーン中央に配置
      final startR = rowStart + (activeRows - patternRows) ~/ 2;
      final startC = colStart + (activeCols - patternCols) ~/ 2;
      for (final (dr, dc) in shape) {
        final r = startR + dr;
        final c = startC + dc;
        if (r >= 0 && r < Board.size && c >= 0 && c < Board.size) {
          noisePositions.add((r, c));
        }
      }
    }

    // ── 不足分をランダムで補完 ─────────────────────────────────
    if (noisePositions.length < noiseCount) {
      final usedSet = noisePositions.toSet();
      final available = <(int, int)>[];
      for (var r = rowStart; r < Board.size; r++) {
        for (var c = colStart; c < colEnd; c++) {
          if (!usedSet.contains((r, c))) {
            available.add((r, c));
          }
        }
      }
      available.shuffle(rng);
      noisePositions.addAll(available.take(noiseCount - noisePositions.length));
    }

    // ── ノイズブロックをボードに配置 ─────────────────────────────
    var ni = 0;
    for (final (r, c) in noisePositions) {
      if (ni >= noiseHPs.length) {
        break;
      }
      if (r >= 0 && r < Board.size && c >= 0 && c < Board.size) {
        board[r][c] = true;
        noiseBoard[r][c] = noiseHPs[ni++];
      }
    }

    // ── 普通ブロック: ノイズを消す補助として最小限を配置 ────────────
    // 1ラインあたりの補助ブロック数をレベルで段階的に減らす:
    //   L1-10: 3個、L11-20: 2個、L21-30: 1個、L31+: 0個
    final normalPerLine = max(0, 3 - (level - 1) ~/ 10);
    if (normalPerLine > 0) {
      // 行・列ごとのノイズ数を集計
      final rowNoiseCnt = List.filled(Board.size, 0);
      final colNoiseCnt = List.filled(Board.size, 0);
      for (final (r, c) in noisePositions) {
        if (r >= 0 && r < Board.size && c >= 0 && c < Board.size) {
          rowNoiseCnt[r]++;
          colNoiseCnt[c]++;
        }
      }

      // 補完量が少ない軸（ノイズが集中している軸）を選択
      final totalNormalRows = rowNoiseCnt.fold<int>(
        0,
        (s, n) => n > 0 ? s + max(0, Board.size - n) : s,
      );
      final totalNormalCols = colNoiseCnt.fold<int>(
        0,
        (s, n) => n > 0 ? s + max(0, Board.size - n) : s,
      );
      final useRows = totalNormalRows <= totalNormalCols;
      final targetCounts = useRows ? rowNoiseCnt : colNoiseCnt;

      // ノイズが多い順に補助ライン数を決定 (noiseCount ÷ 4、最小1・最大3)
      final assistLines = max(1, min(3, noiseCount ~/ 4));
      final sortedLines = List.generate(Board.size, (i) => i)
        ..sort((a, b) => targetCounts[b].compareTo(targetCounts[a]));
      final targetLines =
          sortedLines.where((i) => targetCounts[i] > 0).take(assistLines);

      // 各ラインに normalPerLine 個だけ補助ブロックを配置
      for (final lineIdx in targetLines) {
        final empties = <(int, int)>[];
        for (var i = 0; i < Board.size; i++) {
          final r = useRows ? lineIdx : i;
          final c = useRows ? i : lineIdx;
          if (!board[r][c]) {
            empties.add((r, c));
          }
        }
        empties.shuffle(rng);
        final toFill = min(normalPerLine, empties.length);
        for (var i = 0; i < toFill; i++) {
          board[empties[i].$1][empties[i].$2] = true;
          // noiseBoard は 0 のまま（普通ブロック）
        }
      }
    }

    return (board: board, noiseBoard: noiseBoard);
  }

  /// ピース補充とゲームオーバー判定を行う。
  void _checkRefillAndGameOver() {
    // 3ピース全て使用済みなら補充
    var piecesToCheck = state.pieces;
    if (piecesToCheck.every((p) => p == null)) {
      final newPieces = _generatePieces(state.board);
      state = state.copyWith(pieces: newPieces);
      piecesToCheck = newPieces;
    }

    // 現在の（補充後の）ピースで配置可能か判定
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

  /// [piece] が現在の [boardCells] 上でラインクリアに貢献できるか判定する。
  bool _canClearLine(Piece piece, List<List<bool>> boardCells) {
    final baseBoard = Board.from(boardCells);
    for (var r = 0; r < Board.size; r++) {
      for (var c = 0; c < Board.size; c++) {
        if (baseBoard.canPlace(piece, r, c)) {
          final testBoard = baseBoard.copy()..place(piece, r, c);
          if (testBoard.checkClearLines().clearedCells.isNotEmpty) {
            return true;
          }
        }
      }
    }
    return false;
  }

  /// 3ピースのバッチを生成する（クエスト・クラシック共通ロジック）。
  ///
  /// 1. Piece 1: mediumPoolをシャッフルして最初に配置可能なピースを選択。
  ///    mediumPoolに配置可能なピースがなければeasyPoolにフォールバック。
  /// 2. ラインクリア可能ピースをallPieces全体から一括算出（事前計算）。
  ///    P1がクリアできる場合は算出をスキップ。
  /// 3. Piece 2 & 3: ラインクリア候補リストから重複なしでO(1)選択。
  ///    候補なしの場合はallPiecesから重複なし選択。それも不可の場合は完全ランダム。
  /// 4. 小ピース保証: 3セル以下のピースがなければP3を小ピースに置き換え。
  List<Piece> _generatePieces(List<List<bool>> board) {
    final boardObj = Board.from(board);

    // ── Piece 1: mediumPool をシャッフルして配置可能な先頭ピースを選択 ──
    final shuffledMedium = [...PieceDefinitions.mediumPool]..shuffle(_rng);
    var piece1 = shuffledMedium.firstWhere(
      (p) => boardObj.canPlaceAny([p]),
      orElse: () => shuffledMedium.first,
    );
    if (!boardObj.canPlaceAny([piece1])) {
      // mediumPool に配置可能なピースがない → easyPool にフォールバック
      final shuffledEasy = [...PieceDefinitions.easyPool]..shuffle(_rng);
      piece1 = shuffledEasy.firstWhere(
        (p) => boardObj.canPlaceAny([p]),
        orElse: () => piece1,
      );
    }

    // ── ラインクリア可能ピースをallPieces全体から一括算出 ──
    final p1ClearsLine = _canClearLine(piece1, board);
    final lineClearers = p1ClearsLine
        ? <Piece>[]
        : [
            for (final p in PieceDefinitions.allPieces)
              if (_canClearLine(p, board)) p,
          ];

    // ── Piece 2 & 3: 事前計算済みリストから O(1) 選択 ──
    final pieces = <Piece>[piece1];
    for (var i = 0; i < 2; i++) {
      final clearCandidates =
          lineClearers.where((p) => !pieces.contains(p)).toList();
      final allCandidates = clearCandidates.isNotEmpty
          ? clearCandidates
          : PieceDefinitions.allPieces
              .where((p) => !pieces.contains(p))
              .toList();

      pieces.add(
        allCandidates.isNotEmpty
            ? allCandidates[_rng.nextInt(allCandidates.length)]
            : PieceDefinitions.randomFrom(PieceDefinitions.allPieces, _rng),
      );
    }

    // ── 小ピース保証: 3セル以下のピースがなければ P3 を置き換え ──
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
    final hasSmall = pieces.any((p) => p.offsets.length <= 3);
    if (!hasSmall) {
      final available =
          smallPieces.where((p) => !pieces.sublist(0, 2).contains(p)).toList();
      final pool = available.isNotEmpty ? available : smallPieces;
      pieces[2] = pool[_rng.nextInt(pool.length)];
    }

    return pieces;
  }

  /// ハイスコアをローカルストレージから読み込む。
  int _loadHighScore() {
    SharedPreferences.getInstance().then((prefs) {
      final value = prefs.getInt(_highScoreKey);
      if (value != null && value > state.highScore) {
        state = state.copyWith(highScore: value);
      }
    });
    return 0;
  }

  /// ハイスコアをローカルストレージに保存する。
  void _saveHighScore(int score) {
    SharedPreferences.getInstance().then((prefs) {
      prefs.setInt(_highScoreKey, score);
    });
  }

  // ── タイムアタック ──────────────────────────────────────────

  /// タイムアタックモードを開始する（3秒カウントダウン → 90秒ゲーム開始）。
  void startTimeAttack() {
    _timeAttackTimer?.cancel();
    final emptyBoard =
        List.generate(Board.size, (_) => List.filled(Board.size, false));
    state = BlockPuzzleState(
      board: emptyBoard,
      pieces: _generatePieces(emptyBoard),
      highScore: state.highScore,
      isTimeAttackMode: true,
      isTimeAttackCountingDown: true,
      timeAttackCountdownSeconds: 3,
      timeAttackHighScore: state.timeAttackHighScore,
      // 両モードのセーブフラグを引き継ぐ
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

  /// タイムアタックのベストスコアをローカルストレージから読み込む。
  int _loadTimeAttackHighScore() {
    SharedPreferences.getInstance().then((prefs) {
      final value = prefs.getInt(_timeAttackHighScoreKey);
      if (value != null && value > state.timeAttackHighScore) {
        state = state.copyWith(timeAttackHighScore: value);
      }
    });
    return 0;
  }

  /// タイムアタックのベストスコアをローカルストレージに保存する。
  void _saveTimeAttackHighScore(int score) {
    SharedPreferences.getInstance().then((prefs) {
      prefs.setInt(_timeAttackHighScoreKey, score);
    });
  }

  // ── ゲーム状態の永続化 ──────────────────────────────────────

  /// 現在のゲーム状態を保存する。タイムアタックは永続化しない。
  void _saveGame() {
    if (state.isTimeAttackMode) {
      return;
    }
    if (state.isQuestMode) {
      _saveQuestGame();
    } else {
      _saveClassicGame();
    }
  }

  /// クラシックゲームの状態をキャッシュと永続ストレージに保存する。
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
    // 再開可能フラグを更新
    if (state.hasSavedClassicGame == s.isGameOver) {
      state = state.copyWith(hasSavedClassicGame: !s.isGameOver);
    }
    // 非同期で永続化
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

  /// クエストゲームの状態をキャッシュと永続ストレージに保存する。
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
    // 再開可能フラグを更新
    final canResume = !s.isGameOver && !s.isQuestComplete;
    if (state.hasSavedQuestGame != canResume) {
      state = state.copyWith(hasSavedQuestGame: canResume);
    }
    // 非同期で永続化
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

  /// 両モードのセーブデータを非同期で読み込み、キャッシュとフラグを更新する。
  ///
  /// 旧フォーマット（単一スロット）のデータが存在する場合はマイグレーションする。
  void _loadSavedGames() {
    SharedPreferences.getInstance().then((prefs) {
      _migrateOldSave(prefs);

      // クラシックセーブを読み込む
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

      // クエストセーブを読み込む
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

      // 再開可能フラグを更新
      final classicCache = _classicCache;
      final questCache = _questCache;
      final hasSavedClassic = classicCache != null && !classicCache.isGameOver;
      final hasSavedQuest = questCache != null &&
          !questCache.isGameOver &&
          !questCache.isQuestComplete;

      // クエスト最大解放レベルを読み込む
      final savedMaxLevel = prefs.getInt(_questMaxLevelKey) ?? 1;
      state = state.copyWith(
        hasSavedClassicGame: hasSavedClassic,
        hasSavedQuestGame: hasSavedQuest,
        maxUnlockedLevel: savedMaxLevel > state.maxUnlockedLevel
            ? savedMaxLevel
            : state.maxUnlockedLevel,
      );
    });
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

    // 旧キーを削除
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

  // ── シリアライズヘルパー ──────────────────────────────────

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

  static List<Piece?> _piecesFromString(String s) => s.split(',').map((idx) {
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

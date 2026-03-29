import 'dart:math';

import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:mono_games/features/block_puzzle/model/board.dart';
import 'package:mono_games/features/block_puzzle/model/piece.dart';
import 'package:mono_games/features/block_puzzle/model/piece_generator.dart';
import 'package:mono_games/features/quiz/model/quiz_word.dart';
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
const _quizBoardKey = 'block_puzzle_quiz_board';
const _quizPiecesKey = 'block_puzzle_quiz_pieces';
const _quizScoreKey = 'block_puzzle_quiz_score';
const _quizComboKey = 'block_puzzle_quiz_combo';
const _quizNonClearTurnsKey = 'block_puzzle_quiz_non_clear_turns';
const _quizMultiplierKey = 'block_puzzle_quiz_multiplier';
const _quizIsGameOverKey = 'block_puzzle_quiz_is_game_over';
const _quizIsQuizPhaseKey = 'block_puzzle_quiz_is_quiz_phase';

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

  // 起動時に読み込んだセーブデータのインメモリキャッシュ。
  // resumeClassicGame で同期的に復元するために使用。
  _ClassicCache? _classicCache;
  _QuizModeCache? _quizModeCache;

  // クイズモード用バッグ（全ピースを1巡してからリフィル）
  final _quizEasyBag = <Piece>[];
  final _quizMediumBag = <Piece>[];
  final _quizHardBag = <Piece>[];

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

    final scoreMultiplier = state.quizMultiplier;

    // 基本スコア: セル数 × 1pt（コンボ倍率を適用）
    var pointsEarned = piece.offsets.length * scoreMultiplier;

    // ライン消去チェック（ボード状態は変更しない）
    final clearResult = board.checkClearLines();

    Board finalBoard;
    if (clearResult.clearedCells.isNotEmpty) {
      final actualClearCells = clearResult.clearedCells;

      // ラインをクリア
      finalBoard = board.clearCells(actualClearCells);

      // コンボを加算（同時消去ライン数分）
      final newCombo = state.combo + clearResult.linesCleared;

      // クイズモードではライン消去のたびに倍率を+1（最大10）
      final newMultiplier = state.isQuizMode
          ? (state.quizMultiplier + 1).clamp(1, 10)
          : state.quizMultiplier;

      // ライン消去スコア: 10 × ライン数²
      final lineScore =
          10 * clearResult.linesCleared * clearResult.linesCleared;
      // コンボ倍率: 増加前の combo + 1（初回は必ず 1×、2連続で 2×）
      final comboMultiplier = state.combo + 1;
      pointsEarned += lineScore * comboMultiplier * newMultiplier;

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
        quizMultiplier: newMultiplier,
        lastPlacedCells: placedCells,
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
      final newMultiplier =
          state.isQuizMode && nonClearTurns >= 3 ? 1 : state.quizMultiplier;
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
        combo: newCombo,
        quizMultiplier: newMultiplier,
        consecutiveNonClearTurns: nonClearTurns,
        lastClearResult: null,
        lastPlacedCells: placedCells,
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
      state = state.copyWith(
        isGameOver: true,
        hasSavedClassicGame: false,
      );
    }
    _saveGame();
  }

  // ── クイズモード ─────────────────────────────────────────────

  /// クイズモードを開始する。保存済みデータがあれば自動復元する。
  void startQuizMode() {
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
        sessionCorrectWords: [],
        sessionIncorrectWords: [],
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
      sessionCorrectWords: [],
      sessionIncorrectWords: [],
    );
    // 新規ゲーム開始直後に保存しておく（アプリ強制終了時の復元用）。
    _saveGame();
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
  /// 充填率を最優先で評価し、ストリークは充填率ガードが発動しない場合にのみ参照する:
  /// 充填率3段階 × 正誤でピース難易度を決定する。
  ///
  /// | fillRate       | 正解                          | 不正解            |
  /// |----------------|-------------------------------|-------------------|
  /// | ≥ 65%          | Easy（盤面最適）               | Medium（ランダム）|
  /// | 30% 〜 65%     | Easy/Medium 50% ずつ（最適）  | Hard/Medium 50%   |
  /// | < 30%          | Medium（盤面最適）             | Hard（ランダム）  |
  ///
  /// 正解時は [_bestFitFromPool] で複合スコア最大のピースを選ぶ。
  /// 不正解時はバッグ方式でランダム選択（ペナルティ）。
  void addQuizPiece(
    int slot, {
    required bool isCorrect,
    QuizWord? word,
    int overdueBonus = 0,
  }) {
    final board = Board.from(state.board);
    final fillRate = _boardFillRate(board);

    // 同一ラウンド内で既に割り当て済みのピースを除外候補として収集
    final usedPieces = state.pieces.whereType<Piece>().toSet();

    final Piece piece;

    if (fillRate >= 0.65) {
      piece = isCorrect
          ? _bestFitFromPool(
              PieceDefinitions.quizEasyPool, board, usedPieces,
            )
          : _drawFromQuizBag(
              _quizMediumBag, PieceDefinitions.quizMediumPool, board,
              usedPieces,
            );
    } else if (fillRate >= 0.30) {
      if (isCorrect) {
        piece = _rng.nextBool()
            ? _bestFitFromPool(
                PieceDefinitions.quizEasyPool, board, usedPieces,
              )
            : _bestFitFromPool(
                PieceDefinitions.quizMediumPool, board, usedPieces,
              );
      } else {
        piece = _rng.nextBool()
            ? _drawFromQuizBag(
                _quizHardBag, PieceDefinitions.quizHardPool, board,
                usedPieces,
              )
            : _drawFromQuizBag(
                _quizMediumBag, PieceDefinitions.quizMediumPool, board,
                usedPieces,
              );
      }
    } else {
      piece = isCorrect
          ? _bestFitFromPool(
              PieceDefinitions.quizMediumPool, board, usedPieces,
            )
          : _drawFromQuizBag(
              _quizHardBag, PieceDefinitions.quizHardPool, board,
              usedPieces,
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
      score: state.score + overdueBonus,
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
    Set<Piece> excluded,
  ) {
    if (bag.isEmpty) {
      bag
        ..addAll(pool)
        ..shuffle(_rng);
    }
    final idx = bag.indexWhere(
      (p) => !excluded.contains(p) && board.canPlaceAny([p]),
    );
    if (idx != -1) {
      return bag.removeAt(idx);
    }
    // excluded を無視して配置可能なピースを探す（フォールバック）
    final idxAny = bag.indexWhere((p) => board.canPlaceAny([p]));
    if (idxAny != -1) {
      return bag.removeAt(idxAny);
    }
    final fallback = PieceDefinitions.quizEasyPool
        .where((p) => board.canPlaceAny([p]))
        .toList()
      ..shuffle(_rng);
    return fallback.isNotEmpty ? fallback.first : PieceDefinitions.dot;
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
        }
      }

      if (placementCount == 0) {
        continue;
      }

      final score = maxLineClear * 100 + placementCount;
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

  double _boardFillRate(Board board) {
    const total = Board.size * Board.size;
    final filled = board.cells.expand((r) => r).where((c) => c).length;
    return filled / total;
  }

  // ── ゲーム状態の永続化 ──────────────────────────────────────

  /// 全データを一括ロードし、キャッシュとスコアを初期化する。
  Future<void> _loadPersistedData() async {
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
    final hasSavedClassic = classicCache != null && !classicCache.isGameOver;

    state = state.copyWith(
      highScore: highScore,
      hasSavedClassicGame: hasSavedClassic,
    );
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

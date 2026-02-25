import 'dart:math';

import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:mono_games/features/block_puzzle/model/board.dart';
import 'package:mono_games/features/block_puzzle/model/piece.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shared_preferences/shared_preferences.dart';

part 'block_puzzle_view_model.freezed.dart';
part 'block_puzzle_view_model.g.dart';

const _highScoreKey = 'block_puzzle_high_score';

// ゲーム状態の永続化キー
const _savedBoardKey = 'block_puzzle_saved_board';
const _savedPiecesKey = 'block_puzzle_saved_pieces';
const _savedScoreKey = 'block_puzzle_saved_score';
const _savedComboKey = 'block_puzzle_saved_combo';
const _savedNonClearTurnsKey = 'block_puzzle_saved_non_clear_turns';
const _savedIsQuestModeKey = 'block_puzzle_saved_is_quest_mode';
const _savedQuestLevelKey = 'block_puzzle_saved_quest_level';
const _savedTargetScoreKey = 'block_puzzle_saved_target_score';
const _savedIsQuestCompleteKey = 'block_puzzle_saved_is_quest_complete';

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
  }) = _BlockPuzzleState;
}

/// Noir Mindパズルゲームのビューモデル。
@riverpod
class BlockPuzzleViewModel extends _$BlockPuzzleViewModel {
  final _rng = Random();

  @override
  BlockPuzzleState build() {
    final highScore = _loadHighScore();
    _loadSavedGame();
    final emptyBoard =
        List.generate(Board.size, (_) => List.filled(Board.size, false));
    return BlockPuzzleState(
      board: emptyBoard,
      pieces: _generatePieces(emptyBoard),
      highScore: highScore,
    );
  }

  /// [pieceIndex]番目のピースを([row], [col])に配置する。
  /// 配置成功なら`true`を返す。
  bool placePiece(int pieceIndex, int row, int col) {
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
      // ラインを即座にクリア
      finalBoard = board.clearCells(clearResult.clearedCells);

      // 同時消去ライン数分だけコンボを加算（複数行消去でコンボが加速する）
      final newCombo = state.combo + clearResult.linesCleared;

      // ライン消去スコア: 10 × ライン数²
      final lineScore =
          10 * clearResult.linesCleared * clearResult.linesCleared;
      // コンボ倍率を適用
      pointsEarned += lineScore * newCombo;

      final newScore = state.score + pointsEarned;
      final isNewHigh = newScore > state.highScore;
      final newHighScore = isNewHigh ? newScore : state.highScore;
      final questComplete = state.isQuestMode &&
          !state.isQuestComplete &&
          newScore >= state.targetScore;

      if (isNewHigh) {
        _saveHighScore(newHighScore);
      }

      // 消去済みボードで状態を更新（参照共有を防ぐためディープコピー）
      final boardCopy = [
        for (final row in finalBoard.cells) [...row]
      ];

      state = state.copyWith(
        board: boardCopy,
        pieces: newPieces,
        clearingCells: clearResult.clearedCells,
        score: newScore,
        highScore: newHighScore,
        combo: newCombo,
        consecutiveNonClearTurns: 0,
        lastClearResult: ClearResult(
          linesCleared: clearResult.linesCleared,
          pointsEarned: pointsEarned,
          combo: newCombo,
          cells: clearResult.clearedCells,
          placementRow: row,
          placementCol: col,
          clearedRows: clearResult.clearedRows,
          clearedCols: clearResult.clearedCols,
        ),
        lastPlacedCells: placedCells,
        isNewHighScore: isNewHigh,
        isQuestComplete: questComplete,
      );
      // 配置直後に状態を永続化（アニメーション前でも最新スコアを保存）
      _saveGame();
      // クリア完了はビュー側のアニメーション終了時に completeClearAnimation() で通知する。
    } else {
      // ライン消去なし — 配置済みボードをそのまま使用
      finalBoard = board;

      final nonClearTurns = state.consecutiveNonClearTurns + 1;
      final newCombo = nonClearTurns >= 3 ? 0 : state.combo;
      final newScore = state.score + pointsEarned;
      final isNewHigh = newScore > state.highScore;
      final newHighScore = isNewHigh ? newScore : state.highScore;
      final questComplete = state.isQuestMode &&
          !state.isQuestComplete &&
          newScore >= state.targetScore;

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
      pieces: _generatePieces(emptyBoard),
      highScore: state.highScore,
    );
    _saveGame();
  }

  /// クエストモードで指定レベルを開始する。
  void startQuestLevel(int level) {
    final questBoard = _generateQuestBoard(level);
    state = BlockPuzzleState(
      board: questBoard,
      pieces: _generatePieces(questBoard),
      highScore: state.highScore,
      isQuestMode: true,
      questLevel: level,
      targetScore: _questTargetScore(level),
    );
    _saveGame();
  }

  /// 現在のクエストレベルをリトライする。
  void retryQuestLevel() {
    startQuestLevel(state.questLevel);
  }

  /// レベルに対応する目標スコアを返す。
  static int _questTargetScore(int level) => 50 + level * 150;

  /// クエスト用の戦略的初期ボードを生成する。
  ///
  /// 行を「あと2〜4マスで完成」する状態にして最初の数手を快適にする。
  /// 同じレベルは常に同じ配置になる（シード固定）。
  List<List<bool>> _generateQuestBoard(int level) {
    final rng = Random(level * 1337 + 42);
    final board =
        List.generate(Board.size, (_) => List.filled(Board.size, false));

    // ターゲット密度: レベル1 = 15%, 以降 2% ずつ増加, 上限 40%
    final targetDensity = (0.15 + (level - 1) * 0.02).clamp(0.10, 0.40);
    final targetCells = (Board.size * Board.size * targetDensity).round();

    var placed = 0;
    final rows = (List.generate(Board.size, (i) => i)..shuffle(rng));

    for (final r in rows) {
      if (placed >= targetCells) {
        break;
      }

      // ギャップ数 2〜4（プレイヤーがバーやドミノで埋めやすいサイズ）
      final gap = 2 + rng.nextInt(3);
      final fillCount = Board.size - gap;

      // 残り目標を大幅に超えるならこの行はスキップ
      if (placed + fillCount > targetCells + Board.size) {
        continue;
      }

      // ギャップ開始位置をランダムに決定（端を避けて中央付近に置く）
      final maxGapStart = Board.size - gap;
      final gapStart = rng.nextInt(maxGapStart);

      for (var c = 0; c < Board.size; c++) {
        final inGap = c >= gapStart && c < gapStart + gap;
        if (!inGap) {
          board[r][c] = true;
          placed++;
        }
      }
    }

    return board;
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
      state = state.copyWith(isGameOver: true);
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

  // ── ゲーム状態の永続化 ──────────────────────────────────────

  /// 現在のゲーム状態を保存する。アニメーション等の一時フィールドは除く。
  void _saveGame() {
    final s = state;
    SharedPreferences.getInstance().then((prefs) {
      prefs
        ..setString(_savedBoardKey, _boardToString(s.board))
        ..setString(_savedPiecesKey, _piecesToString(s.pieces))
        ..setInt(_savedScoreKey, s.score)
        ..setInt(_savedComboKey, s.combo)
        ..setInt(_savedNonClearTurnsKey, s.consecutiveNonClearTurns)
        ..setBool(_savedIsQuestModeKey, s.isQuestMode)
        ..setInt(_savedQuestLevelKey, s.questLevel)
        ..setInt(_savedTargetScoreKey, s.targetScore)
        ..setBool(_savedIsQuestCompleteKey, s.isQuestComplete);
    });
  }

  /// 保存済みゲーム状態を非同期で読み込み、state を更新する。
  void _loadSavedGame() {
    SharedPreferences.getInstance().then((prefs) {
      final boardStr = prefs.getString(_savedBoardKey);
      if (boardStr == null) {
        return;
      }
      try {
        final board = _boardFromString(boardStr);
        if (board.length != Board.size ||
            board.any((r) => r.length != Board.size)) {
          return;
        }
        final piecesStr = prefs.getString(_savedPiecesKey) ?? '';
        final pieces = _piecesFromString(piecesStr);

        state = state.copyWith(
          board: board,
          pieces: pieces,
          score: prefs.getInt(_savedScoreKey) ?? 0,
          combo: prefs.getInt(_savedComboKey) ?? 0,
          consecutiveNonClearTurns:
              prefs.getInt(_savedNonClearTurnsKey) ?? 0,
          isQuestMode: prefs.getBool(_savedIsQuestModeKey) ?? false,
          questLevel: prefs.getInt(_savedQuestLevelKey) ?? 1,
          targetScore: prefs.getInt(_savedTargetScoreKey) ?? 0,
          isQuestComplete:
              prefs.getBool(_savedIsQuestCompleteKey) ?? false,
        );
      } on Exception catch (_) {
        // データ破損時はデフォルト状態のまま継続
      }
    });
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
        (p) => p == null
            ? '-1'
            : PieceDefinitions.allPieces.indexOf(p).toString(),
      )
      .join(',');

  static List<Piece?> _piecesFromString(String s) => s
      .split(',')
      .map((idx) {
        final i = int.tryParse(idx) ?? -1;
        if (i < 0 || i >= PieceDefinitions.allPieces.length) {
          return null;
        }
        return PieceDefinitions.allPieces[i];
      })
      .toList();
}

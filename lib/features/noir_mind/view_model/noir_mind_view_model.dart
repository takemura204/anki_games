import 'dart:math';

import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:mono_games/features/noir_mind/model/board.dart';
import 'package:mono_games/features/noir_mind/model/piece.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shared_preferences/shared_preferences.dart';

part 'noir_mind_view_model.freezed.dart';
part 'noir_mind_view_model.g.dart';

const _highScoreKey = 'noir_mind_high_score';

// ゲーム状態の永続化キー
const _savedBoardKey = 'noir_mind_saved_board';
const _savedPiecesKey = 'noir_mind_saved_pieces';
const _savedScoreKey = 'noir_mind_saved_score';
const _savedComboKey = 'noir_mind_saved_combo';
const _savedNonClearTurnsKey = 'noir_mind_saved_non_clear_turns';
const _savedIsQuestModeKey = 'noir_mind_saved_is_quest_mode';
const _savedQuestLevelKey = 'noir_mind_saved_quest_level';
const _savedTargetScoreKey = 'noir_mind_saved_target_score';
const _savedIsQuestCompleteKey = 'noir_mind_saved_is_quest_complete';

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
abstract class NoirMindState with _$NoirMindState {
  /// ゲーム状態を作成する。
  const factory NoirMindState({
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
  }) = _NoirMindState;
}

/// Noir Mindパズルゲームのビューモデル。
@riverpod
class NoirMindViewModel extends _$NoirMindViewModel {
  final _rng = Random();

  @override
  NoirMindState build() {
    final highScore = _loadHighScore();
    _loadSavedGame();
    return NoirMindState(
      board: List.generate(
        Board.size,
        (_) => List.filled(Board.size, false),
      ),
      pieces: _generatePieces(),
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

      final newCombo = state.combo + 1;

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
    state = NoirMindState(
      board: List.generate(
        Board.size,
        (_) => List.filled(Board.size, false),
      ),
      pieces: _generatePieces(),
      highScore: state.highScore,
    );
    _saveGame();
  }

  /// クエストモードで指定レベルを開始する。
  void startQuestLevel(int level) {
    final questBoard = _generateQuestBoard(level);
    state = NoirMindState(
      board: questBoard,
      pieces: _generatePieces(board: questBoard, questLevel: level),
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
      final newPieces = _generatePieces(
        board: state.board,
        questLevel: state.questLevel,
      );
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

  /// ボードの埋まり具合（0.0〜1.0）を返す。
  double _boardDensity(List<List<bool>> board) {
    var filled = 0;
    for (final row in board) {
      for (final cell in row) {
        if (cell) {
          filled++;
        }
      }
    }
    return filled / (Board.size * Board.size);
  }

  /// クエストレベルとボード密度に基づいてピースプールを選択する。
  /// ボード密度 > 65% の場合は常に easyPool を返す。
  List<Piece> _selectPool({required int questLevel, required double density}) {
    if (density > 0.65) {
      return PieceDefinitions.easyPool;
    }
    if (questLevel == 0) {
      return PieceDefinitions.allPieces;
    }
    if (questLevel <= 5) {
      return PieceDefinitions.easyPool;
    }
    if (questLevel <= 12) {
      return PieceDefinitions.mediumPool;
    }
    return PieceDefinitions.allPieces;
  }

  /// 3ピースのバッチを生成する。
  ///
  /// [board] が指定された場合、少なくとも1ピースがボード上に配置可能なことを
  /// 保証するためリトライする（最大10回）。
  /// [questLevel] が 0 のときはクラシックモードとして扱う。
  List<Piece> _generatePieces({
    List<List<bool>>? board,
    int questLevel = 0,
  }) {
    final boardState = board ??
        List.generate(
          Board.size,
          (_) => List.filled(Board.size, false),
        );
    final density = _boardDensity(boardState);
    final pool = _selectPool(questLevel: questLevel, density: density);

    // 配置可能なバッチが生成されるまでリトライ（最大10回）
    for (var attempt = 0; attempt < 10; attempt++) {
      final pieces = List.generate(
        3,
        (_) => PieceDefinitions.randomFrom(pool, _rng),
      );
      if (Board.from(boardState).canPlaceAny(pieces)) {
        return pieces;
      }
    }

    // フォールバック: easyPool から生成（必ず配置できる最小ピースが含まれる）
    return List.generate(
      3,
      (_) => PieceDefinitions.randomFrom(PieceDefinitions.easyPool, _rng),
    );
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

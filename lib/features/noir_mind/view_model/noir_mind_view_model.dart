import 'dart:math';

import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:mono_games/features/noir_mind/model/board.dart';
import 'package:mono_games/features/noir_mind/model/piece.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shared_preferences/shared_preferences.dart';

part 'noir_mind_view_model.freezed.dart';
part 'noir_mind_view_model.g.dart';

const _highScoreKey = 'noir_mind_high_score';

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
  }) = _NoirMindState;
}

/// Noir Mindパズルゲームのビューモデル。
@riverpod
class NoirMindViewModel extends _$NoirMindViewModel {
  final _rng = Random();

  @override
  NoirMindState build() {
    final highScore = _loadHighScore();
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
        ),
        lastPlacedCells: placedCells,
        isNewHighScore: isNewHigh,
      );

      // 消去アニメーション終了後にクリア
      Future<void>.delayed(const Duration(milliseconds: 400), () {
        state = state.copyWith(
          clearingCells: const {},
          lastClearResult: null,
          lastPlacedCells: const {},
        );
        _checkRefillAndGameOver();
      });
    } else {
      // ライン消去なし — 配置済みボードをそのまま使用
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
        combo: newCombo,
        consecutiveNonClearTurns: nonClearTurns,
        lastClearResult: null,
        lastPlacedCells: placedCells,
        isNewHighScore: isNewHigh,
      );

      // 配置アニメーション終了後にクリア
      Future<void>.delayed(const Duration(milliseconds: 200), () {
        state = state.copyWith(lastPlacedCells: const {});
        _checkRefillAndGameOver();
      });
    }

    return true;
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

  /// ゲームをリセットして新しいラウンドを開始する。
  void resetGame() {
    state = NoirMindState(
      board: List.generate(
        Board.size,
        (_) => List.filled(Board.size, false),
      ),
      pieces: _generatePieces(),
      highScore: state.highScore,
    );
  }

  /// ピース補充とゲームオーバー判定を行う。
  void _checkRefillAndGameOver() {
    // 3ピース全て使用済みなら補充
    var piecesToCheck = state.pieces;
    if (piecesToCheck.every((p) => p == null)) {
      final newPieces = _generatePieces();
      state = state.copyWith(pieces: newPieces);
      piecesToCheck = newPieces;
    }

    // 現在の（補充後の）ピースで配置可能か判定
    final board = Board.from(state.board);
    if (!board.canPlaceAny(piecesToCheck)) {
      state = state.copyWith(isGameOver: true);
    }
  }

  /// ランダムな3ピースを生成する。
  List<Piece> _generatePieces() {
    return List.generate(3, (_) => PieceDefinitions.random(_rng));
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
}

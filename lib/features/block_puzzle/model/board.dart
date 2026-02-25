import 'package:mono_games/features/block_puzzle/model/piece.dart';

/// ライン消去の結果。
class ClearLineResult {
  /// ライン消去結果を作成する。
  const ClearLineResult({
    required this.clearedCells,
    required this.linesCleared,
    required this.clearedRows,
    required this.clearedCols,
  });

  /// 消去された (row, col) セルの集合。
  final Set<(int, int)> clearedCells;

  /// 消去されたライン数（行 + 列）。
  final int linesCleared;

  /// 消去された行番号の集合。
  final Set<int> clearedRows;

  /// 消去された列番号の集合。
  final Set<int> clearedCols;
}

/// Noir Mindの8x8ゲームボード。
class Board {
  /// 空の8x8ボードを作成する。
  Board() : cells = List.generate(size, (_) => List.filled(size, false));

  /// 既存セルグリッドからボードを作成（イミュータブルコピー用）。
  Board.from(List<List<bool>> source)
      : cells = [
          for (final row in source) [...row]
        ];

  /// ボードの一辺のセル数 (8x8)。
  static const int size = 8;

  /// 2Dセルグリッド。`true` = 配置済み、`false` = 空。
  final List<List<bool>> cells;

  /// [piece]を([row], [col])に配置可能か判定する。
  bool canPlace(Piece piece, int row, int col) {
    for (final (dr, dc) in piece.offsets) {
      final r = row + dr;
      final c = col + dc;
      if (r < 0 || r >= size || c < 0 || c >= size) {
        return false;
      }
      if (cells[r][c]) {
        return false;
      }
    }
    return true;
  }

  /// [piece]を([row], [col])に配置する。先に[canPlace]を呼ぶこと。
  void place(Piece piece, int row, int col) {
    for (final (dr, dc) in piece.offsets) {
      cells[row + dr][col + dc] = true;
    }
  }

  /// 完成した行・列をチェックし、消去すべきセル情報を返す（状態は変更しない）。
  ClearLineResult checkClearLines() {
    final cleared = <(int, int)>{};
    final clearedRows = <int>{};
    final clearedCols = <int>{};
    var linesCleared = 0;

    // 行チェック
    for (var r = 0; r < size; r++) {
      if (cells[r].every((c) => c)) {
        linesCleared++;
        clearedRows.add(r);
        for (var c = 0; c < size; c++) {
          cleared.add((r, c));
        }
      }
    }

    // 列チェック
    for (var c = 0; c < size; c++) {
      var full = true;
      for (var r = 0; r < size; r++) {
        if (!cells[r][c]) {
          full = false;
          break;
        }
      }
      if (full) {
        linesCleared++;
        clearedCols.add(c);
        for (var r = 0; r < size; r++) {
          cleared.add((r, c));
        }
      }
    }

    return ClearLineResult(
      clearedCells: cleared,
      linesCleared: linesCleared,
      clearedRows: clearedRows,
      clearedCols: clearedCols,
    );
  }

  /// 指定されたセルをクリアする（新しいボードを返す）
  Board clearCells(Set<(int, int)> cellsToClear) {
    final newBoard = copy();
    for (final (r, c) in cellsToClear) {
      newBoard.cells[r][c] = false;
    }
    return newBoard;
  }

  /// [pieces]のいずれかをボード上のどこかに配置可能か判定する。
  bool canPlaceAny(List<Piece?> pieces) {
    for (final piece in pieces) {
      if (piece == null) {
        continue;
      }
      for (var r = 0; r < size; r++) {
        for (var c = 0; c < size; c++) {
          if (canPlace(piece, r, c)) {
            return true;
          }
        }
      }
    }
    return false;
  }

  /// このボードのディープコピーを作成する。
  Board copy() => Board.from(cells);
}

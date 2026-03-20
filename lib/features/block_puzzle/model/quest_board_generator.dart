import 'dart:math';

import 'package:mono_games/features/block_puzzle/model/board.dart';

/// [level] に対応するクエスト用ボードとノイズ盤面を生成して返す。
///
/// アイコン形状パターンでノイズブロックを配置し、
/// 同じレベルは常に同じ配置になる（シード固定）。
({List<List<bool>> board, List<List<int>> noiseBoard})
    generateQuestBoardAndNoise(int level) {
  final rng = Random(level * 1337 + 42);
  final board =
      List.generate(Board.size, (_) => List.filled(Board.size, false));
  final noiseBoard =
      List.generate(Board.size, (_) => List.filled(Board.size, 0));

  // アクティブ列数: L1=2, L4=3, L7=4, L10=5, L13=6, L16=7, L19+=8
  final activeCols = min(Board.size, 2 + (level - 1) ~/ 3);
  // 中央寄せで配置
  final colStart = (Board.size - activeCols) ~/ 2;
  final colEnd = colStart + activeCols;

  // アクティブ行数: L1=3行, L5=4行, L9=5行, L13=6行, L17=7行, L21+=8行（下から）
  final activeRows = min(Board.size, 3 + (level - 1) ~/ 4);
  final rowStart = Board.size - activeRows;

  final noiseHPs = _computeNoiseHPs(level);
  final noiseCount = noiseHPs.length;

  final noisePositions = <(int, int)>[];

  final shapes = _noiseIconShapes[noiseCount]!;
  final shape = shapes[(level - 1) % shapes.length];
  final patternRows = shape.map((p) => p.$1).reduce(max) + 1;
  final patternCols = shape.map((p) => p.$2).reduce(max) + 1;

  if (patternRows <= activeRows && patternCols <= activeCols) {
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

  // 1ラインあたりの補助ブロック数をレベルで段階的に減らす:
  //   L1-10: 3個、L11-20: 2個、L21-30: 1個、L31+: 0個
  final normalPerLine = max(0, 3 - (level - 1) ~/ 10);
  if (normalPerLine > 0) {
    final rowNoiseCnt = List.filled(Board.size, 0);
    final colNoiseCnt = List.filled(Board.size, 0);
    for (final (r, c) in noisePositions) {
      if (r >= 0 && r < Board.size && c >= 0 && c < Board.size) {
        rowNoiseCnt[r]++;
        colNoiseCnt[c]++;
      }
    }

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
      }
    }
  }

  return (board: board, noiseBoard: noiseBoard);
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
List<int> _computeNoiseHPs(int level) {
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
const _noiseIconShapes = <int, List<List<(int, int)>>>{
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
    [
      (0, 0), (0, 2), (1, 0), (1, 1), (1, 2),
      (2, 0), (2, 1), (2, 2), (3, 1),
    ],
    [
      (0, 1), (1, 0), (1, 1), (1, 2), (2, 0),
      (2, 2), (3, 0), (3, 1), (3, 2),
    ],
    [
      (0, 1), (0, 2), (1, 1), (1, 2), (2, 0),
      (2, 1), (2, 2), (3, 0), (3, 1),
    ],
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

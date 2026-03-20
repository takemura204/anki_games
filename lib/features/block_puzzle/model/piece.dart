import 'dart:math';

/// A puzzle piece defined by relative cell offsets from (0,0).
class Piece {
  /// Creates a piece with the given cell [offsets].
  const Piece(this.offsets);

  /// Relative cell coordinates that make up this piece.
  /// Each tuple is (row, col) offset from the anchor (0,0).
  final List<(int, int)> offsets;

  /// Width of this piece in cells.
  int get width =>
      offsets.map((o) => o.$2).reduce(max) -
      offsets.map((o) => o.$2).reduce(min) +
      1;

  /// Height of this piece in cells.
  int get height =>
      offsets.map((o) => o.$1).reduce(max) -
      offsets.map((o) => o.$1).reduce(min) +
      1;
}

/// All available piece shapes including rotations.
class PieceDefinitions {
  PieceDefinitions._();

  /// Small, simple pieces (1–4 cells). Used in early quest levels.
  static const List<Piece> easyPool = [
    dot, dominoH, dominoV,
    triominoH, triominoV,
    cornerA, cornerB, cornerC, cornerD,
    barH, barV,
    square2x2,
  ];

  /// Medium-difficulty pieces: easyPool plus L/T-shapes (4 cells each).
  static const List<Piece> mediumPool = [
    dot, dominoH, dominoV,
    triominoH, triominoV,
    cornerA, cornerB, cornerC, cornerD,
    barH, barV,
    square2x2,
    lShape0, lShape90, lShape180, lShape270,
    tShape0, tShape90, tShape180, tShape270,
  ];

  /// All available piece shapes including large/complex shapes.
  ///
  /// 新ピースは末尾に追加してセーブデータのインデックスを保持する。
  static const List<Piece> allPieces = [
    dot, dominoH, dominoV,
    triominoH, triominoV,
    barH, barV,
    square2x2, square3x3,
    lShape0, lShape90, lShape180, lShape270,
    tShape0, tShape90, tShape180, tShape270,
    zShape0, zShape90, sShape0, sShape90,
    // 追加ピース（インデックス保持のため末尾に追加）
    cornerA, cornerB, cornerC, cornerD,
    barH5, barV5,
    rect2x3, rect3x2,
    plus,
    uShape, bigLShape0, bigLShape90, wShape,
  ];

  /// クイズモード用: 小ピースプール（1〜3セル）。
  static const List<Piece> quizEasyPool = [
    dot, dominoH, dominoV,
    triominoH, triominoV,
    cornerA, cornerB, cornerC, cornerD,
  ];

  /// クイズモード用: 中ピースプール（4セル、全テトロミノ）。
  static const List<Piece> quizMediumPool = [
    barH, barV, square2x2,
    lShape0, lShape90, lShape180, lShape270,
    tShape0, tShape90, tShape180, tShape270,
    zShape0, zShape90, sShape0, sShape90,
  ];

  /// クイズモード用: 大ピースプール（5セル以上）。
  static const List<Piece> quizHardPool = [
    square3x3, barH5, barV5, rect2x3, rect3x2, plus,
    uShape, bigLShape0, bigLShape90, wShape,
  ];

  /// Returns a random piece from [pool].
  static Piece randomFrom(List<Piece> pool, Random rng) =>
      pool[rng.nextInt(pool.length)];

  /// Returns a random piece from all definitions.
  static Piece random(Random rng) => randomFrom(allPieces, rng);

  /// 1x1 dot.
  static const dot = Piece([(0, 0)]);

  /// Horizontal 1x2.
  static const dominoH = Piece([(0, 0), (0, 1)]);

  /// Vertical 2x1.
  static const dominoV = Piece([(0, 0), (1, 0)]);

  /// Horizontal 1x3.
  static const triominoH = Piece([(0, 0), (0, 1), (0, 2)]);

  /// Vertical 3x1.
  static const triominoV = Piece([(0, 0), (1, 0), (2, 0)]);

  /// Horizontal 1x4 bar.
  static const barH = Piece([(0, 0), (0, 1), (0, 2), (0, 3)]);

  /// Vertical 4x1 bar.
  static const barV = Piece([(0, 0), (1, 0), (2, 0), (3, 0)]);

  /// 2x2 square.
  static const square2x2 = Piece([(0, 0), (0, 1), (1, 0), (1, 1)]);

  /// 3x3 square.
  static const square3x3 = Piece([
    (0, 0), (0, 1), (0, 2),
    (1, 0), (1, 1), (1, 2),
    (2, 0), (2, 1), (2, 2),
  ]);

  /// L-shape, 0 degree rotation.
  static const lShape0 = Piece([(0, 0), (0, 1), (1, 0), (2, 0)]);

  /// L-shape, 90 degree rotation.
  static const lShape90 = Piece([(0, 0), (1, 0), (1, 1), (1, 2)]);

  /// L-shape, 180 degree rotation.
  static const lShape180 = Piece([(0, 1), (1, 1), (2, 0), (2, 1)]);

  /// L-shape, 270 degree rotation.
  static const lShape270 = Piece([(0, 0), (0, 1), (0, 2), (1, 2)]);

  /// T-shape, 0 degree rotation.
  static const tShape0 = Piece([(0, 0), (0, 1), (0, 2), (1, 1)]);

  /// T-shape, 90 degree rotation.
  static const tShape90 = Piece([(0, 1), (1, 0), (1, 1), (2, 1)]);

  /// T-shape, 180 degree rotation.
  static const tShape180 = Piece([(0, 1), (1, 0), (1, 1), (1, 2)]);

  /// T-shape, 270 degree rotation.
  static const tShape270 = Piece([(0, 0), (1, 0), (1, 1), (2, 0)]);

  /// Z-shape, horizontal.
  static const zShape0 = Piece([(0, 0), (0, 1), (1, 1), (1, 2)]);

  /// Z-shape, vertical.
  static const zShape90 = Piece([(0, 1), (1, 0), (1, 1), (2, 0)]);

  /// S-shape, horizontal.
  static const sShape0 = Piece([(0, 1), (0, 2), (1, 0), (1, 1)]);

  /// S-shape, vertical.
  static const sShape90 = Piece([(0, 0), (1, 0), (1, 1), (2, 1)]);

  /// Corner (3-cell L), bottom-right orientation.
  /// ■□
  /// ■■
  static const cornerA = Piece([(0, 0), (1, 0), (1, 1)]);

  /// Corner (3-cell L), bottom-left orientation.
  /// □■
  /// ■■
  static const cornerB = Piece([(0, 1), (1, 0), (1, 1)]);

  /// Corner (3-cell L), top-right orientation.
  /// ■■
  /// ■□
  static const cornerC = Piece([(0, 0), (0, 1), (1, 0)]);

  /// Corner (3-cell L), top-left orientation.
  /// ■■
  /// □■
  static const cornerD = Piece([(0, 0), (0, 1), (1, 1)]);

  /// Horizontal 1×5 bar.
  static const barH5 = Piece([(0, 0), (0, 1), (0, 2), (0, 3), (0, 4)]);

  /// Vertical 5×1 bar.
  static const barV5 = Piece([(0, 0), (1, 0), (2, 0), (3, 0), (4, 0)]);

  /// 2×3 rectangle (2 rows × 3 cols).
  static const rect2x3 = Piece([
    (0, 0), (0, 1), (0, 2),
    (1, 0), (1, 1), (1, 2),
  ]);

  /// 3×2 rectangle (3 rows × 2 cols).
  static const rect3x2 = Piece([
    (0, 0), (0, 1),
    (1, 0), (1, 1),
    (2, 0), (2, 1),
  ]);

  /// Plus (cross) shape.
  /// □■□
  /// ■■■
  /// □■□
  static const plus = Piece([(0, 1), (1, 0), (1, 1), (1, 2), (2, 1)]);

  /// U-shape (5 cells).
  /// ■□■
  /// ■■■
  static const uShape = Piece([
    (0, 0), (0, 2),
    (1, 0), (1, 1), (1, 2),
  ]);

  /// Big L-shape, 0 degree (5 cells).
  /// ■□
  /// ■□
  /// ■□
  /// ■■
  static const bigLShape0 = Piece([
    (0, 0),
    (1, 0),
    (2, 0),
    (3, 0), (3, 1),
  ]);

  /// Big L-shape, 90 degree (5 cells).
  /// ■■■■
  /// ■□□□
  static const bigLShape90 = Piece([
    (0, 0), (0, 1), (0, 2), (0, 3),
    (1, 0),
  ]);

  /// W-staircase shape (5 cells).
  /// ■□□
  /// ■■□
  /// □■■
  static const wShape = Piece([
    (0, 0),
    (1, 0), (1, 1),
    (2, 1), (2, 2),
  ]);
}

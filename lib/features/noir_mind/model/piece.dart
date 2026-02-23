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
    barH, barV,
    square2x2,
  ];

  /// Medium-difficulty pieces: easyPool plus L/T-shapes (4 cells each).
  static const List<Piece> mediumPool = [
    dot, dominoH, dominoV,
    triominoH, triominoV,
    barH, barV,
    square2x2,
    lShape0, lShape90, lShape180, lShape270,
    tShape0, tShape90, tShape180, tShape270,
  ];

  /// All available piece shapes including large shapes (e.g. 3×3 square).
  static const List<Piece> allPieces = [
    dot, dominoH, dominoV,
    triominoH, triominoV,
    barH, barV,
    square2x2, square3x3,
    lShape0, lShape90, lShape180, lShape270,
    tShape0, tShape90, tShape180, tShape270,
    zShape0, zShape90, sShape0, sShape90,
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
}

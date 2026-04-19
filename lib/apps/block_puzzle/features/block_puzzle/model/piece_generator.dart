import 'dart:math';

import 'package:anki_games/apps/block_puzzle/features/block_puzzle/model/board.dart';
import 'package:anki_games/apps/block_puzzle/features/block_puzzle/model/piece.dart';

/// [piece] が [boardCells] 上でラインクリアに貢献できるか判定する。
bool canClearLine(Piece piece, List<List<bool>> boardCells) {
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
List<Piece> generatePieces(List<List<bool>> board, Random rng) {
  final boardObj = Board.from(board);

  // Piece 1: mediumPool をシャッフルして配置可能な先頭ピースを選択
  final shuffledMedium = [...PieceDefinitions.mediumPool]..shuffle(rng);
  var piece1 = shuffledMedium.firstWhere(
    (p) => boardObj.canPlaceAny([p]),
    orElse: () => shuffledMedium.first,
  );
  if (!boardObj.canPlaceAny([piece1])) {
    // mediumPool に配置可能なピースがない → easyPool にフォールバック
    final shuffledEasy = [...PieceDefinitions.easyPool]..shuffle(rng);
    piece1 = shuffledEasy.firstWhere(
      (p) => boardObj.canPlaceAny([p]),
      orElse: () => piece1,
    );
  }

  // ラインクリア可能ピースをallPieces全体から一括算出
  // P1がすでにクリアできる場合は算出をスキップ
  final p1ClearsLine = canClearLine(piece1, board);
  final lineClearers = p1ClearsLine
      ? <Piece>[]
      : [
          for (final p in PieceDefinitions.allPieces)
            if (canClearLine(p, board)) p,
        ];

  // Piece 2 & 3: 事前計算済みリストから O(1) 選択
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
          ? allCandidates[rng.nextInt(allCandidates.length)]
          : PieceDefinitions.randomFrom(PieceDefinitions.allPieces, rng),
    );
  }

  // 小ピース保証: 3セル以下のピースがなければ P3 を置き換え
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
    pieces[2] = pool[rng.nextInt(pool.length)];
  }

  return pieces;
}

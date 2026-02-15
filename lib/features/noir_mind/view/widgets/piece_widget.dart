import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mono_games/features/noir_mind/model/piece.dart';

/// ドラッグ可能なピースウィジェット。
class PieceWidget extends StatefulWidget {
  /// ドラッグ可能なピースウィジェットを作成する。
  const PieceWidget({
    required this.piece,
    required this.pieceIndex,
    required this.cellSize,
    super.key,
  });

  /// 描画するピース。
  final Piece piece;

  /// トレイ内のインデックス（ドラッグデータとして使用）。
  final int pieceIndex;

  /// 各セルの論理ピクセルサイズ。
  final double cellSize;

  @override
  State<PieceWidget> createState() => _PieceWidgetState();
}

class _PieceWidgetState extends State<PieceWidget> {
  bool _isDragging = false;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Draggable<int>(
      data: widget.pieceIndex,
      onDragStarted: () {
        HapticFeedback.selectionClick();
        setState(() => _isDragging = true);
      },
      onDragEnd: (_) {
        setState(() => _isDragging = false);
      },
      onDraggableCanceled: (_, __) {
        setState(() => _isDragging = false);
      },
      // ドラッグ中のフィードバック（指の上にオフセット、ボードセル等倍サイズ）
      feedback: Transform.translate(
        offset: Offset(0, -(widget.cellSize / 0.6) * 2),
        child: Material(
          color: Colors.transparent,
          child: Opacity(
            opacity: 0.85,
            child: _PieceShape(
              piece: widget.piece,
              cellSize: widget.cellSize / 0.6,
              color: colorScheme.onSurface,
            ),
          ),
        ),
      ),
      // ドラッグ中は元の位置を空にする
      childWhenDragging: SizedBox(
        width: widget.piece.width * widget.cellSize,
        height: widget.piece.height * widget.cellSize,
      ),
      child: AnimatedScale(
        scale: _isDragging ? 1.15 : 1,
        duration: const Duration(milliseconds: 150),
        curve: Curves.easeOut,
        child: _PieceShape(
          piece: widget.piece,
          cellSize: widget.cellSize,
          color: colorScheme.onSurface,
        ),
      ),
    );
  }
}

class _PieceShape extends StatelessWidget {
  const _PieceShape({
    required this.piece,
    required this.cellSize,
    required this.color,
  });

  final Piece piece;
  final double cellSize;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size(piece.width * cellSize, piece.height * cellSize),
      painter: _PiecePainter(
        piece: piece,
        cellSize: cellSize,
        color: color,
      ),
    );
  }
}

class _PiecePainter extends CustomPainter {
  _PiecePainter({
    required this.piece,
    required this.cellSize,
    required this.color,
  });

  final Piece piece;
  final double cellSize;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    const gap = 1.5;
    const radius = 3.0;

    for (final (row, col) in piece.offsets) {
      final rect = Rect.fromLTWH(
        col * cellSize + gap,
        row * cellSize + gap,
        cellSize - gap * 2,
        cellSize - gap * 2,
      );
      final rrect = RRect.fromRectAndRadius(
        rect,
        const Radius.circular(radius),
      );

      // ベース + ハイライト + シャドウ（立体感のあるタイル）
      canvas
        ..drawRRect(rrect, Paint()..color = color)
        ..drawRRect(
          rrect,
          Paint()
            ..shader = LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.white.withValues(alpha: 0.25),
                Colors.white.withValues(alpha: 0),
              ],
              stops: const [0.0, 0.5],
            ).createShader(rect),
        )
        ..drawRRect(
          rrect,
          Paint()
            ..shader = LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.black.withValues(alpha: 0),
                Colors.black.withValues(alpha: 0.15),
              ],
              stops: const [0.6, 1.0],
            ).createShader(rect),
        );
    }
  }

  @override
  bool shouldRepaint(_PiecePainter oldDelegate) =>
      color != oldDelegate.color;
}

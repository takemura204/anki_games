import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:mono_games/features/noir_mind/model/piece.dart';
import 'package:mono_games/features/noir_mind/view/widgets/piece_widget.dart';
import 'package:mono_games/features/noir_mind/view_model/noir_mind_view_model.dart';

/// 画面下部に3つのドラッグ可能なピースを表示するトレイ。
class PieceTrayWidget extends ConsumerWidget {
  /// ピーストレイを作成する。
  const PieceTrayWidget({required this.cellSize, super.key});

  /// 各セルの論理ピクセルサイズ。
  final double cellSize;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pieces = ref.watch(
      noirMindViewModelProvider.select((s) => s.pieces),
    );

    return SizedBox(
      height: cellSize * 4,
      child: Row(
        children: [
          for (var i = 0; i < pieces.length; i++)
            Expanded(
              child: _AnimatedPieceSlot(
                key: ValueKey('slot_$i'),
                piece: pieces[i],
                index: i,
                cellSize: cellSize,
              ),
            ),
        ],
      ),
    );
  }
}

class _AnimatedPieceSlot extends StatefulWidget {
  const _AnimatedPieceSlot({
    required this.piece,
    required this.index,
    required this.cellSize,
    super.key,
  });

  final Piece? piece;
  final int index;
  final double cellSize;

  @override
  State<_AnimatedPieceSlot> createState() => _AnimatedPieceSlotState();
}

class _AnimatedPieceSlotState extends State<_AnimatedPieceSlot>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scaleAnimation;
  late final Animation<double> _opacityAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    );
    _scaleAnimation = Tween<double>(begin: 0.5, end: 1).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.elasticOut,
      ),
    );
    _opacityAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0, 0.5),
      ),
    );

    if (widget.piece != null) {
      _controller.forward();
    }
  }

  @override
  void didUpdateWidget(_AnimatedPieceSlot oldWidget) {
    super.didUpdateWidget(oldWidget);
    // ピースが出現したとき（null → 有効値）アニメーション開始
    if (oldWidget.piece == null && widget.piece != null) {
      _controller
        ..reset()
        ..forward();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final piece = widget.piece;

    if (piece == null) {
      return const SizedBox.shrink();
    }

    return Center(
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return Opacity(
            opacity: _opacityAnimation.value,
            child: Transform.scale(
              scale: _scaleAnimation.value,
              child: child,
            ),
          );
        },
        child: PieceWidget(
          piece: piece,
          pieceIndex: widget.index,
          cellSize: widget.cellSize * 0.6,
        ),
      ),
    );
  }
}

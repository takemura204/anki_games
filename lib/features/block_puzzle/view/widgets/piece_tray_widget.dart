import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:mono_games/features/block_puzzle/model/game_theme.dart';
import 'package:mono_games/features/block_puzzle/model/piece.dart';
import 'package:mono_games/features/block_puzzle/view/widgets/piece_widget.dart';
import 'package:mono_games/features/block_puzzle/view_model/block_puzzle_view_model.dart';
import 'package:mono_games/features/settings/view_model/settings_view_model.dart';
import 'package:mono_games/gen/assets.gen.dart';
import 'package:mono_games/until/service/audio_service.dart';

/// 画面下部に3つのドラッグ可能なピースを表示するトレイ。
class PieceTrayWidget extends ConsumerWidget {
  /// ピーストレイを作成する。
  const PieceTrayWidget({
    required this.cellSize,
    required this.theme,
    super.key,
  });

  /// 各セルの論理ピクセルサイズ。
  final double cellSize;

  /// 現在のゲームテーマ。
  final GameTheme theme;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pieces = ref.watch(
      blockPuzzleViewModelProvider.select((s) => s.pieces),
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
                theme: theme,
              ),
            ),
        ],
      ),
    );
  }
}

class _AnimatedPieceSlot extends ConsumerStatefulWidget {
  const _AnimatedPieceSlot({
    required this.piece,
    required this.index,
    required this.cellSize,
    required this.theme,
    super.key,
  });

  final Piece? piece;
  final int index;

  /// ボードセルサイズ（トレイ表示は 0.6 倍して使用）。
  final double cellSize;
  final GameTheme theme;

  @override
  ConsumerState<_AnimatedPieceSlot> createState() => _AnimatedPieceSlotState();
}

class _AnimatedPieceSlotState extends ConsumerState<_AnimatedPieceSlot>
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

    // スロット全体（Expanded の 1/3 幅 × cellSize*4 高さ）を Draggable にする。
    // SizedBox.expand() が Draggable の child になることで、
    // ブロックを直接タップしなくてもスロット内ならどこでもドラッグ開始できる。
    return SizedBox.expand(
      child: Draggable<int>(
        data: widget.index,
        // 指の位置を基点に Transform.translate で feedback を配置する
        dragAnchorStrategy: pointerDragAnchorStrategy,
        onDragStarted: () {
          final settings = ref.read(settingsViewModelProvider);
          if (settings.vibrationEnabled) {
            HapticFeedback.selectionClick();
          }
          if (settings.soundEnabled) {
            AudioService.instance.playWithPan(
              'sounds/block_puzzle/block_select.mp3',
              rate: 0.85,
            );
          }
        },
        // ドラッグ中フィードバック: ボードセルサイズで表示。横中央合わせ・底辺が指の1セル上
        feedback: Transform.translate(
          offset: Offset(
            -(piece.width / 2) * widget.cellSize,
            -(piece.height + 1) * widget.cellSize,
          ),
          child: Material(
            color: Colors.transparent,
            child: Opacity(
              opacity: 0.85,
              child: PieceWidget(
                piece: piece,
                cellSize: widget.cellSize,
                theme: widget.theme,
              ),
            ),
          ),
        ),
        // ドラッグ中はスロット全体を空にする
        childWhenDragging: const SizedBox.expand(),
        // 通常表示: ピースをスロット中央にトレイサイズ（0.6倍）で配置
        // Listener(opaque) でスロット全体をヒットテスト対象にする。
        // CustomPaint は塗りつぶし領域外でhitTest=falseを返すため、
        // opaque Listener がスロット全域でhitTarget=trueを保証する。
        child: Listener(
          behavior: HitTestBehavior.opaque,
          child: AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              return Opacity(
                opacity: _opacityAnimation.value,
                // transformHitTests: false でスポーンアニメーション中も全スロット幅を維持
                child: Transform.scale(
                  scale: _scaleAnimation.value,
                  transformHitTests: false,
                  child: child,
                ),
              );
            },
            child: Center(
              child: PieceWidget(
                piece: piece,
                cellSize: widget.cellSize * 0.6,
                theme: widget.theme,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

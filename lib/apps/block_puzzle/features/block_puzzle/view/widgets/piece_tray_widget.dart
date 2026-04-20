import 'package:anki_games/apps/block_puzzle/features/block_puzzle/model/game_theme.dart';
import 'package:anki_games/apps/block_puzzle/features/block_puzzle/model/piece.dart';
import 'package:anki_games/apps/block_puzzle/features/block_puzzle/view/widgets/piece_widget.dart';
import 'package:anki_games/apps/block_puzzle/features/block_puzzle/view_model/block_puzzle_view_model.dart';
import 'package:anki_games/common/features/settings/view_model/settings_view_model.dart';
import 'package:anki_games/common/utils/service/audio_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

/// 画面下部にピースを表示するトレイ。
///
/// スロット数は `blockPuzzleViewModelProvider.pieces.length` で動的に決まる。
class PieceTrayWidget extends ConsumerWidget {
  const PieceTrayWidget({
    required this.cellSize,
    required this.theme,
    this.onDragStart,
    this.choiceTexts,
    this.trayHeight,
    this.pieceScale,
    super.key,
  });

  final double cellSize;
  final GameTheme theme;

  /// ドラッグ開始時に呼ばれるコールバック（引数はスロットインデックス）。
  final void Function(int slotIndex)? onDragStart;

  /// 各スロットのブロック下に表示するラベル（4択モード用）。
  ///
  /// 長さはスロット数と一致する必要がある。null の場合はラベルなし。
  final List<String>? choiceTexts;

  /// トレイ全体の高さ。省略時は cellSize × 4。
  final double? trayHeight;

  /// ピース描画スケール。省略時は 0.5。
  final double? pieceScale;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pieces = ref.watch(
      blockPuzzleViewModelProvider.select((s) => s.pieces),
    );

    final height = trayHeight ?? cellSize * 4;
    final scale = pieceScale ?? 0.5;

    if (pieces.isEmpty) {
      return SizedBox(height: height);
    }

    return SizedBox(
      height: height,
      child: Row(
        children: [
          for (var i = 0; i < pieces.length; i++)
            Expanded(
              child: _AnimatedPieceSlot(
                key: ValueKey('slot_$i'),
                piece: i < pieces.length ? pieces[i] : null,
                index: i,
                cellSize: cellSize,
                theme: theme,
                trayHeight: height,
                pieceScale: scale,
                choiceText: choiceTexts != null && i < choiceTexts!.length
                    ? choiceTexts![i]
                    : null,
                onDragStart: onDragStart != null ? () => onDragStart!(i) : null,
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
    required this.trayHeight,
    required this.pieceScale,
    this.choiceText,
    this.onDragStart,
    super.key,
  });

  final Piece? piece;
  final int index;
  final double cellSize;
  final GameTheme theme;
  final double trayHeight;
  final double pieceScale;

  /// 選択肢ラベル（4択モード時に表示）。
  final String? choiceText;

  /// ドラッグ開始時コールバック。
  final VoidCallback? onDragStart;

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

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final hasLabel = widget.choiceText != null;
    final labelHeight = hasLabel ? widget.cellSize * 1 : 0.0;
    final blockHeight = widget.trayHeight - labelHeight;

    return SizedBox.expand(
      child: Draggable<int>(
        data: widget.index,
        dragAnchorStrategy: pointerDragAnchorStrategy,
        onDragStarted: () {
          widget.onDragStart?.call();
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
        childWhenDragging: const SizedBox.expand(),
        child: Listener(
          behavior: HitTestBehavior.opaque,
          child: AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              return Opacity(
                opacity: _opacityAnimation.value,
                child: Transform.scale(
                  scale: _scaleAnimation.value,
                  transformHitTests: false,
                  child: child,
                ),
              );
            },
            child: Column(
              children: [
                SizedBox(
                  height: blockHeight,
                  child: Center(
                    child: PieceWidget(
                      piece: piece,
                      cellSize: widget.cellSize * widget.pieceScale,
                      theme: widget.theme,
                    ),
                  ),
                ),
                if (hasLabel)
                  SizedBox(
                    height: labelHeight,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 2),
                      child: Text(
                        widget.choiceText!,
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: isDark ? Colors.white70 : Colors.black54,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

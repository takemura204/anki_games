import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:mono_games/features/block_puzzle/model/game_theme.dart';
import 'package:mono_games/features/block_puzzle/model/piece.dart';
import 'package:mono_games/features/block_puzzle/view/widgets/piece_widget.dart';
import 'package:mono_games/features/block_puzzle/view_model/block_puzzle_view_model.dart';
import 'package:mono_games/features/quiz/model/quiz_word.dart';
import 'package:mono_games/features/settings/view_model/settings_view_model.dart';
import 'package:mono_games/until/service/audio_service.dart';

/// 画面下部に3つのピースを表示するトレイ。
///
/// [quizWords] が非null のときはクイズモード表示（非ドラッグ・正方形枠・単語ラベル）。
class PieceTrayWidget extends ConsumerWidget {
  /// ピーストレイを作成する。
  const PieceTrayWidget({
    required this.cellSize,
    required this.theme,
    this.quizWords,
    this.quizCorrectness,
    super.key,
  });

  /// 各セルの論理ピクセルサイズ。
  final double cellSize;

  /// 現在のゲームテーマ。
  final GameTheme theme;

  /// クイズモード時の単語（非null でクイズモード表示に切り替わる）。
  final List<QuizWord?>? quizWords;

  /// クイズモード時の正誤（true=緑・false=赤・null=未回答）。
  final List<bool?>? quizCorrectness;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pieces = ref.watch(
      blockPuzzleViewModelProvider.select((s) => s.pieces),
    );
    final isQuizMode = quizWords != null;
    const slotCount = 3;

    return SizedBox(
      height: cellSize * 4,
      child: Row(
        children: [
          for (var i = 0; i < slotCount; i++)
            Expanded(
              child: isQuizMode
                  ? _QuizPieceSlot(
                      key: ValueKey('quiz_slot_$i'),
                      piece: i < pieces.length ? pieces[i] : null,
                      quizWord: i < quizWords!.length ? quizWords![i] : null,
                      isCorrect: quizCorrectness != null &&
                              i < quizCorrectness!.length
                          ? quizCorrectness![i]
                          : null,
                      cellSize: cellSize,
                      theme: theme,
                    )
                  : _AnimatedPieceSlot(
                      key: ValueKey('slot_$i'),
                      piece: i < pieces.length ? pieces[i] : null,
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

  /// ボードセルサイズ（トレイ表示は 0.5 倍して使用）。
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
        // 通常表示: ピースをブロックエリア（上 cellSize*3）の中央に配置。
        // 下 cellSize 分の余白はクイズモードの単語ラベルエリアと高さを揃えるため。
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
            child: Column(
              children: [
                SizedBox(
                  height: widget.cellSize * 3,
                  child: Center(
                    child: PieceWidget(
                      piece: piece,
                      cellSize: widget.cellSize * 0.5,
                      theme: widget.theme,
                    ),
                  ),
                ),
                SizedBox(height: widget.cellSize),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════════════════════
// クイズモードのスロット
// ════════════════════════════════════════════════════════════════════════════

/// クイズ回答で獲得したピースを表示するスロット。
///
/// 上 cellSize*3 をフレームエリア（枠＋ブロック）、下 cellSize を単語ラベルエリアに分割する。
/// ブロックモードも同じ高さ配分なので、モード切替時にブロック位置がずれない。
class _QuizPieceSlot extends StatelessWidget {
  const _QuizPieceSlot({
    required this.piece,
    required this.quizWord,
    required this.isCorrect,
    required this.cellSize,
    required this.theme,
    super.key,
  });

  final Piece? piece;
  final QuizWord? quizWord;
  final bool? isCorrect;
  final double cellSize;
  final GameTheme theme;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final Color borderColor;
    final Color bgColor;
    final Color? wordColor;

    if (piece != null && isCorrect != null) {
      final base = isCorrect! ? Colors.green : Colors.red;
      borderColor = base.withValues(alpha: 0.6);
      bgColor = base.withValues(alpha: isDark ? 0.25 : 0.15);
      wordColor = isCorrect! ? Colors.green.shade300 : Colors.red.shade300;
    } else {
      borderColor =
          (isDark ? Colors.white : Colors.black).withValues(alpha: 0.2);
      bgColor =
          (isDark ? Colors.white : Colors.black).withValues(alpha: 0.05);
      wordColor = null;
    }

    return Column(
      children: [
        // フレームエリア: ブロックのみを囲む（cellSize * 3）
        SizedBox(
          height: cellSize * 3,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              decoration: BoxDecoration(
                color: bgColor,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: borderColor),
              ),
              child: Center(
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 250),
                  transitionBuilder: (child, anim) => ScaleTransition(
                    scale: anim,
                    child: FadeTransition(opacity: anim, child: child),
                  ),
                  child: piece != null
                      ? PieceWidget(
                          key: ValueKey(piece),
                          piece: piece!,
                          cellSize: cellSize * 0.5,
                          theme: theme,
                        )
                      : const SizedBox.shrink(),
                ),
              ),
            ),
          ),
        ),
        // 単語ラベルエリア: 枠の外・下部（cellSize * 1）
        SizedBox(
          height: cellSize,
          child: quizWord != null
              ? Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      quizWord!.en,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: wordColor,
                      ),
                    ),
                    Text(
                      quizWord!.ja,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: wordColor,
                      ),
                    ),
                  ],
                )
              : const SizedBox.shrink(),
        ),
      ],
    );
  }
}

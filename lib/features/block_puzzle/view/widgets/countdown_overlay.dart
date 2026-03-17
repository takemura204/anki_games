import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:mono_games/features/block_puzzle/model/game_theme.dart';
import 'package:mono_games/features/block_puzzle/view_model/block_puzzle_view_model.dart';

/// タイムアタック開始前の 3-2-1 カウントダウンオーバーレイ。
class CountdownOverlay extends ConsumerStatefulWidget {
  /// カウントダウンオーバーレイを作成する。
  const CountdownOverlay({required this.theme, super.key});

  /// 現在のゲームテーマ。
  final GameTheme theme;

  @override
  ConsumerState<CountdownOverlay> createState() => _CountdownOverlayState();
}

class _CountdownOverlayState extends ConsumerState<CountdownOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scaleAnim;
  late final Animation<double> _fadeAnim;

  var _lastSeconds = -1;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _scaleAnim = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 1.4, end: 1), weight: 6),
      TweenSequenceItem(tween: Tween(begin: 1, end: 0.85), weight: 4),
    ]).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));
    _fadeAnim = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 1, end: 1), weight: 5),
      TweenSequenceItem(tween: Tween(begin: 1, end: 0), weight: 5),
    ]).animate(CurvedAnimation(parent: _controller, curve: Curves.easeIn));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _triggerPop(int seconds) {
    if (seconds == _lastSeconds) {
      return;
    }
    _lastSeconds = seconds;
    _controller
      ..reset()
      ..forward();
  }

  @override
  Widget build(BuildContext context) {
    final colors = widget.theme.colorsFor(Theme.of(context).brightness);
    final countdown = ref.watch(
      blockPuzzleViewModelProvider.select((s) => s.timeAttackCountdownSeconds),
    );

    _triggerPop(countdown);

    final label = countdown > 0 ? '$countdown' : 'GO!';

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        return ColoredBox(
          color: colors.overlayBg.withValues(alpha: 0.55),
          child: Center(
            child: Opacity(
              opacity: _fadeAnim.value,
              child: Transform.scale(
                scale: _scaleAnim.value,
                child: Text(
                  label,
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 96,
                    fontWeight: FontWeight.bold,
                    color: colors.onSurface,
                    height: 1,
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

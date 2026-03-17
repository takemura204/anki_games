import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:mono_games/features/admob/admob_interstitial.dart';
import 'package:mono_games/features/block_puzzle/model/game_theme.dart';
import 'package:mono_games/features/block_puzzle/view_model/block_puzzle_view_model.dart';
import 'package:mono_games/features/settings/view_model/settings_view_model.dart';

/// クエストモードのレベル達成時に表示するフルスクリーンオーバーレイ。
class QuestSuccessOverlay extends ConsumerStatefulWidget {
  /// クエスト成功オーバーレイを作成する。
  const QuestSuccessOverlay({
    required this.theme,
    required this.level,
    required this.score,
    super.key,
  });

  /// 現在のゲームテーマ。
  final GameTheme theme;

  /// クリアしたレベル番号。
  final int level;

  /// 達成スコア。
  final int score;

  @override
  ConsumerState<QuestSuccessOverlay> createState() =>
      _QuestSuccessOverlayState();
}

class _QuestSuccessOverlayState extends ConsumerState<QuestSuccessOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _fadeIn;
  late final Animation<double> _slideUp;
  late final Animation<double> _starBounce;

  var _progressSaved = false;

  @override
  void initState() {
    super.initState();
    if (ref.read(settingsViewModelProvider).vibrationEnabled) {
      HapticFeedback.heavyImpact();
    }

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );

    _fadeIn = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0, 0.4, curve: Curves.easeOut),
      ),
    );

    _slideUp = Tween<double>(begin: 40, end: 0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.2, 0.7, curve: Curves.easeOut),
      ),
    );

    _starBounce = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0, end: 1.3), weight: 6),
      TweenSequenceItem(tween: Tween(begin: 1.3, end: 1), weight: 4),
    ]).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.5, 1, curve: Curves.easeOut),
      ),
    );

    _controller.forward();
    _saveProgress();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        AdmobInterstitial().loadAndShow();
      }
    });
  }

  Future<void> _saveProgress() async {
    if (_progressSaved) {
      return;
    }
    _progressSaved = true;
    await ref
        .read(blockPuzzleViewModelProvider.notifier)
        .completeQuestLevel(widget.level);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = widget.theme.colorsFor(Theme.of(context).brightness);

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        return ColoredBox(
          color: colors.overlayBg.withValues(
            alpha: _fadeIn.value * colors.overlayBg.a,
          ),
          child: Center(
            child: Transform.translate(
              offset: Offset(0, _slideUp.value),
              child: Opacity(
                opacity: _fadeIn.value,
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 32),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 32,
                    vertical: 36,
                  ),
                  decoration: BoxDecoration(
                    color: colors.surface,
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // レベル表示
                      Text(
                        'LEVEL ${widget.level}',
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 2,
                          color: colors.onSurface.withValues(alpha: 0.5),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'CLEARED!',
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 2,
                          color: colors.onSurface,
                        ),
                      ),
                      const SizedBox(height: 20),
                      // スター
                      Transform.scale(
                        scale: _starBounce.value,
                        child: Icon(
                          Icons.star_rounded,
                          size: 64,
                          color: colors.accent,
                        ),
                      ),
                      const SizedBox(height: 20),
                      // スコア
                      Text(
                        '${widget.score}',
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 44,
                          fontWeight: FontWeight.bold,
                          color: colors.onSurface,
                          height: 1,
                        ),
                      ),
                      Text(
                        'SCORE',
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 1.5,
                          color: colors.onSurface.withValues(alpha: 0.4),
                        ),
                      ),
                      const SizedBox(height: 32),
                      // Next Level ボタン
                      SizedBox(
                        width: double.infinity,
                        child: TextButton(
                          onPressed: () {
                            if (ref
                                .read(settingsViewModelProvider)
                                .vibrationEnabled) {
                              HapticFeedback.lightImpact();
                            }
                            ref
                                .read(blockPuzzleViewModelProvider.notifier)
                                .startQuestLevel(widget.level + 1);
                          },
                          style: TextButton.styleFrom(
                            backgroundColor: colors.onSurface,
                            foregroundColor: colors.surface,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(50),
                            ),
                          ),
                          child: const Text(
                            'Next Level  →',
                            style: TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      // ホームボタン
                      SizedBox(
                        width: double.infinity,
                        child: TextButton(
                          onPressed: () {
                            if (ref
                                .read(settingsViewModelProvider)
                                .vibrationEnabled) {
                              HapticFeedback.lightImpact();
                            }
                            Navigator.of(context).pop();
                          },
                          style: TextButton.styleFrom(
                            foregroundColor:
                                colors.onSurface.withValues(alpha: 0.55),
                          ),
                          child: const Text(
                            'Home',
                            style: TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ),
                    ],
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

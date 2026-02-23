import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:mono_games/features/noir_mind/model/game_theme.dart';
import 'package:mono_games/features/noir_mind/view_model/noir_mind_view_model.dart';
import 'package:mono_games/until/service/audio_service.dart';

/// ゲームオーバー時に表示するフルスクリーンオーバーレイ。
class GameOverOverlay extends ConsumerStatefulWidget {
  /// ゲームオーバーオーバーレイを作成する。
  const GameOverOverlay({required this.theme, super.key});

  /// 現在のゲームテーマ。
  final GameTheme theme;

  @override
  ConsumerState<GameOverOverlay> createState() => _GameOverOverlayState();
}

class _GameOverOverlayState extends ConsumerState<GameOverOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _fadeIn;
  late final Animation<double> _slideUp;
  late final Animation<double> _newBestScale;

  @override
  void initState() {
    super.initState();
    HapticFeedback.heavyImpact();
    AudioService.instance.play(widget.theme.sounds.gameOverPath);

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    _fadeIn = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0, 0.4, curve: Curves.easeOut),
      ),
    );

    _slideUp = Tween<double>(begin: 30, end: 0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.2, 0.7, curve: Curves.easeOut),
      ),
    );

    _newBestScale = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween(begin: 0, end: 1.2),
        weight: 6,
      ),
      TweenSequenceItem(
        tween: Tween(begin: 1.2, end: 1),
        weight: 4,
      ),
    ]).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.5, 1, curve: Curves.easeOut),
      ),
    );

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = widget.theme.colorsFor(Theme.of(context).brightness);
    final gameState = ref.watch(noirMindViewModelProvider);

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
                  margin: const EdgeInsets.symmetric(
                    horizontal: 40,
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 32,
                    vertical: 40,
                  ),
                  decoration: BoxDecoration(
                    color: colors.surface,
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // クエストモードではレベル表示
                      if (gameState.isQuestMode) ...[
                        Text(
                          'LEVEL ${gameState.questLevel}',
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 2,
                            color: colors.onSurface.withValues(alpha: 0.5),
                          ),
                        ),
                        const SizedBox(height: 4),
                      ],
                      Text(
                        gameState.isQuestMode ? 'LEVEL FAILED' : 'GAME OVER',
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 3,
                          color: colors.onSurface,
                        ),
                      ),
                      const SizedBox(height: 24),
                      Text(
                        '${gameState.score}',
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 48,
                          fontWeight: FontWeight.bold,
                          color: colors.onSurface,
                          height: 1,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        gameState.isQuestMode
                            ? 'SCORE  (TARGET: ${gameState.targetScore})'
                            : 'SCORE',
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 2,
                          color: colors.onSurface.withValues(alpha: 0.4),
                        ),
                      ),
                      if (!gameState.isQuestMode) ...[
                        const SizedBox(height: 16),
                        // クラシックモードのみハイスコア表示
                        Text(
                          'BEST  ${gameState.highScore}',
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: colors.onSurface.withValues(alpha: 0.5),
                          ),
                        ),
                        // NEW BESTバッジ
                        if (gameState.isNewHighScore) ...[
                          const SizedBox(height: 12),
                          Transform.scale(
                            scale: _newBestScale.value,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: colors.accent.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                'NEW BEST!',
                                style: TextStyle(
                                  fontFamily: 'Poppins',
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 1.5,
                                  color: colors.accent,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ],
                      const SizedBox(height: 32),
                      // メインアクションボタン
                      SizedBox(
                        width: double.infinity,
                        child: TextButton(
                          onPressed: () {
                            HapticFeedback.lightImpact();
                            if (gameState.isQuestMode) {
                              ref
                                  .read(
                                    noirMindViewModelProvider.notifier,
                                  )
                                  .retryQuestLevel();
                            } else {
                              ref
                                  .read(
                                    noirMindViewModelProvider.notifier,
                                  )
                                  .resetGame();
                            }
                          },
                          style: TextButton.styleFrom(
                            backgroundColor: colors.onSurface,
                            foregroundColor: colors.surface,
                            padding: const EdgeInsets.symmetric(
                              vertical: 14,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(50),
                            ),
                          ),
                          child: Text(
                            gameState.isQuestMode ? 'Retry Level' : 'Play Again',
                            style: const TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                      // クエストモードのみHomeボタン
                      if (gameState.isQuestMode) ...[
                        const SizedBox(height: 8),
                        SizedBox(
                          width: double.infinity,
                          child: TextButton(
                            onPressed: () {
                              HapticFeedback.lightImpact();
                              Navigator.of(context).pop();
                            },
                            style: TextButton.styleFrom(
                              foregroundColor: colors.onSurface.withValues(alpha: 0.55),
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

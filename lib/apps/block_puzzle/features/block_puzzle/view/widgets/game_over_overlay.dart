import 'package:anki_games/apps/block_puzzle/features/block_puzzle/model/game_theme.dart';
import 'package:anki_games/apps/block_puzzle/features/block_puzzle/view_model/block_puzzle_view_model.dart';
import 'package:anki_games/common/features/admob/admob_interstitial.dart';
import 'package:anki_games/common/features/admob/admob_reward.dart';
import 'package:anki_games/common/features/purchase/view_model/premium_view_model.dart';
import 'package:anki_games/common/features/quiz/view/widgets/quiz_session_stats_widget.dart';
import 'package:anki_games/common/features/quiz/view_model/quiz_view_model.dart';
import 'package:anki_games/common/features/settings/view_model/settings_view_model.dart';
import 'package:anki_games/common/i18n/translations.g.dart';
import 'package:anki_games/common/utils/router/router_constants.dart';
import 'package:anki_games/common/utils/service/audio_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

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
  late final RewardedAdService _rewardedAdService;

  @override
  void initState() {
    super.initState();
    final settings = ref.read(settingsViewModelProvider);
    if (settings.vibrationEnabled) {
      HapticFeedback.heavyImpact();
    }
    if (settings.soundEnabled) {
      AudioService.instance.play(widget.theme.sounds.gameOverPath);
    }

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

    _rewardedAdService = RewardedAdService();
    final gameState = ref.read(blockPuzzleViewModelProvider);
    final isPremium =
        ref.read(premiumViewModelProvider).valueOrNull?.isPremium ?? false;

    if (!isPremium && !gameState.isQuizMode) {
      _rewardedAdService.load();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _rewardedAdService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = widget.theme.colorsFor(Theme.of(context).brightness);
    final gameState = ref.watch(blockPuzzleViewModelProvider);
    final bestScore = gameState.highScore;
    final isClassicMode = !gameState.isQuizMode;

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
                  constraints: const BoxConstraints(maxWidth: 320),
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
                      Text(
                        t.blockPuzzle.gameOver,
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
                        t.blockPuzzle.scoreLabel,
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 2,
                          color: colors.onSurface.withValues(alpha: 0.4),
                        ),
                      ),
                      // クイズモード: セッション統計
                      if (gameState.isQuizMode) ...[
                        const SizedBox(height: 20),
                        QuizSessionStatsWidget(
                          correctWords: gameState.sessionCorrectWords,
                          incorrectWords: gameState.sessionIncorrectWords,
                          tomorrowReviewCount: ref
                              .watch(quizViewModelProvider)
                              .tomorrowReviewCount,
                          colors: colors,
                        ),
                      ],
                      if (!gameState.isQuizMode) ...[
                        const SizedBox(height: 16),
                        // クラシック / タイムアタックのベストスコア表示
                        Text(
                          '${t.blockPuzzle.bestLabel}  $bestScore',
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
                                t.blockPuzzle.newBest,
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
                      // クラシックモード + コンティニュー可能: Continue ボタン
                      if (isClassicMode && gameState.canContinue) ...[
                        SizedBox(
                          width: double.infinity,
                          child: TextButton(
                            onPressed: () {
                              final vibration = ref
                                  .read(settingsViewModelProvider)
                                  .vibrationEnabled;
                              if (vibration) {
                                HapticFeedback.lightImpact();
                              }
                              final shown = _rewardedAdService.show(
                                (ad, reward) {
                                  if (mounted) {
                                    ref
                                        .read(
                                          blockPuzzleViewModelProvider.notifier,
                                        )
                                        .continueGame();
                                  }
                                },
                              );
                              if (!shown) {
                                // 広告未ロード時は再ロードしてスナックバー通知
                                _rewardedAdService.load();
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      t.blockPuzzle.adLoading,
                                    ),
                                    duration: const Duration(seconds: 2),
                                  ),
                                );
                              }
                            },
                            style: TextButton.styleFrom(
                              backgroundColor: colors.accent,
                              foregroundColor: colors.surface,
                              padding: const EdgeInsets.symmetric(
                                vertical: 14,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(50),
                              ),
                            ),
                            child: Text(
                              t.blockPuzzle.continueGame,
                              style: const TextStyle(
                                fontFamily: 'Poppins',
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                      ],
                      // メインアクションボタン
                      SizedBox(
                        width: double.infinity,
                        child: TextButton(
                          onPressed: () {
                            final vibration = ref
                                .read(settingsViewModelProvider)
                                .vibrationEnabled;
                            if (vibration) {
                              HapticFeedback.lightImpact();
                            }
                            final notifier = ref.read(
                              blockPuzzleViewModelProvider.notifier,
                            );
                            if (gameState.isQuizMode) {
                              rootNavigatorKey.currentContext?.pop();
                              return;
                            }
                            final isPremiumNow = ref
                                    .read(premiumViewModelProvider)
                                    .valueOrNull
                                    ?.isPremium ??
                                false;
                            void proceed() {
                              if (!mounted) {
                                return;
                              }
                              notifier.resetGame();
                            }

                            if (isPremiumNow) {
                              proceed();
                            } else {
                              AdmobInterstitial()
                                  .loadAndShow(onDismissed: proceed);
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
                            t.blockPuzzle.playAgain,
                            style: const TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                      // クイズはHomeボタンを表示
                      if (gameState.isQuizMode) ...[
                        const SizedBox(height: 8),
                        SizedBox(
                          width: double.infinity,
                          child: TextButton(
                            onPressed: () {
                              final vibration = ref
                                  .read(settingsViewModelProvider)
                                  .vibrationEnabled;
                              if (vibration) {
                                HapticFeedback.lightImpact();
                              }
                              // ゲームオーバーオーバーレイはスタック上のルートではないため
                              // Navigator.popUntil で HomeScreen まで戻る
                              Navigator.of(context)
                                  .popUntil((route) => route.isFirst);
                            },
                            style: TextButton.styleFrom(
                              foregroundColor:
                                  colors.onSurface.withValues(alpha: 0.55),
                            ),
                            child: Text(
                              t.blockPuzzle.homeButton,
                              style: const TextStyle(
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

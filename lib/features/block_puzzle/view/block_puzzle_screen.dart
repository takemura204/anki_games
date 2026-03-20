import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_card_swiper/flutter_card_swiper.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:mono_games/features/admob/admob_banner.dart';
import 'package:mono_games/features/block_puzzle/model/board.dart';
import 'package:mono_games/features/block_puzzle/model/game_theme.dart';
import 'package:mono_games/features/block_puzzle/view/widgets/background_effect_widget.dart';
import 'package:mono_games/features/block_puzzle/view/widgets/board_widget.dart';
import 'package:mono_games/features/block_puzzle/view/widgets/countdown_overlay.dart';
import 'package:mono_games/features/block_puzzle/view/widgets/game_over_overlay.dart';
import 'package:mono_games/features/block_puzzle/view/widgets/piece_tray_widget.dart';
import 'package:mono_games/features/block_puzzle/view/widgets/quest_success_overlay.dart';
import 'package:mono_games/features/block_puzzle/view/widgets/score_hud_widget.dart';
import 'package:mono_games/features/block_puzzle/view/widgets/time_attack_result_overlay.dart';
import 'package:mono_games/features/block_puzzle/view_model/block_puzzle_view_model.dart';
import 'package:mono_games/features/block_puzzle/view_model/theme_view_model.dart';
import 'package:mono_games/features/quiz/view/widgets/quiz_card.dart';
import 'package:mono_games/features/quiz/view_model/quiz_view_model.dart';
import 'package:mono_games/features/settings/view/settings_dialog.dart';
import 'package:mono_games/i18n/translations.g.dart';

/// Noir Mindパズルゲームのメイン画面。
///
/// クイズフェーズ時はボードを縮小し、同一画面内でフェード切り替えする。
class BlockPuzzleScreen extends ConsumerWidget {
  /// Noir Mind画面を作成する。
  const BlockPuzzleScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ref.watch(themeViewModelProvider);
    final gameState = ref.watch(blockPuzzleViewModelProvider);
    final isGameOver = gameState.isGameOver;
    final isQuestComplete = gameState.isQuestComplete;
    final isQuestMode = gameState.isQuestMode;
    final isTimeAttackMode = gameState.isTimeAttackMode;
    final isTimeAttackComplete = gameState.isTimeAttackComplete;
    final isTimeAttackCountingDown = gameState.isTimeAttackCountingDown;
    final isQuizMode = gameState.isQuizMode;
    final isQuizPhase = gameState.isQuizPhase;
    final colors = theme.colorsFor(Theme.of(context).brightness);

    // クイズフェーズ開始を検知して新しいラウンドを開始
    ref.listen<bool>(
      blockPuzzleViewModelProvider.select((s) => s.isQuizPhase),
      (prev, next) {
        if (next && !(prev ?? false)) {
          ref.read(quizViewModelProvider.notifier).startNewRound();
        }
      },
    );

    return Scaffold(
      backgroundColor: colors.surface,
      body: SafeArea(
        child: Stack(
          children: [
            // 背景エフェクト
            Positioned.fill(
              child: BackgroundEffectWidget(theme: theme),
            ),
            // メインレイアウト
            Column(
              children: [
                const SizedBox(height: 8),
                // 上部バー（常時）
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton(
                        icon: Icon(
                          Icons.arrow_back_ios_new_rounded,
                          color: colors.onSurface.withValues(alpha: 0.6),
                          size: 20,
                        ),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                      if (isTimeAttackMode)
                        Text(
                          'TIME ATTACK',
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 2,
                            color: colors.onSurface.withValues(alpha: 0.6),
                          ),
                        )
                      else if (isQuestMode)
                        Text(
                          'LEVEL ${gameState.questLevel}',
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 2,
                            color: colors.onSurface.withValues(alpha: 0.6),
                          ),
                        )
                      else if (isQuizMode)
                        Text(
                          t.quiz.quizMode.toUpperCase(),
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 2,
                            color: colors.onSurface.withValues(alpha: 0.6),
                          ),
                        ),
                      IconButton(
                        icon: Icon(
                          Icons.settings_outlined,
                          color: colors.onSurface.withValues(alpha: 0.6),
                          size: 22,
                        ),
                        onPressed: () => showGameSettingsDialog(context),
                      ),
                    ],
                  ),
                ),
                // タイムアタック: タイマーバー
                if (isTimeAttackMode)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: _TimerBar(
                      fraction: gameState.timeAttackRemainingSeconds / 90,
                      color: colors.accent,
                      trackColor: colors.emptyCellFill,
                    ),
                  ),
                // スコアHUD（クイズ中は非表示、レイアウトは維持）
                Visibility(
                  visible: !isQuizPhase,
                  maintainSize: true,
                  maintainAnimation: true,
                  maintainState: true,
                  child: ScoreHudWidget(theme: theme),
                ),
                const SizedBox(height: 24),
                // メインコンテンツ（LayoutBuilder でセルサイズを確定）
                Expanded(
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      const boardPadding = 20.0;
                      const totalCellsForHeight = 14.0;
                      final cellSizeFromWidth =
                          (constraints.maxWidth - boardPadding * 2) /
                              Board.size;
                      final cellSizeFromHeight =
                          constraints.maxHeight / totalCellsForHeight;
                      final cellSize =
                          min(cellSizeFromWidth, cellSizeFromHeight);

                      return AnimatedSwitcher(
                        duration: const Duration(milliseconds: 350),
                        child: isQuizPhase
                            ? _QuizLayout(
                                key: const ValueKey('quiz'),
                                cellSize: cellSize,
                                theme: theme,
                              )
                            : _BlockLayout(
                                key: const ValueKey('block'),
                                cellSize: cellSize,
                                theme: theme,
                                boardPadding: boardPadding,
                              ),
                      );
                    },
                  ),
                ),
                const AdmobBanner(),
              ],
            ),
            // 固定オーバーレイ
            if (isGameOver && !isTimeAttackMode)
              Positioned.fill(child: GameOverOverlay(theme: theme)),
            if (isQuestComplete)
              Positioned.fill(
                child: QuestSuccessOverlay(
                  theme: theme,
                  level: gameState.questLevel,
                  score: gameState.score,
                ),
              ),
            if (isTimeAttackComplete)
              Positioned.fill(child: TimeAttackResultOverlay(theme: theme)),
            if (isTimeAttackCountingDown)
              Positioned.fill(child: CountdownOverlay(theme: theme)),
          ],
        ),
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════════════════════
// ブロックモードレイアウト
// ════════════════════════════════════════════════════════════════════════════

/// ボード + ドラッグ可能なピーストレイを縦に並べたレイアウト。
class _BlockLayout extends StatelessWidget {
  const _BlockLayout({
    required this.cellSize,
    required this.theme,
    required this.boardPadding,
    super.key,
  });

  final double cellSize;
  final GameTheme theme;
  final double boardPadding;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: Center(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: boardPadding),
              child: BoardWidget(cellSize: cellSize, theme: theme),
            ),
          ),
        ),
        PieceTrayWidget(cellSize: cellSize, theme: theme),
      ],
    );
  }
}

// ════════════════════════════════════════════════════════════════════════════
// クイズモードレイアウト
// ════════════════════════════════════════════════════════════════════════════

/// ミニボード（上部）＋スワイプカード（中央）＋獲得ピースプレビュー（下部）。
///
/// ピーストレイは [_BlockLayout] と同じ高さ（cellSize × 4）で固定する。
class _QuizLayout extends ConsumerStatefulWidget {
  const _QuizLayout({
    required this.cellSize,
    required this.theme,
    super.key,
  });

  final double cellSize;
  final GameTheme theme;

  @override
  ConsumerState<_QuizLayout> createState() => _QuizLayoutState();
}

class _QuizLayoutState extends ConsumerState<_QuizLayout> {
  late CardSwiperController _swiperController;
  var _isShowingFeedback = false;
  final List<bool?> _slotCorrectness = [null, null, null];
  final List<String?> _slotWords = [null, null, null];
  var _roundKey = 0;

  @override
  void initState() {
    super.initState();
    _swiperController = CardSwiperController();
  }

  @override
  void dispose() {
    _swiperController.dispose();
    super.dispose();
  }

  void _resetForNewRound() {
    _swiperController.dispose();
    _swiperController = CardSwiperController();
    setState(() {
      _roundKey++;
      _isShowingFeedback = false;
      _slotCorrectness[0] = null;
      _slotCorrectness[1] = null;
      _slotCorrectness[2] = null;
      _slotWords[0] = null;
      _slotWords[1] = null;
      _slotWords[2] = null;
    });
  }

  bool _onSwipe(
    int previousIndex,
    int? currentIndex,
    CardSwiperDirection cardDir,
  ) {
    if (_isShowingFeedback) {
      return false;
    }
    final swipeDir = _toSwipeDir(cardDir);
    if (swipeDir == null) {
      return false;
    }

    _isShowingFeedback = true;
    final quizStateBeforeAnswer = ref.read(quizViewModelProvider);
    final question = previousIndex < quizStateBeforeAnswer.questions.length
        ? quizStateBeforeAnswer.questions[previousIndex]
        : null;
    final displayWord = question?.displayText;
    ref.read(quizViewModelProvider.notifier).answer(previousIndex, swipeDir);

    final quizState = ref.read(quizViewModelProvider);
    final isCorrect =
        quizState.answers.isNotEmpty && quizState.answers.last.isCorrect;
    ref.read(blockPuzzleViewModelProvider.notifier).addQuizPiece(
          previousIndex,
          isCorrect: isCorrect,
          word: question?.word,
        );
    setState(() {
      _slotCorrectness[previousIndex] = isCorrect;
      _slotWords[previousIndex] = displayWord;
    });

    Future<void>.delayed(const Duration(milliseconds: 300), () {
      if (!mounted) {
        return;
      }
      ref.read(quizViewModelProvider.notifier).clearLastAnswer();
      setState(() => _isShowingFeedback = false);
      if (currentIndex == null) {
        // 全3問正解でコンボ有効化
        final allCorrect = _slotCorrectness.every((c) => c == true);
        ref
            .read(blockPuzzleViewModelProvider.notifier)
            .endQuizPhase(comboActive: allCorrect);
      }
    });

    return true;
  }

  SwipeDirection? _toSwipeDir(CardSwiperDirection dir) => switch (dir) {
        CardSwiperDirection.left => SwipeDirection.left,
        CardSwiperDirection.right => SwipeDirection.right,
        CardSwiperDirection.top => SwipeDirection.up,
        CardSwiperDirection.bottom => SwipeDirection.down,
        _ => null,
      };

  /// オフセット量から優位軸を判定してアクティブ方向を返す。
  ///
  /// [horizontalOffsetPercent] と [verticalOffsetPercent] のどちらが
  /// 絶対値で大きいかを比較することで、左右・上下の検出感度を均等にする。
  SwipeDirection? _directionFromOffsets(
    int horizontalOffsetPercent,
    int verticalOffsetPercent,
  ) {
    const threshold = 4; // 4% 以上の移動で反応
    final absH = horizontalOffsetPercent.abs();
    final absV = verticalOffsetPercent.abs();
    if (absH < threshold && absV < threshold) {
      return null;
    }
    if (absH >= absV) {
      return horizontalOffsetPercent > 0
          ? SwipeDirection.right
          : SwipeDirection.left;
    }
    return verticalOffsetPercent > 0 ? SwipeDirection.down : SwipeDirection.up;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // 問題リスト更新 = 新ラウンド開始
    ref.listen<List<QuizQuestion>>(
      quizViewModelProvider.select((s) => s.questions),
      (prev, next) {
        if (next.isNotEmpty &&
            (prev == null || prev.isEmpty || prev[0] != next[0])) {
          _resetForNewRound();
        }
      },
    );

    final quizState = ref.watch(quizViewModelProvider);

    return Column(
      children: [
        // スワイプカード
        Expanded(
          child: quizState.isLoading
              ? Center(
                  child: Text(
                    t.quiz.loading,
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      color: (isDark ? Colors.white : Colors.black)
                          .withValues(alpha: 0.5),
                    ),
                  ),
                )
              : quizState.questions.isEmpty
                  ? const SizedBox.shrink()
                  : CardSwiper(
                      key: ValueKey(_roundKey),
                      controller: _swiperController,
                      cardsCount: quizState.questions.length,
                      isLoop: false,
                      onSwipe: _onSwipe,
                      cardBuilder: (
                        context,
                        index,
                        horizontalOffsetPercent,
                        verticalOffsetPercent,
                      ) {
                        if (index >= quizState.questions.length) {
                          return const SizedBox.shrink();
                        }
                        return QuizCard(
                          question: quizState.questions[index],
                          activeDirection: _directionFromOffsets(
                            horizontalOffsetPercent,
                            verticalOffsetPercent,
                          ),
                        );
                      },
                    ),
        ),
        // 獲得ピースプレビュー（PieceTrayWidget のクイズモードで表示）
        PieceTrayWidget(
          cellSize: widget.cellSize,
          theme: widget.theme,
          quizWords: _slotWords,
          quizCorrectness: _slotCorrectness,
        ),
      ],
    );
  }
}

// ════════════════════════════════════════════════════════════════════════════
// タイマーバー（タイムアタック用）
// ════════════════════════════════════════════════════════════════════════════

class _TimerBar extends StatelessWidget {
  const _TimerBar({
    required this.fraction,
    required this.color,
    required this.trackColor,
  });

  final double fraction;
  final Color color;
  final Color trackColor;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(2),
      child: LinearProgressIndicator(
        value: fraction.clamp(0, 1),
        minHeight: 4,
        backgroundColor: trackColor,
        valueColor: AlwaysStoppedAnimation<Color>(color),
      ),
    );
  }
}

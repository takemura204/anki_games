import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_card_swiper/flutter_card_swiper.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:mono_games/features/admob/admob_banner.dart';
import 'package:mono_games/features/block_puzzle/model/board.dart';
import 'package:mono_games/features/block_puzzle/model/game_theme.dart';
import 'package:mono_games/features/block_puzzle/view/widgets/background_effect_widget.dart';
import 'package:mono_games/features/block_puzzle/view/widgets/board_widget.dart';
import 'package:mono_games/features/block_puzzle/view/widgets/game_over_overlay.dart';
import 'package:mono_games/features/block_puzzle/view/widgets/piece_tray_widget.dart';
import 'package:mono_games/features/block_puzzle/view/widgets/score_hud_widget.dart';
import 'package:mono_games/features/block_puzzle/view_model/block_puzzle_view_model.dart';
import 'package:mono_games/features/block_puzzle/view_model/theme_view_model.dart';
import 'package:mono_games/features/purchase/view_model/premium_view_model.dart';
import 'package:mono_games/features/quiz/model/quiz_word.dart';
import 'package:mono_games/features/quiz/view/widgets/quiz_card.dart';
import 'package:mono_games/features/quiz/view_model/quiz_view_model.dart';
import 'package:mono_games/features/settings/view/settings_dialog.dart';
import 'package:mono_games/features/settings/view_model/settings_view_model.dart';
import 'package:mono_games/i18n/translations.g.dart';
import 'package:mono_games/until/service/tts_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
    final isQuizMode = gameState.isQuizMode;
    final isQuizPhase = gameState.isQuizPhase;
    final isPremium = ref.watch(
      premiumViewModelProvider.select((s) => s.valueOrNull?.isPremium ?? false),
    );
    final colors = theme.colorsFor(Theme.of(context).brightness);

    // クイズフェーズ開始を検知して新しいラウンドを開始。問題0件時は前画面へ戻る。
    ref
      ..listen<bool>(
        blockPuzzleViewModelProvider.select((s) => s.isQuizPhase),
        (bool? prev, bool next) {
          if (next && !(prev ?? false)) {
            ref.read(quizViewModelProvider.notifier).startNewRound();
          }
        },
      )
      ..listen<(bool, int)>(
        quizViewModelProvider.select(
          (s) => (s.isLoading, s.questions.length),
        ),
        ((bool, int)? prev, (bool, int) next) {
          final (prevLoading, _) = prev ?? (false, 0);
          final (nextLoading, nextCount) = next;
          if (prevLoading && !nextLoading && nextCount == 0) {
            if (!context.mounted) {
              return;
            }
            ref.read(blockPuzzleViewModelProvider.notifier).endQuizPhase();
            Navigator.of(context).pop();
          }
        },
      );

    return Scaffold(
      backgroundColor: colors.surface,
      resizeToAvoidBottomInset: false,
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
                      if (isQuizMode)
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
                if (!isPremium) const AdmobBanner(),
              ],
            ),
            // 固定オーバーレイ
            if (isGameOver)
              Positioned.fill(child: GameOverOverlay(theme: theme)),
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
  late FocusNode _typingFocusNode;
  var _isShowingFeedback = false;
  var _isTypingCardActive = false;
  var _isLetterTapCardActive = false;
  final List<bool?> _slotCorrectness = [null, null, null];
  final List<QuizWord?> _slotWords = [null, null, null];
  var _roundKey = 0;
  var _showHint = false;

  /// タイピングで回答済みのカードインデックス（_onSwipe で二重処理を防ぐ）。
  final _typingAnsweredIndices = <int>{};

  /// letterTap で回答済みのカードインデックス（_onSwipe で二重処理を防ぐ）。
  final _letterTapAnsweredIndices = <int>{};

  @override
  void initState() {
    super.initState();
    _swiperController = CardSwiperController();
    _typingFocusNode = FocusNode();
    _checkFirstPlay();
  }

  Future<void> _checkFirstPlay() async {
    final prefs = await SharedPreferences.getInstance();
    final shown = prefs.getBool('quiz_swipe_hint_shown') ?? false;
    if (!shown && mounted) {
      setState(() => _showHint = true);
    }
  }

  void _dismissHint() {
    if (!_showHint) {
      return;
    }
    setState(() => _showHint = false);
    SharedPreferences.getInstance()
        .then((prefs) => prefs.setBool('quiz_swipe_hint_shown', true));
  }

  @override
  void dispose() {
    _swiperController.dispose();
    _typingFocusNode.dispose();
    TtsService.instance.stop();
    super.dispose();
  }

  /// カードが切り替わった際にフォーマットを反映し、必要ならフォーカスを当てる。
  void _updateActiveCardType(int index) {
    final quizState = ref.read(quizViewModelProvider);
    if (index >= quizState.questions.length) {
      return;
    }
    final format = quizState.questions[index].format;
    final isTyping = format == QuizFormat.jaToEnTyping;
    final isLetterTap = format == QuizFormat.letterTap;
    setState(() {
      _isTypingCardActive = isTyping;
      _isLetterTapCardActive = isLetterTap;
    });
    if (isTyping) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _typingFocusNode.requestFocus();
        }
      });
    }
  }

  void _resetForNewRound() {
    _swiperController.dispose();
    _swiperController = CardSwiperController();
    _typingAnsweredIndices.clear();
    _letterTapAnsweredIndices.clear();
    setState(() {
      _roundKey++;
      _isShowingFeedback = false;
      _isLetterTapCardActive = false;
      _slotCorrectness[0] = null;
      _slotCorrectness[1] = null;
      _slotCorrectness[2] = null;
      _slotWords[0] = null;
      _slotWords[1] = null;
      _slotWords[2] = null;
    });
    _speakCurrentCard(0);
    _updateActiveCardType(0);
  }

  void _speakCurrentCard(int index) {
    final settings = ref.read(settingsViewModelProvider);
    if (!settings.ttsEnabled) {
      return;
    }
    final quizState = ref.read(quizViewModelProvider);
    final questions = quizState.questions;
    if (index >= questions.length) {
      return;
    }
    if (questions[index].format != QuizFormat.enToJaChoice) {
      return;
    }
    TtsService.instance.speak(questions[index].word.en);
  }

  /// タイピング形式の問題に回答する。
  void _onTypingSubmit(int questionIndex, String text) {
    if (_isShowingFeedback) {
      return;
    }
    FocusScope.of(context).unfocus();
    _isShowingFeedback = true;

    final quizStateBeforeAnswer = ref.read(quizViewModelProvider);
    final question = questionIndex < quizStateBeforeAnswer.questions.length
        ? quizStateBeforeAnswer.questions[questionIndex]
        : null;

    ref
        .read(quizViewModelProvider.notifier)
        .answerWithText(questionIndex, text);

    final quizState = ref.read(quizViewModelProvider);
    final lastAnswer =
        quizState.answers.isNotEmpty ? quizState.answers.last : null;
    final isCorrect = lastAnswer?.isCorrect ?? false;

    ref.read(blockPuzzleViewModelProvider.notifier).addQuizPiece(
          questionIndex,
          isCorrect: isCorrect,
          word: question?.word,
          overdueBonus: lastAnswer?.overdueBonus ?? 0,
        );
    setState(() {
      _slotCorrectness[questionIndex] = isCorrect;
      _slotWords[questionIndex] = question?.word;
    });

    // 回答済みとしてマークし、遅延後にプログラム的にカードを進める
    _typingAnsweredIndices.add(questionIndex);
    Future<void>.delayed(const Duration(milliseconds: 300), () {
      if (!mounted) {
        return;
      }
      ref.read(quizViewModelProvider.notifier).clearLastAnswer();
      setState(() => _isShowingFeedback = false);
      _swiperController.swipe(CardSwiperDirection.right);
    });
  }

  /// letterTap 形式の問題に回答する。
  void _onLetterTapSubmit(int questionIndex, bool isCorrect) {
    if (_isShowingFeedback) {
      return;
    }
    _isShowingFeedback = true;

    final quizStateBeforeAnswer = ref.read(quizViewModelProvider);
    final question = questionIndex < quizStateBeforeAnswer.questions.length
        ? quizStateBeforeAnswer.questions[questionIndex]
        : null;

    ref
        .read(quizViewModelProvider.notifier)
        .answerLetterTap(questionIndex, isCorrect: isCorrect);

    final quizState = ref.read(quizViewModelProvider);
    final lastAnswer =
        quizState.answers.isNotEmpty ? quizState.answers.last : null;

    ref.read(blockPuzzleViewModelProvider.notifier).addQuizPiece(
          questionIndex,
          isCorrect: isCorrect,
          word: question?.word,
          overdueBonus: lastAnswer?.overdueBonus ?? 0,
        );
    setState(() {
      _slotCorrectness[questionIndex] = isCorrect;
      _slotWords[questionIndex] = question?.word;
    });

    _letterTapAnsweredIndices.add(questionIndex);
    Future<void>.delayed(const Duration(milliseconds: 300), () {
      if (!mounted) {
        return;
      }
      ref.read(quizViewModelProvider.notifier).clearLastAnswer();
      setState(() => _isShowingFeedback = false);
      _swiperController.swipe(CardSwiperDirection.right);
    });
  }

  bool _onSwipe(
    int previousIndex,
    int? currentIndex,
    CardSwiperDirection cardDir,
  ) {
    _dismissHint();

    // タイピング回答済みのカードがプログラム的にスワイプされた場合
    if (_typingAnsweredIndices.remove(previousIndex)) {
      if (currentIndex == null) {
        final allCorrect = _slotCorrectness.every((c) => c == true);
        ref
            .read(blockPuzzleViewModelProvider.notifier)
            .endQuizPhase(comboActive: allCorrect);
      } else {
        _speakCurrentCard(currentIndex);
        _updateActiveCardType(currentIndex);
      }
      return true;
    }

    // letterTap 回答済みのカードがプログラム的にスワイプされた場合
    if (_letterTapAnsweredIndices.remove(previousIndex)) {
      if (currentIndex == null) {
        final allCorrect = _slotCorrectness.every((c) => c == true);
        ref
            .read(blockPuzzleViewModelProvider.notifier)
            .endQuizPhase(comboActive: allCorrect);
      } else {
        _speakCurrentCard(currentIndex);
        _updateActiveCardType(currentIndex);
      }
      return true;
    }

    // タイピング・letterTap 形式はユーザーのスワイプを無効化
    final quizState = ref.read(quizViewModelProvider);
    if (previousIndex < quizState.questions.length) {
      final fmt = quizState.questions[previousIndex].format;
      if (fmt == QuizFormat.jaToEnTyping || fmt == QuizFormat.letterTap) {
        return false;
      }
    }

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
    ref.read(quizViewModelProvider.notifier).answer(previousIndex, swipeDir);

    final answeredState = ref.read(quizViewModelProvider);
    final lastAnswer = answeredState.answers.isNotEmpty
        ? answeredState.answers.last
        : null;
    final isCorrect = lastAnswer?.isCorrect ?? false;
    ref.read(blockPuzzleViewModelProvider.notifier).addQuizPiece(
          previousIndex,
          isCorrect: isCorrect,
          word: question?.word,
          overdueBonus: lastAnswer?.overdueBonus ?? 0,
        );
    setState(() {
      _slotCorrectness[previousIndex] = isCorrect;
      _slotWords[previousIndex] = question?.word;
    });

    Future<void>.delayed(const Duration(milliseconds: 300), () {
      if (!mounted) {
        return;
      }
      ref.read(quizViewModelProvider.notifier).clearLastAnswer();
      setState(() => _isShowingFeedback = false);
      if (currentIndex == null) {
        final allCorrect = _slotCorrectness.every((c) => c == true);
        ref
            .read(blockPuzzleViewModelProvider.notifier)
            .endQuizPhase(comboActive: allCorrect);
      } else {
        _speakCurrentCard(currentIndex);
        _updateActiveCardType(currentIndex);
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
          child: Stack(
            children: [
              if (quizState.isLoading)
                Center(
                  child: Text(
                    t.quiz.loading,
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      color: (isDark ? Colors.white : Colors.black)
                          .withValues(alpha: 0.5),
                    ),
                  ),
                )
              else if (quizState.questions.isEmpty)
                const SizedBox.shrink()
              else
                CardSwiper(
                  key: ValueKey(_roundKey),
                  controller: _swiperController,
                  cardsCount: quizState.questions.length,
                  numberOfCardsDisplayed: 1,
                  isLoop: false,
                  allowedSwipeDirection:
                      (_isTypingCardActive || _isLetterTapCardActive)
                          ? const AllowedSwipeDirection.none()
                          : const AllowedSwipeDirection.all(),
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
                    final q = quizState.questions[index];
                    final ttsEnabled =
                        ref.read(settingsViewModelProvider).ttsEnabled;
                    return QuizCard(
                      question: q,
                      activeDirection: _directionFromOffsets(
                        horizontalOffsetPercent,
                        verticalOffsetPercent,
                      ),
                      onSpeak: ttsEnabled &&
                              q.format == QuizFormat.enToJaChoice
                          ? () => TtsService.instance.speak(q.word.en)
                          : null,
                      onTypingSubmit:
                          q.format == QuizFormat.jaToEnTyping
                              ? (text) => _onTypingSubmit(index, text)
                              : null,
                      onLetterTapSubmit:
                          q.format == QuizFormat.letterTap
                              ? ({required bool isCorrect}) =>
                                  _onLetterTapSubmit(index, isCorrect)
                              : null,
                      typingFocusNode: index == quizState.answeredCount
                          ? _typingFocusNode
                          : null,
                    );
                  },
                ),
              // 初回スワイプヒント（4択スワイプ形式のみ表示）
              if (_showHint &&
                  quizState.questions.isNotEmpty &&
                  (quizState.questions.first.format ==
                          QuizFormat.enToJaChoice ||
                      quizState.questions.first.format ==
                          QuizFormat.jaToEnChoice))
                Positioned.fill(
                  child: _SwipeHintOverlay(
                    choices: quizState.questions.first.choices,
                    onDismiss: _dismissHint,
                  ),
                ),
            ],
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
// 初回スワイプヒントオーバーレイ
// ════════════════════════════════════════════════════════════════════════════

class _SwipeHintOverlay extends StatefulWidget {
  const _SwipeHintOverlay({
    required this.choices,
    required this.onDismiss,
  });

  final List<QuizChoice> choices;
  final VoidCallback onDismiss;

  @override
  State<_SwipeHintOverlay> createState() => _SwipeHintOverlayState();
}

class _SwipeHintOverlayState extends State<_SwipeHintOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulseController;
  late final Animation<double> _pulse;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
    _pulse = Tween<double>(begin: 0.4, end: 1).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  QuizChoice? _choiceFor(SwipeDirection dir) {
    final matches = widget.choices.where((c) => c.direction == dir);
    return matches.isEmpty ? null : matches.first;
  }

  @override
  Widget build(BuildContext context) {
    final up = _choiceFor(SwipeDirection.up);
    final down = _choiceFor(SwipeDirection.down);
    final left = _choiceFor(SwipeDirection.left);
    final right = _choiceFor(SwipeDirection.right);

    return GestureDetector(
      onTap: widget.onDismiss,
      child: ColoredBox(
        color: Colors.black.withValues(alpha: 0.62),
        child: AnimatedBuilder(
          animation: _pulse,
          builder: (context, _) => Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _HintArrow(
                  icon: Icons.keyboard_arrow_up_rounded,
                  text: up?.text ?? '',
                  isVertical: true,
                  arrowFirst: true,
                  opacity: _pulse.value,
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _HintArrow(
                      icon: Icons.keyboard_arrow_left_rounded,
                      text: left?.text ?? '',
                      isVertical: false,
                      arrowFirst: true,
                      opacity: _pulse.value,
                    ),
                    const SizedBox(width: 20),
                    Text(
                      'スワイプして回答',
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Colors.white.withValues(alpha: 0.85),
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(width: 20),
                    _HintArrow(
                      icon: Icons.keyboard_arrow_right_rounded,
                      text: right?.text ?? '',
                      isVertical: false,
                      arrowFirst: false,
                      opacity: _pulse.value,
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                _HintArrow(
                  icon: Icons.keyboard_arrow_down_rounded,
                  text: down?.text ?? '',
                  isVertical: true,
                  arrowFirst: false,
                  opacity: _pulse.value,
                ),
                const SizedBox(height: 28),
                Text(
                  'タップまたはスワイプで閉じる',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 11,
                    color: Colors.white.withValues(alpha: 0.4),
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

class _HintArrow extends StatelessWidget {
  const _HintArrow({
    required this.icon,
    required this.text,
    required this.isVertical,
    required this.arrowFirst,
    required this.opacity,
  });

  final IconData icon;
  final String text;
  final bool isVertical;
  final bool arrowFirst;
  final double opacity;

  @override
  Widget build(BuildContext context) {
    final arrow = Icon(
      icon,
      color: Colors.white.withValues(alpha: opacity),
      size: 36,
    );
    final label = Text(
      text,
      style: TextStyle(
        fontFamily: 'Poppins',
        fontSize: 11,
        fontWeight: FontWeight.w500,
        color: Colors.white.withValues(alpha: opacity * 0.85),
      ),
      textAlign: TextAlign.center,
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
    );

    if (isVertical) {
      return SizedBox(
        width: 80,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: arrowFirst ? [arrow, label] : [label, arrow],
        ),
      );
    }
    return SizedBox(
      width: 90,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment:
            arrowFirst ? MainAxisAlignment.start : MainAxisAlignment.end,
        children: arrowFirst
            ? [arrow, Flexible(child: label)]
            : [Flexible(child: label), arrow],
      ),
    );
  }
}

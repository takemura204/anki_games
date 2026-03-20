import 'package:flutter/material.dart';
import 'package:flutter_card_swiper/flutter_card_swiper.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:mono_games/features/block_puzzle/view/block_puzzle_screen.dart';
import 'package:mono_games/features/block_puzzle/view_model/block_puzzle_view_model.dart';
import 'package:mono_games/features/quiz/model/quiz_result.dart';
import 'package:mono_games/features/quiz/view/widgets/dot_indicator.dart';
import 'package:mono_games/features/quiz/view/widgets/quiz_card.dart';
import 'package:mono_games/features/quiz/view_model/quiz_view_model.dart';
import 'package:mono_games/i18n/translations.g.dart';

/// 英単語クイズ画面（3問スワイプ式）。
///
/// 3問終了後にモーダルなしでブロックフェーズへ直接遷移する。
class QuizScreen extends ConsumerStatefulWidget {
  /// [QuizScreen] を作成する。
  const QuizScreen({super.key});

  @override
  ConsumerState<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends ConsumerState<QuizScreen> {
  late final CardSwiperController _swiperController;

  /// スワイプ中のアクティブ方向（チップハイライト用）。
  SwipeDirection? _activeDirection;

  /// 正誤表示中かどうか（短時間ロック）。
  var _isShowingFeedback = false;

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

  // ── スワイプ処理 ──────────────────────────────────────────────

  bool _onSwipe(
    int previousIndex,
    int? currentIndex,
    CardSwiperDirection cardDir,
  ) {
    if (_isShowingFeedback) {
      return false;
    }
    final swipeDir = _toSwipeDirection(cardDir);
    if (swipeDir == null) {
      return false;
    }

    _isShowingFeedback = true;
    ref.read(quizViewModelProvider.notifier).answer(previousIndex, swipeDir);

    Future<void>.delayed(const Duration(milliseconds: 800), () {
      if (!mounted) {
        return;
      }
      ref.read(quizViewModelProvider.notifier).clearLastAnswer();
      setState(() => _isShowingFeedback = false);

      // 最後のカードをスワイプしたら即ブロック画面へ遷移
      if (currentIndex == null) {
        final answers = ref.read(quizViewModelProvider).answers;
        _goToBlock(QuizResult(answers: answers));
      }
    });

    return true;
  }

  void _onDirectionChange(
    CardSwiperDirection horizontal,
    CardSwiperDirection vertical,
  ) {
    final active = horizontal != CardSwiperDirection.none
        ? _toSwipeDirection(horizontal)
        : _toSwipeDirection(vertical);
    if (active != _activeDirection) {
      setState(() => _activeDirection = active);
    }
  }

  SwipeDirection? _toSwipeDirection(CardSwiperDirection dir) =>
      switch (dir) {
        CardSwiperDirection.left => SwipeDirection.left,
        CardSwiperDirection.right => SwipeDirection.right,
        CardSwiperDirection.top => SwipeDirection.up,
        CardSwiperDirection.bottom => SwipeDirection.down,
        _ => null,
      };

  // ── ブロックフェーズへ遷移 ───────────────────────────────────

  void _goToBlock(QuizResult result) {
    ref
        .read(blockPuzzleViewModelProvider.notifier)
        .startQuizMode();
    Navigator.of(context).pushReplacement(
      MaterialPageRoute<void>(
        builder: (_) => const BlockPuzzleScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final quizState = ref.watch(quizViewModelProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? const Color(0xFF0D0D0D) : const Color(0xFFF5F5F5);
    final textColor = isDark ? Colors.white : Colors.black;

    return Scaffold(
      backgroundColor: bg,
      body: SafeArea(
        child: Stack(
          children: [
            Column(
              children: [
                const SizedBox(height: 12),
                // 上部バー
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: [
                      IconButton(
                        icon: Icon(
                          Icons.arrow_back_ios_new_rounded,
                          color: textColor.withValues(alpha: 0.5),
                          size: 20,
                        ),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                      Expanded(
                        child: Center(
                          child: Text(
                            t.quiz.quizMode.toUpperCase(),
                            style: TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 2,
                              color: textColor.withValues(alpha: 0.5),
                            ),
                          ),
                        ),
                      ),
                      // 英→日 / 日→英 切り替えボタン
                      TextButton(
                        onPressed: () => ref
                            .read(quizViewModelProvider.notifier)
                            .toggleDirection(),
                        child: Text(
                          quizState.isEnToJa
                              ? t.quiz.questionDirectionEnToJa
                              : t.quiz.questionDirectionJaToEn,
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 11,
                            color: textColor.withValues(alpha: 0.5),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                // ドットインジケーター
                if (!quizState.isLoading && quizState.questions.isNotEmpty)
                  DotIndicator(
                    total: 3,
                    current: quizState.answeredCount.clamp(0, 2),
                  ),
                const SizedBox(height: 16),
                // メインコンテンツ
                Expanded(
                  child: quizState.isLoading
                      ? Center(
                          child: Text(
                            t.quiz.loading,
                            style: TextStyle(
                              fontFamily: 'Poppins',
                              color: textColor.withValues(alpha: 0.5),
                            ),
                          ),
                        )
                      : quizState.questions.isEmpty
                          ? const SizedBox.shrink()
                          : CardSwiper(
                              controller: _swiperController,
                              cardsCount: quizState.questions.length,
                              isLoop: false,
                              onSwipe: _onSwipe,
                              onSwipeDirectionChange: _onDirectionChange,
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
                                  activeDirection: _activeDirection,
                                );
                              },
                            ),
                ),
              ],
            ),
            // 正誤フィードバックオーバーレイ
            if (quizState.lastAnswer != null)
              _FeedbackOverlay(
                isCorrect: quizState.lastAnswer!.isCorrect,
                isDark: isDark,
              ),
          ],
        ),
      ),
    );
  }
}

/// 正誤判定の一時フィードバックオーバーレイ。
class _FeedbackOverlay extends StatelessWidget {
  const _FeedbackOverlay({
    required this.isCorrect,
    required this.isDark,
  });

  final bool isCorrect;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: ColoredBox(
        color: (isCorrect ? Colors.green : Colors.red)
            .withValues(alpha: 0.15),
        child: Center(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
            decoration: BoxDecoration(
              color: isCorrect ? Colors.green : Colors.red,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Text(
              isCorrect
                  ? t.quiz.correct
                  : t.quiz.incorrect,
              style: const TextStyle(
                fontFamily: 'Poppins',
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

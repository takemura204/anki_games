import 'dart:math';
import 'dart:ui';

import 'package:anki_games/apps/it_pass/features/quiz/model/question.dart';
import 'package:anki_games/apps/it_pass/features/quiz/model/quiz_session.dart';
import 'package:anki_games/apps/it_pass/features/quiz/view/filter_bottom_sheet.dart';
import 'package:anki_games/apps/it_pass/features/quiz/view_model/quiz_view_model.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

part 'widgets/question_card_widget.dart';
part 'widgets/choice_button_widget.dart';
part 'widgets/explanation_panel_widget.dart';
part 'widgets/session_finished_widget.dart';

class QuizScreen extends ConsumerWidget {
  const QuizScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncState = ref.watch(quizViewModelProvider);

    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          const _QuizGradientBackground(),
          asyncState.when(
            loading: () => const Center(
              child: CircularProgressIndicator(color: Colors.white),
            ),
            error: (e, _) => Center(
              child: Text(
                'エラーが発生しました\n$e',
                style: const TextStyle(color: Colors.white70),
                textAlign: TextAlign.center,
              ),
            ),
            data: (quizState) {
              if (quizState is! QuizReady) {
                return const SizedBox.shrink();
              }
              final session = quizState.session;
              if (session.isFinished) {
                return _SessionFinishedWidget(
                  onRestart: () => ref.invalidate(quizViewModelProvider),
                );
              }
              return _QuizContent(session: session);
            },
          ),
        ],
      ),
    );
  }
}

class _QuizContent extends ConsumerStatefulWidget {
  const _QuizContent({required this.session});

  final QuizSession session;

  @override
  ConsumerState<_QuizContent> createState() => _QuizContentState();
}

class _QuizContentState extends ConsumerState<_QuizContent>
    with TickerProviderStateMixin {
  late final PageController _pageController;
  late final ConfettiController _confettiController;
  late final AnimationController _sheetController;
  late final Animation<Offset> _sheetSlide;
  var _sheetMounted = false;

  static const _inlineBannerDelay = Duration(milliseconds: 500);

  @override
  void initState() {
    super.initState();
    _pageController = PageController(
      initialPage: widget.session.currentIndex,
    );
    _confettiController = ConfettiController(
      duration: const Duration(milliseconds: 1200),
    );
    _sheetController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 380),
    );
    _sheetSlide = Tween<Offset>(
      begin: const Offset(0, 1),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _sheetController, curve: Curves.easeOutCubic),
    );
  }

  @override
  void didUpdateWidget(_QuizContent oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (!oldWidget.session.isAnswered &&
        widget.session.isAnswered &&
        widget.session.answerState == AnswerState.correct) {
      _confettiController.play();
    }

    if (!oldWidget.session.showExplanation && widget.session.showExplanation) {
      Future.delayed(_inlineBannerDelay, () {
        if (mounted) {
          setState(() => _sheetMounted = true);
          _sheetController.forward();
        }
      });
    }

    if (oldWidget.session.currentIndex != 0 &&
        widget.session.currentIndex == 0) {
      _pageController.jumpToPage(0);
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    _confettiController.dispose();
    _sheetController.dispose();
    super.dispose();
  }

  void _goNext() {
    _sheetController.reverse();
    _pageController.nextPage(
      duration: const Duration(milliseconds: 450),
      curve: Curves.easeInOutCubic,
    );
  }

  void _closeSheet() {
    _sheetController.reverse().then((_) {
      if (mounted) {
        setState(() => _sheetMounted = false);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final session = widget.session;

    return Stack(
      children: [
        SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(4, 12, 8, 0),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.white70),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                    const Spacer(),
                    Text(
                      '${session.currentIndex + 1} / ${session.totalCount}',
                      style: const TextStyle(
                        color: Colors.white60,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(width: 4),
                    IconButton(
                      icon: const Icon(
                        Icons.tune_rounded,
                        color: Colors.white54,
                        size: 22,
                      ),
                      onPressed: () =>
                          showQuizFilterBottomSheet(context, ref),
                    ),
                  ],
                ),
              ),
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: (session.currentIndex + 1) / session.totalCount,
                    backgroundColor: Colors.white12,
                    valueColor: const AlwaysStoppedAnimation<Color>(
                      Color(0xFF7C3AED),
                    ),
                    minHeight: 4,
                  ),
                ),
              ),
              Expanded(
                child: PageView.builder(
                  controller: _pageController,
                  scrollDirection: Axis.vertical,
                  physics: (session.isAnswered && !_sheetMounted)
                      ? const ClampingScrollPhysics()
                      : const NeverScrollableScrollPhysics(),
                  itemCount: session.totalCount,
                  onPageChanged: (index) {
                    if (index > session.currentIndex) {
                      setState(() => _sheetMounted = false);
                      ref
                          .read(quizViewModelProvider.notifier)
                          .nextQuestion();
                    }
                  },
                  itemBuilder: (context, index) {
                    final isCurrentPage = index == session.currentIndex;
                    final pageSession = isCurrentPage
                        ? session
                        : QuizSession(
                            questions: session.questions,
                            currentIndex: index,
                          );
                    return _QuizPageItem(
                      session: pageSession,
                      onAnswer: (label) => ref
                          .read(quizViewModelProvider.notifier)
                          .answer(label),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
        Align(
          alignment: Alignment.topCenter,
          child: ConfettiWidget(
            confettiController: _confettiController,
            blastDirectionality: BlastDirectionality.explosive,
            blastDirection: pi / 2,
            numberOfParticles: 30,
            gravity: 0.3,
            emissionFrequency: 0.06,
            colors: const [
              Color(0xFF10B981),
              Color(0xFF7C3AED),
              Color(0xFF4F46E5),
              Color(0xFFFBBF24),
              Color(0xFF60A5FA),
            ],
          ),
        ),
        if (_sheetMounted)
          _ExplanationBottomSheet(
            sheetController: _sheetController,
            slideAnimation: _sheetSlide,
            question: session.currentQuestion,
            isLast: session.currentIndex == session.totalCount - 1,
            onNext: _goNext,
            onDismiss: _closeSheet,
          ),
      ],
    );
  }
}

class _QuizPageItem extends StatelessWidget {
  const _QuizPageItem({
    required this.session,
    required this.onAnswer,
  });

  final QuizSession session;
  final ValueChanged<String> onAnswer;

  @override
  Widget build(BuildContext context) {
    final question = session.currentQuestion;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _QuestionCardWidget(question: question),
          const SizedBox(height: 12),
          _InlineFeedbackBanner(
            isAnswered: session.isAnswered,
            isCorrect: session.answerState == AnswerState.correct,
            correctLabel: question.answer,
          ),
          ...question.choices.map(
            (choice) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _ChoiceButtonWidget(
                choice: choice,
                session: session,
                onTap: () => onAnswer(choice.label),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _InlineFeedbackBanner extends StatefulWidget {
  const _InlineFeedbackBanner({
    required this.isAnswered,
    required this.isCorrect,
    required this.correctLabel,
  });

  final bool isAnswered;
  final bool isCorrect;
  final String correctLabel;

  @override
  State<_InlineFeedbackBanner> createState() => _InlineFeedbackBannerState();
}

class _InlineFeedbackBannerState extends State<_InlineFeedbackBanner>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _fade;
  late final Animation<double> _slide;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 380),
    );
    _fade = CurvedAnimation(parent: _controller, curve: Curves.easeOut);
    _slide = Tween<double>(begin: -16, end: 0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
    );
    if (widget.isAnswered) {
      _controller.value = 1;
    }
  }

  @override
  void didUpdateWidget(_InlineFeedbackBanner oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!oldWidget.isAnswered && widget.isAnswered) {
      _controller.forward();
    }
    if (oldWidget.isAnswered && !widget.isAnswered) {
      _controller.reset();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedSize(
      duration: const Duration(milliseconds: 380),
      curve: Curves.easeOutCubic,
      child: widget.isAnswered
          ? Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: FadeTransition(
                opacity: _fade,
                child: AnimatedBuilder(
                  animation: _slide,
                  builder: (context, child) => Transform.translate(
                    offset: Offset(0, _slide.value),
                    child: child,
                  ),
                  child: widget.isCorrect
                      ? _CorrectBanner()
                      : _IncorrectBanner(correctLabel: widget.correctLabel),
                ),
              ),
            )
          : const SizedBox.shrink(),
    );
  }
}

class _CorrectBanner extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: const Color(0xFF10B981).withValues(alpha: 0.18),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: const Color(0xFF10B981).withValues(alpha: 0.5),
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF10B981).withValues(alpha: 0.25),
                blurRadius: 18,
                spreadRadius: 1,
              ),
            ],
          ),
          child: const Row(
            children: [
              Icon(
                Icons.check_circle_rounded,
                color: Color(0xFF10B981),
                size: 22,
              ),
              SizedBox(width: 10),
              Text(
                'CORRECT!',
                style: TextStyle(
                  color: Color(0xFF10B981),
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.5,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _IncorrectBanner extends StatelessWidget {
  const _IncorrectBanner({required this.correctLabel});

  final String correctLabel;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: const Color(0xFFEF4444).withValues(alpha: 0.14),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: const Color(0xFFEF4444).withValues(alpha: 0.45),
            ),
          ),
          child: Row(
            children: [
              const Icon(
                Icons.cancel_rounded,
                color: Color(0xFFEF4444),
                size: 22,
              ),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'INCORRECT',
                    style: TextStyle(
                      color: Color(0xFFEF4444),
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.5,
                    ),
                  ),
                  Text(
                    '正解: $correctLabel',
                    style: const TextStyle(
                      color: Color(0xFF10B981),
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _QuizNetworkImage extends StatelessWidget {
  const _QuizNetworkImage({required this.url, this.borderRadius});

  final String url;
  final BorderRadiusGeometry? borderRadius;

  @override
  Widget build(BuildContext context) {
    final radius = borderRadius ?? BorderRadius.circular(10);
    final dpr = MediaQuery.devicePixelRatioOf(context);
    final screenWidth = MediaQuery.sizeOf(context).width;
    // キャッシュ解像度をデバイス実ピクセル幅に合わせて鮮明に表示
    final cacheWidth = (screenWidth * dpr).round();

    return ClipRRect(
      borderRadius: radius,
      child: CachedNetworkImage(
        imageUrl: url,
        width: double.infinity,
        fit: BoxFit.contain,
        memCacheWidth: cacheWidth,
        placeholder: (context, url) => const SizedBox(
          height: 100,
          child: Center(
            child: SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Colors.white30,
              ),
            ),
          ),
        ),
        errorWidget: (context, url, error) => Container(
          height: 60,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.04),
            borderRadius: radius,
          ),
          child: const Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.broken_image_outlined, color: Colors.white24),
                SizedBox(height: 4),
                Text(
                  '画像を読み込めませんでした',
                  style: TextStyle(color: Colors.white24, fontSize: 11),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _QuizGradientBackground extends StatelessWidget {
  const _QuizGradientBackground();

  @override
  Widget build(BuildContext context) {
    return const DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF0D0B2B),
            Color(0xFF1A0A3C),
            Color(0xFF2D1B69),
          ],
        ),
      ),
    );
  }
}

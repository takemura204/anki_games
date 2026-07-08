import 'dart:math';

import 'package:confetti/confetti.dart';
import 'package:core/components/adaptive_body.dart';
import 'package:core/components/explanation_card.dart';
import 'package:core/config/brand/app_color_scheme.dart';
import 'package:core/config/styles/app_colors.dart';
import 'package:core/config/styles/app_spacing.dart';
import 'package:core/config/styles/app_text_style.dart';
import 'package:core/features/exam_quiz/learning/model/learning_level.dart';
import 'package:core/features/exam_quiz/onboarding/model/onboarding_question.dart';
import 'package:core/features/exam_quiz/onboarding/view/widgets/onboarding_page_anim.dart';
import 'package:core/features/exam_quiz/onboarding/view_model/onboarding_ui_notifier.dart';
import 'package:core/features/exam_quiz/quiz/view/widgets/choice_button.dart';
import 'package:core/features/exam_quiz/quiz/view/widgets/question_card.dart';
import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

class OnboardingQuizPage extends ConsumerStatefulWidget {
  const OnboardingQuizPage({super.key});

  @override
  ConsumerState<OnboardingQuizPage> createState() => _OnboardingQuizPageState();
}

class _OnboardingQuizPageState extends ConsumerState<OnboardingQuizPage>
    with SingleTickerProviderStateMixin {
  late final ConfettiController _confettiController;
  late final AnimationController _ctrl;
  late final OnboardingPageAnim _anim;

  @override
  void initState() {
    super.initState();
    _confettiController = ConfettiController(
      duration: const Duration(milliseconds: 1200),
    );
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
    _anim = OnboardingPageAnim.from(_ctrl);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _ctrl.forward();
    });
  }

  @override
  void dispose() {
    _confettiController.dispose();
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ob = ref.watch(onboardingUiProvider);
    final notifier = ref.read(onboardingUiProvider.notifier);
    final bottom = MediaQuery.of(context).padding.bottom;
    final c = context.appColors;

    return Stack(
      children: [
        AdaptiveBody(
          child: SafeArea(
          child: SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(
              AppSpacing.md,
              AppSpacing.xxxl,
              AppSpacing.md,
              bottom + AppSpacing.onboardingFooterClearance + AppSpacing.sm,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Section 1: タイトル
                OnboardingFadeSlide(
                  fade: _anim.topFade,
                  slide: _anim.topSlide,
                  child: Column(
                    children: [
                      Icon(Icons.checklist_rounded, color: c.fg, size: 40),
                      const Gap(AppSpacing.md),
                      Text(
                        '問題を解いてみましょう',
                        style: AppTextStyle.titleLarge.copyWith(
                          color: c.fg,
                          fontWeight: FontWeight.bold,
                          fontSize: 24,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const Gap(AppSpacing.md),
                      Text(
                        '※学習データには影響されません。',
                        style: AppTextStyle.bodySmall.copyWith(
                          color: c.fgShade400,
                          height: 1.7,
                          fontWeight: FontWeight.normal,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
                const Gap(AppSpacing.xl),
                // Section 2: クイズ
                OnboardingFadeSlide(
                  fade: _anim.bottomFade,
                  slide: _anim.bottomSlide,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const QuizQuestionCard(
                        question: kOnboardingQuestion,
                        learningLevel: LearningLevel.unseen,
                      ),
                      const Gap(AppSpacing.md),
                      ...kOnboardingQuestion.choices.map(
                        (choice) => Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: QuizChoiceButton(
                            choice: choice,
                            questionNo: 0,
                            correctLabel: kOnboardingQuestion.answer,
                            isAnswered: ob.quizIsAnswered,
                            selectedLabel: ob.quizSelectedLabel,
                            onTap: ob.quizIsAnswered
                                ? null
                                : () {
                                    notifier.answerQuiz(choice.label);
                                    if (choice.label ==
                                        kOnboardingQuestion.answer) {
                                      _confettiController.play();
                                    }
                                    Future.delayed(
                                      const Duration(milliseconds: 480),
                                      () {
                                        if (mounted) {
                                          notifier.showQuizActionBar();
                                        }
                                      },
                                    );
                                  },
                          ),
                        ),
                      ),
                      AnimatedSize(
                        duration: const Duration(milliseconds: 320),
                        curve: Curves.easeOutCubic,
                        child: ob.quizIsAnswered && ob.quizSelectedLabel != null
                            ? Padding(
                                padding: const EdgeInsets.only(
                                  top: AppSpacing.md,
                                ),
                                child: ExplanationCard(
                                  question: kOnboardingQuestion,
                                  selectedLabel: ob.quizSelectedLabel!,
                                ),
                              )
                            : const SizedBox.shrink(),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
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
              AppColors.success,
              AppPalette.seed,
              AppPalette.accent,
              AppColors.warning,
              Color(0xFF60A5FA),
            ],
          ),
        ),
      ],
    );
  }
}

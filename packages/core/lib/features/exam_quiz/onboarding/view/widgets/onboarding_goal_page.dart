import 'package:core/components/adaptive_body.dart';
import 'package:core/components/glass_widget.dart';
import 'package:core/config/brand/app_color_scheme.dart';
import 'package:core/config/haptic/haptics.dart';
import 'package:core/config/styles/app_animation.dart';
import 'package:core/config/styles/app_border_radius.dart';
import 'package:core/config/styles/app_spacing.dart';
import 'package:core/config/styles/app_text_style.dart';
import 'package:core/features/exam_quiz/onboarding/model/study_goal.dart';
import 'package:core/features/exam_quiz/onboarding/view_model/onboarding_ui_notifier.dart';
import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

/// オンボーディング: 学習期間の目標を選択するページ（4択）。
///
/// 「次へ」はフッターのボタンで制御する（選択前は非表示）。
/// アニメーションは 3 段階: ① アイコン → ② テキスト → ③ 選択肢リスト
class OnboardingGoalPage extends ConsumerStatefulWidget {
  const OnboardingGoalPage({super.key});

  @override
  ConsumerState<OnboardingGoalPage> createState() => _OnboardingGoalPageState();
}

class _OnboardingGoalPageState extends ConsumerState<OnboardingGoalPage>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  // ① アイコン: 0.00 - 0.40
  late final Animation<double> _iconFade;
  late final Animation<Offset> _iconSlide;

  // ② テキスト: 0.25 - 0.65
  late final Animation<double> _textFade;
  late final Animation<Offset> _textSlide;

  // ③ リスト: 0.50 - 1.00
  late final Animation<double> _listFade;
  late final Animation<Offset> _listSlide;

  static const _offset = Offset(0, 0.05);

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    );

    _iconFade = CurvedAnimation(
      parent: _ctrl,
      curve: const Interval(0, 0.4, curve: Curves.easeOut),
    );
    _iconSlide = Tween<Offset>(begin: _offset, end: Offset.zero).animate(
      CurvedAnimation(
        parent: _ctrl,
        curve: const Interval(0, 0.45, curve: Curves.easeOutCubic),
      ),
    );

    _textFade = CurvedAnimation(
      parent: _ctrl,
      curve: const Interval(0.25, 0.65, curve: Curves.easeOut),
    );
    _textSlide = Tween<Offset>(begin: _offset, end: Offset.zero).animate(
      CurvedAnimation(
        parent: _ctrl,
        curve: const Interval(0.25, 0.7, curve: Curves.easeOutCubic),
      ),
    );

    _listFade = CurvedAnimation(
      parent: _ctrl,
      curve: const Interval(0.5, 1, curve: Curves.easeOut),
    );
    _listSlide = Tween<Offset>(begin: _offset, end: Offset.zero).animate(
      CurvedAnimation(
        parent: _ctrl,
        curve: const Interval(0.5, 1, curve: Curves.easeOutCubic),
      ),
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _ctrl.forward();
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ob = ref.watch(onboardingUiProvider);
    final notifier = ref.read(onboardingUiProvider.notifier);
    final bottom = MediaQuery.of(context).padding.bottom;
    final c = context.appColors;

    return AdaptiveBody(
      child: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(
            AppSpacing.md,
            AppSpacing.xxxl,
            AppSpacing.md,
            bottom + AppSpacing.onboardingFooterClearance + AppSpacing.sm,
          ),
          child: Column(
            children: [
              // ① アイコン
              FadeTransition(
                opacity: _iconFade,
                child: SlideTransition(
                  position: _iconSlide,
                  child: Icon(Icons.flag_rounded, size: 44, color: c.fg),
                ),
              ),
              const Gap(AppSpacing.md),
              // ② テキスト
              FadeTransition(
                opacity: _textFade,
                child: SlideTransition(
                  position: _textSlide,
                  child: Column(
                    children: [
                      Text(
                        'どのくらいの期間で\n合格を目指しますか？',
                        style: AppTextStyle.titleLarge.copyWith(
                          color: c.fg,
                          fontWeight: FontWeight.bold,
                          fontSize: 24,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const Gap(AppSpacing.md),
                      Text(
                        '学習期間に合ったプランをご提案します。\nあとから変更もできます。',
                        style: AppTextStyle.bodyMedium.copyWith(
                          color: c.fgShade400,
                          height: 1.6,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
              const Gap(AppSpacing.xl),
              // ③ 選択肢リスト
              FadeTransition(
                opacity: _listFade,
                child: SlideTransition(
                  position: _listSlide,
                  child: Column(
                    children: StudyGoal.values
                        .map(
                          (goal) => Padding(
                            padding: const EdgeInsets.only(
                              bottom: AppSpacing.sm,
                            ),
                            child: _GoalRadioCard(
                              goal: goal,
                              isSelected: ob.selectedGoal == goal,
                              onTap: () => notifier.selectGoal(goal),
                              c: c,
                            ),
                          ),
                        )
                        .toList(),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _GoalRadioCard extends StatelessWidget {
  const _GoalRadioCard({
    required this.goal,
    required this.isSelected,
    required this.onTap,
    required this.c,
  });

  final StudyGoal goal;
  final bool isSelected;
  final VoidCallback onTap;
  final AppColorScheme c;

  @override
  Widget build(BuildContext context) {
    return GlassContainer(
      cardRadius: AppBorderRadius.md,
      padding: EdgeInsets.zero,
      child: Material(
        color: Colors.transparent,
        borderRadius: AppBorderRadius.md,
        child: InkWell(
          onTap: onTap.withHaptic(HapticType.selection),
          borderRadius: AppBorderRadius.md,
          child: AnimatedContainer(
            duration: AppAnimation.fast,
            decoration: BoxDecoration(
              borderRadius: AppBorderRadius.md,
              border: Border.all(
                color: isSelected ? AppPalette.seed : Colors.transparent,
                width: 1.5,
              ),
            ),
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.md,
            ),
            child: Row(
              children: [
                AnimatedSwitcher(
                  duration: AppAnimation.fast,
                  child: isSelected
                      ? const Icon(
                          Icons.radio_button_checked_rounded,
                          key: ValueKey('checked'),
                          color: AppPalette.seed,
                          size: 22,
                        )
                      : Icon(
                          Icons.radio_button_unchecked_rounded,
                          key: const ValueKey('unchecked'),
                          color: c.fgShade200,
                          size: 22,
                        ),
                ),
                const Gap(AppSpacing.md),
                Text(
                  goal.label,
                  style: AppTextStyle.bodyLarge.copyWith(
                    color: c.fg,
                    fontWeight: isSelected
                        ? FontWeight.bold
                        : FontWeight.normal,
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

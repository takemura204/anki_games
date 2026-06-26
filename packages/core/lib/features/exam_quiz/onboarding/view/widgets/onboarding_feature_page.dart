import 'package:core/components/adaptive_body.dart';
import 'package:core/config/brand/it_pass_color_scheme.dart';
import 'package:core/config/styles/app_spacing.dart';
import 'package:core/config/styles/app_text_style.dart';
import 'package:core/features/exam_quiz/onboarding/view/widgets/onboarding_page_anim.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:gap/gap.dart';

class OnboardingFeaturePage extends StatefulWidget {
  const OnboardingFeaturePage({super.key});

  @override
  State<OnboardingFeaturePage> createState() => _OnboardingFeaturePageState();
}

class _OnboardingFeaturePageState extends State<OnboardingFeaturePage>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final OnboardingPageAnim _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2500),
    );
    _anim = OnboardingPageAnim.from(_ctrl);
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
    final c = context.appColors;
    final bottom = MediaQuery.of(context).padding.bottom;

    return AdaptiveBody(
      child: SafeArea(
      child: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(
          AppSpacing.xl,
          AppSpacing.xl,
          AppSpacing.xl,
          bottom + AppSpacing.onboardingFooterClearance + AppSpacing.sm,
        ),
        child: Column(
          children: [
            const Gap(AppSpacing.xl),

            OnboardingFadeSlide(
              fade: _anim.topFade,
              slide: _anim.topSlide,
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final svgWidth = constraints.maxWidth * 0.8;
                  return Stack(
                    alignment: Alignment.topCenter,
                    children: [
                      Align(
                        alignment: Alignment.bottomLeft,
                        child: Padding(
                          padding: const EdgeInsets.only(
                            top: AppSpacing.xl,
                            left: AppSpacing.xl,
                          ),
                          child: SvgPicture.asset(
                            'packages/app_it_pass/assets/image/onboarding_level.svg',
                            width: svgWidth,
                            errorBuilder: (_, _, _) => const SizedBox.shrink(),
                          ),
                        ),
                      ),
                      Align(
                        alignment: Alignment.topLeft,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              '解答状況から、\n学習レベルを記録。\n得意分野が簡単に分かる💪',
                              style: AppTextStyle.titleMedium.copyWith(
                                color: c.fg,
                                fontWeight: FontWeight.bold,
                                height: 1.5,
                              ),
                              textAlign: TextAlign.left,
                            ),
                          ],
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),

            const Gap(AppSpacing.xl),

            OnboardingFadeSlide(
              fade: _anim.bottomFade,
              slide: _anim.bottomSlide,
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final svgWidth = constraints.maxWidth * 0.8;
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '忘れた頃に再出題\n効率よく記憶できます📈',
                        style: AppTextStyle.titleMedium.copyWith(
                          color: c.fg,
                          fontWeight: FontWeight.bold,
                          height: 1.5,
                        ),
                        textAlign: TextAlign.end,
                      ),
                      const Gap(AppSpacing.md),
                      Center(
                        child: SvgPicture.asset(
                          'packages/app_it_pass/assets/image/onbordhing_remind.svg',
                          width: svgWidth,
                          errorBuilder: (_, _, _) => const SizedBox.shrink(),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    ),
    );
  }
}

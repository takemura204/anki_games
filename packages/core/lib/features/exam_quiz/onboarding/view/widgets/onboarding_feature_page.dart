import 'package:core/components/adaptive_body.dart';
import 'package:core/components/glass_widget.dart';
import 'package:core/config/brand/app_color_scheme.dart';
import 'package:core/config/brand/brand_config.dart';
import 'package:core/config/styles/app_border_radius.dart';
import 'package:core/config/styles/app_spacing.dart';
import 'package:core/config/styles/app_text_style.dart';
import 'package:core/features/exam_quiz/onboarding/view/widgets/onboarding_page_anim.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:gap/gap.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

class OnboardingFeaturePage extends ConsumerStatefulWidget {
  const OnboardingFeaturePage({super.key});

  @override
  ConsumerState<OnboardingFeaturePage> createState() =>
      _OnboardingFeaturePageState();
}

class _OnboardingFeaturePageState extends ConsumerState<OnboardingFeaturePage>
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
    final brand = ref.watch(brandConfigProvider);

    return AdaptiveBody(
      child: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(
            AppSpacing.md,
            AppSpacing.xl,
            AppSpacing.md,
            bottom + AppSpacing.onboardingFooterClearance + AppSpacing.sm,
          ),
          child: Column(
            children: [
              OnboardingFadeSlide(
                fade: _anim.topFade,
                slide: _anim.topSlide,
                child: Column(
                  children: [
                    Icon(
                      Icons.signal_cellular_alt_rounded,
                      size: 40,
                      color: c.fg,
                    ),
                    const Gap(AppSpacing.md),
                    Text(
                      '学習を分析して\n復習をサポートします',
                      style: AppTextStyle.titleLarge.copyWith(
                        color: c.fg,
                        fontWeight: FontWeight.bold,
                        fontSize: 24,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
              const Gap(AppSpacing.lg),

              OnboardingFadeSlide(
                fade: _anim.topFade,
                slide: _anim.topSlide,
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final svgWidth = constraints.maxWidth * 0.8;
                    return GlassContainer(
                      cardRadius: AppBorderRadius.lg,
                      padding: const EdgeInsets.all(AppSpacing.lg),
                      child: Stack(
                        alignment: Alignment.topCenter,
                        children: [
                          Align(
                            alignment: Alignment.bottomCenter,
                            child: SvgPicture.asset(
                              brand.onboardingLevelAsset,
                              width: svgWidth,
                              errorBuilder: (_, _, _) =>
                                  const SizedBox.shrink(),
                            ),
                          ),
                          Align(
                            alignment: Alignment.topLeft,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  'レベルに合わせた\n最適な出題💪',
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
                      ),
                    );
                  },
                ),
              ),

              const Gap(AppSpacing.md),

              OnboardingFadeSlide(
                fade: _anim.bottomFade,
                slide: _anim.bottomSlide,
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final svgWidth = constraints.maxWidth * 0.85;
                    return GlassContainer(
                      cardRadius: AppBorderRadius.lg,
                      padding: const EdgeInsets.all(AppSpacing.lg),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            '忘却曲線に沿って\n記憶の定着を効率化📈',
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
                              brand.onboardingRemindAsset,
                              width: svgWidth,
                              errorBuilder: (_, _, _) =>
                                  const SizedBox.shrink(),
                            ),
                          ),
                        ],
                      ),
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

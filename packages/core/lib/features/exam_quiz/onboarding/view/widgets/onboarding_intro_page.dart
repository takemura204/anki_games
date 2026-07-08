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

class OnboardingIntroPage extends ConsumerStatefulWidget {
  const OnboardingIntroPage({super.key});

  @override
  ConsumerState<OnboardingIntroPage> createState() =>
      _OnboardingIntroPageState();
}

class _OnboardingIntroPageState extends ConsumerState<OnboardingIntroPage>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final OnboardingPageAnim _anim;

  @override
  void initState() {
    super.initState();
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
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.appColors;
    final logoAsset = ref.watch(brandConfigProvider).introLogoAsset;

    return AdaptiveBody(
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.xl,
            AppSpacing.xl,
            AppSpacing.xl,
            80 + AppSpacing.xl,
          ),
          child: Column(
            children: [
              const Gap(AppSpacing.xxl),
              const Spacer(),
              OnboardingFadeSlide(
                fade: _anim.topFade,
                slide: _anim.topSlide,
                child: ClipRRect(
                  borderRadius: AppBorderRadius.lg,
                  child: SvgPicture.asset(
                    logoAsset,
                    height: MediaQuery.sizeOf(context).height * 0.3,
                  ),
                ),
              ),
              const Gap(AppSpacing.xxl),
              OnboardingFadeSlide(
                fade: _anim.bottomFade,
                slide: _anim.bottomSlide,
                child: GlassContainer(
                  cardRadius: AppBorderRadius.lg,
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  child: Text(
                    'スキマ時間を活用して、\n最短合格を目指しましょう🔥',
                    style: AppTextStyle.bodyMedium.copyWith(
                      color: c.fg,
                      height: 1.8,
                      fontWeight: FontWeight.normal,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
              const Spacer(),
            ],
          ),
        ),
      ),
    );
  }
}

import 'package:core/components/adaptive_body.dart';
import 'package:core/components/glass_widget.dart';
import 'package:core/config/brand/app_color_scheme.dart';
import 'package:core/config/haptic/haptics.dart';
import 'package:core/config/styles/app_border_radius.dart';
import 'package:core/config/styles/app_spacing.dart';
import 'package:core/config/styles/app_text_style.dart';
import 'package:core/features/exam_quiz/onboarding/view/widgets/onboarding_page_anim.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:gap/gap.dart';

class OnboardingTrackingPage extends StatefulWidget {
  const OnboardingTrackingPage({
    super.key,
    required this.onAllow,
    required this.appDisplayName,
  });

  final VoidCallback onAllow;
  final String appDisplayName;

  @override
  State<OnboardingTrackingPage> createState() => _OnboardingTrackingPageState();
}

class _OnboardingTrackingPageState extends State<OnboardingTrackingPage>
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
    final bottom = MediaQuery.of(context).padding.bottom;

    return AdaptiveBody(
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: EdgeInsets.fromLTRB(
            AppSpacing.xl,
            AppSpacing.xl,
            AppSpacing.xl,
            bottom + AppSpacing.onboardingFooterClearance + AppSpacing.sm,
          ),
          child: Column(
            children: [
              const Spacer(),
              OnboardingFadeSlide(
                fade: _anim.topFade,
                slide: _anim.topSlide,
                child: Column(
                  children: [
                    Icon(Icons.privacy_tip_outlined, color: c.fg, size: 40),
                    const Gap(AppSpacing.md),
                    Text(
                      '安全な利用のために',
                      style: AppTextStyle.titleLarge.copyWith(
                        color: c.fg,
                        fontWeight: FontWeight.bold,
                        fontSize: 24,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const Gap(AppSpacing.md),
                    Text(
                      defaultTargetPlatform == TargetPlatform.iOS
                          ? '次の画面で許可いただくと、アプリで表示される広告が、興味関心により合ったものになります。'
                          : '次の画面で同意いただくと、\nあなたに関連性の高い広告を'
                                '表示できるようになります。同意しなくてもご利用いただけます。',
                      style: AppTextStyle.bodyMedium.copyWith(
                        color: c.fg,
                        height: 1.7,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
              const Gap(AppSpacing.xl),
              OnboardingFadeSlide(
                fade: _anim.bottomFade,
                slide: _anim.bottomSlide,
                child: Column(
                  children: [
                    if (defaultTargetPlatform == TargetPlatform.iOS)
                      _IosAttMockup(onAllow: widget.onAllow, appDisplayName: widget.appDisplayName)
                    else
                      _AndroidUmpMockup(),
                    const Gap(AppSpacing.md),
                    Text(
                      '※ これは表示例です。実際の画面が次に表示されます',
                      style: AppTextStyle.labelSmall.copyWith(
                        color: c.fgShade200,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
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

class _IosAttMockup extends StatelessWidget {
  const _IosAttMockup({this.onAllow, required this.appDisplayName});

  final VoidCallback? onAllow;
  final String appDisplayName;

  @override
  Widget build(BuildContext context) {
    final c = context.appColors;
    return GlassContainer(
      cardRadius: AppBorderRadius.lg,
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.lg,
        AppSpacing.lg,
        AppSpacing.sm,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                height: 52,
                width: 52,
                decoration: BoxDecoration(
                  color: const Color(0xFFF5862E),
                  borderRadius: BorderRadius.circular(13),
                ),
                child: const Icon(Icons.route, size: 28, color: Colors.white),
              ),
              Positioned(
                right: -5,
                bottom: -5,
                child: Container(
                  height: 24,
                  width: 24,
                  decoration: BoxDecoration(
                    color: Colors.blueAccent,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Icon(
                    Icons.front_hand_rounded,
                    size: 13,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
          const Gap(AppSpacing.md),
          Text(
            '"$appDisplayName" が他社のアプリやWebサイトを横断してあなたのアクティビティをトラッキングすることを許可しますか?',
            style: AppTextStyle.bodyMedium.copyWith(
              color: c.fgShade400,
              fontWeight: FontWeight.bold,
              height: 1.4,
            ),
            textAlign: TextAlign.start,
          ),
          const Gap(AppSpacing.sm),
          Text(
            'あなたに合った広告を表示するために使用します。許可しなくても引き続きご利用いただけます。',
            style: AppTextStyle.bodySmall.copyWith(
              color: c.fgShade400,
              height: 1.5,
            ),
            textAlign: TextAlign.start,
          ),
          const Gap(AppSpacing.md),

          _MockButton(label: 'アプリにトラッキングしないように要求', color: c.fgShade400),
          const Gap(AppSpacing.md),
          _MockButton(
            label: '許可',
            color: c.fgShade400,
            bold: true,
            onTap: onAllow,
          ),
          const Gap(AppSpacing.md),
        ],
      ),
    );
  }
}

class _AndroidUmpMockup extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final c = context.appColors;
    return GlassContainer(
      cardRadius: AppBorderRadius.lg,
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'プライバシーに関する同意',
            style: AppTextStyle.titleSmall.copyWith(
              color: c.fg,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          const Gap(AppSpacing.md),
          Text(
            '本アプリはユーザーの同意に基づいて、'
            '関連性の高い広告を表示します。',
            style: AppTextStyle.bodySmall.copyWith(
              color: c.fgShade400,
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
          const Gap(AppSpacing.md),

          _MockButton(label: '同意して続ける', color: c.fg, bold: true),
          const Gap(AppSpacing.sm),

          _MockButton(label: '管理する', color: c.fgShade300),
        ],
      ),
    );
  }
}

class _MockButton extends StatelessWidget {
  const _MockButton({
    required this.label,
    required this.color,
    this.bold = false,
    this.onTap,
  });
  final String label;
  final Color color;
  final bool bold;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap.withHaptic(HapticType.selection),
      child: GlassButton(
        cardRadius: AppBorderRadius.circle,
        padding: const EdgeInsets.symmetric(
          vertical: AppSpacing.md,
          horizontal: AppSpacing.md,
        ),
        child: Center(
          child: Text(
            label,
            style: AppTextStyle.bodySmall.copyWith(
              color: color,
              fontWeight: bold ? FontWeight.bold : FontWeight.normal,
            ),
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }
}

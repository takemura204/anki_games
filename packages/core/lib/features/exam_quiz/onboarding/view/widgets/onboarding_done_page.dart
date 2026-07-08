import 'package:core/components/adaptive_body.dart';
import 'package:core/components/checkmark_painter.dart';
import 'package:core/config/brand/app_color_scheme.dart';
import 'package:core/config/styles/app_spacing.dart';
import 'package:core/config/styles/app_text_style.dart';
import 'package:flutter/material.dart';
import 'package:gap/gap.dart';

class OnboardingDonePage extends StatefulWidget {
  const OnboardingDonePage({super.key});

  @override
  State<OnboardingDonePage> createState() => _OnboardingDonePageState();
}

class _OnboardingDonePageState extends State<OnboardingDonePage>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _checkProgress;
  late final Animation<double> _fadeIn;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
    _checkProgress = CurvedAnimation(
      parent: _ctrl,
      curve: const Interval(0, 0.6, curve: Curves.easeOutCubic),
    );
    _fadeIn = CurvedAnimation(
      parent: _ctrl,
      curve: const Interval(0.5, 1, curve: Curves.easeIn),
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _ctrl.forward();
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
    return AdaptiveBody(
      child: SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.md,
          AppSpacing.xl,
          AppSpacing.md,
          80 + AppSpacing.xl,
        ),
        child: Column(
          children: [
            const Spacer(),
            AnimatedBuilder(
              animation: _checkProgress,
              builder: (context, _) => CustomPaint(
                size: const Size(100, 100),
                painter: CheckmarkPainter(
                  progress: _checkProgress.value,
                  color: AppPalette.seed,
                ),
              ),
            ),
            const Gap(AppSpacing.xl),
            Text(
              '準備完了！',
              style: AppTextStyle.titleLarge.copyWith(
                color: c.fg,
                fontWeight: FontWeight.bold,
                fontSize: 28,
              ),
              textAlign: TextAlign.center,
            ),
            const Gap(AppSpacing.md),
            FadeTransition(
              opacity: _fadeIn,
              child: Column(
                children: [
                  Text(
                    'さっそく問題に挑戦しましょう！',
                    style: AppTextStyle.bodyMedium.copyWith(
                      color: c.fgShade400,
                      height: 1.6,
                      fontWeight: FontWeight.w600,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const Gap(AppSpacing.xs),
                  Text(
                    'はじめる前に「今日の格言」をお届けします📣',
                    style: AppTextStyle.bodyMedium.copyWith(
                      color: c.fgShade400,
                      height: 1.6,
                      fontWeight: FontWeight.w600,
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

part of '../quiz_screen.dart';

class _Footer extends StatelessWidget {
  const _Footer({
    required this.cardRadius,
    required this.session,
    required this.onTapNote,
    required this.onTapReport,
    this.showNextButton = false,
    this.onNext,
    this.isOnboarding = false,
    this.onboardingNextCallback,
    this.isOnboardingNextLoading = false,
    this.onboardingNextLabel = '次へ',
  });

  final BorderRadius cardRadius;
  final QuizSession? session;
  final VoidCallback onTapNote;
  final VoidCallback onTapReport;
  final bool showNextButton;
  final VoidCallback? onNext;
  final bool isOnboarding;
  final VoidCallback? onboardingNextCallback;
  final bool isOnboardingNextLoading;
  final String onboardingNextLabel;

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).padding.bottom;
    final padding = EdgeInsets.only(
      left: AppSpacing.sm,
      right: AppSpacing.sm,
      top: AppSpacing.sm,
      bottom: bottom + AppSpacing.sm,
    );

    if (isOnboarding) {
      final show = onboardingNextCallback != null || isOnboardingNextLoading;
      return Padding(
        padding: padding,
        child: AnimatedSlide(
          offset: show ? Offset.zero : const Offset(0, 1.5),
          duration: const Duration(milliseconds: 260),
          curve: Curves.easeOutCubic,
          child: AnimatedOpacity(
            opacity: show ? 1.0 : 0.0,
            duration: const Duration(milliseconds: 180),
            child: _OnboardingNextBarContent(
              callback: onboardingNextCallback,
              isLoading: isOnboardingNextLoading,
              label: onboardingNextLabel,
            ),
          ),
        ),
      );
    }

    return Padding(
      padding: padding,
      child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
          GlassButton(
            cardRadius: cardRadius,
            child: IconButton(
              padding: const EdgeInsets.all(AppSpacing.md),
              icon: Icon(AppIcons.note, color: context.appColors.fgShade400),
              onPressed: onTapNote.withHaptic(),
            ),
          ),
          const Gap(AppSpacing.sm),
          Expanded(
            child: IgnorePointer(
              ignoring: !showNextButton,
              child: AnimatedSlide(
                offset: showNextButton ? Offset.zero : const Offset(0, 1),
                duration: const Duration(milliseconds: 280),
                curve: Curves.easeOutCubic,
                child: AnimatedOpacity(
                  opacity: showNextButton ? 1 : 0,
                  duration: const Duration(milliseconds: 200),
                  child: _NextButton(onNext: onNext ?? () {}),
                ),
              ),
            ),
          ),
          const Gap(AppSpacing.sm),
          GlassButton(
            cardRadius: cardRadius,
            child: IconButton(
              padding: const EdgeInsets.all(AppSpacing.md),
              color: context.appColors.fgShade400,
              icon: const Icon(AppIcons.report),
              onPressed: onTapReport.withHaptic(),
            ),
          ),
          ],
        ),
    );
  }
}

class _NextButton extends StatelessWidget {
  const _NextButton({required this.onNext});

  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    final c = context.appColors;
    return ClipRRect(
      borderRadius: AppBorderRadius.circle,
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: c.surface2,
            borderRadius: AppBorderRadius.circle,
            border: Border.all(color: c.border1),
          ),
          child: TextButton.icon(
            onPressed: onNext.withHaptic(HapticType.medium),
            iconAlignment: IconAlignment.end,
            icon: Icon(AppIcons.nextUp, color: c.fg, size: 20),
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
              minimumSize: const Size.fromHeight(52),
            ),
            label: Text(
              '次の問題へ',
              style: AppTextStyle.labelLarge.copyWith(
                color: c.fg,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _OnboardingNextBarContent extends StatelessWidget {
  const _OnboardingNextBarContent({
    required this.callback,
    this.isLoading = false,
    this.label = '次へ',
  });

  final VoidCallback? callback;
  final bool isLoading;
  final String label;

  @override
  Widget build(BuildContext context) {
    final c = context.appColors;
    return ClipRRect(
      borderRadius: AppBorderRadius.circle,
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: c.surface2,
            borderRadius: AppBorderRadius.circle,
            border: Border.all(color: c.border1),
          ),
          child: isLoading
              ? const SizedBox(
                  height: 52,
                  child: Center(
                    child: SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  ),
                )
              : TextButton.icon(
                  onPressed: callback.withHaptic(),
                  iconAlignment: IconAlignment.end,
                  icon: Icon(
                    Icons.keyboard_arrow_up_rounded,
                    color: c.fg,
                    size: 20,
                  ),
                  label: Text(
                    label,
                    style: AppTextStyle.labelLarge.copyWith(
                      color: c.fg,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      vertical: AppSpacing.md,
                    ),
                    minimumSize: const Size.fromHeight(52),
                  ),
                ),
        ),
      ),
    );
  }
}

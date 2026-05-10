part of 'quiz_screen.dart';

class _AnsweredActionBar extends StatelessWidget {
  const _AnsweredActionBar({
    required this.onShowExplanation,
    required this.onNext,
  });

  final VoidCallback onShowExplanation;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    final c = context.appColors;
    return ClipRRect(
      borderRadius: const BorderRadius.all(Radius.circular(20)),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: c.surface2,
            borderRadius: const BorderRadius.all(Radius.circular(20)),
            border: Border.all(color: c.border1),
          ),
          child: Row(
            children: [
              Expanded(
                child: TextButton.icon(
                  onPressed: onShowExplanation.withHaptic(HapticType.medium),
                  icon: const Icon(
                    AppIcons.explanation,
                    color: AppColors.success,
                    size: 18,
                  ),
                  label: Text(
                    '解説を見る',
                    style: AppTextStyle.labelLarge.copyWith(
                      color: AppColors.success,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              Container(width: 1, height: 28, color: c.fgShade50),
              Expanded(
                child: TextButton.icon(
                  onPressed: onNext.withHaptic(HapticType.medium),
                  iconAlignment: IconAlignment.end,
                  icon: Icon(
                    AppIcons.nextUp,
                    color: c.fg,
                    size: 20,
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
            ],
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
    return DecoratedBox(
      decoration: BoxDecoration(gradient: context.appColors.bgGradient),
    );
  }
}

class _QuizErrorView extends StatelessWidget {
  const _QuizErrorView({
    required this.message,
    required this.onOpenFilter,
  });

  final String message;
  final VoidCallback onOpenFilter;

  @override
  Widget build(BuildContext context) {
    final c = context.appColors;
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.filter_list_off_rounded, size: 52, color: c.fgShade300),
            const Gap(AppSpacing.md),
            Text(
              message,
              style: AppTextStyle.titleMedium.copyWith(color: c.fgShade400),
              textAlign: TextAlign.center,
            ),
            const Gap(AppSpacing.lg),
            FilledButton.icon(
              onPressed: onOpenFilter,
              icon: const Icon(Icons.tune_rounded),
              label: const Text('出題設定を開く'),
            ),
          ],
        ),
      ),
    );
  }
}

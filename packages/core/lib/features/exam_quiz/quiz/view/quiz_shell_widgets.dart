part of 'quiz_screen.dart';

class _ConfettiOverlay extends StatelessWidget {
  const _ConfettiOverlay({required this.controller});

  final ConfettiController controller;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.topCenter,
      child: ConfettiWidget(
        confettiController: controller,
        blastDirectionality: BlastDirectionality.explosive,
        blastDirection: pi / 2,
        numberOfParticles: 30,
        gravity: 0.3,
        emissionFrequency: 0.06,
        colors: const [
          AppColors.success,
          ItPassColors.seed,
          ItPassColors.accent,
          AppColors.warning,
          Color(0xFF60A5FA),
        ],
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
  const _QuizErrorView({required this.message, required this.onOpenFilter});

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

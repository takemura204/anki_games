part of '../quiz_screen.dart';

class _SessionEndPage extends StatelessWidget {
  const _SessionEndPage({
    super.key,
    required this.onOpenFilter,
  });

  final VoidCallback onOpenFilter;

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.of(context).padding.top;
    final bottom = MediaQuery.of(context).padding.bottom;

    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(
        AppSpacing.md,
        top + AppSpacing.xxl + AppSpacing.sm,
        AppSpacing.md,
        bottom + AppSpacing.lg,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Icon(
            Icons.emoji_events_outlined,
            size: AppSpacing.xxl + AppSpacing.sm,
            color: AppColors.warning,
          ),
          const Gap(AppSpacing.md + 4),
          Text(
            '全問完了！',
            textAlign: TextAlign.center,
            style: AppTextStyle.headlineSmall.copyWith(
              color: context.appColors.fg,
            ),
          ),
          const Gap(12),
          Text(
            'すべての問題を解き終えました。\n出題範囲を変えて新たな問題に挑戦しましょう。',
            textAlign: TextAlign.center,
            style: AppTextStyle.bodyMedium.copyWith(
              color: context.appColors.fgShade400,
              height: 1.5,
            ),
          ),
          const Gap(AppSpacing.xl + 4),
          GestureDetector(
            onTap: onOpenFilter.withHaptic(HapticType.medium),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [ItPassColors.seed, ItPassColors.accent],
                ),
                borderRadius: AppBorderRadius.lg,
                boxShadow: [
                  BoxShadow(
                    color: ItPassColors.seed.withValues(alpha: 0.4),
                    blurRadius: AppSpacing.md + 4,
                    offset: const Offset(0, AppSpacing.xs + 2),
                  ),
                ],
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.tune_rounded,
                    color: Colors.white,
                    size: 22,
                  ),
                  Gap(10),
                  Text(
                    '出題範囲を選び直す',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

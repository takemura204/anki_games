part of '../quiz_screen.dart';

/// QuizContent が読み込まれるまで表示するスケルトン画面。
/// _QuizPageItem（QuestionCard + 4 ChoiceButton）の形状を模倣する。
/// 初回ダウンロード中は画面下部に進捗バーを重ねて表示する。
class _QuizSkeleton extends ConsumerWidget {
  const _QuizSkeleton();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final progress = ref.watch(quizDownloadProgressProvider);
    final top = MediaQuery.of(context).padding.top;
    final bottom = MediaQuery.of(context).padding.bottom;
    final headerClearance = top + 80.0;
    final footerClearance = 16.0 + bottom + 48.0;
    final c = context.appColors;

    return Stack(
      children: [
        Shimmer.fromColors(
          baseColor: c.surface2,
          highlightColor: c.border2,
          period: AppAnimation.slow + AppAnimation.normal,
          child: SingleChildScrollView(
            physics: const NeverScrollableScrollPhysics(),
            padding: EdgeInsets.fromLTRB(
              AppSpacing.md,
              headerClearance,
              AppSpacing.md,
              footerClearance,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _SkeletonQuestionCard(),
                const Gap(12),
                for (int i = 0; i < 4; i++) ...[
                  _SkeletonChoiceButton(wide: i == 3),
                  if (i < 3) const Gap(10),
                ],
              ],
            ),
          ),
        ),
        if (progress != null)
          Positioned(
            left: 0,
            right: 0,
            bottom: bottom + AppSpacing.md,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'データをダウンロード中... ${(progress * 100).round()}%',
                    style: AppTextStyle.bodySmall.copyWith(
                      color: c.fgShade400,
                    ),
                  ),
                  const Gap(AppSpacing.xs),
                  ClipRRect(
                    borderRadius: AppBorderRadius.full,
                    child: LinearProgressIndicator(
                      value: progress,
                      minHeight: 4,
                      backgroundColor: c.border1,
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

/// _QuestionCard のスケルトン
class _SkeletonQuestionCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final c = context.appColors;
    return ClipRRect(
      borderRadius: const BorderRadius.all(Radius.circular(20)),
      child: Container(
        decoration: BoxDecoration(
          color: c.surface2,
          borderRadius: const BorderRadius.all(Radius.circular(20)),
          border: Border.all(color: c.border1),
        ),
        padding: const EdgeInsets.all(AppSpacing.md),
        child: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                _SkeletonBox(
                  width: 120,
                  height: 22,
                  radius: AppBorderRadius.full,
                ),
                Spacer(),
                _SkeletonBox(
                  width: 56,
                  height: 22,
                  radius: AppBorderRadius.full,
                ),
              ],
            ),
            Gap(AppSpacing.sm),
            _SkeletonBox(width: double.infinity, height: 14),
            Gap(AppSpacing.xs),
            _SkeletonBox(width: double.infinity, height: 14),
            Gap(AppSpacing.xs),
            _SkeletonBox(width: 200, height: 14),
            Gap(AppSpacing.md),
            Align(
              alignment: Alignment.centerRight,
              child: _SkeletonBox(width: 80, height: 12),
            ),
          ],
        ),
      ),
    );
  }
}

/// _ChoiceButton のスケルトン
class _SkeletonChoiceButton extends StatelessWidget {
  const _SkeletonChoiceButton({this.wide = false});

  final bool wide;

  @override
  Widget build(BuildContext context) {
    final c = context.appColors;
    return Container(
      height: 56,
      decoration: BoxDecoration(
        color: c.surface2,
        borderRadius: AppBorderRadius.md,
        border: Border.all(color: c.border1),
      ),
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      child: Row(
        children: [
          const _SkeletonBox(width: 24, height: 24, radius: AppBorderRadius.sm),
          const Gap(AppSpacing.sm),
          Expanded(
            child: _SkeletonBox(
              width: wide ? 220 : 140,
              height: 13,
            ),
          ),
        ],
      ),
    );
  }
}

/// 汎用シマーボックス（shimmer の baseColor/highlightColor に白を使う）
class _SkeletonBox extends StatelessWidget {
  const _SkeletonBox({
    required this.width,
    required this.height,
    this.radius = const BorderRadius.all(Radius.circular(4)),
  });

  final double width;
  final double height;
  final BorderRadius radius;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width == double.infinity ? null : width,
      height: height,
      decoration: BoxDecoration(
        color: Colors.white, // Shimmer.fromColors が上書きするので常に白
        borderRadius: radius,
      ),
    );
  }
}

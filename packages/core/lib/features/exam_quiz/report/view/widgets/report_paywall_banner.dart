part of '../report_sheet.dart';

const _dummyProgress = ProgressDashboardData(
  all: SystemProgress(
    counts: {
      LearningLevel.unseen: 450,
      LearningLevel.weak: 180,
      LearningLevel.fuzzy: 230,
      LearningLevel.familiar: 280,
      LearningLevel.mastered: 107,
    },
    total: 1247,
  ),
  bySystem: {
    'ストラテジ系': SystemProgress(
      counts: {
        LearningLevel.unseen: 120,
        LearningLevel.weak: 50,
        LearningLevel.fuzzy: 80,
        LearningLevel.familiar: 90,
        LearningLevel.mastered: 30,
      },
      total: 370,
    ),
    'マネジメント系': SystemProgress(
      counts: {
        LearningLevel.unseen: 130,
        LearningLevel.weak: 60,
        LearningLevel.fuzzy: 70,
        LearningLevel.familiar: 80,
        LearningLevel.mastered: 37,
      },
      total: 377,
    ),
    'テクノロジ系': SystemProgress(
      counts: {
        LearningLevel.unseen: 200,
        LearningLevel.weak: 70,
        LearningLevel.fuzzy: 80,
        LearningLevel.familiar: 110,
        LearningLevel.mastered: 40,
      },
      total: 500,
    ),
  },
  byEra: {},
);

const _dummyStats = ReportStats(
  totalAnswered: 1247,
  todayAnswered: 23,
  totalCorrect: 986,
  todayCorrect: 19,
  reviewCount: 84,
  todayNewReview: 5,
  totalStudySec: 18540,
  todayStudySec: 1380,
  studyTimeDaily: [500.0, 200.0, 150.0, 300.0, 350.0, 500.0, 450.0],
  answeredDaily: [10.0, 15.0, 20.0, 25.0, 18.0, 30.0, 23.0],
  correctDaily: [8.0, 12.0, 18.0, 22.0, 15.0, 25.0, 19.0],
  newReviewDaily: [2.0, 3.0, 4.0, 5.0, 2.0, 6.0, 5.0],
);

class _LockedContentPreview extends StatelessWidget {
  const _LockedContentPreview();

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: AppBorderRadius.md,
      child: AbsorbPointer(
        child: ImageFiltered(
          imageFilter: ImageFilter.blur(
            sigmaX: 6,
            sigmaY: 6,
            tileMode: TileMode.mirror,
          ),
          child: const Column(
            children: [
              _StatsGrid(stats: _dummyStats),
              Gap(AppSpacing.lg),
              _ProgressSection(data: _dummyProgress),
              Gap(200),
            ],
          ),
        ),
      ),
    );
  }
}

class _PaywallBanner extends StatelessWidget {
  const _PaywallBanner({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.appColors;
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            c.surfaceSheet.withValues(alpha: 0),
            c.surfaceSheet.withValues(alpha: 0.92),
            c.surfaceSheet,
          ],
          stops: const [0.0, 0.25, 0.5],
        ),
      ),
      padding: EdgeInsets.fromLTRB(
        AppSpacing.md,
        AppSpacing.xl,
        AppSpacing.md,
        bottomPadding + AppSpacing.md,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Gap(AppSpacing.lg),
          Text(
            'レポートをフル活用しよう',
            style: AppTextStyle.titleMedium.copyWith(color: c.fg),
            textAlign: TextAlign.center,
          ),
          const Gap(AppSpacing.sm),
          Text(
            '学習時間・正解率・進捗グラフで\n弱点を把握して合格に近づけます',
            style: AppTextStyle.bodySmall.copyWith(color: c.fg),
            textAlign: TextAlign.center,
          ),
          const Gap(AppSpacing.md),
          PrimaryButton(label: 'プレミアムプランを見る', onPressed: onTap),
        ],
      ),
    );
  }
}

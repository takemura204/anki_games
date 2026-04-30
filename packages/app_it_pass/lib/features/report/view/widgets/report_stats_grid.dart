part of '../report_sheet.dart';

class _StatsGrid extends StatelessWidget {
  const _StatsGrid({required this.stats});

  final ReportStats stats;

  @override
  Widget build(BuildContext context) {
    final primary = ReportStats.studyTimePrimary(stats.totalStudySec);
    final secondary = ReportStats.studyTimeSecondary(stats.totalStudySec);
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _StatCard(
                label: '学習時間',
                value: primary.value,
                unit: primary.unit,
                secondaryValue: secondary?.value,
                secondaryUnit: secondary?.unit,
                delta: ReportStats.formatStudyTimeDelta(stats.todayStudySec),
                icon: Icons.timer_outlined,
                chartData: stats.studyTimeDaily,
              ),
            ),
            const Gap(AppSpacing.sm),
            Expanded(
              child: _StatCard(
                label: '解答数',
                value: ReportStats.formatCount(stats.totalAnswered),
                unit: '問',
                delta: '${stats.todayAnswered}',
                icon: Icons.school_outlined,
                chartData: stats.answeredDaily,
              ),
            ),
          ],
        ),
        const Gap(AppSpacing.sm),
        Row(
          children: [
            Expanded(
              child: _StatCard(
                label: '正解数',
                value: ReportStats.formatCount(stats.totalCorrect),
                unit: '問',
                delta: '${stats.todayCorrect}',
                icon: Icons.check_circle_outline,
                chartData: stats.correctDaily,
              ),
            ),
            const Gap(AppSpacing.sm),
            Expanded(
              child: _StatCard(
                label: '復習問題数',
                value: ReportStats.formatCount(stats.reviewCount),
                unit: '問',
                delta: '${stats.todayNewReview}',
                icon: Icons.replay_outlined,
                chartData: stats.newReviewDaily,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.label,
    required this.value,
    required this.unit,
    required this.delta,
    required this.icon,
    required this.chartData,
    this.secondaryValue,
    this.secondaryUnit,
  });

  final String label;
  final String value;
  final String unit;
  final String? secondaryValue;
  final String? secondaryUnit;
  final String delta;
  final IconData icon;
  final List<double> chartData;

  @override
  Widget build(BuildContext context) {
    final c = context.appColors;
    return GlassContainer(
      cardRadius: BorderRadius.circular(16),
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.md,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: c.fgShade400, size: 14),
              const Gap(AppSpacing.xs),
              Text(
                label,
                style: AppTextStyle.labelMedium.copyWith(
                  color: c.fgShade400,
                ),
              ),
            ],
          ),
          const Gap(AppSpacing.xs),
          Stack(
            alignment: Alignment.topCenter,
            children: [
              Positioned(child: _Sparkline(data: chartData)),
              Row(
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Flexible(
                    child: Text(
                      value,
                      style: AppTextStyle.headlineSmall.copyWith(color: c.fg),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (unit.isNotEmpty) ...[
                    const Gap(2),
                    Text(
                      unit,
                      style: AppTextStyle.bodySmall.copyWith(
                        color: c.fgShade400,
                      ),
                    ),
                  ],
                  if (secondaryValue != null) ...[
                    const Gap(2),
                    Text(
                      secondaryValue!,
                      style: AppTextStyle.headlineSmall.copyWith(color: c.fg),
                    ),
                  ],
                  if (secondaryUnit != null) ...[
                    const Gap(2),
                    Text(
                      secondaryUnit!,
                      style: AppTextStyle.bodySmall.copyWith(
                        color: c.fgShade400,
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Sparkline extends StatelessWidget {
  const _Sparkline({required this.data});

  final List<double> data;

  static const _lineColor = AppColors.itPassSeed;
  static const _lineColorEnd = AppColors.itPassAccent;

  @override
  Widget build(BuildContext context) {
    if (!data.any((v) => v > 0)) {
      return const SizedBox(height: 40);
    }

    var running = 0.0;
    final cumulative = data.map((v) {
      running += v;
      return running;
    }).toList();
    const minY = 0.0;
    final maxY = cumulative.last;
    final yRange = maxY - minY;
    final spots = [
      for (var i = 0; i < cumulative.length; i++)
        FlSpot(i.toDouble(), cumulative[i]),
    ];

    return SizedBox(
      height: 50,
      child: LineChart(
        LineChartData(
          minY: minY,
          maxY: yRange == 0 ? minY + 1 : maxY + yRange * 0.2,
          gridData: const FlGridData(show: false),
          borderData: FlBorderData(show: false),
          titlesData: const FlTitlesData(show: false),
          lineTouchData: const LineTouchData(enabled: false),
          lineBarsData: [
            LineChartBarData(
              spots: spots,
              isCurved: true,
              curveSmoothness: 0.35,
              gradient: const LinearGradient(
                colors: [_lineColor, _lineColorEnd],
              ),
              barWidth: 2,
              dotData: const FlDotData(show: false),
              belowBarData: BarAreaData(
                show: true,
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    _lineColor.withValues(alpha: 0.35),
                    _lineColorEnd.withValues(alpha: 0.0),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

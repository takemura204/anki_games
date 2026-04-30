part of '../report_sheet.dart';

sealed class _Tab {
  const _Tab();
  String get label;
}

class _AllTab extends _Tab {
  const _AllTab();
  @override
  String get label => 'すべて';
}

class _SystemTab extends _Tab {
  const _SystemTab(this.system);
  final String system;
  @override
  String get label => system;
}

class _EraTab extends _Tab {
  const _EraTab({required this.eraId, required this.label});
  final String eraId;
  @override
  final String label;
}

class _ProgressSection extends HookConsumerWidget {
  const _ProgressSection();

  static const _tabs = <_Tab>[
    _AllTab(),
    _SystemTab('ストラテジ系'),
    _SystemTab('マネジメント系'),
    _SystemTab('テクノロジ系'),
    _EraTab(eraId: 'sample1', label: 'サンプル①'),
    _EraTab(eraId: 'sample2', label: 'サンプル②'),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedTab = useState(0);
    final asyncData = ref.watch(progressDashboardProvider);

    return asyncData.when(
      loading: () => GlassContainer(
        cardRadius: BorderRadius.circular(16),
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _SectionTitle(color: context.appColors.fgShade400),
            const Gap(AppSpacing.sm),
            const _ProgressSkeleton(),
          ],
        ),
      ),
      error: (_, __) => const SizedBox.shrink(),
      data: (data) {
        final tab = _tabs[selectedTab.value];
        final progress = switch (tab) {
          _AllTab() => data.all,
          _SystemTab(:final system) => data.forSystem(system),
          _EraTab(:final eraId) => data.forEra(eraId),
        };
        return GlassContainer(
          cardRadius: BorderRadius.circular(16),
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _SectionTitle(color: context.appColors.fgShade400),
              const Gap(AppSpacing.sm),
              _TabBar(
                tabs: _tabs.map((t) => t.label).toList(),
                selected: selectedTab.value,
                onTap: (i) => selectedTab.value = i,
              ),
              const Gap(AppSpacing.sm),
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  _DonutChart(progress: progress),
                  const Gap(AppSpacing.md),
                  Expanded(child: _LevelList(progress: progress)),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(AppIcons.progressChart, color: color, size: 16),
        const Gap(AppSpacing.xs),
        Text(
          '学習進捗',
          style: AppTextStyle.titleSmall.copyWith(color: color),
        ),
      ],
    );
  }
}

class _TabBar extends StatelessWidget {
  const _TabBar({
    required this.tabs,
    required this.selected,
    required this.onTap,
  });

  final List<String> tabs;
  final int selected;
  final void Function(int) onTap;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          for (var i = 0; i < tabs.length; i++) ...[
            _TabChip(
              label: tabs[i],
              isSelected: selected == i,
              onTap: () => onTap(i),
            ),
            if (i < tabs.length - 1) const Gap(AppSpacing.xs),
          ],
        ],
      ),
    );
  }
}

class _TabChip extends StatelessWidget {
  const _TabChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.appColors;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm,
          vertical: 6,
        ),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.itPassSeed.withValues(alpha: 0.25)
              : c.surface2,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected
                ? AppColors.itPassSeed.withValues(alpha: 0.6)
                : Colors.transparent,
          ),
        ),
        child: Text(
          label,
          style: AppTextStyle.captionSmall.copyWith(
            color: isSelected ? Colors.white : c.fgShade300,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
      ),
    );
  }
}

class _DonutChart extends StatelessWidget {
  const _DonutChart({required this.progress});

  final SystemProgress progress;

  @override
  Widget build(BuildContext context) {
    final sections = LearningLevel.values.reversed.map((level) {
      final count = progress.countFor(level);
      return PieChartSectionData(
        value: count == 0 ? 0.001 : count.toDouble(),
        color: level.colorFg,
        radius: 12,
        showTitle: false,
      );
    }).toList();

    return SizedBox(
      width: context.width * 0.3,
      height: context.width * 0.3,
      child: Stack(
        alignment: Alignment.center,
        children: [
          PieChart(
            PieChartData(
              sections: sections,
              centerSpaceRadius: 40,
              sectionsSpace: 1.5,
              startDegreeOffset: -90,
            ),
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '${progress.total}',
                style: AppTextStyle.bodyLarge.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                ),
              ),
              Text(
                '問',
                style: AppTextStyle.captionSmall.copyWith(
                  color: context.appColors.fgShade300,
                  fontSize: 9,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _LevelList extends StatelessWidget {
  const _LevelList({required this.progress});

  final SystemProgress progress;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (final level in LearningLevel.values.reversed)
          _LevelRow(level: level, progress: progress),
      ],
    );
  }
}

class _LevelRow extends StatelessWidget {
  const _LevelRow({required this.level, required this.progress});

  final LearningLevel level;
  final SystemProgress progress;

  @override
  Widget build(BuildContext context) {
    final c = context.appColors;
    final percent = progress.percentFor(level);
    final pct = (percent * 100).round();

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: level.colorFg,
              shape: BoxShape.circle,
            ),
          ),
          const Gap(AppSpacing.xs),
          SizedBox(
            width: 60,
            child: Text(
              level.label,
              style: AppTextStyle.captionSmall.copyWith(
                color: c.fgShade300,
                fontSize: 11,
              ),
            ),
          ),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: percent,
                backgroundColor: c.surface2,
                valueColor: AlwaysStoppedAnimation(
                  level.colorFg.withValues(alpha: 0.8),
                ),
                minHeight: 5,
              ),
            ),
          ),
          const Gap(AppSpacing.xs),
          SizedBox(
            width: 32,
            child: Text(
              '$pct%',
              textAlign: TextAlign.right,
              style: AppTextStyle.captionSmall.copyWith(
                color: c.fg,
                fontSize: 11,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ProgressSkeleton extends StatelessWidget {
  const _ProgressSkeleton();

  static const _shimmerBase = Color(0x26FFFFFF);
  static const _shimmerHighlight = Color(0x4DFFFFFF);

  Widget _box({
    double? width,
    double? height,
    BoxShape shape = BoxShape.rectangle,
  }) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: _shimmerBase,
        shape: shape,
        borderRadius:
            shape == BoxShape.rectangle ? BorderRadius.circular(6) : null,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: _shimmerBase,
      highlightColor: _shimmerHighlight,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(
            width: 120,
            height: 120,
            child: Stack(
              alignment: Alignment.center,
              children: [
                _box(width: 120, height: 120, shape: BoxShape.circle),
                Container(
                  width: 72,
                  height: 72,
                  decoration: const BoxDecoration(
                    color: Colors.transparent,
                    shape: BoxShape.circle,
                  ),
                ),
              ],
            ),
          ),
          const Gap(AppSpacing.md),
          Expanded(
            child: Column(
              children: [
                for (var i = 0; i < 5; i++) ...[
                  Row(
                    children: [
                      _box(width: 8, height: 8, shape: BoxShape.circle),
                      const Gap(AppSpacing.xs),
                      _box(width: 48, height: 10),
                      const Gap(AppSpacing.xs),
                      Expanded(child: _box(height: 5)),
                      const Gap(AppSpacing.xs),
                      _box(width: 28, height: 10),
                    ],
                  ),
                  if (i < 4) const Gap(9),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

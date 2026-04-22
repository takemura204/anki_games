part of '../filter_sheet.dart';

class _OrderModeSection extends StatelessWidget {
  const _OrderModeSection({
    required this.mode,
    required this.onChanged,
  });

  final QuizOrderMode mode;
  final ValueChanged<QuizOrderMode> onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionLabel('出題の順番'),
        Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.sm,
          children: [
            _OrderModeChip(
              label: '最適化',
              subtitle: '学習履歴で重み付け',
              selected: mode == QuizOrderMode.optimized,
              onTap: () => onChanged(QuizOrderMode.optimized),
            ),
            _OrderModeChip(
              label: '順番通り',
              subtitle: '試験回の定義順',
              selected: mode == QuizOrderMode.sequential,
              onTap: () => onChanged(QuizOrderMode.sequential),
            ),
            _OrderModeChip(
              label: 'ランダム',
              subtitle: '一様にシャッフル',
              selected: mode == QuizOrderMode.random,
              onTap: () => onChanged(QuizOrderMode.random),
            ),
          ],
        ),
      ],
    );
  }
}

class _OrderModeChip extends StatelessWidget {
  const _OrderModeChip({
    required this.label,
    required this.subtitle,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final String subtitle;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.appColors;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: AppAnimation.fast,
        padding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: AppSpacing.sm,
        ),
        decoration: BoxDecoration(
          color: selected
              ? AppColors.itPassSeed.withValues(alpha: 0.28)
              : c.surface1,
          borderRadius: AppBorderRadius.md,
          border: Border.all(
            color: selected ? AppColors.itPassSeed : c.border1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: AppTextStyle.labelLarge.copyWith(
                color: selected ? c.fg : c.fgShade300,
                fontWeight: FontWeight.bold,
                letterSpacing: 0,
              ),
            ),
            Text(
              subtitle,
              style: AppTextStyle.labelSmall.copyWith(
                color: selected ? c.fgShade400 : c.fgShade200,
                letterSpacing: 0,
                fontWeight: FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

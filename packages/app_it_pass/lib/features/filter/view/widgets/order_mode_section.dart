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
              label: 'おまかせ',
              icon: Icons.auto_awesome_rounded,
              selected: mode == QuizOrderMode.optimized,
              onTap: () => onChanged(QuizOrderMode.optimized),
            ),
            _OrderModeChip(
              label: '順番通り',
              icon: Icons.format_list_numbered_rounded,
              selected: mode == QuizOrderMode.sequential,
              onTap: () => onChanged(QuizOrderMode.sequential),
            ),
            _OrderModeChip(
              label: 'ランダム',
              icon: Icons.shuffle_rounded,
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
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.appColors;
    return Material(
      color: Colors.transparent,
      borderRadius: AppBorderRadius.md,
      child: InkWell(
        borderRadius: AppBorderRadius.md,
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
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 16,
                color: selected ? c.fg : c.fgShade300,
              ),
              const Gap(AppSpacing.xs),
              Text(
                label,
                style: AppTextStyle.labelLarge.copyWith(
                  color: selected ? c.fg : c.fgShade300,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

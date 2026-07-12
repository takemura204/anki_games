part of '../filter_sheet.dart';

class _LearningLevelFilterSection extends StatelessWidget {
  const _LearningLevelFilterSection({
    required this.selected,
    required this.onToggle,
    required this.onSelectAll,
    required this.onClearAll,
  });

  final Set<LearningLevel> selected;
  final ValueChanged<LearningLevel> onToggle;
  final VoidCallback onSelectAll;
  final VoidCallback onClearAll;

  @override
  Widget build(BuildContext context) {
    final allSelected =
        selected.length == LearningLevel.values.length;
    final noneSelected = selected.isEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionLabel(
          '学習レベル',
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _TextLinkButton(
                label: 'すべて選択',
                onTap: allSelected ? null : onSelectAll,
                active: allSelected,
              ),
              const Gap(AppSpacing.xs),
              _TextLinkButton(
                label: 'すべて解除',
                onTap: noneSelected ? null : onClearAll,
              ),
            ],
          ),
        ),
        Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.sm,
          children: LearningLevel.values.map((level) {
            final isOn = selected.contains(level);
            return _LearningLevelFilterChip(
              level: level,
              isSelected: isOn,
              onTap: () => onToggle(level),
            );
          }).toList(),
        ),
        if (noneSelected)
          Padding(
            padding: const EdgeInsets.only(top: AppSpacing.sm),
            child: Row(
              children: [
                const Icon(
                  Icons.warning_amber_rounded,
                  color: AppColors.warning,
                  size: 14,
                ),
                const Gap(AppSpacing.xs + 2),
                Text(
                  '学習レベルを1つ以上選択してください',
                  style: AppTextStyle.labelLarge.copyWith(
                    color: AppColors.warning.withValues(alpha: 0.8),
                    letterSpacing: 0,
                    fontWeight: FontWeight.normal,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

class _LearningLevelFilterChip extends StatelessWidget {
  const _LearningLevelFilterChip({
    required this.level,
    required this.isSelected,
    required this.onTap,
  });

  final LearningLevel level;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final fg = level.colorFg;
    final bg = level.colorBg;
    final c = context.appColors;
    return Material(
      color: Colors.transparent,
      borderRadius: AppBorderRadius.full,
      child: InkWell(
        borderRadius: AppBorderRadius.full,
        onTap: onTap.withHaptic(HapticType.selection),
        child: AnimatedContainer(
          duration: AppAnimation.fast,
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: isSelected ? bg : c.surface1,
            borderRadius: AppBorderRadius.full,
            border: Border.all(
              color: isSelected ? fg.withValues(alpha: 0.55) : c.border1,
              width: 1.5,
            ),
          ),
          child: Text(
            level.label,
            style: AppTextStyle.labelMedium.copyWith(
              color: isSelected ? fg : c.fgShade200,
              fontWeight: FontWeight.w600,
              letterSpacing: 0,
            ),
          ),
        ),
      ),
    );
  }
}

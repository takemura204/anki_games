part of '../filter_sheet.dart';

class _LearningLevelFilterSection extends StatelessWidget {
  const _LearningLevelFilterSection({
    required this.selected,
    required this.onToggle,
    required this.onClear,
  });

  final Set<LearningLevel> selected;
  final ValueChanged<LearningLevel> onToggle;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    final hasFilter = selected.isNotEmpty;
    final c = context.appColors;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionLabel(
          '学習レベル',
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _TextLinkButton(
                label: 'クリア',
                onTap: onClear,
                active: hasFilter,
              ),
            ],
          ),
        ),
        Text(
          hasFilter ? '選んだレベルの問題だけ出題します（複数選択は OR）' : '未選択のときは全レベルが対象です',
          style: AppTextStyle.labelMedium.copyWith(
            color: c.fgShade200,
            height: 1.35,
            letterSpacing: 0,
          ),
        ),
        const Gap(12),
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
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: AppAnimation.fast,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? bg : c.surface1,
          borderRadius: AppBorderRadius.full,
          border: Border.all(
            color: isSelected ? fg.withValues(alpha: 0.55) : c.border1,
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Text(
          level.label,
          style: AppTextStyle.labelMedium.copyWith(
            color: isSelected ? fg : c.fgShade200,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
            letterSpacing: 0,
          ),
        ),
      ),
    );
  }
}

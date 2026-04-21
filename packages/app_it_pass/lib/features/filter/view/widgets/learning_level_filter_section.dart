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
          hasFilter
              ? '選んだレベルの問題だけ出題します（複数選択は OR）'
              : '未選択のときは全レベルが対象です',
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.42),
            fontSize: 11,
            height: 1.35,
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
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
    final fg = level.filterForeground;
    final bg = level.filterBackground;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? bg : Colors.white.withValues(alpha: 0.04),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected
                ? fg.withValues(alpha: 0.55)
                : Colors.white.withValues(alpha: 0.12),
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Text(
          level.label,
          style: TextStyle(
            color: isSelected ? fg : Colors.white.withValues(alpha: 0.4),
            fontSize: 11,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
          ),
        ),
      ),
    );
  }
}

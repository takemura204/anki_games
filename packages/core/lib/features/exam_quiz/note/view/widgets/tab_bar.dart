part of '../note_sheet.dart';

class _NoteTabBar extends StatelessWidget {
  const _NoteTabBar({
    required this.selectedTab,
    required this.onTabChanged,
  });

  final NoteTab selectedTab;
  final ValueChanged<NoteTab> onTabChanged;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      child: Row(
        children: [
          _TabPill(
            icon: AppIcons.review,
            label: '復習',
            selected: selectedTab == NoteTab.review,
            onTap: () => onTabChanged(NoteTab.review),
          ),
          const Gap(AppSpacing.sm),
          _TabPill(
            icon: AppIcons.bookmark,
            label: 'ブックマーク',
            selected: selectedTab == NoteTab.bookmark,
            onTap: () => onTabChanged(NoteTab.bookmark),
          ),
          const Gap(AppSpacing.sm),
          _TabPill(
            icon: AppIcons.history,
            label: '履歴',
            selected: selectedTab == NoteTab.history,
            onTap: () => onTabChanged(NoteTab.history),
          ),
        ],
      ),
    );
  }
}

class _TabPill extends StatelessWidget {
  const _TabPill({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.appColors;
    final color = selected ? Colors.white : c.fgShade300;
    return GestureDetector(
      onTap: onTap.withHaptic(HapticType.selection),
      child: AnimatedContainer(
        duration: AppAnimation.fast,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: selected ? AppPalette.seed : c.surface2,
          borderRadius: AppBorderRadius.full,
          border: Border.all(
            color: selected ? AppPalette.seed : c.border1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: color),
            const Gap(4),
            Text(
              label,
              style: AppTextStyle.labelMedium.copyWith(
                color: color,
                fontWeight: selected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

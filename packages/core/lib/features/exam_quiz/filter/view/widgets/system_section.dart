part of '../filter_sheet.dart';

class _SystemMajorSection extends StatelessWidget {
  const _SystemMajorSection({
    required this.selectedSystems,
    required this.selectedMajors,
    required this.expandedSystems,
    required this.categoryTree,
    required this.onSystemToggle,
    required this.onMajorToggle,
    required this.onExpansionToggle,
  });

  final Set<String> selectedSystems;
  final Set<String> selectedMajors;
  final Set<String> expandedSystems;
  final Map<String, List<String>> categoryTree;
  final ValueChanged<String> onSystemToggle;
  final ValueChanged<String> onMajorToggle;
  final ValueChanged<String> onExpansionToggle;

  @override
  Widget build(BuildContext context) {
    final systems = categoryTree.keys.toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ...systems.map((system) {
          final majors = categoryTree[system] ?? [];
          return _GlassExpansionTile(
            title: system,
            isSelected: selectedSystems.contains(system),
            isExpanded: expandedSystems.contains(system),
            onSelectToggle: () => onSystemToggle(system),
            onExpansionToggle: () => onExpansionToggle(system),
            child: Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              children: majors
                  .map(
                    (major) => _MajorChip(
                      label: major,
                      isSelected: selectedMajors.contains(major),
                      onTap: () => onMajorToggle(major),
                    ),
                  )
                  .toList(),
            ),
          );
        }),
        if (selectedSystems.isEmpty)
          Padding(
            padding: const EdgeInsets.only(top: AppSpacing.xs),
            child: Row(
              children: [
                const Icon(
                  Icons.warning_amber_rounded,
                  color: AppColors.warning,
                  size: 14,
                ),
                const Gap(AppSpacing.xs + 2),
                Text(
                  '分野を1つ以上選択してください',
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

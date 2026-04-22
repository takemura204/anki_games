part of '../filter_sheet.dart';

class _MajorSection extends StatelessWidget {
  const _MajorSection({
    required this.selectedSystems,
    required this.selectedMajors,
    required this.expandedSystems,
    required this.onToggle,
    required this.onExpansionToggle,
  });

  final Set<String> selectedSystems;
  final Set<String> selectedMajors;
  final Set<String> expandedSystems;
  final ValueChanged<String> onToggle;
  final ValueChanged<String> onExpansionToggle;

  @override
  Widget build(BuildContext context) {
    final c = context.appColors;

    if (selectedSystems.isEmpty) {
      return Text(
        '分野を選択すると中分類で絞り込めます（任意）',
        style: AppTextStyle.labelLarge.copyWith(
          color: c.fgShade100,
          letterSpacing: 0,
          fontWeight: FontWeight.normal,
        ),
      );
    }

    return Column(
      children: selectedSystems.map((system) {
        final majors = ExamMeta.categoryTree[system] ?? [];
        final isExpanded = expandedSystems.contains(system);
        return _GlassExpansionTile(
          title: system,
          isExpanded: isExpanded,
          onToggle: () => onExpansionToggle(system),
          child: Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: majors.map((major) {
              final selected = selectedMajors.contains(major);
              return GestureDetector(
                onTap: () => onToggle(major),
                child: AnimatedContainer(
                  duration: AppAnimation.fast,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 7,
                  ),
                  decoration: BoxDecoration(
                    color: selected
                        ? AppColors.success.withValues(alpha: 0.2)
                        : c.surface1,
                    borderRadius: AppBorderRadius.sm,
                    border: Border.all(
                      color: selected
                          ? AppColors.success.withValues(alpha: 0.6)
                          : c.border1,
                    ),
                  ),
                  child: Text(
                    major,
                    style: AppTextStyle.labelLarge.copyWith(
                      color: selected ? AppColors.success : c.fgShade300,
                      letterSpacing: 0,
                      fontWeight: FontWeight.normal,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        );
      }).toList(),
    );
  }
}

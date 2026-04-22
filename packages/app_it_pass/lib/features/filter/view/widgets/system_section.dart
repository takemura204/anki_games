part of '../filter_sheet.dart';

class _SystemSection extends StatelessWidget {
  const _SystemSection({
    required this.selectedSystems,
    required this.onToggle,
  });

  final Set<String> selectedSystems;
  final ValueChanged<String> onToggle;

  @override
  Widget build(BuildContext context) {
    final systems = ExamMeta.categoryTree.keys.toList();
    final c = context.appColors;
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: systems.map((system) {
        final selected = selectedSystems.contains(system);
        return GestureDetector(
          onTap: () => onToggle(system),
          child: AnimatedContainer(
            duration: AppAnimation.fast,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: selected
                  ? AppColors.itPassSeed.withValues(alpha: 0.3)
                  : c.surface1,
              borderRadius: AppBorderRadius.md,
              border: Border.all(
                color: selected ? AppColors.itPassSeed : c.border1,
              ),
            ),
            child: Text(
              system,
              style: AppTextStyle.labelLarge.copyWith(
                color: selected ? c.fg : c.fgShade300,
                fontWeight: selected ? FontWeight.bold : FontWeight.normal,
                letterSpacing: 0,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

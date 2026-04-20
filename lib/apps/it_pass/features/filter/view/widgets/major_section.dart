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
    if (selectedSystems.isEmpty) {
      return Text(
        '分野を選択すると中分類で絞り込めます（任意）',
        style: TextStyle(
          color: Colors.white.withValues(alpha: 0.3),
          fontSize: 12,
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
            spacing: 8,
            runSpacing: 8,
            children: majors.map((major) {
              final selected = selectedMajors.contains(major);
              return GestureDetector(
                onTap: () => onToggle(major),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 7,
                  ),
                  decoration: BoxDecoration(
                    color: selected
                        ? const Color(0xFF10B981).withValues(alpha: 0.2)
                        : Colors.white.withValues(alpha: 0.04),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: selected
                          ? const Color(0xFF10B981).withValues(alpha: 0.6)
                          : Colors.white.withValues(alpha: 0.1),
                    ),
                  ),
                  child: Text(
                    major,
                    style: TextStyle(
                      color:
                          selected ? const Color(0xFF10B981) : Colors.white54,
                      fontSize: 12,
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

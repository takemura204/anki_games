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
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: systems.map((system) {
        final selected = selectedSystems.contains(system);
        return GestureDetector(
          onTap: () => onToggle(system),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: selected
                  ? const Color(0xFF7C3AED).withValues(alpha: 0.3)
                  : Colors.white.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: selected
                    ? const Color(0xFF7C3AED)
                    : Colors.white.withValues(alpha: 0.15),
              ),
            ),
            child: Text(
              system,
              style: TextStyle(
                color: selected ? Colors.white : Colors.white54,
                fontSize: 12,
                fontWeight: selected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

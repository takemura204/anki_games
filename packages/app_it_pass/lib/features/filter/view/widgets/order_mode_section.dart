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
          spacing: 8,
          runSpacing: 8,
          children: [
            _OrderModeChip(
              label: '最適化',
              subtitle: '学習履歴で重み付け',
              selected: mode == QuizOrderMode.optimized,
              onTap: () => onChanged(QuizOrderMode.optimized),
            ),
            _OrderModeChip(
              label: '順番通り',
              subtitle: '試験回の定義順',
              selected: mode == QuizOrderMode.sequential,
              onTap: () => onChanged(QuizOrderMode.sequential),
            ),
            _OrderModeChip(
              label: 'ランダム',
              subtitle: '一様にシャッフル',
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
    required this.subtitle,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final String subtitle;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: selected
              ? const Color(0xFF7C3AED).withValues(alpha: 0.28)
              : Colors.white.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected
                ? const Color(0xFF7C3AED)
                : Colors.white.withValues(alpha: 0.12),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: TextStyle(
                color: selected ? Colors.white : Colors.white54,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              subtitle,
              style: TextStyle(
                color: Colors.white.withValues(alpha: selected ? 0.55 : 0.35),
                fontSize: 10,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

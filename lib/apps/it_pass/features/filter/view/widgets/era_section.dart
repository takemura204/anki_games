part of '../filter_sheet.dart';

const List<ExamGroup> _groupOrder = [
  ExamGroup.reiwa,
  ExamGroup.heisei,
  ExamGroup.sample,
];

class _EraSection extends StatelessWidget {
  const _EraSection({
    required this.selectedEraIds,
    required this.onToggle,
    required this.onSelectAll,
    required this.onClearAll,
    required this.canApply,
  });

  final Set<String> selectedEraIds;
  final ValueChanged<String> onToggle;
  final VoidCallback onSelectAll;
  final VoidCallback onClearAll;
  final bool canApply;

  Map<ExamGroup, List<ExamMeta>> _buildGrouped() {
    final raw = <ExamGroup, List<ExamMeta>>{};
    for (final meta in ExamMeta.all) {
      raw.putIfAbsent(meta.group, () => []).add(meta);
    }
    return {
      for (final g in _groupOrder)
        if (raw.containsKey(g)) g: raw[g]!.reversed.toList(),
    };
  }

  String _groupLabel(ExamGroup g) => switch (g) {
        ExamGroup.reiwa => '令和',
        ExamGroup.heisei => '平成',
        ExamGroup.sample => 'サンプル',
      };

  @override
  Widget build(BuildContext context) {
    final grouped = _buildGrouped();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionLabel(
          '試験回',
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _TextLinkButton(
                label: 'すべて選択',
                onTap: onSelectAll,
                active: selectedEraIds.length == ExamMeta.all.length,
              ),
              const SizedBox(width: 4),
              _TextLinkButton(label: 'すべて解除', onTap: onClearAll),
            ],
          ),
        ),
        ...grouped.entries.map(
          (entry) => _EraGroupSection(
            groupLabel: _groupLabel(entry.key),
            metas: entry.value,
            selectedEraIds: selectedEraIds,
            onToggle: onToggle,
          ),
        ),
        if (!canApply)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Row(
              children: [
                const Icon(
                  Icons.warning_amber_rounded,
                  color: Color(0xFFFBBF24),
                  size: 14,
                ),
                const SizedBox(width: 6),
                Text(
                  '試験回を1つ以上選択してください',
                  style: TextStyle(
                    color: const Color(0xFFFBBF24).withValues(alpha: 0.8),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

class _EraGroupSection extends StatelessWidget {
  const _EraGroupSection({
    required this.groupLabel,
    required this.metas,
    required this.selectedEraIds,
    required this.onToggle,
  });

  final String groupLabel;
  final List<ExamMeta> metas;
  final Set<String> selectedEraIds;
  final ValueChanged<String> onToggle;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Text(
            groupLabel,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.4),
              fontSize: 11,
            ),
          ),
        ),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: metas.map((meta) {
            return _EraChip(
              label: meta.displayName,
              selected: selectedEraIds.contains(meta.eraId),
              onTap: () => onToggle(meta.eraId),
            );
          }).toList(),
        ),
        const SizedBox(height: 16),
      ],
    );
  }
}

class _TextLinkButton extends StatelessWidget {
  const _TextLinkButton({
    required this.label,
    required this.onTap,
    this.active = false,
  });

  final String label;
  final VoidCallback onTap;
  final bool active;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Text(
        label,
        style: TextStyle(
          color: active
              ? const Color(0xFF7C3AED)
              : Colors.white.withValues(alpha: 0.45),
          fontSize: 11,
          fontWeight: FontWeight.w600,
          decoration: TextDecoration.underline,
          decorationColor: active
              ? const Color(0xFF7C3AED)
              : Colors.white.withValues(alpha: 0.45),
        ),
      ),
    );
  }
}

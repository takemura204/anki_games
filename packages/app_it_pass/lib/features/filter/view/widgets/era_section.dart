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
              const Gap(AppSpacing.xs),
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
                  '試験回を1つ以上選択してください',
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
    final c = context.appColors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: AppSpacing.sm),
          child: Text(
            groupLabel,
            style: AppTextStyle.labelMedium.copyWith(
              color: c.fgShade200,
              letterSpacing: 0,
              fontWeight: FontWeight.normal,
            ),
          ),
        ),
        Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.sm,
          children: metas.map((meta) {
            return _EraChip(
              label: meta.displayName,
              selected: selectedEraIds.contains(meta.eraId),
              onTap: () => onToggle(meta.eraId),
            );
          }).toList(),
        ),
        const Gap(AppSpacing.md),
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
    final color = active ? AppColors.itPassSeed : context.appColors.fgShade300;
    return GestureDetector(
      onTap: onTap,
      child: Text(
        label,
        style: AppTextStyle.labelMedium.copyWith(
          color: color,
          letterSpacing: 0,
          decoration: TextDecoration.underline,
          decorationColor: color,
        ),
      ),
    );
  }
}

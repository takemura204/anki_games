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
    required this.hasEraSelected,
  });

  final Set<String> selectedEraIds;
  final ValueChanged<String> onToggle;
  final VoidCallback onSelectAll;
  final VoidCallback onClearAll;
  final bool hasEraSelected;

  List<ExamMeta> _orderedMetas() {
    final raw = <ExamGroup, List<ExamMeta>>{};
    for (final meta in ExamMeta.all) {
      raw.putIfAbsent(meta.group, () => []).add(meta);
    }
    return _groupOrder
        .where((g) => raw.containsKey(g))
        .expand((g) => raw[g]!.reversed)
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final allSelected = selectedEraIds.length == ExamMeta.all.length;
    final noneSelected = selectedEraIds.isEmpty;

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
                onTap: allSelected ? null : onSelectAll,
                active: allSelected,
              ),
              const Gap(AppSpacing.xs),
              _TextLinkButton(
                label: 'すべて解除',
                onTap: noneSelected ? null : onClearAll,
              ),
            ],
          ),
        ),
        Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.sm,
          children: _orderedMetas().map((meta) {
            return _EraChip(
              label: meta.displayName,
              selected: selectedEraIds.contains(meta.eraId),
              onTap: () => onToggle(meta.eraId),
            );
          }).toList(),
        ),
        if (!hasEraSelected)
          Padding(
            padding: const EdgeInsets.only(top: AppSpacing.sm),
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

class _TextLinkButton extends StatelessWidget {
  const _TextLinkButton({
    required this.label,
    required this.onTap,
    this.active = false,
  });

  final String label;
  final VoidCallback? onTap;
  final bool active;

  @override
  Widget build(BuildContext context) {
    final enabled = onTap != null;
    final c = context.appColors;
    final color = (active && enabled)
        ? AppColors.itPassSeed
        : enabled
            ? c.fgShade400
            : c.fgShade100;
    return GestureDetector(
      onTap: onTap.withHaptic(),
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

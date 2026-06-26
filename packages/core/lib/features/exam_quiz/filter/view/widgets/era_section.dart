part of '../filter_sheet.dart';

const List<ExamGroup> _groupOrder = [
  ExamGroup.reiwa,
  ExamGroup.heisei,
  ExamGroup.sample,
];

class _EraSection extends StatelessWidget {
  const _EraSection({
    required this.selectedEraIds,
    required this.isPremium,
    required this.availableExamList,
    required this.freeEraIds,
    required this.onToggle,
    required this.onSelectAll,
    required this.onClearAll,
    required this.onLockedTap,
    required this.hasEraSelected,
  });

  final Set<String> selectedEraIds;
  final bool isPremium;
  final List<ExamMeta> availableExamList;
  final Set<String> freeEraIds;
  final ValueChanged<String> onToggle;
  final VoidCallback onSelectAll;
  final VoidCallback onClearAll;
  final VoidCallback onLockedTap;
  final bool hasEraSelected;

  List<ExamMeta> _orderedMetas() {
    final raw = <ExamGroup, List<ExamMeta>>{};
    for (final meta in availableExamList) {
      raw.putIfAbsent(meta.group, () => []).add(meta);
    }
    return _groupOrder
        .where(raw.containsKey)
        .expand((g) => raw[g]!.reversed)
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final metas = _orderedMetas();
    final freeIds = isPremium
        ? metas.map((m) => m.eraId).toSet()
        : freeEraIds;
    final allFreeSelected = freeIds.every(selectedEraIds.contains);
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
                onTap: allFreeSelected ? null : onSelectAll,
                active: allFreeSelected,
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
          spacing: AppSpacing.xs,
          runSpacing: AppSpacing.sm,
          children: metas.map((meta) {
            final isLocked =
                !isPremium &&
                !freeEraIds.contains(meta.eraId) &&
                meta.group != ExamGroup.sample;
            return _EraChip(
              label: meta.displayName,
              selected: selectedEraIds.contains(meta.eraId),
              isLocked: isLocked,
              onTap: isLocked ? onLockedTap : () => onToggle(meta.eraId),
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
        ? ItPassColors.seed
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

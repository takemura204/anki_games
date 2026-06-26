part of '../filter_sheet.dart';

class _EraChip extends StatelessWidget {
  const _EraChip({
    required this.label,
    required this.selected,
    required this.onTap,
    this.isLocked = false,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;
  final bool isLocked;

  @override
  Widget build(BuildContext context) {
    final c = context.appColors;
    return Material(
      color: Colors.transparent,
      borderRadius: AppBorderRadius.sm,
      child: InkWell(
        borderRadius: AppBorderRadius.sm,
        onTap: onTap.withHaptic(HapticType.selection),
        child: AnimatedContainer(
          duration: AppAnimation.fast,
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.sm,
            vertical: AppSpacing.sm,
          ),
          decoration: BoxDecoration(
            color: !isLocked && selected
                ? ItPassColors.accent.withValues(alpha: 0.25)
                : c.surface1,
            borderRadius: AppBorderRadius.sm,
            border: Border.all(
              color: !isLocked && selected
                  ? ItPassColors.seed.withValues(alpha: 0.7)
                  : c.border1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (isLocked) ...[
                Icon(Icons.lock_outline_rounded, size: 16, color: c.fgShade100),
                const Gap(4),
              ],
              Text(
                label,
                style: AppTextStyle.labelLarge.copyWith(
                  color: isLocked
                      ? c.fgShade100
                      : selected
                      ? c.fg
                      : c.fgShade200,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

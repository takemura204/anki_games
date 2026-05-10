part of '../filter_sheet.dart';

class _EraChip extends StatelessWidget {
  const _EraChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

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
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: selected
                ? AppColors.itPassAccent.withValues(alpha: 0.25)
                : c.surface1,
            borderRadius: AppBorderRadius.sm,
            border: Border.all(
              color: selected
                  ? AppColors.itPassSeed.withValues(alpha: 0.7)
                  : c.border1,
            ),
          ),
          child: Text(
            label,
            style: AppTextStyle.labelLarge.copyWith(
              color: selected ? c.fg : c.fgShade200,
              fontWeight: FontWeight.w600,
              letterSpacing: 0,
            ),
          ),
        ),
      ),
    );
  }
}

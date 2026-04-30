part of '../filter_sheet.dart';

class _MajorChip extends StatelessWidget {
  const _MajorChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.appColors;
    return Material(
      color: Colors.transparent,
      borderRadius: AppBorderRadius.sm,
      child: InkWell(
        borderRadius: AppBorderRadius.sm,
        onTap: onTap,
        child: AnimatedContainer(
          duration: AppAnimation.fast,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
          decoration: BoxDecoration(
            color: isSelected
                ? AppColors.itPassSeed.withValues(alpha: 0.25)
                : c.surface1,
            borderRadius: AppBorderRadius.sm,
            border: Border.all(
              color: isSelected
                  ? AppColors.itPassSeed.withValues(alpha: 0.7)
                  : c.border1,
            ),
          ),
          child: Text(
            label,
            style: AppTextStyle.labelLarge.copyWith(
              color: isSelected ? c.fg : c.fgShade300,
              letterSpacing: 0,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }
}

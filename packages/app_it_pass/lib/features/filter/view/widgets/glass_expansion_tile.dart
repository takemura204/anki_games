part of '../filter_sheet.dart';

class _GlassExpansionTile extends StatelessWidget {
  const _GlassExpansionTile({
    required this.title,
    required this.isSelected,
    required this.isExpanded,
    required this.onSelectToggle,
    required this.onExpansionToggle,
    required this.child,
  });

  final String title;
  final bool isSelected;
  final bool isExpanded;
  final VoidCallback onSelectToggle;
  final VoidCallback onExpansionToggle;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final c = context.appColors;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: ClipRRect(
        borderRadius: const BorderRadius.all(Radius.circular(14)),
        child: AnimatedContainer(
          duration: AppAnimation.fast,
          decoration: BoxDecoration(
            color: isSelected
                ? AppColors.itPassSeed.withValues(alpha: 0.12)
                : c.surface1,
            borderRadius: const BorderRadius.all(Radius.circular(14)),
            border: Border.all(
              color: isSelected ? AppColors.itPassSeed : c.border1,
            ),
          ),
          child: Material(
            color: Colors.transparent,
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: InkWell(
                        onTap: onSelectToggle.withHaptic(HapticType.selection),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.md,
                            vertical: 12,
                          ),
                          child: Text(
                            title,
                            style: AppTextStyle.bodySmall.copyWith(
                              color: isSelected ? c.fg : c.fgShade400,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ),
                    InkWell(
                      onTap: onExpansionToggle.withHaptic(),
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: AnimatedRotation(
                          turns: isExpanded ? 0.5 : 0,
                          duration: AppAnimation.fast,
                          child: Icon(
                            Icons.keyboard_arrow_down_rounded,
                            color: c.fgShade200,
                            size: AppSpacing.md + 4,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                AnimatedSize(
                  duration: AppAnimation.fast,
                  curve: Curves.easeOut,
                  child: isExpanded
                      ? Padding(
                          padding: const EdgeInsets.fromLTRB(
                            AppSpacing.md,
                            0,
                            AppSpacing.md,
                            AppSpacing.md,
                          ),
                          child: child,
                        )
                      : const SizedBox.shrink(),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

part of '../filter_sheet.dart';

class _GlassExpansionTile extends StatelessWidget {
  const _GlassExpansionTile({
    required this.title,
    required this.isExpanded,
    required this.onToggle,
    required this.child,
  });

  final String title;
  final bool isExpanded;
  final VoidCallback onToggle;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final c = context.appColors;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: ClipRRect(
        borderRadius: const BorderRadius.all(Radius.circular(14)),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: c.surface1,
            borderRadius: const BorderRadius.all(Radius.circular(14)),
            border: Border.all(color: c.border1),
          ),
          child: Column(
            children: [
              InkWell(
                onTap: onToggle,
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md,
                    vertical: 12,
                  ),
                  child: Row(
                    children: [
                      Text(
                        title,
                        style: AppTextStyle.bodySmall.copyWith(
                          color: c.fgShade400,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const Spacer(),
                      AnimatedRotation(
                        turns: isExpanded ? 0.5 : 0,
                        duration: AppAnimation.fast,
                        child: Icon(
                          Icons.keyboard_arrow_down_rounded,
                          color: c.fgShade200,
                          size: AppSpacing.md + 4,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              if (isExpanded)
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.md,
                    0,
                    AppSpacing.md,
                    AppSpacing.md,
                  ),
                  child: child,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

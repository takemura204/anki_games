part of '../note_sheet.dart';

class _Header extends StatelessWidget {
  const _Header({
    required this.isDetail,
    required this.onClose,
    required this.onBack,
    required this.onBookmark,
    required this.isBookmarked,
    required this.current,
    required this.total,
  });

  final bool isDetail;
  final VoidCallback onClose;
  final VoidCallback onBack;
  final VoidCallback onBookmark;
  final bool isBookmarked;
  final int current;
  final int total;

  @override
  Widget build(BuildContext context) {
    final c = context.appColors;

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        AppSpacing.md,
        AppSpacing.md,
        AppSpacing.xs,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          if (isDetail)
            GlassButton(
              cardRadius: AppBorderRadius.circle,
              child: IconButton(
                icon: Icon(AppIcons.back, color: c.fgShade400),
                onPressed: onBack.withHaptic(),
              ),
            )
          else
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(AppIcons.note, color: c.fgShade400),
                const Gap(AppSpacing.xs),
                Text(
                  'ノート',
                  style: AppTextStyle.titleLarge.copyWith(
                    color: c.fgShade400,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0,
                  ),
                ),
              ],
            ),
          if (isDetail)
            SizedBox(
              width: 140,
              child: GlassContainer(
                cardRadius: AppBorderRadius.circle,
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.sm,
                  vertical: AppSpacing.sm,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '$current/$total',
                      style: AppTextStyle.labelLarge.copyWith(
                        color: c.fgShade400,
                        letterSpacing: 0,
                      ),
                    ),
                    const Gap(AppSpacing.sm),
                    Expanded(
                      child: ClipRRect(
                        borderRadius: AppBorderRadius.circle,
                        child: TweenAnimationBuilder<double>(
                          tween: Tween<double>(
                            end: total > 0 ? current / total : 0,
                          ),
                          duration: AppAnimation.slow,
                          curve: Curves.easeOutCubic,
                          builder: (context, value, _) {
                            return LinearProgressIndicator(
                              value: value,
                              backgroundColor: c.fgShade50,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                c.fgShade400,
                              ),
                              minHeight: AppSpacing.sm,
                            );
                          },
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          if (isDetail)
            GlassButton(
              cardRadius: AppBorderRadius.circle,
              child: IconButton(
                icon: Icon(
                  isBookmarked ? AppIcons.bookmarked : AppIcons.bookmark,
                  color: isBookmarked ? AppPalette.seed : c.fgShade300,
                ),
                onPressed: onBookmark.withHaptic(),
              ),
            )
          else
            GlassButton(
              cardRadius: AppBorderRadius.circle,
              child: IconButton(
                icon: Icon(AppIcons.close, color: c.fgShade300),
                onPressed: onClose.withHaptic(),
              ),
            ),
        ],
      ),
    );
  }
}

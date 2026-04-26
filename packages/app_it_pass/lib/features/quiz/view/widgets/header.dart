part of '../quiz_screen.dart';

class _Header extends StatelessWidget {
  const _Header({
    required this.cardRadius,
    required this.session,
    required this.onTapSetting,
    required this.onTapFilter,
    this.centerLabel,
    this.showCenter = true,
  });

  final BorderRadius cardRadius;
  final QuizSession session;
  final VoidCallback onTapSetting;
  final VoidCallback onTapFilter;
  final String? centerLabel;
  final bool showCenter;

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.of(context).padding.top;
    final c = context.appColors;

    return Padding(
      padding: EdgeInsets.only(
        left: AppSpacing.md,
        right: AppSpacing.md,
        top: top + 12,
        bottom: AppSpacing.md + 4,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          GlassButton(
            cardRadius: cardRadius,
            child: IconButton(
              padding: EdgeInsets.zero,
              icon: Icon(
                AppIcons.account,
                color: c.fgShade400,
                size: 22,
              ),
              onPressed: onTapSetting,
            ),
          ),
          if (showCenter)
            GlassContainer(
              cardRadius: cardRadius,
              padding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: AppSpacing.sm,
              ),
              width: 140,
              child: centerLabel != null
                  ? Text(
                      centerLabel!,
                      style: AppTextStyle.labelLarge.copyWith(
                        color: c.fg,
                        letterSpacing: 0,
                      ),
                      textAlign: TextAlign.center,
                    )
                  : Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '${session.indexInSet + 1}/${session.totalCount}',
                          style: AppTextStyle.labelLarge.copyWith(
                            color: c.fgShade400,
                            letterSpacing: 0,
                          ),
                        ),
                        const Gap(AppSpacing.sm),
                        Expanded(
                          child: ClipRRect(
                            borderRadius: AppBorderRadius.sm -
                                const BorderRadius.all(Radius.circular(4)),
                            child: TweenAnimationBuilder<double>(
                              tween: Tween<double>(
                                end: session.totalCount > 0
                                    ? (session.indexInSet + 1) /
                                        session.totalCount
                                    : 0,
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
          GlassButton(
            cardRadius: cardRadius,
            child: IconButton(
              iconSize: 22,
              padding: EdgeInsets.zero,
              color: c.fgShade400,
              icon: const Icon(AppIcons.filter),
              onPressed: onTapFilter,
            ),
          ),
        ],
      ),
    );
  }
}

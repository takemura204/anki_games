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
  final QuizSession? session;
  final VoidCallback onTapSetting;
  final VoidCallback onTapFilter;
  final String? centerLabel;
  final bool showCenter;

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.of(context).padding.top;
    final c = context.appColors;
    final currentSession = session;

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
                  : currentSession == null
                      ? const _ProgressSkeleton()
                      : _ProgressContent(session: currentSession),
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

class _ProgressContent extends StatelessWidget {
  const _ProgressContent({required this.session});

  final QuizSession session;

  @override
  Widget build(BuildContext context) {
    final c = context.appColors;
    return Row(
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
            borderRadius:
                AppBorderRadius.sm - const BorderRadius.all(Radius.circular(4)),
            child: TweenAnimationBuilder<double>(
              tween: Tween<double>(
                end: session.totalCount > 0
                    ? (session.indexInSet + 1) / session.totalCount
                    : 0,
              ),
              duration: AppAnimation.slow,
              curve: Curves.easeOutCubic,
              builder: (context, value, _) {
                return LinearProgressIndicator(
                  value: value,
                  backgroundColor: c.fgShade50,
                  valueColor: AlwaysStoppedAnimation<Color>(c.fgShade400),
                  minHeight: AppSpacing.sm,
                );
              },
            ),
          ),
        ),
      ],
    );
  }
}

class _ProgressSkeleton extends StatelessWidget {
  const _ProgressSkeleton();

  @override
  Widget build(BuildContext context) {
    final c = context.appColors;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 36,
          height: 12,
          decoration: BoxDecoration(
            color: c.fgShade50,
            borderRadius: AppBorderRadius.full,
          ),
        ),
        const Gap(AppSpacing.sm),
        Expanded(
          child: ClipRRect(
            borderRadius:
                AppBorderRadius.sm - const BorderRadius.all(Radius.circular(4)),
            child: LinearProgressIndicator(
              value: null,
              backgroundColor: c.fgShade50,
              valueColor: AlwaysStoppedAnimation<Color>(c.fgShade100),
              minHeight: AppSpacing.sm,
            ),
          ),
        ),
      ],
    );
  }
}

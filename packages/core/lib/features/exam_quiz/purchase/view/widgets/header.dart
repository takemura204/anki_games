part of '../paywall_sheet.dart';

class _Header extends StatelessWidget {
  const _Header({required this.c, required this.colorScheme});
  final AppColorScheme c;
  final ColorScheme colorScheme;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        GlassContainer(
          padding: const EdgeInsets.all(AppSpacing.sm),
          cardRadius: AppBorderRadius.circle,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.workspace_premium_rounded,
                size: 20,
                color: c.fgShade400,
              ),
              const Gap(AppSpacing.xs),
              Text(
                'Premium',
                style: AppTextStyle.titleSmall.copyWith(
                  color: c.fgShade400,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
        const Gap(AppSpacing.md),
        Text(
          '本気で勉強したい人向けのプラン',
          style: AppTextStyle.labelLarge.copyWith(color: c.fg),
        ),
      ],
    );
  }
}

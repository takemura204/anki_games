part of '../paywall_sheet.dart';

class _Header extends StatelessWidget {
  const _Header({required this.c, required this.colorScheme});
  final ItPassColorScheme c;
  final ColorScheme colorScheme;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(Icons.workspace_premium_rounded, size: 32, color: c.fg),
        const Gap(AppSpacing.xs),
        Text(
          'Premium',
          style: AppTextStyle.titleLarge.copyWith(
            color: c.fg,
            fontWeight: FontWeight.w700,
          ),
        ),
        const Gap(AppSpacing.xs),
        Text(
          '本気で勉強したい人向けのプラン',
          style: AppTextStyle.labelMedium.copyWith(color: c.fg),
        ),
      ],
    );
  }
}

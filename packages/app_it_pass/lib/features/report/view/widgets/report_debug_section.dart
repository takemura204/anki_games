part of '../report_sheet.dart';

class _DebugSection extends ConsumerWidget {
  const _DebugSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.appColors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'DEBUG',
          style: AppTextStyle.labelMedium.copyWith(
            color: c.fgShade200,
          ),
        ),
        const Gap(AppSpacing.sm),
        GlassContainer(
          cardRadius: BorderRadius.circular(16),
          child: ListTile(
            leading: Icon(
              Icons.notifications_outlined,
              color: c.fgShade400,
            ),
            title: Text(
              'ストリークバナーを表示',
              style: AppTextStyle.bodyMedium.copyWith(color: c.fg),
            ),
            trailing: Icon(
              Icons.chevron_right,
              color: c.fgShade300,
            ),
            onTap: () {
              ref.read(streakViewModelProvider.notifier).showBannerForDebug();
            },
          ),
        ),
      ],
    );
  }
}

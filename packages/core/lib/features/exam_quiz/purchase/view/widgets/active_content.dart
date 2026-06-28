part of '../paywall_sheet.dart';

class _ActiveContent extends StatelessWidget {
  const _ActiveContent({
    required this.c,
    required this.colorScheme,
    required this.expirationAsync,
    required this.onClose,
  });
  final AppColorScheme c;
  final ColorScheme colorScheme;
  final AsyncValue<String?> expirationAsync;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final expDate = expirationAsync.asData?.value;
    final manageUrl = Platform.isIOS
        ? 'itms-apps://apps.apple.com/account/subscriptions'
        : 'https://play.google.com/store/account/subscriptions';
    final c = context.appColors;

    return Column(
      children: [
        GlassContainer(
          cardRadius: AppBorderRadius.md,
          padding: const EdgeInsets.symmetric(
            vertical: AppSpacing.md,
            horizontal: AppSpacing.md,
          ),
          child: Column(
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.check_circle_rounded,
                    color: ItPassColors.seed,
                    size: 20,
                  ),
                  const Gap(AppSpacing.sm),
                  Text(
                    'Premium 有効中',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: c.fg,
                    ),
                  ),
                ],
              ),
              if (expDate != null) ...[
                const Gap(10),
                Divider(color: c.border1, height: 1),
                const Gap(10),
                Row(
                  children: [
                    Icon(
                      Icons.autorenew_rounded,
                      size: 14,
                      color: c.fgShade300,
                    ),
                    const Gap(6),
                    Text(
                      '次回更新日',
                      style: TextStyle(fontSize: 12, color: c.fgShade300),
                    ),
                    const Spacer(),
                    Text(
                      expDate,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: c.fg,
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
        const Gap(10),
        SizedBox(
          width: double.infinity,
          child: TextButton.icon(
            onPressed: () => launchUrl(
              Uri.parse(manageUrl),
              mode: LaunchMode.externalApplication,
            ),
            icon: Icon(
              Icons.open_in_new_rounded,
              size: 14,
              color: c.fgShade300,
            ),
            label: Text(
              Platform.isIOS ? 'App Store で購読を管理する' : 'Google Play で購読を管理する',
              style: TextStyle(fontSize: 12, color: c.fgShade300),
            ),
          ),
        ),
      ],
    );
  }
}

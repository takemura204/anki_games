part of '../paywall_sheet.dart';

class _ActiveContent extends StatelessWidget {
  const _ActiveContent({
    required this.c,
    required this.colorScheme,
    required this.expirationAsync,
    required this.onClose,
  });
  final ItPassColorScheme c;
  final ColorScheme colorScheme;
  final AsyncValue<String?> expirationAsync;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final expDate = expirationAsync.asData?.value;
    final manageUrl = Platform.isIOS
        ? 'itms-apps://apps.apple.com/account/subscriptions'
        : 'https://play.google.com/store/account/subscriptions';

    return Column(
      children: [
        GlassContainer(
          cardRadius: BorderRadius.circular(14),
          padding: const EdgeInsets.all(14),
          child: Column(
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.check_circle_rounded,
                    color: Colors.green,
                    size: 20,
                  ),
                  const Gap(10),
                  Expanded(
                    child: Text(
                      t.premium.activeBadge,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.green,
                      ),
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
              Platform.isIOS
                  ? 'App Store で購読を管理する'
                  : 'Google Play で購読を管理する',
              style: TextStyle(fontSize: 12, color: c.fgShade300),
            ),
          ),
        ),
        const Gap(4),
        SizedBox(
          width: double.infinity,
          child: FilledButton(onPressed: onClose, child: Text(t.common.ok)),
        ),
      ],
    );
  }
}

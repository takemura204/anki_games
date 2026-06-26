part of '../paywall_sheet.dart';

class _CTASection extends StatelessWidget {
  const _CTASection({
    required this.c,
    required this.selectedPlan,
    required this.monthlyPriceAsync,
    required this.lifetimePriceAsync,
    required this.isLoading,
    required this.bottomPadding,
    required this.onPurchase,
    required this.onRestore,
  });
  final ItPassColorScheme c;
  final _Plan selectedPlan;
  final AsyncValue<String?> monthlyPriceAsync;
  final AsyncValue<String?> lifetimePriceAsync;
  final ValueNotifier<bool> isLoading;
  final double bottomPadding;
  final VoidCallback onPurchase;
  final VoidCallback onRestore;

  @override
  Widget build(BuildContext context) {
    final priceAsync = selectedPlan == _Plan.monthly
        ? monthlyPriceAsync
        : lifetimePriceAsync;
    final isPriceLoading = priceAsync.isLoading || isLoading.value;
    final canPurchase = !isPriceLoading;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        PrimaryButton(
          label: 'プレミアムを体験する',
          onPressed: canPurchase ? onPurchase : null,
          isLoading: isPriceLoading,
          height: 60,
        ),
        const Gap(AppSpacing.md),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _SmallLink(label: t.premium.restoreButton, onTap: onRestore, c: c),
            Text('·', style: TextStyle(fontSize: 11, color: c.fgShade200)),
            _SmallLink(
              label: t.premium.terms,
              onTap: () => launchUrl(
                Uri.parse(AppUrls.termsOfService),
                mode: LaunchMode.inAppWebView,
              ),
              c: c,
            ),
            Text('·', style: TextStyle(fontSize: 11, color: c.fgShade200)),
            _SmallLink(
              label: t.premium.privacy,
              onTap: () => launchUrl(
                Uri.parse(AppUrls.privacyPolicy),
                mode: LaunchMode.inAppWebView,
              ),
              c: c,
            ),
          ],
        ),
      ],
    );
  }
}

class _SmallLink extends StatelessWidget {
  const _SmallLink({required this.label, required this.onTap, required this.c});
  final String label;
  final VoidCallback onTap;
  final ItPassColorScheme c;

  @override
  Widget build(BuildContext context) {
    return TextButton(
      onPressed: onTap,
      style: TextButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 6),
        minimumSize: Size.zero,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
      child: Text(label, style: TextStyle(fontSize: 11, color: c.fgShade300)),
    );
  }
}

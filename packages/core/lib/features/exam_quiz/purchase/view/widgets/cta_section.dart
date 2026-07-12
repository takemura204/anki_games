part of '../paywall_sheet.dart';

class _CTASection extends StatelessWidget {
  const _CTASection({
    required this.c,
    required this.selectedPlan,
    required this.pricingAsync,
    required this.saleMode,
    required this.isLoading,
    required this.onPurchase,
    required this.onRestore,
  });
  final AppColorScheme c;
  final PlanType selectedPlan;
  final AsyncValue<Pricing> pricingAsync;
  final bool saleMode;
  final ValueNotifier<bool> isLoading;
  final VoidCallback onPurchase;
  final VoidCallback onRestore;

  @override
  Widget build(BuildContext context) {
    final isPriceLoading = pricingAsync.isLoading || isLoading.value;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        PrimaryButton(
          label: saleMode ? 'セール価格で始める' : 'プレミアムを体験する',
          onPressed: isPriceLoading ? null : onPurchase,
          isLoading: isPriceLoading,
          height: 60,
        ),
        const Gap(AppSpacing.md),
        Text(
          t.premium.subscriptionDisclosure,
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 8, color: c.fgShade300),
        ),
        const Gap(AppSpacing.sm),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _SmallLink(label: t.premium.restoreButton, onTap: onRestore, c: c),
            Text('·', style: TextStyle(fontSize: 11, color: c.fgShade200)),
            _SmallLink(
              label: t.premium.terms,
              onTap: () => launchUrl(
                Uri.parse(AppUrls.termsOfService),
                mode: LaunchMode.externalApplication,
              ),
              c: c,
            ),
            Text('·', style: TextStyle(fontSize: 11, color: c.fgShade200)),
            _SmallLink(
              label: t.premium.eula,
              onTap: () => launchUrl(
                Uri.parse(AppUrls.appleStandardEula),
                mode: LaunchMode.externalApplication,
              ),
              c: c,
            ),
            Text('·', style: TextStyle(fontSize: 11, color: c.fgShade200)),
            _SmallLink(
              label: t.premium.privacy,
              onTap: () => launchUrl(
                Uri.parse(AppUrls.privacyPolicy),
                mode: LaunchMode.externalApplication,
              ),
              c: c,
            ),
          ],
        ),
        const Gap(AppSpacing.sm),
      ],
    );
  }
}

class _SmallLink extends StatelessWidget {
  const _SmallLink({required this.label, required this.onTap, required this.c});
  final String label;
  final VoidCallback onTap;
  final AppColorScheme c;

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

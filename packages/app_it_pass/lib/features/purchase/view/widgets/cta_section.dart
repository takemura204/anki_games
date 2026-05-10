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
        ClipRRect(
          borderRadius: AppBorderRadius.lg,
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: canPurchase
                  ? onPurchase.withHaptic(HapticType.medium)
                  : null,
              splashColor: Colors.white.withValues(alpha: 0.15),
              highlightColor: Colors.white.withValues(alpha: 0.05),
              child: AnimatedContainer(
                duration: AppAnimation.fast,
                height: 60,
                width: double.infinity,
                decoration: BoxDecoration(
                  gradient: canPurchase
                      ? const LinearGradient(
                          colors: [
                            AppColors.itPassSeed,
                            AppColors.itPassAccent,
                          ],
                        )
                      : null,
                  color: canPurchase ? null : c.surface2,
                  borderRadius: AppBorderRadius.lg,
                ),
                child: Center(
                  child: isPriceLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : Text(
                          'プレミアムを体験する',
                          style: AppTextStyle.titleMedium.copyWith(
                            color: Colors.white,
                            letterSpacing: 0.5,
                          ),
                        ),
                ),
              ),
            ),
          ),
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

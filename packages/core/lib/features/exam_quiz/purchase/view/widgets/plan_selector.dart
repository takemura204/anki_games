part of '../paywall_sheet.dart';

class _PlanSelector extends StatelessWidget {
  const _PlanSelector({
    required this.c,
    required this.selectedPlan,
    required this.pricingAsync,
    required this.saleMode,
    required this.recommendedPlan,
    required this.onSelect,
  });
  final AppColorScheme c;
  final PlanType selectedPlan;
  final AsyncValue<Pricing> pricingAsync;
  final bool saleMode;
  final PlanType recommendedPlan;
  final void Function(PlanType) onSelect;

  @override
  Widget build(BuildContext context) {
    final pricing = pricingAsync.asData?.value ?? const Pricing();
    final isLoading = pricingAsync.isLoading;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
      child: GlassButton(
        cardRadius: AppBorderRadius.md,
        child: Column(
          children: [
            _PlanRow(
              title: '1ヶ月プラン',
              subtitle: '毎月更新。いつでもキャンセル可能。',
              normalPrice: pricing.monthlyNormal,
              salePrice: saleMode ? pricing.monthlySale : null,
              discountBadge: saleMode && pricing.monthlyDiscountPercent != null
                  ? '${pricing.monthlyDiscountPercent}% OFF'
                  : null,
              isSelected: selectedPlan == PlanType.monthly,
              isRecommended: recommendedPlan == PlanType.monthly,
              onTap: () => onSelect(PlanType.monthly),
              c: c,
              isLoading: isLoading,
              priceSuffix: '月',
            ),
            Divider(
              height: 1,
              indent: 14,
              endIndent: 14,
              color: c.fgShade50,
            ),
            _PlanRow(
              title: '買い切りプラン',
              subtitle: '合格まで使い放題。追加課金なし。',
              normalPrice: pricing.lifetimeNormal,
              salePrice: saleMode ? pricing.lifetimeSale : null,
              discountBadge: saleMode && pricing.lifetimeDiscountAmount != null
                  ? pricing.lifetimeDiscountAmount
                  : null,
              isSelected: selectedPlan == PlanType.lifetime,
              isRecommended: recommendedPlan == PlanType.lifetime,
              onTap: () => onSelect(PlanType.lifetime),
              c: c,
              isLoading: isLoading,
            ),
          ],
        ),
      ),
    );
  }
}

class _PlanRow extends StatelessWidget {
  const _PlanRow({
    required this.title,
    required this.subtitle,
    required this.normalPrice,
    required this.isSelected,
    required this.isRecommended,
    required this.onTap,
    required this.c,
    required this.isLoading,
    this.salePrice,
    this.discountBadge,
    this.priceSuffix,
  });
  final String title;
  final String subtitle;
  final String? normalPrice;
  final String? salePrice;
  final String? discountBadge;
  final bool isSelected;
  final bool isRecommended;
  final VoidCallback onTap;
  final AppColorScheme c;
  final bool isLoading;
  final String? priceSuffix;

  String get _displaySuffix => priceSuffix != null ? '/$priceSuffix' : '';
  bool get _hasDiscount =>
      salePrice != null && normalPrice != null && salePrice != normalPrice;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap.withHaptic(HapticType.selection),
      child: AnimatedContainer(
        duration: AppAnimation.fast,
        decoration: BoxDecoration(
          color: isSelected
              ? AppPalette.seed.withValues(alpha: 0.1)
              : Colors.transparent,
          border: Border.all(
            color: isSelected ? AppPalette.seed : Colors.transparent,
            width: 1.5,
          ),
          borderRadius: AppBorderRadius.md,
        ),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.md,
        ),
        child: Row(
          children: [
            AnimatedSwitcher(
              duration: AppAnimation.fast,
              child: isSelected
                  ? const Icon(
                      Icons.check_circle_rounded,
                      key: ValueKey('checked'),
                      size: 22,
                      color: AppPalette.seed,
                    )
                  : Icon(
                      Icons.radio_button_unchecked_rounded,
                      key: const ValueKey('unchecked'),
                      size: 22,
                      color: c.fgShade200,
                    ),
            ),
            const Gap(12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        title,
                        style: AppTextStyle.titleSmall.copyWith(
                          fontWeight: FontWeight.bold,
                          color: c.fg,
                        ),
                      ),
                      if (isRecommended && discountBadge == null) ...[
                        const Gap(6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: c.fg,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            'おすすめ',
                            style: AppTextStyle.labelSmall.copyWith(
                              color: AppPalette.seed,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                      if (discountBadge != null) ...[
                        const Gap(6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.orange.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(
                              color: Colors.orange.withValues(alpha: 0.5),
                            ),
                          ),
                          child: Text(
                            discountBadge!,
                            style: AppTextStyle.labelSmall.copyWith(
                              color: Colors.orange.shade800,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  Text(
                    subtitle,
                    style: AppTextStyle.labelSmall.copyWith(
                      color: c.fgShade400,
                    ),
                  ),
                ],
              ),
            ),
            if (isLoading)
              SizedBox(
                width: 14,
                height: 14,
                child: CircularProgressIndicator(strokeWidth: 1.5, color: c.fg),
              )
            else
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  if (_hasDiscount) ...[
                    Text(
                      '$normalPrice$_displaySuffix',
                      style: AppTextStyle.labelSmall.copyWith(
                        color: c.fgShade300,
                        decoration: TextDecoration.lineThrough,
                        decorationColor: c.fgShade300,
                      ),
                    ),
                    Text(
                      '${salePrice!}$_displaySuffix',
                      style: AppTextStyle.titleMedium.copyWith(
                        color: c.fg,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ] else
                    Text(
                      (salePrice ?? normalPrice) != null
                          ? '${salePrice ?? normalPrice}$_displaySuffix'
                          : '---',
                      style: AppTextStyle.titleMedium.copyWith(
                        color: c.fg,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}

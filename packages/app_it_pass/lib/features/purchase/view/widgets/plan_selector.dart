part of '../paywall_sheet.dart';

class _PlanSelector extends StatelessWidget {
  const _PlanSelector({
    required this.c,
    required this.selectedPlan,
    required this.monthlyPriceAsync,
    required this.lifetimePriceAsync,
    required this.onSelect,
  });
  final ItPassColorScheme c;
  final _Plan selectedPlan;
  final AsyncValue<String?> monthlyPriceAsync;
  final AsyncValue<String?> lifetimePriceAsync;
  final void Function(_Plan) onSelect;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
      child: GlassButton(
        cardRadius: AppBorderRadius.md,
        child: Column(
          children: [
            _PlanRow(
              title: '1ヶ月プラン',
              subtitle: '毎月自動更新。いつでもキャンセル可能。',
              priceAsync: monthlyPriceAsync,
              isSelected: selectedPlan == _Plan.monthly,
              onTap: () => onSelect(_Plan.monthly),
              c: c,
              priceSuffix: '月',
            ),
            Divider(height: 1, indent: 14, endIndent: 14, color: c.fgShade50),
            _PlanRow(
              title: '買い切りプラン',
              subtitle: '１度切りのお支払い。無制限に利用可能。',
              priceAsync: lifetimePriceAsync,
              isSelected: selectedPlan == _Plan.lifetime,
              onTap: () => onSelect(_Plan.lifetime),
              c: c,
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
    required this.priceAsync,
    required this.isSelected,
    required this.onTap,
    required this.c,
    this.priceSuffix,
  });
  final String title;
  final String subtitle;
  final AsyncValue<String?> priceAsync;
  final bool isSelected;
  final VoidCallback onTap;
  final ItPassColorScheme c;
  final String? priceSuffix;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap.withHaptic(HapticType.selection),
      child: AnimatedContainer(
        duration: AppAnimation.fast,
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.itPassSeed.withValues(alpha: 0.1)
              : Colors.transparent,
          border: Border.all(
            color: isSelected ? AppColors.itPassSeed : Colors.transparent,
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
                  ? Icon(
                      Icons.check_circle_rounded,
                      key: const ValueKey('checked'),
                      size: 22,
                      color: AppColors.itPassSeed,
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
                  Text(
                    title,
                    style: AppTextStyle.titleSmall.copyWith(
                      fontWeight: FontWeight.bold,
                      color: c.fg,
                    ),
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
            if (priceAsync.isLoading)
              SizedBox(
                width: 14,
                height: 14,
                child: CircularProgressIndicator(strokeWidth: 1.5, color: c.fg),
              )
            else ...[
              Text(
                priceAsync.asData?.value != null
                    ? '${priceAsync.asData!.value}'
                    : '---',
                style: AppTextStyle.titleMedium.copyWith(
                  color: c.fg,
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (priceSuffix != null) ...[
                const Gap(AppSpacing.xs),
                Text(
                  '/$priceSuffix',
                  style: AppTextStyle.labelMedium.copyWith(color: c.fgShade400),
                ),
              ],
            ],
          ],
        ),
      ),
    );
  }
}

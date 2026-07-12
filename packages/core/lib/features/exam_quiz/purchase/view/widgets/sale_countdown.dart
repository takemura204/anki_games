import 'package:core/config/brand/app_color_scheme.dart';
import 'package:core/config/styles/app_text_style.dart';
import 'package:core/features/purchase/model/plan_type.dart';
import 'package:core/features/purchase/model/pricing.dart';
import 'package:flutter/material.dart';
import 'package:gap/gap.dart';

/// 通常価格（打ち消し線）→ セール価格を表示する行。
class SalePriceRow extends StatelessWidget {
  const SalePriceRow({
    super.key,
    required this.pricing,
    required this.plan,
    required this.c,
  });

  final Pricing pricing;
  final PlanType plan;
  final AppColorScheme c;

  @override
  Widget build(BuildContext context) {
    final normalPrice = plan == PlanType.monthly
        ? pricing.monthlyNormal
        : pricing.lifetimeNormal;
    final salePrice = plan == PlanType.monthly
        ? pricing.monthlySale
        : pricing.lifetimeSale;
    final hasDiscount = plan == PlanType.monthly
        ? pricing.hasMonthlyDiscount
        : pricing.hasLifetimeDiscount;
    final suffix = plan == PlanType.monthly ? '/月' : '';

    if (salePrice == null) return const SizedBox.shrink();

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (hasDiscount && normalPrice != null) ...[
          Text(
            '$normalPrice$suffix',
            style: AppTextStyle.bodySmall.copyWith(
              color: c.fgShade300,
              decoration: TextDecoration.lineThrough,
              decorationColor: c.fgShade300,
            ),
          ),
          const Gap(6),
          Text('→', style: AppTextStyle.bodySmall.copyWith(color: c.fgShade400)),
          const Gap(6),
        ],
        Text(
          '$salePrice$suffix',
          style: AppTextStyle.titleMedium.copyWith(
            color: c.fg,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}

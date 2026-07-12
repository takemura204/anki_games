import 'package:core/components/glass_widget.dart';
import 'package:core/config/styles/app_border_radius.dart';
import 'package:core/config/styles/app_spacing.dart';
import 'package:core/features/admob/admob_banner.dart';
import 'package:core/features/admob/admob_native.dart';
import 'package:core/features/purchase/view_model/premium_view_model.dart';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

/// GlassContainer + AdmobNative のまとまり。
/// プレミアム時は GlassContainer ごと非表示になる。
///
/// [isPremium] を指定するとプロバイダーを参照しない（テスト向け）。
class AdmobNativeGlass extends ConsumerWidget {
  const AdmobNativeGlass({
    super.key,
    this.templateType = TemplateType.medium,
    this.height,
    this.isPremium,
  });

  final TemplateType templateType;
  final double? height;

  /// null の場合は [premiumViewModelProvider] を参照する。
  final bool? isPremium;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final premium = isPremium ??
        (ref.watch(premiumViewModelProvider).asData?.value.isPremium ?? false);
    if (premium) return const SizedBox.shrink();

    return GlassContainer(
      cardRadius: AppBorderRadius.md,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.sm,
      ),
      child: AdmobNative(templateType: templateType, height: height),
    );
  }
}

/// GlassContainer + AdmobBanner のまとまり。
/// プレミアム時は GlassContainer ごと非表示になる。
///
/// [isPremium] を指定するとプロバイダーを参照しない（テスト向け）。
class AdmobBannerGlass extends ConsumerWidget {
  const AdmobBannerGlass({super.key, this.isPremium});

  /// null の場合は [premiumViewModelProvider] を参照する。
  final bool? isPremium;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final premium = isPremium ??
        (ref.watch(premiumViewModelProvider).asData?.value.isPremium ?? false);
    if (premium) return const SizedBox.shrink();

    return const GlassContainer(
      cardRadius: AppBorderRadius.md,
      padding: EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.sm,
      ),
      child: AdmobBanner(),
    );
  }
}

import 'package:app_it_pass/config/env/env.dart';
import 'package:core/config/ads/ad_config.dart';
import 'package:core/config/brand/app_color_scheme.dart';
import 'package:core/config/brand/brand_config.dart';
import 'package:core/config/brand/store_ids.dart';
import 'package:core/features/purchase/model/revenue_cat_config.dart';
import 'package:flutter/material.dart';

class ItPassBrandConfig extends BrandConfig {
  const ItPassBrandConfig();

  @override
  String get appName => 'ITパスポート';

  @override
  String get analyticsBrandKey => 'it_pass';

  @override
  Color get seedColor => AppPalette.seed;

  @override
  List<ThemeExtension<dynamic>> get darkThemeExtensions => [
    AppColorScheme.dark,
  ];

  @override
  List<ThemeExtension<dynamic>> get lightThemeExtensions => [
    AppColorScheme.light,
  ];

  @override
  AdConfig get adConfig => const AdConfig(
    bannerAndroidDebug: ItPassEnv.bannerAndroidDebug,
    bannerAndroidRelease: ItPassEnv.bannerAndroidRelease,
    bannerIosDebug: ItPassEnv.bannerIosDebug,
    bannerIosRelease: ItPassEnv.bannerIosRelease,
    nativeAndroidDebug: ItPassEnv.nativeAndroidDebug,
    nativeAndroidRelease: ItPassEnv.nativeAndroidRelease,
    nativeIosDebug: ItPassEnv.nativeIosDebug,
    nativeIosRelease: ItPassEnv.nativeIosRelease,
    rewardedAndroidDebug: ItPassEnv.rewardedAndroidDebug,
    rewardedAndroidRelease: ItPassEnv.rewardedAndroidRelease,
    rewardedIosDebug: ItPassEnv.rewardedIosDebug,
    rewardedIosRelease: ItPassEnv.rewardedIosRelease,
    interstitialAndroidDebug: ItPassEnv.interstitialAndroidDebug,
    interstitialAndroidRelease: ItPassEnv.interstitialAndroidRelease,
    interstitialIosDebug: ItPassEnv.interstitialIosDebug,
    interstitialIosRelease: ItPassEnv.interstitialIosRelease,
  );

  @override
  RevenueCatConfig get revenueCatConfig => const RevenueCatConfig(
    apiKeyIos: ItPassEnv.revenueCatApiKeyIos,
    apiKeyAndroid: ItPassEnv.revenueCatApiKeyAndroid,
    premium1mProductId: ItPassEnv.premium1m,
    premiumLifetimeProductId: ItPassEnv.premiumLifetime,
    premium1mSaleProductId: ItPassEnv.premium1mSale,
    premiumLifetimeSaleProductId: ItPassEnv.premiumLifetimeSale,
  );

  @override
  StoreIds get storeIds => const StoreIds(
    appStoreId: '6503267015',
    playPackageName: 'jp.tkmr.it_pass',
  );

  @override
  String get introLogoAsset =>
      'packages/core/assets/logo/logo_foreground.svg';

  @override
  String get onboardingLevelAsset =>
      'packages/core/assets/image/onboarding_level.svg';

  @override
  String get onboardingRemindAsset =>
      'packages/core/assets/image/onboarding_remind.svg';
}

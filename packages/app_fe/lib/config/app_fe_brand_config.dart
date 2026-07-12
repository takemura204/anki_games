import 'package:core/config/ads/ad_config.dart';
import 'package:core/config/brand/app_color_scheme.dart';
import 'package:core/config/brand/brand_config.dart';
import 'package:core/config/brand/store_ids.dart';
import 'package:core/features/purchase/model/revenue_cat_config.dart';
import 'package:flutter/material.dart';

class AppFeBrandConfig extends BrandConfig {
  const AppFeBrandConfig();

  @override
  String get appName => '基本情報技術者';

  @override
  String get analyticsBrandKey => 'fe';

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
    bannerAndroidDebug: 'ca-app-pub-3940256099942544/6300978111',
    bannerAndroidRelease: '',
    bannerIosDebug: 'ca-app-pub-3940256099942544/2934735716',
    bannerIosRelease: '',
    nativeAndroidDebug: 'ca-app-pub-3940256099942544/2247696110',
    nativeAndroidRelease: '',
    nativeIosDebug: 'ca-app-pub-3940256099942544/3986624511',
    nativeIosRelease: '',
    rewardedAndroidDebug: 'ca-app-pub-3940256099942544/5224354917',
    rewardedAndroidRelease: '',
    rewardedIosDebug: 'ca-app-pub-3940256099942544/1712485313',
    rewardedIosRelease: '',
    interstitialAndroidDebug: 'ca-app-pub-3940256099942544/1033173712',
    interstitialAndroidRelease: '',
    interstitialIosDebug: 'ca-app-pub-3940256099942544/4560639518',
    interstitialIosRelease: '',
  );

  @override
  RevenueCatConfig get revenueCatConfig => const RevenueCatConfig(
    apiKeyIos: '',
    apiKeyAndroid: '',
    premium1mProductId: '',
    premiumLifetimeProductId: '',
  );

  @override
  StoreIds get storeIds => const StoreIds(
    appStoreId: '',
    playPackageName: 'jp.tkmr.fe',
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

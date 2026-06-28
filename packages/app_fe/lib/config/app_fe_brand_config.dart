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
  Color get seedColor => ItPassColors.seed;

  @override
  List<ThemeExtension<dynamic>> get darkThemeExtensions =>
      [AppColorScheme.dark];

  @override
  List<ThemeExtension<dynamic>> get lightThemeExtensions =>
      [AppColorScheme.light];

  // TODO(fe): 本番用 AdMob ID に差し替える
  @override
  AdConfig get adConfig => const AdConfig(
        bannerAndroidDebug: 'ca-app-pub-3940256099942544/6300978111',
        bannerAndroidRelease: 'REPLACE_WITH_REAL_ID',
        bannerIosDebug: 'ca-app-pub-3940256099942544/2934735716',
        bannerIosRelease: 'REPLACE_WITH_REAL_ID',
        nativeAndroidDebug: 'ca-app-pub-3940256099942544/2247696110',
        nativeAndroidRelease: 'REPLACE_WITH_REAL_ID',
        nativeIosDebug: 'ca-app-pub-3940256099942544/3986624511',
        nativeIosRelease: 'REPLACE_WITH_REAL_ID',
        rewardedAndroidDebug: 'ca-app-pub-3940256099942544/5224354917',
        rewardedAndroidRelease: 'REPLACE_WITH_REAL_ID',
        rewardedIosDebug: 'ca-app-pub-3940256099942544/1712485313',
        rewardedIosRelease: 'REPLACE_WITH_REAL_ID',
        interstitialAndroidDebug: 'ca-app-pub-3940256099942544/1033173712',
        interstitialAndroidRelease: 'REPLACE_WITH_REAL_ID',
        interstitialIosDebug: 'ca-app-pub-3940256099942544/4560639518',
        interstitialIosRelease: 'REPLACE_WITH_REAL_ID',
      );

  // TODO(fe): RevenueCat キーを設定する
  @override
  RevenueCatConfig get revenueCatConfig => const RevenueCatConfig(
        apiKeyIos: '',
        apiKeyAndroid: '',
        premium1mProductId: '',
        premiumLifetimeProductId: '',
      );

  // TODO(fe): ストア ID を設定する
  @override
  StoreIds get storeIds => const StoreIds(
        appStoreId: 'REPLACE_WITH_APP_STORE_ID',
        playPackageName: 'jp.tkmr.fe',
      );
}

import 'package:envied/envied.dart';

part 'env.g.dart';

/// AdMob / RevenueCat などのシークレット。
///
/// リポジトリ直下の `.gitignore` が `.env` を除外するため、未設定でも
/// `defaultValue`（Google 公式のテスト用広告ユニット等）でコード生成が通る。
/// 本番値は `lib/config/env/.env` に置く（ローカルのみ）。
@Envied(path: 'lib/config/env/.env', requireEnvFile: false)
abstract class Env {
  @EnviedField(
    varName: 'BANNER_AD_UNIT_ID_ANDROID_DEBUG',
    defaultValue: 'ca-app-pub-3940256099942544/6300978111',
  )
  static const String bannerAdUnitIdAndroidDebug =
      _Env.bannerAdUnitIdAndroidDebug;

  @EnviedField(
    varName: 'BANNER_AD_UNIT_ID_ANDROID_RELEASE',
    defaultValue: 'ca-app-pub-3940256099942544/6300978111',
  )
  static const String bannerAdUnitIdAndroidRelease =
      _Env.bannerAdUnitIdAndroidRelease;

  @EnviedField(
    varName: 'BANNER_AD_UNIT_ID_IOS_DEBUG',
    defaultValue: 'ca-app-pub-3940256099942544/2934735716',
  )
  static const String bannerAdUnitIdIosDebug = _Env.bannerAdUnitIdIosDebug;

  @EnviedField(
    varName: 'BANNER_AD_UNIT_ID_IOS_RELEASE',
    defaultValue: 'ca-app-pub-3940256099942544/2934735716',
  )
  static const String bannerAdUnitIdIosRelease = _Env.bannerAdUnitIdIosRelease;

  @EnviedField(
    varName: 'NATIVE_AD_UNIT_ID_ANDROID_DEBUG',
    defaultValue: 'ca-app-pub-3940256099942544/2247696110',
  )
  static const String nativeAdUnitIdAndroidDebug =
      _Env.nativeAdUnitIdAndroidDebug;

  @EnviedField(
    varName: 'NATIVE_AD_UNIT_ID_ANDROID_RELEASE',
    defaultValue: 'ca-app-pub-3940256099942544/2247696110',
  )
  static const String nativeAdUnitIdAndroidRelease =
      _Env.nativeAdUnitIdAndroidRelease;

  @EnviedField(
    varName: 'NATIVE_AD_UNIT_ID_IOS_DEBUG',
    defaultValue: 'ca-app-pub-3940256099942544/3986624511',
  )
  static const String nativeAdUnitIdIosDebug = _Env.nativeAdUnitIdIosDebug;

  @EnviedField(
    varName: 'NATIVE_AD_UNIT_ID_IOS_RELEASE',
    defaultValue: 'ca-app-pub-3940256099942544/3986624511',
  )
  static const String nativeAdUnitIdIosRelease = _Env.nativeAdUnitIdIosRelease;

  @EnviedField(
    varName: 'REWARDED_AD_UNIT_ID_ANDROID_DEBUG',
    defaultValue: 'ca-app-pub-3940256099942544/5224354917',
  )
  static const String rewardedAdUnitIdAndroidDebug =
      _Env.rewardedAdUnitIdAndroidDebug;

  @EnviedField(
    varName: 'REWARDED_AD_UNIT_ID_ANDROID_RELEASE',
    defaultValue: 'ca-app-pub-3940256099942544/5224354917',
  )
  static const String rewardedAdUnitIdAndroidRelease =
      _Env.rewardedAdUnitIdAndroidRelease;

  @EnviedField(
    varName: 'REWARDED_AD_UNIT_ID_IOS_DEBUG',
    defaultValue: 'ca-app-pub-3940256099942544/1712485313',
  )
  static const String rewardedAdUnitIdIosDebug = _Env.rewardedAdUnitIdIosDebug;

  @EnviedField(
    varName: 'REWARDED_AD_UNIT_ID_IOS_RELEASE',
    defaultValue: 'ca-app-pub-3940256099942544/1712485313',
  )
  static const String rewardedAdUnitIdIosRelease =
      _Env.rewardedAdUnitIdIosRelease;

  @EnviedField(
    varName: 'INTERSTITIAL_AD_UNIT_ID_ANDROID_DEBUG',
    defaultValue: 'ca-app-pub-3940256099942544/1033173712',
  )
  static const String interstitialAdUnitIdAndroidDebug =
      _Env.interstitialAdUnitIdAndroidDebug;

  @EnviedField(
    varName: 'INTERSTITIAL_AD_UNIT_ID_ANDROID_RELEASE',
    defaultValue: 'ca-app-pub-3940256099942544/1033173712',
  )
  static const String interstitialAdUnitIdAndroidRelease =
      _Env.interstitialAdUnitIdAndroidRelease;

  @EnviedField(
    varName: 'INTERSTITIAL_AD_UNIT_ID_IOS_DEBUG',
    defaultValue: 'ca-app-pub-3940256099942544/4411468910',
  )
  static const String interstitialAdUnitIdIosDebug =
      _Env.interstitialAdUnitIdIosDebug;

  @EnviedField(
    varName: 'INTERSTITIAL_AD_UNIT_ID_IOS_RELEASE',
    defaultValue: 'ca-app-pub-3940256099942544/4411468910',
  )
  static const String interstitialAdUnitIdIosRelease =
      _Env.interstitialAdUnitIdIosRelease;

  @EnviedField(varName: 'REVENUECAT_API_KEY_IOS', defaultValue: '')
  static const String revenueCatApiKeyIos = _Env.revenueCatApiKeyIos;

  @EnviedField(varName: 'REVENUECAT_API_KEY_ANDROID', defaultValue: '')
  static const String revenueCatApiKeyAndroid = _Env.revenueCatApiKeyAndroid;

  @EnviedField(varName: 'PREMIUM_1M', defaultValue: '')
  static const String premium1m = _Env.premium1m;
}

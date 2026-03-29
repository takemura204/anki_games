import 'package:envied/envied.dart';

part 'env.g.dart';

@Envied(path: 'lib/config/env/.env')
abstract class Env {
  @EnviedField(varName: 'BANNER_AD_UNIT_ID_ANDROID_DEBUG')
  static const String bannerAdUnitIdAndroidDebug =
      _Env.bannerAdUnitIdAndroidDebug;

  @EnviedField(varName: 'BANNER_AD_UNIT_ID_ANDROID_RELEASE')
  static const String bannerAdUnitIdAndroidRelease =
      _Env.bannerAdUnitIdAndroidRelease;

  @EnviedField(varName: 'BANNER_AD_UNIT_ID_IOS_DEBUG')
  static const String bannerAdUnitIdIosDebug = _Env.bannerAdUnitIdIosDebug;

  @EnviedField(varName: 'BANNER_AD_UNIT_ID_IOS_RELEASE')
  static const String bannerAdUnitIdIosRelease = _Env.bannerAdUnitIdIosRelease;

  @EnviedField(varName: 'NATIVE_AD_UNIT_ID_ANDROID_DEBUG')
  static const String nativeAdUnitIdAndroidDebug =
      _Env.nativeAdUnitIdAndroidDebug;

  @EnviedField(varName: 'NATIVE_AD_UNIT_ID_ANDROID_RELEASE')
  static const String nativeAdUnitIdAndroidRelease =
      _Env.nativeAdUnitIdAndroidRelease;

  @EnviedField(varName: 'NATIVE_AD_UNIT_ID_IOS_DEBUG')
  static const String nativeAdUnitIdIosDebug = _Env.nativeAdUnitIdIosDebug;

  @EnviedField(varName: 'NATIVE_AD_UNIT_ID_IOS_RELEASE')
  static const String nativeAdUnitIdIosRelease = _Env.nativeAdUnitIdIosRelease;

  @EnviedField(varName: 'REWARDED_AD_UNIT_ID_ANDROID_DEBUG')
  static const String rewardedAdUnitIdAndroidDebug =
      _Env.rewardedAdUnitIdAndroidDebug;

  @EnviedField(varName: 'REWARDED_AD_UNIT_ID_ANDROID_RELEASE')
  static const String rewardedAdUnitIdAndroidRelease =
      _Env.rewardedAdUnitIdAndroidRelease;

  @EnviedField(varName: 'REWARDED_AD_UNIT_ID_IOS_DEBUG')
  static const String rewardedAdUnitIdIosDebug = _Env.rewardedAdUnitIdIosDebug;

  @EnviedField(varName: 'REWARDED_AD_UNIT_ID_IOS_RELEASE')
  static const String rewardedAdUnitIdIosRelease =
      _Env.rewardedAdUnitIdIosRelease;

  @EnviedField(varName: 'INTERSTITIAL_AD_UNIT_ID_ANDROID_DEBUG')
  static const String interstitialAdUnitIdAndroidDebug =
      _Env.interstitialAdUnitIdAndroidDebug;

  @EnviedField(varName: 'INTERSTITIAL_AD_UNIT_ID_ANDROID_RELEASE')
  static const String interstitialAdUnitIdAndroidRelease =
      _Env.interstitialAdUnitIdAndroidRelease;

  @EnviedField(varName: 'INTERSTITIAL_AD_UNIT_ID_IOS_DEBUG')
  static const String interstitialAdUnitIdIosDebug =
      _Env.interstitialAdUnitIdIosDebug;

  @EnviedField(varName: 'INTERSTITIAL_AD_UNIT_ID_IOS_RELEASE')
  static const String interstitialAdUnitIdIosRelease =
      _Env.interstitialAdUnitIdIosRelease;

  @EnviedField(varName: 'REVENUECAT_API_KEY_IOS')
  static const String revenueCatApiKeyIos = _Env.revenueCatApiKeyIos;

  @EnviedField(varName: 'REVENUECAT_API_KEY_ANDROID')
  static const String revenueCatApiKeyAndroid = _Env.revenueCatApiKeyAndroid;

  @EnviedField(varName: 'PREMIUM_1M')
  static const String premium1m = _Env.premium1m;
}

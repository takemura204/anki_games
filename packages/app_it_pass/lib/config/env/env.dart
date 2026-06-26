import 'package:envied/envied.dart';

part 'env.g.dart';

@Envied(path: 'lib/config/env/.env', requireEnvFile: false)
abstract class ItPassEnv {
  // ── AdMob: Banner ──────────────────────────────────────────────────────────
  @EnviedField(
    varName: 'BANNER_AD_UNIT_ID_ANDROID_DEBUG',
    defaultValue: 'ca-app-pub-6280947803421936/1817497206',
  )
  static const String bannerAndroidDebug = _ItPassEnv.bannerAndroidDebug;

  @EnviedField(
    varName: 'BANNER_AD_UNIT_ID_ANDROID_RELEASE',
    defaultValue: 'ca-app-pub-3940256099942544/6300978111',
  )
  static const String bannerAndroidRelease = _ItPassEnv.bannerAndroidRelease;

  @EnviedField(
    varName: 'BANNER_AD_UNIT_ID_IOS_DEBUG',
    defaultValue: 'ca-app-pub-6280947803421936/3327459385',
  )
  static const String bannerIosDebug = _ItPassEnv.bannerIosDebug;

  @EnviedField(
    varName: 'BANNER_AD_UNIT_ID_IOS_RELEASE',
    defaultValue: 'ca-app-pub-3940256099942544/2934735716',
  )
  static const String bannerIosRelease = _ItPassEnv.bannerIosRelease;

  // ── AdMob: Native ──────────────────────────────────────────────────────────
  @EnviedField(
    varName: 'NATIVE_AD_UNIT_ID_ANDROID_DEBUG',
    defaultValue: 'ca-app-pub-6280947803421936/9795675137',
  )
  static const String nativeAndroidDebug = _ItPassEnv.nativeAndroidDebug;

  @EnviedField(
    varName: 'NATIVE_AD_UNIT_ID_ANDROID_RELEASE',
    defaultValue: 'ca-app-pub-3940256099942544/2247696110',
  )
  static const String nativeAndroidRelease = _ItPassEnv.nativeAndroidRelease;

  @EnviedField(
    varName: 'NATIVE_AD_UNIT_ID_IOS_DEBUG',
    defaultValue: 'ca-app-pub-6280947803421936/2683471872',
  )
  static const String nativeIosDebug = _ItPassEnv.nativeIosDebug;

  @EnviedField(
    varName: 'NATIVE_AD_UNIT_ID_IOS_RELEASE',
    defaultValue: 'ca-app-pub-3940256099942544/3986624511',
  )
  static const String nativeIosRelease = _ItPassEnv.nativeIosRelease;

  // ── AdMob: Rewarded ────────────────────────────────────────────────────────
  @EnviedField(
    varName: 'REWARDED_AD_UNIT_ID_ANDROID_DEBUG',
    defaultValue: 'ca-app-pub-6280947803421936/4543348450',
  )
  static const String rewardedAndroidDebug = _ItPassEnv.rewardedAndroidDebug;

  @EnviedField(
    varName: 'REWARDED_AD_UNIT_ID_ANDROID_RELEASE',
    defaultValue: 'ca-app-pub-3940256099942544/5224354917',
  )
  static const String rewardedAndroidRelease =
      _ItPassEnv.rewardedAndroidRelease;

  @EnviedField(
    varName: 'REWARDED_AD_UNIT_ID_IOS_DEBUG',
    defaultValue: 'ca-app-pub-6280947803421936/7069823880',
  )
  static const String rewardedIosDebug = _ItPassEnv.rewardedIosDebug;

  @EnviedField(
    varName: 'REWARDED_AD_UNIT_ID_IOS_RELEASE',
    defaultValue: 'ca-app-pub-3940256099942544/1712485313',
  )
  static const String rewardedIosRelease = _ItPassEnv.rewardedIosRelease;

  // ── AdMob: Interstitial ────────────────────────────────────────────────────
  @EnviedField(
    varName: 'INTERSTITIAL_AD_UNIT_ID_ANDROID_DEBUG',
    defaultValue: 'ca-app-pub-6280947803421936/6303537126',
  )
  static const String interstitialAndroidDebug =
      _ItPassEnv.interstitialAndroidDebug;

  @EnviedField(
    varName: 'INTERSTITIAL_AD_UNIT_ID_ANDROID_RELEASE',
    defaultValue: 'ca-app-pub-3940256099942544/1033173712',
  )
  static const String interstitialAndroidRelease =
      _ItPassEnv.interstitialAndroidRelease;

  @EnviedField(
    varName: 'INTERSTITIAL_AD_UNIT_ID_IOS_DEBUG',
    defaultValue: 'ca-app-pub-6280947803421936/2304197929',
  )
  static const String interstitialIosDebug = _ItPassEnv.interstitialIosDebug;

  @EnviedField(
    varName: 'INTERSTITIAL_AD_UNIT_ID_IOS_RELEASE',
    defaultValue: 'ca-app-pub-3940256099942544/4560639518',
  )
  static const String interstitialIosRelease =
      _ItPassEnv.interstitialIosRelease;

  // ── RevenueCat ─────────────────────────────────────────────────────────────
  @EnviedField(varName: 'REVENUECAT_API_KEY_IOS', defaultValue: '')
  static const String revenueCatApiKeyIos = _ItPassEnv.revenueCatApiKeyIos;

  @EnviedField(varName: 'REVENUECAT_API_KEY_ANDROID', defaultValue: '')
  static const String revenueCatApiKeyAndroid =
      _ItPassEnv.revenueCatApiKeyAndroid;

  @EnviedField(varName: 'PREMIUM_1M', defaultValue: '')
  static const String premium1m = _ItPassEnv.premium1m;

  @EnviedField(varName: 'PREMIUM_LIFETIME', defaultValue: '')
  static const String premiumLifetime = _ItPassEnv.premiumLifetime;
}

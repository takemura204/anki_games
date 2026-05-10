import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

/// アプリ別の AdMob 広告ユニット ID セット。
///
/// 各アプリの `main.dart` で [adConfigProvider] をオーバーライドして注入する:
/// ```dart
/// adConfigProvider.overrideWithValue(AdConfig(...))
/// ```
class AdConfig {
  const AdConfig({
    required this.bannerAndroidDebug,
    required this.bannerAndroidRelease,
    required this.bannerIosDebug,
    required this.bannerIosRelease,
    required this.nativeAndroidDebug,
    required this.nativeAndroidRelease,
    required this.nativeIosDebug,
    required this.nativeIosRelease,
    required this.rewardedAndroidDebug,
    required this.rewardedAndroidRelease,
    required this.rewardedIosDebug,
    required this.rewardedIosRelease,
    required this.interstitialAndroidDebug,
    required this.interstitialAndroidRelease,
    required this.interstitialIosDebug,
    required this.interstitialIosRelease,
  });

  final String bannerAndroidDebug;
  final String bannerAndroidRelease;
  final String bannerIosDebug;
  final String bannerIosRelease;

  final String nativeAndroidDebug;
  final String nativeAndroidRelease;
  final String nativeIosDebug;
  final String nativeIosRelease;

  final String rewardedAndroidDebug;
  final String rewardedAndroidRelease;
  final String rewardedIosDebug;
  final String rewardedIosRelease;

  final String interstitialAndroidDebug;
  final String interstitialAndroidRelease;
  final String interstitialIosDebug;
  final String interstitialIosRelease;

  String get banner => _resolve(
        androidDebug: bannerAndroidDebug,
        androidRelease: bannerAndroidRelease,
        iosDebug: bannerIosDebug,
        iosRelease: bannerIosRelease,
      );

  String get native => _resolve(
        androidDebug: nativeAndroidDebug,
        androidRelease: nativeAndroidRelease,
        iosDebug: nativeIosDebug,
        iosRelease: nativeIosRelease,
      );

  String get rewarded => _resolve(
        androidDebug: rewardedAndroidDebug,
        androidRelease: rewardedAndroidRelease,
        iosDebug: rewardedIosDebug,
        iosRelease: rewardedIosRelease,
      );

  String get interstitial => _resolve(
        androidDebug: interstitialAndroidDebug,
        androidRelease: interstitialAndroidRelease,
        iosDebug: interstitialIosDebug,
        iosRelease: interstitialIosRelease,
      );

  String _resolve({
    required String androidDebug,
    required String androidRelease,
    required String iosDebug,
    required String iosRelease,
  }) {
    if (Platform.isAndroid) {
      return kDebugMode ? androidDebug : androidRelease;
    }
    return kDebugMode ? iosDebug : iosRelease;
  }
}

/// AdMob 設定プロバイダー。各アプリの `main.dart` で必ずオーバーライドする。
///
/// オーバーライドなしの場合は Google 公式のテスト広告ユニット ID を使用する。
final adConfigProvider = Provider<AdConfig>(
  (ref) => const AdConfig(
    bannerAndroidDebug: 'ca-app-pub-3940256099942544/6300978111',
    bannerAndroidRelease: 'ca-app-pub-3940256099942544/6300978111',
    bannerIosDebug: 'ca-app-pub-3940256099942544/2934735716',
    bannerIosRelease: 'ca-app-pub-3940256099942544/2934735716',
    nativeAndroidDebug: 'ca-app-pub-3940256099942544/2247696110',
    nativeAndroidRelease: 'ca-app-pub-3940256099942544/2247696110',
    nativeIosDebug: 'ca-app-pub-3940256099942544/3986624511',
    nativeIosRelease: 'ca-app-pub-3940256099942544/3986624511',
    rewardedAndroidDebug: 'ca-app-pub-3940256099942544/5224354917',
    rewardedAndroidRelease: 'ca-app-pub-3940256099942544/5224354917',
    rewardedIosDebug: 'ca-app-pub-3940256099942544/1712485313',
    rewardedIosRelease: 'ca-app-pub-3940256099942544/1712485313',
    interstitialAndroidDebug: 'ca-app-pub-3940256099942544/1033173712',
    interstitialAndroidRelease: 'ca-app-pub-3940256099942544/1033173712',
    interstitialIosDebug: 'ca-app-pub-3940256099942544/4560639518',
    interstitialIosRelease: 'ca-app-pub-3940256099942544/4560639518',
  ),
  name: 'adConfigProvider',
);

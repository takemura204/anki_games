import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:mono_games/config/env/env.dart';

/// リワード広告のロードと表示を管理するサービス。
///
/// ウィジェットではなく full-screen API を使用する。
/// [load] でプリロードし、[show] で全画面表示する。
class RewardedAdService {
  RewardedAd? _ad;
  var _isLoaded = false;

  /// 広告がロード済みかどうか。
  bool get isLoaded => _isLoaded;

  static String _adUnitId() {
    if (Platform.isAndroid) {
      return kDebugMode
          ? Env.rewardedAdUnitIdAndroidDebug
          : Env.rewardedAdUnitIdAndroidRelease;
    } else if (Platform.isIOS) {
      return kDebugMode
          ? Env.rewardedAdUnitIdIosDebug
          : Env.rewardedAdUnitIdIosRelease;
    }
    throw UnsupportedError('Unsupported platform');
  }

  /// リワード広告をロードする。
  Future<void> load() {
    return RewardedAd.load(
      adUnitId: _adUnitId(),
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (ad) {
          _ad = ad;
          _isLoaded = true;
        },
        onAdFailedToLoad: (error) {
          _isLoaded = false;
          debugPrint('RewardedAd failed to load: $error');
        },
      ),
    );
  }

  /// 広告を全画面表示する。
  ///
  /// 表示成功なら true を返す。ロード未完了の場合は false を返す。
  /// 広告視聴完了時に [onRewarded] が呼ばれる。
  bool show(OnUserEarnedRewardCallback onRewarded) {
    final ad = _ad;
    if (!_isLoaded || ad == null) {
      return false;
    }
    ad
      ..fullScreenContentCallback = FullScreenContentCallback(
        onAdDismissedFullScreenContent: (a) => a.dispose(),
        onAdFailedToShowFullScreenContent: (a, _) => a.dispose(),
      )
      ..show(onUserEarnedReward: onRewarded);
    _ad = null;
    _isLoaded = false;
    return true;
  }

  /// 広告リソースを解放する。
  void dispose() {
    _ad?.dispose();
    _ad = null;
    _isLoaded = false;
  }
}

import 'dart:io';

import 'package:anki_games/common/config/env/env.dart';
import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

/// インタースティシャル広告のロードと表示を管理するサービス。
///
/// [loadAndShow] を呼ぶとロード後に自動で全画面表示する。
/// 表示後は広告リソースを自動解放する。
class AdmobInterstitial {
  static String _adUnitId() {
    if (Platform.isAndroid) {
      return kDebugMode
          ? Env.interstitialAdUnitIdAndroidDebug
          : Env.interstitialAdUnitIdAndroidRelease;
    } else if (Platform.isIOS) {
      return kDebugMode
          ? Env.interstitialAdUnitIdIosDebug
          : Env.interstitialAdUnitIdIosRelease;
    }
    throw UnsupportedError('Unsupported platform');
  }

  /// 広告をロードし、準備完了後に全画面表示する。
  ///
  /// 広告が閉じられた後に [onDismissed] が呼ばれる。
  /// ロード失敗時は何もしない。
  void loadAndShow({VoidCallback? onDismissed}) {
    InterstitialAd.load(
      adUnitId: _adUnitId(),
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          ad
            ..fullScreenContentCallback = FullScreenContentCallback(
              onAdDismissedFullScreenContent: (a) {
                a.dispose();
                onDismissed?.call();
              },
              onAdFailedToShowFullScreenContent: (a, _) => a.dispose(),
            )
            ..show();
        },
        onAdFailedToLoad: (error) {
          debugPrint('InterstitialAd failed to load: $error');
          onDismissed?.call();
        },
      ),
    );
  }
}

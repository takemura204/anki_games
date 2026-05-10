import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import '../../config/ads/ad_config.dart';

/// インタースティシャル広告のロードと表示を管理するサービス。
///
/// コンストラクタに adConfigProvider から取得した AdConfig を渡す:
/// ```dart
/// AdmobInterstitial(ref.read(adConfigProvider)).loadAndShow();
/// ```
class AdmobInterstitial {
  AdmobInterstitial(this._adConfig);

  final AdConfig _adConfig;

  /// 広告をロードし、準備完了後に全画面表示する。
  ///
  /// 広告が閉じられた後に [onDismissed] が呼ばれる。
  /// ロード失敗時は何もしない。
  void loadAndShow({VoidCallback? onDismissed}) {
    InterstitialAd.load(
      adUnitId: _adConfig.interstitial,
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

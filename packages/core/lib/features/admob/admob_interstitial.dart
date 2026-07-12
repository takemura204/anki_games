import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import '../../config/ads/ad_config.dart';

/// インタースティシャル広告のロードと表示を管理するサービス。
///
/// [preload] で事前ロードしておき、[showIfReady] で即時表示する。
/// 事前ロードなしの従来フローは [loadAndShow] で引き続き使用できる。
class AdmobInterstitial {
  AdmobInterstitial(this._adConfig);

  final AdConfig _adConfig;
  InterstitialAd? _preloadedAd;

  bool get hasPreloadedAd => _preloadedAd != null;

  /// 広告を事前ロードして保持する。
  ///
  /// 既にロード済みの場合は上書きしない。
  void preload() {
    if (_preloadedAd != null) return;
    InterstitialAd.load(
      adUnitId: _adConfig.interstitial,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) => _preloadedAd = ad,
        onAdFailedToLoad: (error) {
          debugPrint('[AdInterstitial] preload failed: $error');
        },
      ),
    );
  }

  /// 事前ロード済み広告を表示する。
  ///
  /// 広告が準備できている場合は全画面表示して `true` を返す。
  /// 広告未準備の場合は何もせず `false` を返す。
  /// 広告を閉じた後または表示失敗時に [onDismissed] が呼ばれる。
  bool showIfReady({VoidCallback? onDismissed}) {
    final ad = _preloadedAd;
    if (ad == null) return false;
    _preloadedAd = null;
    ad
      ..fullScreenContentCallback = FullScreenContentCallback(
        onAdDismissedFullScreenContent: (a) {
          a.dispose();
          onDismissed?.call();
        },
        onAdFailedToShowFullScreenContent: (a, _) {
          a.dispose();
          onDismissed?.call();
        },
      )
      ..show();
    return true;
  }

  /// 広告をロードし、準備完了後に全画面表示する（従来フロー）。
  ///
  /// lifecycle_observer などの既存呼び出し元向けに維持する。
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

  /// 保持中の広告リソースを解放する。
  void dispose() {
    _preloadedAd?.dispose();
    _preloadedAd = null;
  }}

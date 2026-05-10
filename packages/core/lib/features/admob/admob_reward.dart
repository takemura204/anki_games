import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import '../../config/ads/ad_config.dart';

/// リワード広告のロードと表示を管理するサービス。
///
/// コンストラクタに adConfigProvider から取得した AdConfig を渡す:
/// ```dart
/// final _rewardedAdService = RewardedAdService(ref.read(adConfigProvider));
/// ```
class RewardedAdService {
  RewardedAdService(this._adConfig);

  final AdConfig _adConfig;
  RewardedAd? _ad;
  var _isLoaded = false;

  bool get isLoaded => _isLoaded;

  Future<void> load() {
    return RewardedAd.load(
      adUnitId: _adConfig.rewarded,
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

  /// 広告を全画面表示する。ロード未完了の場合は false を返す。
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

  void dispose() {
    _ad?.dispose();
    _ad = null;
    _isLoaded = false;
  }
}

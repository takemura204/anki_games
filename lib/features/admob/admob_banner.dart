import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:mono_games/config/env/env.dart';

/// バナー広告を表示するウィジェット
class AdmobBanner extends StatefulWidget {
  const AdmobBanner({super.key});

  @override
  State<AdmobBanner> createState() => _AdmobBannerState();
}

class _AdmobBannerState extends State<AdmobBanner> {
  BannerAd? _bannerAd;
  var _isAdLoaded = false;
  var _isLoading = false;

  String get _bannerAdUnitId {
    if (Platform.isAndroid) {
      return kDebugMode
          ? Env.bannerAdUnitIdAndroidDebug
          : Env.bannerAdUnitIdAndroidRelease;
    } else if (Platform.isIOS) {
      return kDebugMode
          ? Env.bannerAdUnitIdIosDebug
          : Env.bannerAdUnitIdIosRelease;
    }
    throw UnsupportedError('Unsupported platform');
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    if (_isLoading) {
      return; // すでにロード開始済みなら何もしない
    }
    _isLoading = true;

    final width = MediaQuery.of(context).size.width;

    AdSize.getCurrentOrientationAnchoredAdaptiveBannerAdSize(width.truncate())
        .then((adSize) {
      if (!mounted || adSize == null) {
        return;
      }

      _bannerAd = BannerAd(
        adUnitId: _bannerAdUnitId,
        size: adSize,
        request: const AdRequest(),
        listener: BannerAdListener(
          onAdLoaded: (Ad ad) {
            if (!mounted) {
              return;
            }
            setState(() => _isAdLoaded = true);
          },
          onAdFailedToLoad: (Ad ad, LoadAdError error) {
            ad.dispose();
            if (!mounted) {
              return;
            }
            setState(() {
              _bannerAd = null;
              _isAdLoaded = false;
            });
          },
        ),
      )..load();
    });
  }

  @override
  void dispose() {
    _bannerAd?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isAdLoaded && _bannerAd != null) {
      return SizedBox(
        width: _bannerAd!.size.width.toDouble(),
        height: 60,
        child: AdWidget(ad: _bannerAd!),
      );
    }

    // ロード中・未ロード時のプレースホルダ
    return const SizedBox(
      height: 60,
    );
  }
}

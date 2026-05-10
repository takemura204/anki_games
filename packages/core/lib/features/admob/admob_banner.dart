import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../config/ads/ad_config.dart';

class AdmobBanner extends ConsumerStatefulWidget {
  const AdmobBanner({super.key});

  @override
  ConsumerState<AdmobBanner> createState() => _AdmobBannerState();
}

class _AdmobBannerState extends ConsumerState<AdmobBanner> {
  BannerAd? _bannerAd;
  var _isAdLoaded = false;
  var _isLoading = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    if (_isLoading) {
      return;
    }
    _isLoading = true;

    final adUnitId = ref.read(adConfigProvider).banner;
    final width = MediaQuery.of(context).size.width;

    AdSize.getLargeAnchoredAdaptiveBannerAdSize(width.truncate())
        .then((adSize) {
      if (!mounted || adSize == null) {
        return;
      }

      _bannerAd = BannerAd(
        adUnitId: adUnitId,
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
    return const SizedBox(height: 60);
  }
}

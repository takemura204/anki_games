import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:shimmer/shimmer.dart';

import '../../config/ads/ad_config.dart';
import '../purchase/view_model/premium_view_model.dart';

class AdmobNative extends ConsumerStatefulWidget {
  const AdmobNative({
    this.templateType = TemplateType.medium,
    this.height,
    super.key,
  });

  final TemplateType templateType;
  final double? height;

  @override
  ConsumerState<AdmobNative> createState() => _AdmobNativeState();
}

class _AdmobNativeState extends ConsumerState<AdmobNative> {
  NativeAd? _nativeAd;
  var _isLoaded = false;

  double get _defaultHeight =>
      widget.templateType == TemplateType.small ? 90 : 300;

  @override
  void initState() {
    super.initState();
    _loadAd();
  }

  void _loadAd() {
    final adUnitId = ref.read(adConfigProvider).native;
    _nativeAd = NativeAd(
      adUnitId: adUnitId,
      request: const AdRequest(),
      listener: NativeAdListener(
        onAdLoaded: (_) {
          if (!mounted) {
            return;
          }
          setState(() => _isLoaded = true);
        },
        onAdFailedToLoad: (ad, error) {
          debugPrint('NativeAd failed to load: $error');
          ad.dispose();
        },
      ),
      nativeTemplateStyle: NativeTemplateStyle(
        templateType: widget.templateType,
        mainBackgroundColor: Colors.transparent,
        cornerRadius: 8,
      ),
    )..load();
  }

  @override
  void dispose() {
    _nativeAd?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isPremium =
        ref.watch(premiumViewModelProvider).asData?.value.isPremium ?? false;
    if (isPremium) return const SizedBox.shrink();

    final height = widget.height ?? _defaultHeight;

    if (!_isLoaded || _nativeAd == null) {
      return Shimmer.fromColors(
        baseColor: Colors.white.withValues(alpha: 0.08),
        highlightColor: Colors.white.withValues(alpha: 0.18),
        child: Container(
          width: double.infinity,
          height: height,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      );
    }

    return SizedBox(
      width: double.infinity,
      height: height,
      child: AdWidget(ad: _nativeAd!),
    );
  }
}

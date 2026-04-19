import 'dart:io';

import 'package:anki_games/common/config/env/env.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

/// ネイティブ広告を表示するウィジェット。
///
/// [templateType] でテンプレートサイズを選択する。
/// [height] を指定しない場合はテンプレートに応じたデフォルト高さを使用する。
class NativeAdBanner extends StatefulWidget {
  /// ネイティブ広告ウィジェットを作成する。
  const NativeAdBanner({
    this.templateType = TemplateType.medium,
    this.height,
    super.key,
  });

  /// 使用するネイティブテンプレートの種類。
  final TemplateType templateType;

  /// コンテナの高さ。null の場合はテンプレート種類に応じたデフォルト値を使用する。
  final double? height;

  @override
  State<NativeAdBanner> createState() => _NativeAdBannerState();
}

class _NativeAdBannerState extends State<NativeAdBanner> {
  NativeAd? _nativeAd;
  var _isLoaded = false;

  String get _adUnitId {
    if (Platform.isAndroid) {
      return kDebugMode
          ? Env.nativeAdUnitIdAndroidDebug
          : Env.nativeAdUnitIdAndroidRelease;
    } else if (Platform.isIOS) {
      return kDebugMode
          ? Env.nativeAdUnitIdIosDebug
          : Env.nativeAdUnitIdIosRelease;
    }
    throw UnsupportedError('Unsupported platform');
  }

  double get _defaultHeight =>
      widget.templateType == TemplateType.small ? 90 : 300;

  @override
  void initState() {
    super.initState();
    _loadAd();
  }

  void _loadAd() {
    _nativeAd = NativeAd(
      adUnitId: _adUnitId,
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
    if (!_isLoaded || _nativeAd == null) {
      return const SizedBox.shrink();
    }
    return SizedBox(
      width: double.infinity,
      height: widget.height ?? _defaultHeight,
      child: AdWidget(ad: _nativeAd!),
    );
  }
}

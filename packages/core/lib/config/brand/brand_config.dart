import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../features/purchase/model/revenue_cat_config.dart';
import '../ads/ad_config.dart';
import 'store_ids.dart';

/// アプリごとに異なるブランド要素（見た目・サービスID）を注入する抽象設定。
///
/// 各アプリの `main.dart` で [brandConfigProvider] をオーバーライドして使う:
/// ```dart
/// brandConfigProvider.overrideWithValue(ItPassBrandConfig())
/// ```
abstract class BrandConfig {
  const BrandConfig();
  String get appName;

  /// Firebase Analytics / Firestore でアプリを識別するキー（例: 'it_pass', 'fe'）
  String get analyticsBrandKey;

  Color get seedColor;

  /// ダークモード用 ThemeExtension（例: ItPassColorScheme.dark）
  List<ThemeExtension<dynamic>> get darkThemeExtensions;

  /// ライトモード用 ThemeExtension（例: ItPassColorScheme.light）
  List<ThemeExtension<dynamic>> get lightThemeExtensions;

  AdConfig get adConfig;

  RevenueCatConfig get revenueCatConfig;

  StoreIds get storeIds;
}

/// ブランド設定プロバイダー。各アプリの `main.dart` で必ずオーバーライドする。
final brandConfigProvider = Provider<BrandConfig>(
  (ref) => throw UnimplementedError('brandConfigProvider must be overridden'),
  name: 'brandConfigProvider',
);

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

  /// ユーザー向け表示名（例: 'ITパスポート', '基本情報技術者'）。
  /// オンボーディングや通知文面など UI に埋め込む名称として使用する。
  String get appDisplayName => appName;

  /// Firebase Analytics / Firestore でアプリを識別するキー（例: 'it_pass', 'fe'）
  String get analyticsBrandKey;

  /// ローカル通知チャンネル ID（例: 'it_pass_reminder'）。
  String get notificationChannelId => '${analyticsBrandKey}_reminder';

  Color get seedColor;

  /// ダークモード用 ThemeExtension（例: AppColorScheme.dark）
  List<ThemeExtension<dynamic>> get darkThemeExtensions;

  /// ライトモード用 ThemeExtension（例: AppColorScheme.light）
  List<ThemeExtension<dynamic>> get lightThemeExtensions;

  AdConfig get adConfig;

  RevenueCatConfig get revenueCatConfig;

  StoreIds get storeIds;

  /// オンボーディング導入ページのロゴ SVG アセットパス。
  String get introLogoAsset;

  /// オンボーディング機能紹介ページ: 習熟度画像の SVG アセットパス。
  String get onboardingLevelAsset;

  /// オンボーディング機能紹介ページ: リマインダー画像の SVG アセットパス。
  String get onboardingRemindAsset;
}

/// ブランド設定プロバイダー。各アプリの `main.dart` で必ずオーバーライドする。
final brandConfigProvider = Provider<BrandConfig>(
  (ref) => throw UnimplementedError('brandConfigProvider must be overridden'),
  name: 'brandConfigProvider',
);

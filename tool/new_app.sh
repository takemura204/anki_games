#!/usr/bin/env bash
# tool/new_app.sh
# 新しい試験対策アプリのボイラープレートを生成するスクリプト
#
# 使い方:
#   bash tool/new_app.sh <app_id> <bundle_id_base> "<アプリ名>"
#
# 例:
#   bash tool/new_app.sh app_fe jp.tkmr.fe "基本情報技術者"
#
# 生成されるもの:
#   packages/<app_id>/
#     pubspec.yaml
#     lib/main.dart
#     lib/config/<app_id>_brand_config.dart
#     lib/config/<app_id>_exam_config.dart
#     assets/quiz/.gitkeep

set -euo pipefail

APP_ID="${1:-}"
BUNDLE_ID="${2:-}"
APP_NAME="${3:-}"

if [[ -z "$APP_ID" || -z "$BUNDLE_ID" || -z "$APP_NAME" ]]; then
  echo "使い方: bash tool/new_app.sh <app_id> <bundle_id_base> \"<アプリ名>\""
  echo "例:    bash tool/new_app.sh app_fe jp.tkmr.fe \"基本情報技術者\""
  exit 1
fi

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
DEST="$REPO_ROOT/packages/$APP_ID"

if [[ -d "$DEST" ]]; then
  echo "エラー: $DEST は既に存在します。"
  exit 1
fi

# Dart 識別子として有効なクラス名を生成（例: app_fe → AppFe）
CLASS_PREFIX=$(echo "$APP_ID" | sed 's/^app_//' | sed 's/_\([a-z]\)/\U\1/g; s/^./\U&/')

echo "→ $DEST を作成します..."

mkdir -p "$DEST/lib/config"
mkdir -p "$DEST/lib/features"
mkdir -p "$DEST/assets/quiz"
touch "$DEST/assets/quiz/.gitkeep"

# ── pubspec.yaml ─────────────────────────────────────────────────────────────
cat > "$DEST/pubspec.yaml" << PUBSPEC
name: $APP_ID
description: "$APP_NAME 試験対策アプリ"

publish_to: 'none'
version: 1.0.0+1

environment:
  sdk: ">=3.0.0 <4.0.0"

dependencies:
  app_it_pass:
    path: ../app_it_pass
  core:
    path: ../core
  envied:
  flutter:
    sdk: flutter
  hooks_riverpod:

dev_dependencies:
  envied_generator:
  build_runner:
  flutter_test:
    sdk: flutter

flutter:
  uses-material-design: true
  assets:
    - assets/quiz/
PUBSPEC

# ── lib/config/<app_id>_exam_config.dart ────────────────────────────────────
cat > "$DEST/lib/config/${APP_ID}_exam_config.dart" << EXAM_CONFIG
import 'package:core/features/exam_quiz/config/exam_config.dart';
import 'package:core/features/exam_quiz/model/exam_meta.dart';

class ${CLASS_PREFIX}ExamConfig extends ExamConfig {
  const ${CLASS_PREFIX}ExamConfig();

  static const _base = 'packages/$APP_ID/assets/quiz';

  @override
  String get examTypeKey => '$(echo "${APP_ID#app_}")';

  @override
  Set<String> get freeEraIds => const {};

  @override
  List<ExamMeta> get examList => const [
        // TODO: 試験回を列挙する
        // ExamMeta(
        //   eraId: 'r06_aki',
        //   displayName: '令和6年度秋期',
        //   assetPath: '\$_base/xxx.json',
        //   group: ExamGroup.reiwa,
        // ),
      ];

  @override
  Map<String, List<String>> get categoryTree => const {
        // TODO: カテゴリツリーを定義する
        // '大分類': ['小分類1', '小分類2'],
      };
}
EXAM_CONFIG

# ── lib/config/<app_id>_brand_config.dart ───────────────────────────────────
cat > "$DEST/lib/config/${APP_ID}_brand_config.dart" << BRAND_CONFIG
import 'package:app_it_pass/config/theme/it_pass_color_scheme.dart';
import 'package:core/config/ads/ad_config.dart';
import 'package:core/config/brand/brand_config.dart';
import 'package:core/config/brand/store_ids.dart';
import 'package:core/features/purchase/model/revenue_cat_config.dart';
import 'package:flutter/material.dart';

class ${CLASS_PREFIX}BrandConfig extends BrandConfig {
  const ${CLASS_PREFIX}BrandConfig();

  @override
  String get appName => '$APP_NAME';

  @override
  String get analyticsBrandKey => '$(echo "${APP_ID#app_}")';

  // TODO: ブランドカラーを変更する
  @override
  Color get seedColor => const Color(0xFF7C3AED);

  @override
  List<ThemeExtension<dynamic>> get darkThemeExtensions =>
      [ItPassColorScheme.dark];

  @override
  List<ThemeExtension<dynamic>> get lightThemeExtensions =>
      [ItPassColorScheme.light];

  // TODO: 本番用 AdMob ID に差し替える
  @override
  AdConfig get adConfig => const AdConfig(
        bannerAndroidDebug: 'ca-app-pub-3940256099942544/6300978111',
        bannerAndroidRelease: 'REPLACE_WITH_REAL_ID',
        bannerIosDebug: 'ca-app-pub-3940256099942544/2934735716',
        bannerIosRelease: 'REPLACE_WITH_REAL_ID',
        nativeAndroidDebug: 'ca-app-pub-3940256099942544/2247696110',
        nativeAndroidRelease: 'REPLACE_WITH_REAL_ID',
        nativeIosDebug: 'ca-app-pub-3940256099942544/3986624511',
        nativeIosRelease: 'REPLACE_WITH_REAL_ID',
        rewardedAndroidDebug: 'ca-app-pub-3940256099942544/5224354917',
        rewardedAndroidRelease: 'REPLACE_WITH_REAL_ID',
        rewardedIosDebug: 'ca-app-pub-3940256099942544/1712485313',
        rewardedIosRelease: 'REPLACE_WITH_REAL_ID',
        interstitialAndroidDebug: 'ca-app-pub-3940256099942544/1033173712',
        interstitialAndroidRelease: 'REPLACE_WITH_REAL_ID',
        interstitialIosDebug: 'ca-app-pub-3940256099942544/4560639518',
        interstitialIosRelease: 'REPLACE_WITH_REAL_ID',
      );

  // TODO: RevenueCat キーを設定する
  @override
  RevenueCatConfig get revenueCatConfig => const RevenueCatConfig(
        apiKeyIos: '',
        apiKeyAndroid: '',
        premium1mProductId: '',
        premiumLifetimeProductId: '',
      );

  // TODO: ストア ID を設定する
  @override
  StoreIds get storeIds => const StoreIds(
        appStoreId: 'REPLACE_WITH_APP_STORE_ID',
        playPackageName: '$BUNDLE_ID',
      );
}
BRAND_CONFIG

# ── lib/main.dart ────────────────────────────────────────────────────────────
cat > "$DEST/lib/main.dart" << MAIN_DART
import 'package:app_it_pass/config/lifecycle/app_lifecycle_provider.dart';
import 'package:app_it_pass/features/quiz/view/quiz_screen.dart';
import 'package:app_it_pass/features/settings/view_model/theme_mode_view_model.dart';
import 'package:app_it_pass/features/streak/view/streak_banner.dart';
import 'package:core/config/ads/ad_config.dart';
import 'package:core/config/brand/brand_config.dart';
import 'package:core/config/theme/app_theme.dart' show buildAppTheme;
import 'package:core/features/exam_quiz/config/exam_config.dart';
import 'package:core/features/purchase/service/real_purchase_service.dart';
import 'package:core/features/purchase/view_model/premium_view_model.dart';
import 'package:core/firebase_options.dart';
import 'package:core/i18n/translations.g.dart';
import 'package:core/utils/router/router_constants.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import 'config/${APP_ID}_brand_config.dart';
import 'config/${APP_ID}_exam_config.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await LocaleSettings.useDeviceLocale();

  runApp(
    TranslationProvider(
      child: ProviderScope(
        overrides: [
          brandConfigProvider.overrideWithValue(
            const ${CLASS_PREFIX}BrandConfig(),
          ),
          examConfigProvider.overrideWithValue(
            const ${CLASS_PREFIX}ExamConfig(),
          ),
          adConfigProvider.overrideWithValue(
            const ${CLASS_PREFIX}BrandConfig().adConfig,
          ),
          purchaseServiceProvider.overrideWithValue(
            RealPurchaseService(const ${CLASS_PREFIX}BrandConfig().revenueCatConfig),
          ),
        ],
        child: const ${CLASS_PREFIX}App(),
      ),
    ),
  );
}

class ${CLASS_PREFIX}App extends ConsumerWidget {
  const ${CLASS_PREFIX}App({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeViewModelProvider);
    final brandConfig = ref.watch(brandConfigProvider);

    ref.listen<AppLifecycleData>(appLifecycleProvider, (prev, next) {});

    return MaterialApp(
      navigatorKey: rootNavigatorKey,
      debugShowCheckedModeBanner: false,
      title: brandConfig.appName,
      themeMode: themeMode,
      theme: buildAppTheme(
        seedColor: brandConfig.seedColor,
        dark: false,
      ).copyWith(extensions: brandConfig.lightThemeExtensions),
      darkTheme: buildAppTheme(
        seedColor: brandConfig.seedColor,
        dark: true,
      ).copyWith(extensions: brandConfig.darkThemeExtensions),
      builder: (context, child) => StreakBannerHost(child: child!),
      home: const QuizScreen(),
    );
  }
}
MAIN_DART

echo ""
echo "✅ $DEST を作成しました。"
echo ""
echo "次のステップ:"
echo "  1. lib/config/${APP_ID}_exam_config.dart の examList を実装"
echo "  2. lib/config/${APP_ID}_brand_config.dart のブランドカラーを設定"
echo "  3. assets/quiz/ に問題 JSON を配置"
echo "  4. Android フレーバーを android/app/build.gradle.kts に追加"
echo "  5. iOS xcconfig + Xcode Scheme を追加（手動）"
echo "  6. docs/whitelabel/add_new_app.md の手順を完了する"

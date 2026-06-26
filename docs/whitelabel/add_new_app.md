# 新アプリ追加 Runbook

このドキュメントに従うと、新しい試験対策アプリ（例: `app_fp3`）を最小工数で追加できる。  
所要時間の目安: **エンジニア1名・2〜3日**（CI 設定込み）。

`app_fe`（基本情報技術者）は本手順で実際に作成済みのため、参考として活用できる。

---

## 前提条件

- `packages/core/` に試験データ（JSON）が存在すること
- Flutter 環境・Xcode・Android Studio がセットアップ済みであること

---

## Step 1: 新アプリの雛形を生成

```bash
bash tool/new_app.sh <app_id> <bundle_id> "<アプリ名>"

# 例:
bash tool/new_app.sh app_fp3 jp.tkmr.fp3 "FP3級"
```

生成されるファイル:
```
packages/<app_id>/
├── pubspec.yaml
├── lib/
│   ├── main.dart
│   └── config/
│       ├── <app_id>_brand_config.dart  ← BrandConfig 実装の雛形
│       └── <app_id>_exam_config.dart   ← ExamConfig 実装の雛形
└── assets/
    └── quiz/                            ← データを配置する場所
```

---

## Step 2: 試験データを配置

問題 JSON は `packages/core/assets/quiz/<試験>/` に置くか、  
新アプリの `assets/quiz/` に直接配置する。

```bash
# core の FE データを参照する場合（app_fe の例）
# assetPath: 'packages/core/assets/quiz/fe/fe_r07_haru.json'

# アプリ固有のデータを配置する場合
cp /path/to/source/*.json packages/app_fp3/assets/quiz/
# pubspec.yaml の flutter.assets に追加が必要
```

---

## Step 3: ExamConfig を実装

`lib/config/<app_id>_exam_config.dart` を編集:

```dart
class AppFp3ExamConfig extends ExamConfig {
  const AppFp3ExamConfig();

  @override
  String get examTypeKey => 'fp3';

  @override
  Set<String> get freeEraIds => const {'fp3_2025_5'};

  @override
  List<ExamMeta> get examList => const [
        ExamMeta(
          eraId: 'fp3_2025_5',
          displayName: '2025年5月',
          assetPath: 'packages/app_fp3/assets/quiz/fp3_2025_5.json',
          group: ExamGroup.reiwa,
        ),
        // ... 全試験回を列挙
      ];

  @override
  Map<String, List<String>> get categoryTree => const {
        'リスク管理': ['リスクと不確実性', '保険と保険料'],
        // ...
      };
}
```

---

## Step 4: BrandConfig を実装

`lib/config/<app_id>_brand_config.dart` を編集:

```dart
class AppFp3BrandConfig extends BrandConfig {
  const AppFp3BrandConfig();

  @override
  String get appName => 'FP3級';

  @override
  String get analyticsBrandKey => 'fp3';

  @override
  Color get seedColor => const Color(0xFF059669); // グリーン系

  @override
  List<ThemeExtension<dynamic>> get darkThemeExtensions =>
      [ItPassColorScheme.dark]; // 独自カラーを作る場合は別途 ColorScheme 定義

  @override
  List<ThemeExtension<dynamic>> get lightThemeExtensions =>
      [ItPassColorScheme.light];

  @override
  AdConfig get adConfig => const AdConfig(
        bannerAndroidDebug: 'ca-app-pub-3940256099942544/6300978111',
        bannerAndroidRelease: 'YOUR_ADMOB_BANNER_ANDROID',
        // ...
      );

  @override
  RevenueCatConfig get revenueCatConfig => const RevenueCatConfig(
        apiKeyIos: '',
        apiKeyAndroid: '',
        premium1mProductId: '',
        premiumLifetimeProductId: '',
      );

  @override
  StoreIds get storeIds => const StoreIds(
        appStoreId: 'YOUR_APP_STORE_ID',
        playPackageName: 'jp.tkmr.fp3',
      );
}
```

---

## Step 5: Android フレーバーを追加

`android/app/build.gradle.kts` の `productFlavors` に追記:

```kotlin
create("app_fp3") {
    dimension = "app"
    applicationId = "jp.tkmr.fp3"
    resValue("string", "app_name", "FP3級")
}
```

---

## Step 6: iOS フレーバーを追加（手動）

1. `ios/Flutter/flavors/` に xcconfig を2つ作成:

```
# app_fp3-Debug.xcconfig
#include "../Debug.xcconfig"
BUNDLE_ID = jp.tkmr.fp3
APP_NAME = FP3級
DEVELOPMENT_TEAM = A6MZ7WPLWN
```

```
# app_fp3-Release.xcconfig
#include "../Release.xcconfig"
BUNDLE_ID = jp.tkmr.fp3
APP_NAME = FP3級
DEVELOPMENT_TEAM = A6MZ7WPLWN
```

2. Xcode で `Runner` Scheme を複製して `app_fp3` に改名
3. Scheme の Build Configuration に `Debug-app_fp3` / `Release-app_fp3` を設定

---

## Step 7: アプリアイコン・スプラッシュを設定

```yaml
# packages/app_fp3/pubspec.yaml に追加
flutter_launcher_icons:
  android: true
  ios: true
  image_path: "assets/logo/logo_fp3.png"
  adaptive_icon_background: "#052E16"
  adaptive_icon_foreground: "assets/logo/logo_foreground.svg"
```

```bash
cd packages/app_fp3
flutter pub run flutter_launcher_icons
```

---

## Step 8: Firebase にアプリを登録

1. [Firebase Console](https://console.firebase.google.com/) で既存プロジェクトを開く
2. 「アプリを追加」→ Android / iOS それぞれ Bundle ID を登録
3. `google-services.json` / `GoogleService-Info.plist` を適切な場所に配置
4. `packages/core/lib/firebase_options.dart` は共有のため変更不要

---

## Step 9: CI に追加

`.github/workflows/ci.yml` の `analyze` ジョブに追記:

```yaml
- name: Install dependencies (app_fp3)
  working-directory: packages/app_fp3
  run: flutter pub get

- name: Flutter analyze (app_fp3)
  working-directory: packages/app_fp3
  run: flutter analyze --fatal-infos
```

---

## Step 10: 動作確認

```bash
# 静的解析
cd packages/app_fp3 && flutter analyze

# 起動確認（シミュレータ）
flutter run -t packages/app_fp3/lib/main.dart

# IT Pass の既存動作が壊れていないことを確認
flutter run -t packages/app_it_pass/lib/main.dart --flavor it_pass
```

---

## チェックリスト

- [ ] `tool/new_app.sh` で雛形生成
- [ ] 試験データ（JSON）を配置（core or アプリ固有）
- [ ] `ExamConfig` を実装（`examList` 全試験回、`categoryTree`、`freeEraIds`）
- [ ] `BrandConfig` を実装（色・AdMob・RevenueCat・ストアID）
- [ ] Android フレーバー追加（`build.gradle.kts`）
- [ ] iOS xcconfig + Xcode Scheme 追加
- [ ] アプリアイコン・スプラッシュ生成
- [ ] Firebase 登録（iOS + Android）
- [ ] CI（`.github/workflows/ci.yml`）に追加
- [ ] `flutter analyze` 0件
- [ ] IT Pass の既存動作が壊れていないこと確認

# 外部サービス セットアップ手順

> App Store Connect / Google Play Console でのアプリ作成完了後に実施。  
> `<APP>` は各アプリのフレーバー名（例: `it_pass`）に読み替える。

---

## 共通化設計

| サービス | 共通レイヤー（core） | アプリ別設定 |
|---|---|---|
| Firebase | `packages/core/lib/firebase_options.dart`（FlutterFire CLI 生成） | Firebase プロジェクトにアプリを追加し再生成 |
| AdMob | Widget 実装: `packages/core/lib/features/admob/`<br>`AdConfig` モデル + `adConfigProvider`: `packages/core/lib/config/ads/ad_config.dart` | `packages/<APP>/lib/config/env/.env` に広告ユニット ID を記入し `main.dart` で `adConfigProvider` をオーバーライド |
| RevenueCat | `IPurchaseService` / `RealPurchaseService` / UI: `packages/core/lib/features/purchase/`<br>`RevenueCatConfig` モデル: `packages/core/lib/features/purchase/model/revenue_cat_config.dart` | `packages/<APP>/lib/config/env/.env` に API キーを記入し `main.dart` で `purchaseServiceProvider` をオーバーライド |

### キー管理の仕組み

```
packages/<APP>/
  lib/config/env/
    .env          ← 本番キー（gitignore 済み・ローカルのみ）
    env.dart      ← @Envied クラス（XxxEnv）。未設定時は defaultValue のテスト ID を使用
```

`main.dart` の `ProviderScope.overrides` で値を注入するため、**`core` パッケージはアプリ固有のキーを一切持たない**。

---

## Firebase

### 共通設計
- 1 つの Firebase プロジェクトに複数アプリ（フレーバー）を登録
- `firebase_options.dart` を `packages/core` に置き全アプリから共有

### セットアップ手順

**① Firebase Console でアプリを追加**

1. [console.firebase.google.com](https://console.firebase.google.com) → 対象プロジェクト
2. 「プロジェクトの設定」→「アプリを追加」
   - iOS: Bundle ID（例: `jp.tkmr.it-pass`）を入力 → `GoogleService-Info.plist` をダウンロード
   - Android: パッケージ名（例: `jp.tkmr.it_pass`）を入力 → `google-services.json` をダウンロード

**② ネイティブ設定ファイルを配置**

| プラットフォーム | 配置先 |
|---|---|
| iOS | `ios/Runner/GoogleService-Info.plist` |
| Android | `android/app/src/<APP>/google-services.json` |

> Android はフレーバー別ディレクトリ（`src/it_pass/`, `src/blockPuzzle/`）に分けることで  
> ビルド時に自動で該当ファイルが選択される。Firebase 不使用のフレーバーはダミー json を置く。

**③ FlutterFire CLI で `firebase_options.dart` を更新**

```bash
# 未インストールの場合（どのディレクトリでも可）
dart pub global activate flutterfire_cli

# プロジェクトルートで実行
flutterfire configure \
  --project=<firebase-project-id> \
  --out=packages/core/lib/firebase_options.dart \
  --platforms=ios,android \
  --android-package-name=<android-application-id> \
  --ios-bundle-id=<ios-bundle-id> \
  --android-out=android/app/src/<APP>/google-services.json \
  --ios-out=ios/Runner/GoogleService-Info.plist \
  --ios-build-config=Release-<APP> \
  --overwrite-firebase-options \
  --yes
```

> `--ios-build-config` には Xcode の build configuration 名（`Release-it_pass` など）を指定する。  
> 有効な名前は `Debug-<APP>` / `Release-<APP>` / `Profile-<APP>` など。  
> **新しいアプリを追加したら必ずこのコマンドを再実行する。**

**it_pass の実行例:**

```bash
flutterfire configure \
  --project=anki-quiz-dev \
  --out=packages/core/lib/firebase_options.dart \
  --platforms=ios,android \
  --android-package-name=jp.tkmr.it_pass \
  --ios-bundle-id=jp.tkmr.it-pass \
  --android-out=android/app/src/it_pass/google-services.json \
  --ios-out=ios/Runner/GoogleService-Info.plist \
  --ios-build-config=Release-it_pass \
  --overwrite-firebase-options \
  --yes
```

**④ `main.dart` で初期化**

Firebase を使用するアプリは起動時に初期化する:

```dart
import 'package:core/firebase_options.dart';
import 'package:firebase_core/firebase_core.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const MyApp());
}
```

---

## Google AdMob

### 共通設計
- Widget 実装（`AdmobBanner` / `AdmobNative` / `AdmobInterstitial` / `RewardedAdService`）は `packages/core/lib/features/admob/` に集約
- Widget は `adConfigProvider` から広告ユニット ID を取得する。**直接 `.env` を参照しない**
- **App ID のみ**ネイティブ設定（`Info.plist` / `AndroidManifest.xml`）に記入が必要

### セットアップ手順

**① AdMob でアプリを登録**

1. [admob.google.com](https://admob.google.com) → 「アプリ」→「アプリを追加」
2. App Store / Google Play と連携済みならストアから検索。未公開なら「手動で追加」
3. **アプリ ID**（`ca-app-pub-XXXX~YYYY`）を取得

**② App ID をネイティブ設定に記入**

- iOS: `ios/Runner/Info.plist`

  ```xml
  <key>GADApplicationIdentifier</key>
  <string>ca-app-pub-XXXX~YYYY</string>
  ```

- Android: `android/app/src/main/AndroidManifest.xml`

  ```xml
  <meta-data
      android:name="com.google.android.gms.ads.APPLICATION_ID"
      android:value="ca-app-pub-XXXX~YYYY"/>
  ```

**③ アプリ別 `.env` に広告ユニット ID を記入**

`packages/<APP>/lib/config/env/.env`（ファイルがなければ新規作成）:

```
# Banner
BANNER_AD_UNIT_ID_ANDROID_DEBUG=ca-app-pub-3940256099942544/6300978111
BANNER_AD_UNIT_ID_ANDROID_RELEASE=ca-app-pub-XXXX/YYYY
BANNER_AD_UNIT_ID_IOS_DEBUG=ca-app-pub-3940256099942544/2934735716
BANNER_AD_UNIT_ID_IOS_RELEASE=ca-app-pub-XXXX/YYYY

# Native / Rewarded / Interstitial も同様
```

> **`packages/core/lib/config/env/.env` には記入しない。**  
> `DEBUG` 行はデフォルト値（Google 公式テスト ID）のままでも動作する。

**④ アプリ別 `env.dart` に `@Envied` クラスを定義**

`packages/<APP>/lib/config/env/env.dart`（`it_pass` は定義済み）:

```dart
@Envied(path: 'lib/config/env/.env', requireEnvFile: false)
abstract class XxxEnv {
  @EnviedField(varName: 'BANNER_AD_UNIT_ID_ANDROID_DEBUG',
      defaultValue: 'ca-app-pub-3940256099942544/6300978111')
  static const String bannerAndroidDebug = _XxxEnv.bannerAndroidDebug;
  // ... 他のフィールドも同様
}
```

**⑤ `main.dart` で `adConfigProvider` をオーバーライド**

```dart
import 'package:core/config/ads/ad_config.dart';
import 'package:<APP>/config/env/env.dart';

ProviderScope(
  overrides: [
    adConfigProvider.overrideWithValue(const AdConfig(
      bannerAndroidDebug: XxxEnv.bannerAndroidDebug,
      bannerAndroidRelease: XxxEnv.bannerAndroidRelease,
      // ... 全 16 フィールド
    )),
  ],
  child: const MyApp(),
)
```

**⑥ コード生成**

```bash
# packages/<APP> ディレクトリで実行
cd packages/<APP>
dart run build_runner build
```

**⑦ 審査提出前の確認**

- [ ] `GADApplicationIdentifier` が本番 ID（テスト ID `ca-app-pub-3940256099942544~...` のままでないか）
- [ ] App Store Connect の「広告識別子」→ **はい** を選択

---

## RevenueCat

### 共通設計
- **抽象インターフェース**: `packages/core/lib/features/purchase/service/i_purchase_service.dart`
- **実装**: `RealPurchaseService`（本番） / `MockPurchaseService`（開発用）
- **UI**: `packages/core/lib/features/purchase/view/paywall_bottom_sheet.dart`
- `RealPurchaseService` は `RevenueCatConfig` をコンストラクタで受け取る。**直接 `.env` を参照しない**

### セットアップ手順

**① RevenueCat でアプリを登録**

1. [app.revenuecat.com](https://app.revenuecat.com) → プロジェクト選択（または「New Project」）
2. 「Apps」→「+」→ iOS App / Android App を追加（Bundle ID / パッケージ名を入力）
3. **Public SDK Key** を取得（iOS: `appl_...` / Android: `goog_...`）

**② ストア側でプロダクトを作成**

| ストア | 操作 |
|---|---|
| App Store Connect | 「App 内課金」→「＋」→ 種類を選択 → プロダクト ID を作成 |
| Google Play Console | 「収益化」→「定期購読」または「アプリ内アイテム」→ プロダクト ID を作成 |

**③ RevenueCat にエンタイトルメント・オファリングを設定**

RevenueCat ダッシュボード:
1. 「Entitlements」→「＋」→ 識別子（例: `premium`）を作成
2. 「Products」→「＋」→ ②で作成したプロダクト ID を登録
3. 「Offerings」→「＋」→ オファリングを作成 → パッケージにプロダクトをアタッチ

**④ アプリ別 `.env` に API キーを記入**

`packages/<APP>/lib/config/env/.env`（AdMob と同じファイル）:

```
REVENUECAT_API_KEY_IOS=appl_XXXX
REVENUECAT_API_KEY_ANDROID=goog_XXXX
PREMIUM_1M=<プロダクトID>
PREMIUM_LIFETIME=<プロダクトID>
```

**⑤ `main.dart` で `purchaseServiceProvider` をオーバーライド**

```dart
import 'package:core/features/purchase/model/revenue_cat_config.dart';
import 'package:core/features/purchase/service/real_purchase_service.dart';
import 'package:<APP>/config/env/env.dart';

ProviderScope(
  overrides: [
    purchaseServiceProvider.overrideWithValue(
      RealPurchaseService(const RevenueCatConfig(
        apiKeyIos: XxxEnv.revenueCatApiKeyIos,
        apiKeyAndroid: XxxEnv.revenueCatApiKeyAndroid,
        premium1mProductId: XxxEnv.premium1m,
        premiumLifetimeProductId: XxxEnv.premiumLifetime,
      )),
    ),
  ],
  child: const MyApp(),
)
```

**⑥ コード生成 & 動作確認**

```bash
cd packages/<APP>
dart run build_runner build
```

RevenueCat ダッシュボード → 「Customers」にテスト購入が記録されれば完了。

---

## 新しいアプリを追加するときのチェックリスト

### Firebase

- [ ] Firebase Console でアプリを追加（iOS + Android）
- [ ] `GoogleService-Info.plist` を `ios/Runner/` に配置
- [ ] `google-services.json` を `android/app/src/<APP>/` に配置
- [ ] `flutterfire configure ... --out=packages/core/lib/firebase_options.dart` を再実行
- [ ] Firebase を使う場合は `main.dart` に `Firebase.initializeApp` を追加

### AdMob

- [ ] AdMob でアプリを登録 → App ID を取得
- [ ] `ios/Runner/Info.plist` の `GADApplicationIdentifier` に本番 App ID を設定
- [ ] `android/app/src/main/AndroidManifest.xml` の `APPLICATION_ID` を更新
- [ ] `packages/<APP>/lib/config/env/.env` に広告ユニット ID を記入
- [ ] `packages/<APP>/lib/config/env/env.dart` に `@Envied` クラスを作成
- [ ] `main.dart` で `adConfigProvider.overrideWithValue(AdConfig(...))` を追加
- [ ] `cd packages/<APP> && dart run build_runner build` を実行

### RevenueCat

- [ ] RevenueCat ダッシュボードにアプリを追加 → SDK キーを取得
- [ ] ストアでプロダクトを作成
- [ ] RevenueCat にエンタイトルメント・オファリングを設定
- [ ] `packages/<APP>/lib/config/env/.env` に SDK キー・`PREMIUM_1M`・`PREMIUM_LIFETIME` のプロダクト ID を記入
- [ ] `main.dart` の `purchaseServiceProvider` を `RealPurchaseService(RevenueCatConfig(...))` でオーバーライド（`premiumLifetimeProductId` も含める）
- [ ] `cd packages/<APP> && dart run build_runner build` を実行

---

*最終更新: 2026-05-09*

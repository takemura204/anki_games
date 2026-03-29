# Phase 9: プレミアムプラン実装仕様書

> 作成: 2026-03-25 / 改訂: 2026-03-25（公式ドキュメント確認・設計刷新）

---

## 概要

RevenueCat (`purchases_flutter` v9) を使って月額サブスクリプションを実装する。
`IPurchaseService` インターフェースによる Mock/Real 切り替えで、RevenueCat API キー取得前でも完全な開発・テストが可能。

| 項目 | 内容 |
|------|------|
| 料金体系 | 月額 ¥480/月のみ |
| 対応プラットフォーム | iOS + Android 同時 |
| SDK | `purchases_flutter: ^9.15.1` |
| 課金管理 | RevenueCat Entitlement ID: `premium` |
| ペイウォールUI | カスタムボトムシート（`PaywallBottomSheet`） |

---

## プレミアム機能差分

| 機能 | 無料 | プレミアム |
|------|------|-----------|
| バナー広告 | 常時表示 | 非表示 |
| インタースティシャル広告（ゲームオーバー時） | 表示 | 非表示 |
| Word Mode ジャンルフィルター | 「頻出50選」のみ | 全10ジャンル |

---

## アーキテクチャ

### サービス層: インターフェース + 2実装

```
lib/features/purchase/
├── service/
│   ├── i_purchase_service.dart         # 抽象インターフェース
│   ├── mock_purchase_service.dart      # kDebugMode 用（SharedPrefs toggle）
│   └── real_purchase_service.dart      # RevenueCat SDK 実装
├── view_model/
│   └── premium_view_model.dart         # AsyncNotifier<PremiumState> + provider
└── view/
    └── paywall_bottom_sheet.dart       # カスタム購入UI
```

### Riverpod プロバイダ階層

```dart
// lib/features/purchase/view_model/premium_view_model.dart

// サービス: main.dart で overrideWithValue
@Riverpod(keepAlive: true)
IPurchaseService purchaseService(Ref ref); // throws by default

// 月額価格文字列 ("¥480" など)
@riverpod
Future<String?> monthlyPrice(Ref ref);

// プレミアム状態
@Riverpod(keepAlive: true)
class PremiumViewModel extends _$PremiumViewModel {
  Future<PremiumState> build() async { ... }
  Future<void> purchase() async { ... }
  Future<void> restore() async { ... }
}
```

### データフロー

```
アプリ起動 (main.dart)
  └─ service = kDebugMode ? Mock : Real
  └─ await service.configure()
  └─ ProviderScope(overrides: [purchaseServiceProvider.overrideWithValue(service)])
       └─ PremiumViewModel.build()
            ├─ service.addPremiumStatusListener()  ← リアルタイム更新
            └─ service.isPremium() → PremiumState 初期化

ジャンルカードタップ (ロック状態)
  └─ PaywallBottomSheet 表示
       └─ 購入ボタン → PremiumViewModel.purchase()
            └─ service.purchaseMonthly() → listener 発火
                 └─ state = PremiumState(isPremium: true)

ゲームオーバー
  └─ isPremium チェック → false のみ広告表示
```

---

## IPurchaseService インターフェース

```dart
abstract class IPurchaseService {
  Future<void> configure();
  Future<bool> isPremium();
  Future<String?> getMonthlyPriceString();
  Future<void> purchaseMonthly();
  Future<bool> restorePurchases();
  void addPremiumStatusListener(void Function(bool) listener);
  void removePremiumStatusListener(void Function(bool) listener);
  Future<void> logIn(String userId);  // 将来用スタブ
  Future<void> logOut();              // 将来用スタブ
  // Debug only: MockPurchaseService で実装
  Future<void> toggleMockPremium();
}
```

### MockPurchaseService の挙動

- `SharedPreferences` に `mock_premium_enabled` を保存
- `purchaseMonthly()`: `mock_premium_enabled = true` → リスナー発火
- `restorePurchases()`: 現在の値を返す
- `toggleMockPremium()`: 値を反転 → リスナー発火（Debug トグルから呼ぶ）
- `getMonthlyPriceString()`: `"¥480"` を返す（固定）

### RealPurchaseService の挙動

- `configure()`: `Env.revenueCatApiKeyIos/Android` を読んで `Purchases.configure()`
- `isPremium()`: `Purchases.getCustomerInfo()` の `entitlements.all["premium"]?.isActive`
- `getMonthlyPriceString()`: `getOfferings().current?.monthly?.storeProduct.priceString`
- `purchaseMonthly()`: `Purchases.purchase(PurchaseParams.package(package))` ← v9 新API
- `restorePurchases()`: `Purchases.restorePurchases()` → entitlement 確認
- リスナー: `Purchases.addCustomerInfoUpdateListener()` でブリッジ

---

## PremiumViewModel

```dart
@Riverpod(keepAlive: true)
class PremiumViewModel extends _$PremiumViewModel {
  void Function(bool)? _listener;

  @override
  Future<PremiumState> build() async {
    final service = ref.read(purchaseServiceProvider);
    _listener = (isPremium) {
      state = AsyncData(PremiumState(isPremium: isPremium));
    };
    service.addPremiumStatusListener(_listener!);
    ref.onDispose(() => service.removePremiumStatusListener(_listener!));
    final isPremium = await service.isPremium();
    return PremiumState(isPremium: isPremium);
  }

  Future<void> purchase() async {
    await ref.read(purchaseServiceProvider).purchaseMonthly();
    // State は listener 経由で自動更新
  }

  Future<void> restore() async {
    final isPremium =
        await ref.read(purchaseServiceProvider).restorePurchases();
    state = AsyncData(PremiumState(isPremium: isPremium));
  }
}
```

---

## PaywallBottomSheet UI

```
┌─────────────────────────────┐
│  ── (ドラッグハンドル)         │
│  🔓 Block. Premium           │
│                              │
│  ✓ 広告を完全に非表示         │
│  ✓ 全ジャンルの単語を解放     │
│                              │
│  [ ¥480/月で始める ]         │  ← price は getMonthlyPriceString()
│  [ 購入を復元する ]           │
│                              │
│  利用規約   プライバシーポリシー │
└─────────────────────────────┘
```

- 購入/復元ボタン押下中は `useState` でローカルローディング管理
- エラーは `ScaffoldMessenger.showSnackBar` で通知
- isPremium 時: 「プレミアム有効中」表示 + 閉じるボタンのみ

---

## 広告制御変更点

**`game_over_overlay.dart`**
```dart
final isPremium = ref.read(premiumViewModelProvider).valueOrNull?.isPremium ?? false;
if (!gameState.isQuizMode && !isPremium) {
  AdmobInterstitial().loadAndShow();
}
// リワード広告も同様に isPremium ガード
```

**`block_puzzle_screen.dart`**
```dart
final isPremium = ref.watch(
  premiumViewModelProvider.select((s) => s.valueOrNull?.isPremium ?? false),
);
// ...
if (!isPremium) const AdmobBanner(),
```

---

## ジャンルフィルター変更点

**`word_range_selector_screen.dart`**

- `_ThemeCards` に `isPremium: bool` パラメータ追加
- `frequent` 以外は `isLocked = !isPremium`
- `_ThemeCard` の `isLocked: bool`:
  - true 時: opacity 0.5 + 右上に 🔒 アイコン
  - タップ: `PaywallBottomSheet` を表示

---

## main.dart 変更点

```dart
Future<void> main() async {
  // ...既存コード...
  final purchaseService = kDebugMode
      ? MockPurchaseService()
      : RealPurchaseService();
  await purchaseService.configure();
  runApp(TranslationProvider(child: MyApp(purchaseService: purchaseService)));
}

class MyApp extends StatelessWidget {
  const MyApp({required this.purchaseService, super.key});
  final IPurchaseService purchaseService;

  @override
  Widget build(BuildContext context) => ProviderScope(
    overrides: [purchaseServiceProvider.overrideWithValue(purchaseService)],
    child: const _MaterialApp(),
  );
}
```

---

## RevenueCat セットアップ手順（API キー取得時）

1. [RevenueCat](https://app.revenuecat.com) でアプリ登録
2. App Store Connect / Google Play Console で月額商品を作成
   - Product ID: `mono_games_premium_monthly`、Price: ¥480
3. RevenueCat で Entitlement `premium` を作成し商品を紐付け
4. iOS / Android の API Key を取得
5. `lib/config/env/.env` に追記:
   ```
   REVENUECAT_API_KEY_IOS=appl_xxxx
   REVENUECAT_API_KEY_ANDROID=goog_xxxx
   ```
6. `dart run build_runner build --delete-conflicting-outputs` を実行

### Android 追加設定

`android/app/src/main/AndroidManifest.xml` の `MainActivity` に `launchMode` を設定:
```xml
android:launchMode="singleTop"
```

`android/app/src/main/AndroidManifest.xml` に BILLING パーミッション追加:
```xml
<uses-permission android:name="com.android.vending.BILLING"/>
```

### iOS 追加設定

`ios/Podfile` の platform バージョンが `13.0` 以上であることを確認:
```ruby
platform :ios, '13.0'
```

---

## テスト用チェックリスト

- [ ] Debug モード: 設定画面の「Dev: Premium 切り替え」で isPremium がトグルできる
- [ ] isPremium=false 時: ジャンルカード（頻出50選以外）がロック表示される
- [ ] ロックカードタップ: PaywallBottomSheet が開く
- [ ] Mock 購入ボタン押下: ジャンルが解放される・バナー/インタースティシャルが消える
- [ ] アプリ再起動後も premium 状態が維持される（SharedPrefs）
- [ ] 購入を復元する: Mock での復元が機能する
- [ ] isPremium=false 時: ゲームオーバーでインタースティシャルが表示される
- [ ] isPremium=true 時: ゲームオーバーで広告が表示されない

---

## 注意事項

- `purchases_flutter` v9 の購入 API: `Purchases.purchase(PurchaseParams.package(pkg))`（旧 `purchasePackage()` は廃止）
- Apple 審査要件: ペイウォールに利用規約・プライバシーポリシーリンクが必要
- `RevenueCatUI.presentPaywallIfNeeded` は BottomSheet 内に配置不可（公式注意事項）→ カスタム UI を採用
- オフライン時: `isPremium()` が例外を投げる場合は `false` にフォールバック
- `Purchases.addCustomerInfoUpdateListener` は自動的に購読更新を受信（更新・解約など）

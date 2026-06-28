# アーキテクチャ詳細

> 採用担当・コードレビュアー向け。設計の判断理由は [docs/adr/](adr/) を参照。

---

## 技術選定サマリー（2026年版）

転職ポートフォリオ観点で、なぜこの技術スタックを選んだかを示す。

| 技術                  | 選定理由                                                                 |
| ------------------- | -------------------------------------------------------------------- |
| **Flutter**         | iOS/Android を単一コードベースで開発。Dart の型安全性と Widget ツリーが MVVM と相性良い           |
| **Riverpod 3.0**    | グローバルな暗黙的 DI を排除し、`ProviderScope.overrides` で明示的・テスタブルな DI を実現      |
| **Riverpod Codegen** | `@riverpod` アノテーションで定型コードを排除、LSP による型チェックを担保                        |
| **Freezed**         | イミュータブルな Value Object を自動生成。`copyWith` / パターンマッチが MVVM の State 更新に必須 |
| **go_router**       | 宣言的 URL ベースルーティング。ShellRoute によるモーダル管理・ディープリンク対応                    |
| **SharedPreferences** | ブランドごとのキープレフィックスで共存。シンプルな KV ストアが軽量な試験クイズに最適             |
| **Firestore**       | リアルタイム同期と匿名ログイン対応。クライアント SDK で追加のバックエンド不要                        |
| **Melos**           | パッケージ間の依存管理・一括スクリプト実行をモノレポ規模で効率化                                     |
| **slang**           | Dart ソースから型安全な i18n アクセサを生成（`t.xxx` でコンパイル時チェック）                    |

---

## 全体構成（モノレポ）

```
anki_games/（Melos モノレポルート）
│
├── packages/core/           ← 全アプリ共通ビジネスロジック
│   └── lib/
│       ├── config/
│       │   ├── brand/       ← BrandConfig 抽象（テーマ・広告ID・RevenueCat）
│       │   ├── ads/         ← AdConfig（広告 ID セット）
│       │   └── styles/      ← AppColorScheme・AppSpacing 等の共通デザイントークン
│       ├── features/
│       │   └── exam_quiz/   ← 試験クイズ機能（16 feature）
│       │       └── router/  ← ExamModalSheetRouter（遷移定義）
│       └── components/      ← 共通 UI コンポーネント（AdmobGlass 等）
│
├── packages/app_it_pass/    ← ITパスポート（BrandConfig + ExamConfig 2クラスのみ）
├── packages/app_fe/         ← 基本情報技術者試験（同上）
└── packages/quiz_data/      ← 問題CSV・JSONの管理パッケージ
```

---

## レイヤー設計（Feature-based MVVM + Repository）

```
┌──────────────────────────────────────────────────────────────────┐
│ View 層                                                          │
│   HookConsumerWidget ─ ref.watch(viewModelProvider) → State      │
│   ├── Screen（1画面1クラス、スクロール・ページング管理）               │
│   └── widgets/（プライベート StatelessWidget、part で集約）          │
├──────────────────────────────────────────────────────────────────┤
│ ViewModel 層                                                     │
│   @riverpod AutoDisposeAsyncNotifier<XxxxState>                  │
│   ├── build() で初期データをロード                                 │
│   ├── ユーザー操作に対応するメソッドを公開                           │
│   └── Repository にのみ依存（View・BuildContext の知識を持たない）  │
├──────────────────────────────────────────────────────────────────┤
│ Repository 層                                                    │
│   abstract class XxxxRepository { ... }                          │
│   ├── Local実装（SharedPreferences / drift）← ブランドプレフィックス付き │
│   └── Remote実装（Firestore）← auth uid でドキュメントを分離          │
├──────────────────────────────────────────────────────────────────┤
│ Model 層                                                         │
│   @freezed データクラス（immutable・copyWith・fromJson/toJson）      │
└──────────────────────────────────────────────────────────────────┘
```

**設計判断：Repository を抽象化する理由**

ViewModel はインターフェースにしか依存しないため、次の恩恵がある:

1. **テスト**: `ProviderContainer(overrides: [learningHistoryRepositoryProvider.overrideWithValue(FakeRepo())])` でワンラインモック
2. **切り替え**: Local → Firestore のデータソース切り替えが ViewModel 無変更
3. **並走**: Local で即時表示し、Firestore で非同期同期する二層構成が自然に書ける

---

## ホワイトラベル設計（Config DI）

新しい試験アプリを追加する際の実装量を最小化する設計。

### 注入ポイント

```dart
// packages/app_it_pass/lib/main.dart
runApp(
  ProviderScope(
    overrides: [
      brandConfigProvider.overrideWithValue(ItPassBrandConfig()),
      examConfigProvider.overrideWithValue(ItPassExamConfig()),
    ],
    child: const CoreApp(),
  ),
);
```

### BrandConfig の責務

| フィールド              | 用途                              |
| ------------------- | ------------------------------- |
| `appName`           | アプリ名（ストア向け）                     |
| `appDisplayName`    | UI 表示名（オンボーディング・通知文面）           |
| `analyticsBrandKey` | SharedPreferences プレフィックス・Analytics タグ |
| `seedColor`         | MaterialApp テーマシード色             |
| `darkThemeExtensions` / `lightThemeExtensions` | `AppColorScheme` インスタンスを渡してテーマを切り替える |
| `adConfig`          | AdMob 広告 ID セット（デバッグ/リリース別）     |
| `revenueCatConfig`  | RevenueCat 商品 ID・API キー         |
| `storeIds`          | App Store / Play Store の ID     |

### SharedPreferences キー衝突防止

複数アプリを同一端末で並走させる場合でも `analyticsBrandKey`（`'it_pass'` / `'fe'`）をプレフィックスとして付与するため、キーが衝突しない:

```dart
// FilterRepository
String get _keyEraIds => '${_prefix}_filter_era_ids';
// it_pass → 'it_pass_filter_era_ids'
// fe      → 'fe_filter_era_ids'
```

### 新アプリ追加手順（3ステップ）

```
1. packages/app_xxx/ を作成
2. XxxBrandConfig extends BrandConfig を実装（約 60 行）
3. XxxExamConfig extends ExamConfig を実装（約 30 行）
   └── main.dart で ProviderScope.overrides に渡す
```

---

## 状態管理（Riverpod 3.0）

### Provider の種類と使い分け

| Provider                       | 用途                      | 例                                        |
| ------------------------------ | ----------------------- | ---------------------------------------- |
| `@riverpod` AsyncNotifier      | 非同期データを持つ ViewModel      | `QuizViewModel`, `FilterViewModel`       |
| `@riverpod` Notifier           | 同期ロジックの ViewModel        | `OnboardingUiNotifier`                   |
| `@riverpod` Future (keepAlive) | アプリ起動後に再利用する共有データ        | `filterRepositoryProvider` 等 Repository |
| `Provider override`            | DI の差し込み口（テスト・ブランド切り替え） | `brandConfigProvider`                    |

### AutoDispose の重要性

```
QuizScreen を開く
  → QuizViewModelProvider が生成
  → Firestore リスナ・SharedPreferences 読込が開始
BackButton で戻る
  → autoDispose で QuizViewModelProvider が自動破棄
  → すべてのリスナが自動クローズ
```

`@riverpod` アノテーションはデフォルトで `autoDispose` になる。`keepAlive: true` は Repository など起動後も保持したいものにのみ付与する。

---

## データ永続化の二層構造

```
QuizViewModel.answer()
    │
    ├── LocalLearningHistoryRepository.save(stats)
    │       └── SharedPreferences に JSON 保存（即時・同期）
    │
    ├── LocalDailyStudyLogRepository.record(log)
    │       └── SharedPreferences に JSON 保存（即時・同期）
    │
    └── [ログイン済み] BackupService.upload()
            ├── Firestore からリモートデータ読込
            ├── ローカルと加算マージ（正答数+正答数、誤答数+誤答数）
            └── マージ結果をローカルに保存・Firestore へ書き戻し
```

**マージ戦略の詳細**: [docs/adr/0002-drift-firestore-dual-layer.md](adr/0002-drift-firestore-dual-layer.md)

---

## ルーティング

画面遷移は `go_router` の `ShellRoute` で宣言的管理。`ExamModalSheetRouter` がモーダルの遷移ロジックを担う。

```
/ (shell)
├── /quiz          → QuizScreen（メイン画面）
├── /filter        → FilterSheet（モーダル）
├── /report        → ReportSheet（モーダル）
├── /note          → NoteSheet（モーダル）
├── /settings      → SettingsSheet（モーダル）
└── /onboarding    → OnboardingFlow
```

**ViewModel から Context を渡さない方針**: `rootNavigatorKey.currentContext` と `ExamModalSheetRouter` を経由することで、ViewModel がルーティングをトリガーしつつ `BuildContext` を直接保持しない。

---

## AppColorScheme（テーマ設計）

`AppColorScheme` は `ThemeExtension<AppColorScheme>` を継承する共通カラーコントラクト。ブランドは `darkThemeExtensions` / `lightThemeExtensions` に独自の `AppColorScheme` インスタンスを渡すことで、全コンポーネントのカラーを一括上書きできる。

```dart
// 利用側（Widget）
final c = context.appColors; // AppColorScheme

Text('テスト', style: TextStyle(color: c.fg));
```

---

## コード生成

| ツール                  | 生成対象                                           |
| -------------------- | ---------------------------------------------- |
| `freezed`            | データクラスの `copyWith` / `fromJson` / パターンマッチング    |
| `json_serializable`  | `fromJson` / `toJson`                          |
| `riverpod_generator` | `@riverpod` → `XxxxProvider` / `_$Xxxx` ミックスイン |
| `slang`              | `i18n/*.i18n.json` → 型安全アクセサ `t.xxx`           |

```bash
# packages/core 内での再生成
dart run build_runner build
```

---

## feature 一覧（packages/core/lib/features/exam_quiz/）

| feature           | 役割                                            |
| ----------------- | --------------------------------------------- |
| `quiz`            | 出題・回答・セッション管理。出題順アルゴリズム（QuizQuestionOrdering） |
| `filter`          | 年度・カテゴリ・習熟度・出題順のフィルター条件管理                     |
| `learning`        | 問題ごとの学習統計（正答数・誤答数・最終解答日）の読み書き                 |
| `report`          | 日次・累計のレポートデータ集計・ダッシュボード表示                     |
| `streak`          | 連続学習日数のカウント・フリーズ機能                            |
| `daily_study_log` | 日次の解答数・正答数・学習時間の記録                            |
| `note`            | 問題メモ・ブックマークの管理                                |
| `profile`         | ユーザープロフィール（年齢層・性別・目標設定）                       |
| `auth`            | Firebase Auth による匿名 → メール/Google ログインのリンク     |
| `backup`          | Firestore への学習履歴バックアップ・リストア（加算マージ）            |
| `onboarding`      | 初回起動フロー（目標設定・通知許可・チュートリアル）                    |
| `purchase`        | RevenueCat サブスクリプション状態の管理・paywall 表示          |
| `notification`    | リマインダー通知のスケジューリング（ブランド別チャンネルID対応）             |
| `settings`        | アプリ設定（テーマ・通知 ON/OFF）                          |
| `review`          | 復習フラグ付き問題の管理                                  |
| `router`          | `ExamModalSheetRouter`（モーダル遷移の集約）               |

---

## 10点評価と改善ロードマップ

### 現状評価：8.0 / 10

| 観点               | 点数   | コメント                                    |
| ---------------- | ---- | --------------------------------------- |
| 関心の分離           | 9/10 | View/ViewModel/Repository の境界が明確        |
| テスタビリティ         | 8/10 | Repository 抽象化 + Riverpod override で容易 |
| ホワイトラベル拡張性      | 8/10 | Config 2クラスで新アプリ追加可能                    |
| 型安全性            | 9/10 | Freezed + Riverpod Codegen + slang      |
| パフォーマンス         | 7/10 | autoDispose 適用済み。大量問題データのレイジーロードは課題    |
| 可読性・命名          | 8/10 | 汎用名（AppColorScheme・ExamModalSheetRouter）に統一済み |
| ドキュメント          | 8/10 | ADR + architecture.md 整備済み            |
| CI/CD           | 7/10 | GitHub Actions 基本構成済み。E2E は未整備        |

### 残課題（将来対応）

- **Service 層の導入**: 複数 Repository を横断するロジック（Backup・Sync）を Service として独立させる
- **E2E テスト**: `integration_test` パッケージによるクリティカルパスのカバー
- **app_fe カラー**: `FeColors` を定義して `app_fe` が IT Pass 色を参照しないように分離
- **RevenueCat / AdMob ID**: `app_fe` の本番 ID 設定

---

> 参考：[Riverpod Architecture Guide](https://riverpod.dev/docs/concepts/about_code_generation)
> 参考：[Flutter App Architecture with Riverpod](https://codewithandrea.com/articles/flutter-app-architecture-riverpod-introduction/)

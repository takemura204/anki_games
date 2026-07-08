# IT Pass Quiz — ITパスポート試験対策アプリ

**「次に解くべき1問」を自動で出す、ITパスポート試験対策の学習アプリ。** Flutter + Riverpod 3.0 で構築し、重み付き出題アルゴリズムで苦手な問題を優先出題。オフライン動作 + Firestore でのクロスデバイス同期に対応。個人開発で App Store / Google Play に公開・運用中。

[![CI](https://github.com/takemurataiki/anki_games/actions/workflows/ci.yml/badge.svg)](https://github.com/takemurataiki/anki_games/actions/workflows/ci.yml)
![Flutter](https://img.shields.io/badge/Flutter-3.41-02569B?logo=flutter)
![Dart](https://img.shields.io/badge/Dart-3.10-0175C2?logo=dart)
![State](https://img.shields.io/badge/State-Riverpod_3.0-39477F)
![License](https://img.shields.io/badge/License-MIT-blue)

**📲 ストア**: [App Store](https://apps.apple.com/jp/app/id6767179815) ・ Google Play（準備中）

---

## 目次

[解決する課題](#解決する課題) ・ [スクリーンショット](#スクリーンショット) ・ [主な機能](#主な機能) ・ [技術スタックと選定理由](#技術スタックと選定理由) ・ [アーキテクチャ](#アーキテクチャ) ・ [コアロジック](#コアロジック重み付き出題) ・ [テスト](#テスト) ・ [セットアップ](#セットアップ) ・ [制約と今後](#制約と今後) ・ [設計上の反省点](#設計上の反省点)

---

## 解決する課題

ITパスポート試験の学習者が直面する根本課題は「**何を・どの順番で解くか**」がわからないこと。既存アプリの多くは単純なランダム出題か年度順で、「苦手を効率よく潰す」体験を提供できていない。本アプリは3点をセットで解決する。

| 課題 | 解決策 |
|---|---|
| どの問題を優先すべきかわからない | 正答率・誤答回数・最終解答日に基づく**重み付き出題アルゴリズム** |
| 端末を変えると学習記録が消える | SharedPreferences でオフライン保持 + Firestore でクロスデバイス同期 |
| 学習が続かない | 連続学習ストリーク・リマインダー通知・進捗ダッシュボード |

---

## スクリーンショット

| 出題 | レポート | フィルター | ストリーク |
|---|---|---|---|
| ![出題画面](docs/screenshots/quiz.png) | ![レポート画面](docs/screenshots/report.png) | ![フィルター画面](docs/screenshots/filter.png) | ![ストリーク画面](docs/screenshots/streak.png) |

> 画像は `docs/screenshots/` に配置。

---

## 主な機能

| 機能 | 説明 |
|---|---|
| 重み付き出題 | 誤答回数・放置日数・直前結果からスコアを計算し、苦手問題を先出し |
| 習熟度バッジ | 5段階（未学習〜完璧）を問題ごとに可視化 |
| フィルター出題 | 年度・カテゴリ・習熟度・出題順で対象を絞り込み |
| 学習ログ | 日次解答数・正答率・学習時間をグラフ表示 |
| ストリーク | 連続学習日数のカウント。サボり時はフリーズ機能で救済 |
| オフライン対応 | SharedPreferences でローカル保存。ネット不要で全機能動作 |
| クラウド同期 | ログイン時に学習履歴を Firestore にバックアップ・複数端末同期 |
| 課金 / 広告 | RevenueCat でプレミアム管理、AdMob 広告（プレミアムは非表示） |

---

## 技術スタックと選定理由

採用判断の核は「なぜこの技術を選んだか」。各選定理由は ADR（Architecture Decision Record）に記録している。

| 領域 | 採用技術 | 選定理由（要約） |
|---|---|---|
| UI | Flutter 3.41 | iOS/Android を単一コードベース。Widget ツリーが MVVM と好相性 |
| 状態管理 | Riverpod 3.0 + Codegen | 宣言的 `autoDispose` でリスナ残存を防止。`overrides` で明示的・テスタブルな DI（[ADR-0001](docs/adr/0001-riverpod-over-bloc.md)） |
| モデル | Freezed / json_serializable | イミュータブルな Value Object と `copyWith` を自動生成 |
| 永続化 | SharedPreferences + Firestore | オフラインファースト + 加算マージ同期（[ADR-0002](docs/adr/0002-drift-firestore-dual-layer.md)） |
| ルーティング | go_router | 宣言的 URL ルーティング・ShellRoute でモーダル管理 |
| 構成 | Melos モノレポ | 共通ロジックを `core` に集約しホワイトラベル展開（[ADR-0003](docs/adr/0003-melos-whitelabel-monorepo.md)） |
| 課金 | RevenueCat | レシート検証・解析をダッシュボードに集約（[ADR-0004](docs/adr/0004-revenuecat-for-iap.md)） |
| i18n | slang | Dart ソースから型安全アクセサ（`t.xxx`）を生成 |

---

## アーキテクチャ

Feature 単位の **MVVM + Repository** で統一。全 feature が同じ層構造を持つため、コードの場所が予測可能。詳細は [docs/architecture.md](docs/architecture.md)。

```
View (HookConsumerWidget)
  │ ref.watch / ref.read
  ▼
ViewModel (AutoDisposeAsyncNotifier<State>)   ← 画面状態を一元管理・離脱で自動破棄
  │ 抽象インターフェースにのみ依存
  ▼
Repository (abstract)
  ├── Local 実装（SharedPreferences / drift）  ← ブランドキープレフィックス付き
  └── Remote 実装（Firestore）                 ← auth uid でドキュメント分離
  │
  ▼
Model (@freezed: immutable / copyWith / fromJson)
```

- **View**: 表示ロジックのみ。サブ Widget は private な `StatelessWidget` を `part` で集約。
- **ViewModel**: Repository の抽象にしか依存しないため、テスト時に Fake へ差し替え可能（`ProviderContainer(overrides: [...])`）。
- **Repository**: Local / Firestore の2実装。ローカルキーは `BrandConfig.analyticsBrandKey` をプレフィックス化し、複数ブランドの同一端末共存でも衝突しない。

### ホワイトラベル設計

`packages/core` に共通ロジックを集約し、各アプリは `BrandConfig`（テーマ・広告ID）と `ExamConfig`（問題データ）の差し込みのみ。新しい試験アプリを Config 2クラス（約90行）で追加できる。詳細は [docs/whitelabel/](docs/whitelabel/architecture.md)。

```
anki_games/
├── packages/
│   ├── core/         # 全アプリ共通（features 16個 / config / components）
│   ├── app_it_pass/  # ITパスポート（Config 差し込みのみ）
│   ├── app_fe/       # 基本情報技術者試験（同上）
│   └── quiz_data/    # 問題データ（CSV/JSON）管理
├── .github/workflows/  # CI（analyze / test / coverage）
└── docs/               # adr / architecture / testing / whitelabel
```

---

## コアロジック（重み付き出題）

アプリの中核は出題順を決める `QuizQuestionOrdering`。`optimized` モードは優先度スコアで苦手問題を先出しする。

```
priority = base(1.0)
         + unseen_boost(4.0)          # 未学習を最優先
         + wrongCount × 1.5           # 誤答が多いほど高優先
         + correctCount × (−0.35)     # 得意問題は出題を減らす
         + min(放置日数, 30) × 0.08   # 長期間解いていない問題を浮上
         + last_wrong_boost(2.0)      # 直前が誤答なら追加ブースト
```

同スコアはランダムタイブレークで単調さを排除。習熟度は `LearningLevel.fromStats()` が統計から5段階（未学習 / 苦手 / うろ覚え / 得意 / 完璧）を判定し、バッジ色で可視化する。

---

## テスト

`packages/core` に Unit / Widget テストを実装し、CI（GitHub Actions）で毎 push 実行・カバレッジを artifact 保存。方針の詳細は [docs/testing.md](docs/testing.md)。

- **ピラミッド**: Unit 70%（出題アルゴリズム・習熟度判定・ストリーク）/ Widget 20% / E2E 10%
- **モック**: 手書き Fake Repository を基本とし、呼び出し検証が要る箇所のみ `mocktail`
- **Riverpod**: `ProviderContainer(overrides: [...])` で依存を差し替え

```bash
flutter test -C packages/core --coverage
```

---

## セットアップ

```bash
# 1. クローン & 依存解決（core → app の順）
git clone https://github.com/takemurataiki/anki_games.git
cd anki_games
flutter pub get -C packages/core
flutter pub get -C packages/app_it_pass

# 2. Firebase 設定ファイルを配置（.gitignore 済み。Firebase コンソールから取得）
#    android/app/google-services.json
#    ios/Runner/GoogleService-Info.plist

# 3. コード生成 & 実行
cd packages/app_it_pass
dart run build_runner build --delete-conflicting-outputs
flutter run --flavor it_pass
```

**主要コマンド**

```bash
flutter analyze -C packages/core        # 静的解析（実装後は必須）
dart run melos run analyze              # モノレポ一括解析
dart run build_runner build --delete-conflicting-outputs  # コード生成
```

---

## 制約と今後

成長余地を明示する（採用観点で重要なシグナル）。

- **ViewModel のテスト**: コアドメインは網羅済みだが、`QuizViewModel` 等の ViewModel 層は未カバー。
- **DI の徹底**: 一部 ViewModel が Repository を直接 `new` しており、Provider override を完全化したい。
- **E2E**: クリティカル動線のスモークテスト（Maestro / Patrol）を未整備。
- **カバレッジゲート**: 現状は CI でテスト実行のみ。閾値未満で fail させる仕組みを追加予定。

---

## 設計上の反省点

最初から判断しておくべきだった点。

1. **テストの後回し** — 「まず動くものを」を優先した結果、ViewModel が Repository を直接インスタンス化するコードが積み上がった。最初から抽象 + Fake を用意していればリファクタコストを抑えられた。
2. **Riverpod 記法の混在** — 途中で `riverpod_generator` に移行したため旧 `FutureProvider` と混在した時期があった。規約を lint で強制する仕組みを先に置くべきだった。
3. **モノレポ化の後付け** — `app_it_pass` 単体で開発を始め、後から `core` 分離・ホワイトラベル化を行い import 置換コストが発生した。

---

## ライセンス

[MIT License](LICENSE)

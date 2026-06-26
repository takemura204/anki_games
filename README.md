# IT Pass Quiz — ITパスポート試験対策アプリ

[![CI](https://github.com/takemurataiki/anki_games/actions/workflows/ci.yml/badge.svg)](https://github.com/takemurataiki/anki_games/actions/workflows/ci.yml)
![Flutter](https://img.shields.io/badge/Flutter-3.41-02569B?logo=flutter)
![Dart](https://img.shields.io/badge/Dart-3.10-0175C2?logo=dart)

> **Status:** App Store / Google Play で公開中・個人運用

---

## 目次

1. [解決する課題](#1-解決する課題)
2. [アーキテクチャ](#2-アーキテクチャ)
3. [主要技術の選定理由](#3-主要技術の選定理由)
4. [コアロジック：重み付き出題アルゴリズム](#4-コアロジック重み付き出題アルゴリズム)
5. [機能一覧](#5-機能一覧)
6. [リポジトリ構成（ホワイトラベル・モノレポ）](#6-リポジトリ構成ホワイトラベルモノレポ)
7. [セットアップ](#7-セットアップ)
8. [開発コマンド](#8-開発コマンド)
9. [テスト戦略](#9-テスト戦略)
10. [CI/CD](#10-cicd)
11. [既知の制約と今後の改善](#11-既知の制約と今後の改善)
12. [設計上の反省点（What I'd do differently）](#12-設計上の反省点)

---

## 1. 解決する課題

ITパスポート試験の学習者が直面する根本的な課題は「何を・いつ・どの順番で解くか」がわからないことにある。既存のアプリの多くは問題を単純にランダム出題するか、年度順に並べるだけで、**「苦手な問題を効率よく潰す」体験を提供できていない**。

本アプリは以下の3つをセットで解決する。

| 課題 | 解決策 |
|---|---|
| どの問題を優先すべきかわからない | 正答率・誤答回数・最終解答日に基づく**重み付き出題アルゴリズム** |
| 端末を変えたら学習記録が消える | drift（SQLite）でオフライン保持 + Firestore でクロスデバイス同期 |
| 学習が続かない | 連続学習ストリーク・通知リマインダー・進捗ダッシュボード |

---

## 2. アーキテクチャ

### レイヤー構成（MVVM + Repository パターン）

```
┌─────────────────────────────────────────────────────────────────┐
│  View (HookConsumerWidget)                                      │
│  ┌──────────────┐  ref.watch  ┌──────────────────────────────┐  │
│  │ Screen/Modal │ ──────────▶ │ ViewModel                    │  │
│  │              │ ◀────────── │ AutoDisposeAsyncNotifier<S>   │  │
│  └──────────────┘  state      └──────────────────────────────┘  │
│         │ go_router                        │ ref.read             │
│         ▼                                  ▼                      │
│  ┌──────────────┐              ┌──────────────────────────────┐  │
│  │  sub Widget  │              │ Repository (abstract)        │  │
│  │ (private /   │              │ ┌────────────┐ ┌──────────┐ │  │
│  │ StatelessWidget)            │ │ Local impl │ │ Firestore│ │  │
│  └──────────────┘              │ │ (drift/SP) │ │  impl    │ │  │
│                                │ └────────────┘ └──────────┘ │  │
│                                └──────────────────────────────┘  │
└─────────────────────────────────────────────────────────────────┘
```

- **View**: `HookConsumerWidget`（Hooks + Riverpod を同時利用）。純粋な表示ロジックのみ。
- **ViewModel**: `AutoDisposeAsyncNotifier<State>`。画面単位の状態を一元管理。ナビゲーション離脱で自動破棄。
- **Repository**: 抽象インターフェース＋Local/Firestore の2実装。ViewModel はインターフェースにしか依存しないため、テスト時にインメモリ Fake へ差し替え可能。

### feature ディレクトリ構成

各 feature を同じ層構造で統一することで、コードの場所が予測可能になる。

```
features/exam_quiz/
├── quiz/
│   ├── model/           # Freezed データクラス
│   ├── repository/      # abstract + Local/Firestore 実装
│   ├── view_model/      # AutoDisposeAsyncNotifier
│   └── view/
│       ├── quiz_screen.dart         # Screen（HookConsumerWidget）
│       └── widgets/                 # プライベートサブ Widget
├── filter/
├── learning/
├── report/
└── ...（計16 feature）
```

### データフロー（クイズ回答時）

```
ユーザーが選択肢タップ
        │
        ▼
QuizViewModel.answer(choiceIndex)
        │
        ├── LocalLearningHistoryRepository.save()   → drift (SQLite)
        ├── LocalDailyStudyLogRepository.record()   → SharedPreferences
        ├── StreakViewModel.recordStudy()            → SharedPreferences
        └── [ログイン済み] FirestoreLearningHistoryRepository.save() → Firestore
```

---

## 3. 主要技術の選定理由

### なぜ Riverpod（hooks_riverpod + riverpod_generator）か

BLoC・旧 Provider との比較で選択した。

| 観点 | BLoC | 旧 Provider | **Riverpod（採用）** |
|---|---|---|---|
| コード量 | Event/State クラスが多く冗長 | ChangeNotifier の dispose 漏れリスク | `@riverpod` アノテーションで最小記述 |
| テスタビリティ | bloc_test で別途対応 | モック差し替えが手動 | `ProviderContainer(overrides: [...])` で完全な DI |
| AutoDispose | 手動 | 手動 | 宣言的・自動（画面離脱で即破棄） |
| 型安全なコード生成 | ✓ | ✗ | ✓（riverpod_generator） |

`AutoDisposeAsyncNotifier` を採用することで「画面離脱で状態が自動破棄される」ため、画面スタックが深くなっても不要な Firestore リスナが残り続けるリスクをアーキテクチャレベルで排除している。

> 詳細は [docs/adr/0001-riverpod-over-bloc.md](docs/adr/0001-riverpod-over-bloc.md)

### なぜ drift（SQLite）+ Firestore の二層同期か

- **オフラインファースト設計**: 学習記録の読み書きはすべて drift（ローカル）に対して行う。Firestore へは「バックアップ兼他端末同期」として非同期にプッシュする。これにより、ネットワーク不安定・未ログイン時でも一切機能が落ちない。
- **マージ戦略**: ローカルとリモートが乖離した場合は「正答数・誤答数を加算マージ」を採用。単純な上書きは「片方の端末の記録が消える」問題を起こすため選択しなかった。
- **コスト管理**: Firestore 読み取りは起動時の1回だけ（以降はローカル参照）。アクティブユーザーでも月間読み取り数が無料枠に収まる設計。

> 詳細は [docs/adr/0002-drift-firestore-dual-layer.md](docs/adr/0002-drift-firestore-dual-layer.md)

### なぜ Melos モノレポか

現在 `app_it_pass`（ITパスポート）と `app_fe`（基本情報技術者試験）の2アプリが存在する。共通ロジックを `packages/core` に集約し、アプリパッケージは `BrandConfig`（テーマ・広告ID）と `ExamConfig`（問題データ・カテゴリ）の差し込みだけを担う薄い構成にした。

これにより「バグ修正は `core` の1ファイルを直すだけで全アプリに反映」される。Melos の `exec` コマンドで全パッケージに一括して analyze・test・codegen を実行できる。

> 詳細は [docs/adr/0003-melos-whitelabel-monorepo.md](docs/adr/0003-melos-whitelabel-monorepo.md)

### なぜ RevenueCat か

iOS/Android のサブスクリプション課金を自前実装すると、レシート検証（サーバーサイド）・払い戻し検知・価格変更対応・A/Bテストのたびに数百行のプラットフォーム固有コードが増える。RevenueCat を採用することで：

- 課金ロジックを `purchases_flutter` の数行の呼び出しに封じ込め
- ダッシュボードで MRR・チャーン・トライアル転換率を即座に可視化
- Stripe 等と連携せずにサブスク解析が完結

個人開発でサーバー運用コストを持ちたくない制約下での最適解として採用した。

---

## 4. コアロジック：重み付き出題アルゴリズム

アプリの中核となる出題順決定ロジック（`QuizQuestionOrdering`）を解説する。

### 3つの出題モード

```
sequential  → 年度・番号順（体系的に全問解きたい場合）
random      → シャッフル（気分転換）
optimized   → 重み付きスコアで優先度の高い問題を先出し ← 本命
```

### optimized モードの優先度スコア計算

```
priority = base(1.0)
         + unseen_boost(4.0)         # 一度も解いていない問題を優先
         + wrongCount × 1.5          # 誤答が多いほど高優先
         + correctCount × (−0.35)    # 正答が多いほど低優先（得意問題を減らす）
         + min(放置日数, 30) × 0.08  # 長期間解いていない問題を浮上させる
         + last_wrong_boost(2.0)      # 直前の回答が誤答なら追加ブースト
```

同スコア時はランダムタイブレークにより、スコアが等しい問題群の中では毎回異なる順序になる（単調さを排除）。

### 5段階の習熟度分類（LearningLevel）

`LearningLevel.fromStats()` は1問ごとの学習統計から UI 上のバッジ色を決定する。

```
未学習  → 試行回数が0（スタート地点）
苦手    → 誤答数 > 正答数
うろ覚え→ 上記以外（まだ不安定）
得意    → 正答率65%以上 かつ 正答 > 誤答
完璧    → 4回以上試行 かつ 正答率85%以上 かつ 直前も正解
```

この分類を視覚フィードバックとして表示することで「何が苦手か」を一目で把握できる。

---

## 5. 機能一覧

| 機能 | 説明 |
|---|---|
| 過去問出題 | ITパスポート全期間の過去問を年度・カテゴリ・習熟度でフィルタリング |
| 重み付き出題 | 誤答回数・放置日数・直前結果に基づくスコアで優先度を計算 |
| 習熟度バッジ | 5段階（未学習〜完璧）を問題ごとに可視化 |
| 学習ログ | 日次解答数・正答率・学習時間をグラフ表示 |
| ストリーク | 連続学習日数のカウント。1日サボり時はフリーズ機能で救済 |
| オフライン対応 | drift（SQLite）でローカル保存。ネット不要で全機能動作 |
| Firestore 同期 | ログイン時に学習履歴をクラウドバックアップ・複数端末同期 |
| オンボーディング | 初回起動の目標設定・チュートリアル。通知許可の適切なタイミング誘導 |
| 通知 | `flutter_local_notifications` による毎日のリマインダー |
| サブスクリプション | RevenueCat でプレミアムプランを管理（月額・買い切り） |
| 広告 | AdMob によるバナー・動画広告（無料ユーザー向け・プレミアムは非表示） |

---

## 6. リポジトリ構成（ホワイトラベル・モノレポ）

```
anki_games/
├── packages/
│   ├── core/               # 全アプリ共通ロジック（features, config, components）
│   │   └── lib/
│   │       ├── config/
│   │       │   ├── brand/    # BrandConfig 抽象（テーマ・広告ID・RevenueCat設定）
│   │       │   └── exam/     # ExamConfig 抽象（問題データ定義・カテゴリ）
│   │       └── features/
│   │           └── exam_quiz/  # 16 feature（quiz/filter/learning/report/...）
│   ├── app_it_pass/        # ITパスポートアプリ（Config 差し込みのみ）
│   ├── app_fe/             # 基本情報技術者試験アプリ（Config 差し込みのみ）
│   └── app_block_puzzle/   # ブロックパズル + 英単語クイズ（別ドメイン）
├── .github/workflows/      # GitHub Actions（analyze / test）
├── Makefile                # iOS/Android リリース自動化
├── melos.yaml              # モノレポタスク管理
└── docs/
    ├── adr/                # Architecture Decision Records（意思決定の記録）
    ├── architecture.md     # アーキテクチャ詳細
    ├── testing.md          # テスト戦略
    └── portfolio_roadmap.md # 開発ロードマップ
```

`app_it_pass/main.dart` は `ProviderScope` の `overrides` で `BrandConfig` と `ExamConfig` の具体実装を注入するだけ。アプリ固有コードは Config クラス2つに封じ込めている。

---

## 7. セットアップ

### 必要環境

- Flutter 3.41 以上（`flutter --version` で確認）
- Dart 3.10.0 以上
- Firebase プロジェクト（Firestore / Authentication を有効化）

### 手順

```bash
# 1. リポジトリのクローン
git clone https://github.com/takemurataiki/anki_games.git
cd anki_games

# 2. 依存関係のインストール（core → app_it_pass の順）
flutter pub get -C packages/core
flutter pub get -C packages/app_it_pass

# 3. 環境変数の設定
cp .env.example packages/app_it_pass/lib/config/env/.env
# .env に AdMob ユニットID・RevenueCat APIキーを設定

# 4. Firebase 設定ファイルを配置
# android/app/google-services.json
# ios/Runner/GoogleService-Info.plist
# ※ .gitignore により除外済み。Firebase コンソールから取得してください。

# 5. コード生成
cd packages/app_it_pass
dart run build_runner build --delete-conflicting-outputs

# 6. 実行
flutter run --flavor it_pass
```

---

## 8. 開発コマンド

```bash
# 静的解析（実装後は必ず実行）
flutter analyze -C packages/app_it_pass
flutter analyze -C packages/core

# テスト
flutter test -C packages/core

# コード生成（Freezed / Riverpod / json_serializable）
dart run build_runner build --delete-conflicting-outputs

# モノレポ一括解析
dart run melos run analyze

# リリース（iOS + Android）
make release-it-pass
```

---

## 9. テスト戦略

詳細は [docs/testing.md](docs/testing.md) を参照。

**テストピラミッド方針**

```
        /\
       /  \   Integration（E2E）: 10% — クリティカル動線のみ（Maestro/Patrol）
      /    \
     /------\  Widget: 20% — 主要画面の表示・インタラクション
    /        \
   /----------\  Unit: 70% — コアドメインロジック（出題アルゴリズム・習熟度判定・ストリーク）
```

**Unit テストの対象（優先度順）**

| クラス | テスト観点 |
|---|---|
| `QuizQuestionOrdering` | 各モードの順序・優先度スコアの境界値 |
| `LearningLevel.fromStats` | 5段階分類の全分岐（nullチェック含む） |
| `LocalStreakRepository.recordStudy` | 連続/途切れ/フリーズ消費/同日重複 |
| `ReportStats` 集計 | 累計・日次配列の長さ・正答率 |

**モック方針**: `mocktail`（コード生成不要）+ 手書き Fake Repository。`ProviderContainer(overrides: [...])` で Riverpod 依存を差し替え。

---

## 10. CI/CD

### 現在の構成

```
Push → GitHub Actions
         └── flutter analyze（全パッケージ: core / app_it_pass / app_fe）
               + --fatal-infos（info 以上もエラー扱い）
```

### 整備中（docs/portfolio_roadmap.md Phase A-3）

```
flutter test --coverage（packages/core）
  └── lcov から *.g.dart / *.freezed.dart を除外 → カバレッジレポート生成
```

### リリース（手動）

```
make release-it-pass
  ├── ビルド番号自動インクリメント
  ├── flutter build ipa / appbundle（--flavor it_pass）
  ├── Fastlane Pilot → TestFlight
  └── Fastlane Supply → Google Play 内部テスト
```

---

## 11. 既知の制約と今後の改善

### 現時点の制約

- **テストカバレッジ**: コアロジックの Unit テストは整備中（`docs/portfolio_roadmap.md` の Phase A 対応中）。
- **DI の不徹底**: `QuizViewModel` など一部の ViewModel が Repository を直接 `new` しており、Provider override によるテスト時差し替えが完全ではない。
- **Riverpod 記法の混在**: `reportStatsProvider` など一部が `@riverpod` 生成でなく素の `FutureProvider` を使用している。統一対応予定。

### 今後の改善（ロードマップより）

- Widget テストの追加（クイズ回答フロー・結果画面）
- CI にテスト・カバレッジゲートを追加
- `features/quiz`（旧ブロックパズル用）と `features/exam_quiz` の重複コード整理
- サブスクリプション導線の改善（paywall 最適化）
- E2E スモークテスト（Maestro または Patrol）

---

## 12. 設計上の反省点

振り返ると、以下の判断を最初からしておくべきだった。

**1. テストを後回しにしたこと**
「まず動くものを」を優先したため、ViewModel が Repository を直接インスタンス化するコードが積み上がった。最初から `abstract class` + Fake を用意してテストと並走していれば、リファクタコストが大幅に減った。

**2. Riverpod 記法の部分的な導入**
プロジェクト途中で `riverpod_generator` に移行したため、旧来の `FutureProvider` / `StateNotifierProvider` が混在した時期があった。アーキテクチャ上の規約を `AGENTS.md` や `analysis_options.yaml` のカスタムルールで強制する仕組みを最初から置くべきだった。

**3. モノレポ化の後付け**
`app_it_pass` 単体で開発を始め、あとから `core` 分離とホワイトラベル化を行った。最初からモノレポ + Config 抽象を設計していれば、移設の際の import 置換コストが発生しなかった。

---

## ライセンス

[MIT License](LICENSE)

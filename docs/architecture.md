# アーキテクチャ詳細

> 採用担当・コードレビュアー向け。設計の判断理由は [docs/adr/](adr/) を参照。

---

## 全体構成

本プロジェクトは **Melos モノレポ**で管理された Flutter アプリ群。共通ロジックを `packages/core` に集約し、各アプリパッケージは薄いエントリとして `BrandConfig`（見た目・ID）と `ExamConfig`（問題データ定義）を差し込むだけの構成にしている。

```
anki_games/（モノレポルート）
│
├── packages/core/           ← 全アプリ共通。ここにビジネスロジックが集中する
│   └── lib/
│       ├── config/
│       │   ├── brand/       ← BrandConfig 抽象（テーマ・広告ID・RevenueCat設定）
│       │   └── exam/        ← ExamConfig 抽象（問題一覧・カテゴリ・無料範囲）
│       ├── features/
│       │   └── exam_quiz/   ← 試験クイズ機能（16 feature）
│       └── components/      ← 共通 UI コンポーネント
│
├── packages/app_it_pass/    ← ITパスポート（Config 2クラスのみ）
├── packages/app_fe/         ← 基本情報技術者試験（Config 2クラスのみ）
└── packages/app_block_puzzle/ ← ブロックパズル（別ドメイン・共有なし）
```

---

## レイヤー設計（MVVM + Repository パターン）

```
┌──────────────────────────────────────────────────────────────────┐
│ View 層                                                          │
│   HookConsumerWidget  ─ref.watch(viewModelProvider)→ ViewModel   │
│   ├── Screen（1画面1クラス）                                      │
│   └── widgets/（プライベート StatelessWidget、part ディレクティブで集約）│
├──────────────────────────────────────────────────────────────────┤
│ ViewModel 層                                                     │
│   AutoDisposeAsyncNotifier<XxxxState>                            │
│   ├── build() で初期データをロード                                 │
│   ├── ユーザー操作に対応するメソッドを公開                           │
│   └── Repository にのみ依存（View の知識を持たない）                │
├──────────────────────────────────────────────────────────────────┤
│ Repository 層                                                    │
│   abstract class XxxxRepository { ... }                          │
│   ├── LocalXxxxRepository（drift / SharedPreferences）           │
│   └── FirestoreXxxxRepository（cloud_firestore）                 │
├──────────────────────────────────────────────────────────────────┤
│ Model 層                                                         │
│   Freezed データクラス（immutable・copyWith・fromJson/toJson）      │
└──────────────────────────────────────────────────────────────────┘
```

**Repository を抽象化する理由**: ViewModel がインターフェースにしか依存しないため、テスト時に `FakeXxxxRepository` を `ProviderContainer(overrides: [...])` でワンライン差し替えできる。Local と Firestore の切り替えも View/ViewModel のコードに触れずに済む。

---

## 状態管理（Riverpod）

### Provider の種類と使い分け


| Provider                  | 用途                  | 例                                           |
| ------------------------- | ------------------- | ------------------------------------------- |
| `@riverpod` AsyncNotifier | 非同期データを持つ ViewModel | `QuizViewModel`, `FilterViewModel`          |
| `@riverpod` Notifier      | 同期ロジックの ViewModel   | `OnboardingUiNotifier`                      |
| `@riverpod` Future        | 単一の非同期値（複数画面で共有）    | `learningHistoryRepositoryProvider`         |
| Provider override         | DI の差し込み口           | `brandConfigProvider`, `examConfigProvider` |


### AutoDispose の重要性

```
ユーザーが QuizScreen を開く
  → QuizViewModelProvider が生成される
  → Firestore リスナ・drift クエリが開始
ユーザーが BackButton で戻る
  → autoDispose により QuizViewModelProvider が自動破棄
  → すべてのリスナ・クエリが自動でクローズ
```

`autoDispose` を付け忘れると、画面スタックが深くなるほど不要なリソースが積み上がる。`@riverpod` アノテーションはデフォルトで `autoDispose` になるため、記法の統一がリソースリークの防止に直結する。

---

## データ永続化の二層構造

```
QuizViewModel.answer()
    │
    ├── LocalLearningHistoryRepository.save(stats)
    │       └── SharedPreferences に JSON として保存（即時・同期）
    │
    ├── LocalDailyStudyLogRepository.record(log)
    │       └── SharedPreferences に JSON として保存（即時・同期）
    │
    └── [ログイン済み] FirestoreLearningHistoryRepository.save(stats)
            └── Firestore へ非同期プッシュ（失敗しても UI はブロックしない）

復元時（起動・ログイン後のバックアップ復元）
    └── SyncService.restore()
            ├── Firestore からロード
            ├── ローカルと加算マージ（正答数+正答数、誤答数+誤答数）
            └── マージ結果をローカルに保存
```

マージ方針の詳細は [docs/adr/0002-drift-firestore-dual-layer.md](adr/0002-drift-firestore-dual-layer.md) を参照。

---

## ルーティング（go_router）

画面遷移はすべて `go_router` で宣言的に管理。モーダルシートも `ShellRoute` で定義しており、URL ベースのディープリンクが将来対応できる構造になっている。

```
/ (shell)
├── /quiz          → QuizScreen
├── /filter        → FilterSheet（モーダル）
├── /report        → ReportSheet（モーダル）
├── /note          → NoteSheet（モーダル）
├── /settings      → SettingsSheet（モーダル）
└── /onboarding    → OnboardingFlow
```

---

## ホワイトラベル注入（Config DI）

```dart
// packages/app_it_pass/lib/main.dart
void main() {
  runApp(
    ProviderScope(
      overrides: [
        brandConfigProvider.overrideWithValue(ItPassBrandConfig()),
        examConfigProvider.overrideWithValue(ItPassExamConfig()),
      ],
      child: const CoreApp(),
    ),
  );
}
```

`CoreApp`（packages/core）は `brandConfigProvider` / `examConfigProvider` を `ref.watch` するだけで、どのアプリの設定が入っているかを意識しない。新試験アプリの追加は Config クラス2つを書くだけで完了する。

---

## コード生成

本プロジェクトは以下のコード生成ツールを使用する。**生成ファイル（`.g.dart` / `.freezed.dart`）は `.gitignore` に含め、CI で再生成する。**


| ツール                  | 生成対象                                           |
| -------------------- | ---------------------------------------------- |
| `freezed`            | データクラスの `copyWith` / `fromJson` / パターンマッチング    |
| `json_serializable`  | `fromJson` / `toJson`                          |
| `riverpod_generator` | `@riverpod` → `XxxxProvider` / `_$Xxxx` ミックスイン |
| `drift_dev`          | drift テーブルの型安全クエリ                              |


変更後の再生成コマンド:

```bash
dart run build_runner build --delete-conflicting-outputs
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
| `backup`          | Firestore への学習履歴バックアップ・リストア                   |
| `onboarding`      | 初回起動フロー（目標設定・通知許可・チュートリアル）                    |
| `purchase`        | RevenueCat サブスクリプション状態の管理・paywall 表示          |
| `notification`    | リマインダー通知のスケジューリング                             |
| `settings`        | アプリ設定（テーマ・通知 ON/OFF・TTS）                      |
| `review`          | 復習フラグ付き問題の管理                                  |



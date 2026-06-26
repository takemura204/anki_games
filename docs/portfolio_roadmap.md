# ポートフォリオ昇華ロードマップ（リビングドキュメント）

> このファイルは「常に見返して、何をすればいいかを更新する」ための司令塔です。
> 着手前にここを開き、終わったらチェックを入れて「進捗ログ」に1行残す運用にします。

最終更新: 2026-06-24

---

## 0. ゴール（何のためにやるか）

| 区分 | ゴール | 期限 |
|---|---|---|
| 転職 | メガベンチャー（メルカリ / DeNA / LINEヤフー等）面接官が「保守性・テスト可能・モダン」と評価するコード品質 | 2026-12 内定 |
| 今月 | 公開GitHubリポジトリに「Unit/Widgetテスト + CI + 詳細README」が揃った状態 | 2026-07 末 |
| 事業 | 月1万円の収益をスケール（サブスク導線改善・機能拡充） | 継続 |

**今月の比重: ポートフォリオ 7 : グロース 3**

### 「完成」の定義（Definition of Done / 7月末）
- [ ] コアロジックの Unit テストが green（`QuizQuestionOrdering` / `LearningLevel` / `Streak` / `ReportStats`）
- [ ] 主要画面の Widget テストが green（クイズ回答→正誤、結果、レポート）
- [ ] GitHub Actions で `analyze` + `test` + カバレッジが自動実行
- [ ] README に「技術選定理由・アーキ解説・テスト戦略」を記載
- [ ] 公開前の秘匿情報クリーン完了（履歴含む）

---

## 1. テスト戦略（採用方針の確定版）

- **テストピラミッド**: Unit 70% / Widget 20% / Integration(E2E) 10%
- **モック**: `mocktail`（コード生成不要・null安全）。呼び出し検証が要る箇所のみ `Mock`、基本は**手書き Fake**。
- **Riverpod**: Unit は `ProviderContainer` + `overrides`（`addTearDown` で破棄）。Widget は `ProviderScope` + `overrides`。
- **カバレッジ**: `flutter test --coverage` → lcov（生成ファイル `*.g.dart` / `*.freezed.dart` 除外）。CI でゲート化。
- **E2E（Maestro / Patrol）**: 今月はやらない。Phase C で「クリティカル動線1〜2本のスモーク」のみ任意導入。

---

## 2. 週次スケジュール（4週間）

| 週 | テーマ | 主タスク |
|---|---|---|
| Week 1 (〜7/6) | テスト基盤 + コアUnit | A-1 基盤整備 / A-2 純粋ロジックUnit |
| Week 2 (〜7/13) | DI化 + CI強化 | A-1 DIリファクタ / A-3 CI(test+カバレッジ) |
| Week 3 (〜7/20) | Widgetテスト + Riverpod統一 | B-1 / B-2 |
| Week 4 (〜7/27) | README + 整理 + 公開 + グロース | B-3 / C-1（秘匿情報）/ C-3（サブスク導線） |

---

## 3. タスクボード（優先度 A → B → C）

ステータス: `[ ]` 未着手 / `[~]` 進行中 / `[x]` 完了

### 優先度A（必須・ポートフォリオ直結）

- [x] **A-1 テスト容易化リファクタ**
  - [x] `core/pubspec.yaml` の dev_dependencies に `mocktail` を追加
  - [x] `packages/core/test/` 雛形ディレクトリ作成（`features/exam_quiz/...` 構成をミラー）
  - [ ] ViewModel が直接 `new` している Repository を ref 注入（Provider override 可能）に変更
        - [ ] `QuizViewModel` の `_repository` 等を provider 経由に
- [x] **A-2 コアドメイン Unit テスト**（26件 all green）
  - [x] `QuizQuestionOrdering`（sequential 順序 / weighted 優先度の境界値・未学習ブースト）
  - [x] `LearningLevel.fromStats`（unseen / weak / fuzzy / familiar / mastered の全分岐）
  - [x] `QuestionLearningStats`（fromJson / toJson / copyWith）
  - [x] `LocalStreakRepository.recordStudy`（連続 / 途切れ / フリーズ消費 / 同日二重記録）
  - [x] `ReportStats` 集計（static ヘルパー: formatCount / studyTimePrimary / secondary / delta）
- [x] **A-3 CI 強化**
  - [x] `.github/workflows/ci.yml` に `flutter test --coverage` ジョブ追加
  - [x] lcov アーティファクト保存、生成ファイル除外
  - [ ] lint 設定を全パッケージで統一（root=pedantic_mono / core=flutter_lints の不一致解消）

### 優先度B（差別化・モダンさの証明）

- [x] **B-1 主要画面 Widget テスト**
  - [x] クイズ回答フロー（選択→正誤表示）: `QuizChoiceButton` 6件 green
  - [ ] 結果画面（`finished_result_page`）
  - [ ] レポート画面
- [x] **B-2 Riverpod 完全統一**
  - [x] 素の `FutureProvider` / `StreamProvider` / `Provider` を `@riverpod` へ移行（`report_stats_provider` / `auth_user_provider` / `it_pass_learning_stats_provider` / `quiz_sync_notifier`）
  - [ ] `flutter_riverpod` 依存を pubspec から除去（`hooks_riverpod` に一本化）
- [ ] **B-3 README 拡充**（完了済み ↓ Phase 1-1〜1-4 で対応）
  - [x] 技術選定理由（なぜ Riverpod / drift / Firestore / RevenueCat か）→ `docs/adr/0001〜0003.md`
  - [x] アーキテクチャ解説（層構成・データフロー）→ `docs/architecture.md`
  - [x] テスト戦略セクション → `docs/testing.md`
  - [ ] スクリーンショット差し込み（現状 TODO プレースホルダ）

### 優先度C（仕上げ・グロース）

- [ ] **C-1 公開前クリーン**（公開前に必須）
  - [ ] 履歴クリーン: `.env` / `google-services.json` / `GoogleService-Info.plist` / `StoreKit.storekit` を履歴から除去（orphan 作り直し or git-filter-repo）
  - [ ] `.gitignore` 修正: `.storekit` → `*.storekit`（`StoreKit.storekit` が現在追跡漏れ）
  - [ ] `.env` のキー再発行（AdMob / RevenueCat）
- [ ] **C-2 パフォーマンス/整理**
  - [ ] レガシー/dead code 整理（`features/quiz` と `features/exam_quiz/quiz` の重複）
  - [ ] `select` / `Consumer` スコープ化で不要リビルド削減、`const` 徹底
- [ ] **C-3 グロース（別トラック / 比重30%）**
  - [ ] サブスク導線（paywall）改善
  - [ ] 課金率・離脱の計測
- [ ] **C-4 E2E スモーク（任意）**
  - [ ] Maestro / Patrol を比較し 1〜2本のクリティカル動線を追加

---

## 4. 秘匿情報チェックリスト（公開前ゲート）

- [ ] 真の機密（`private_keys/*.p8` / firebase-adminsdk JSON / service-account JSON）が**履歴にも無い**ことを確認 ← 現状OK
- [ ] `.env` を履歴から除去 + キー再発行
- [ ] `google-services.json` / `GoogleService-Info.plist` を履歴から除去
- [ ] `ios/StoreKit.storekit` を追跡解除 + `.gitignore` 修正
- [ ] 公開直前に `git log --all --name-only` で再スキャン

---

## 5. 運用ルール（このドキュメントの使い方）

1. 作業開始時にこのファイルを開き、「今日やること」を1つ選ぶ（原則 A → B → C の順）。
2. 着手したら `[ ]` → `[~]`、完了したら `[x]` に更新。
3. 完了したら下の「進捗ログ」に日付+1行で記録。
4. 1ファイル変更ごとに `flutter analyze`（0件）/ `flutter test`（green）を回す。
5. 方針が変わったら「最終更新」日付とテスト戦略/スケジュールを更新。

---

## 6. 進捗ログ

| 日付 | 区分 | 内容 |
|---|---|---|
| 2026-06-24 | 計画 | 現状分析・ロードマップ策定・テスト方針(mocktail)確定・秘匿情報点検 |
| 2026-06-24 | Phase1 | README.md 全面改訂（7要素・技術選定理由・アルゴリズム図解・反省点） |
| 2026-06-24 | Phase1 | docs/adr/ 新設（ADR-0000〜0004: ADR運用/Riverpod/drift+Firestore/Melos/RevenueCat） |
| 2026-06-24 | Phase1 | docs/testing.md 新設（テストピラミッド・モック方針・テンプレート・CI予定） |
| 2026-06-24 | Phase1 | docs/architecture.md 採用者向け全面改訂（レイヤー図・DI・feature一覧） |
| 2026-06-24 | Phase2 | A-1: mocktail 追加、test/ ディレクトリ作成 |
| 2026-06-24 | Phase2 | A-2: Unit テスト 26件 green（QuizQuestionOrdering / LearningLevel / Streak） |
| 2026-06-24 | Phase2 | A-3: CI に test+カバレッジジョブ追加、lint 既存1件修正 |
| 2026-06-24 | Phase2 | A-2残り: QuestionLearningStats / ReportStats Unit テスト追加（計43件 green） |
| 2026-06-24 | Phase2 | B-2: FutureProvider/StreamProvider を @riverpod に統一（4ファイル）、CI に core の build_runner ステップ追加 |
| 2026-06-24 | Phase2 | B-1: QuizChoiceButton Widget テスト 6件 green（未回答/正解/誤答/タップ制御） |

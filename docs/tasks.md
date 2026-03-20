# タスクドキュメント — Block.

> 最終更新: 2026-03-20（リファクタリング実施）

---

## 完了済みフェーズ

### Phase 1: ゲームコア ✅

- [x] 8×8ボードのブロック配置ロジック
- [x] ライン消去ロジック（行・列）
- [x] ピース生成・ドラッグ配置UI
- [x] スコア・コンボシステム
- [x] ゲームオーバー判定

### Phase 2: ゲームモード拡充 ✅

- [x] クラシックモード（セーブ・ロード・コンティニュー）
- [x] クエストモード（レベル管理・目標スコア・レベル解放）
- [x] タイムアタックモード（90秒・カウントダウン演出）
- [x] テーマ・スキンシステム（9種のセルレンダリングモード）
- [x] 設定ダイアログ（サウンド・バイブレーション・テーマ変更・ホーム/リスタート）
- [x] AdMob 広告統合（バナー・インタースティシャル・リワード）
- [x] アプリアイコン・ロゴ更新

### Phase 2.5: クイズモード基盤 ✅

- [x] CSV単語データソース（`assets/quiz/words.csv`）
- [x] Drift DB（`WordRecords` テーブル、weight/正誤回数/最終出題日）
- [x] QuizWord モデル（Freezed）
- [x] QuizViewModel 基盤（重み付きランダム選出・4択生成・回答処理）
- [x] スワイプカードUI（`flutter_card_swiper`）
- [x] ブロックフェーズ ↔ クイズフェーズの切り替えアニメーション
- [x] ピース難易度割り当て（充填率×正誤の2軸: `addQuizPiece()`）
- [x] クイズモードのゲームオーバー・Play Again
- [x] 出題方向モード（英→日 / 日→英 / ランダム）設定
- [x] クイズモード中の設定ダイアログ（出題方向セグメント）
- [x] **バグ修正**: 設定画面で出題方向変更後にラウンドが即終了する不具合（`setDirectionMode` で answeredCount等をリセット）

### Phase 3: 習熟度表示・学習範囲選択 ✅

- [x] CSVに `level` フィールド追加（eiken5/4/3/toeic_basic）
- [x] 単語165語に拡充（各レベル別）
- [x] QuizWord モデルに `level` フィールド追加
- [x] `WordRangeFilter` enum（all/weakAndNew/weakOnly/eiken5/4/3/toiecBasic）
- [x] `MasteryBreakdown` Freezed クラス（未学習/苦手/得意/完璧の4段階カウント）
- [x] フィルター別習熟度内訳の計算・表示（`_loadMasteryBreakdowns`）
- [x] 学習範囲選択画面（`WordRangeSelectorScreen`）
  - 全体習熟度サマリーカード（4段階チップ＋プログレスバー）
  - 習熟度系フィルター選択（all/weakAndNew/weakOnly）
  - 資格レベル系フィルター選択（eiken5/4/3/toiecBasic）
  - 各フィルター行に単語数・習熟度ミニバー表示
  - 3語未満のフィルターはSTARTボタン無効
- [x] ホーム画面から「英単語モード」タップで `WordRangeSelectorScreen` に遷移
- [x] `BlockPuzzleState` にセッション統計（`sessionCorrectWords` / `sessionIncorrectWords`）追加
- [x] `addQuizPiece()` に `QuizWord? word` 引数追加
- [x] ゲームオーバー画面（クイズモード）に正解率バー＋苦手単語リスト（最大5語）表示

### Phase 4: UX改善・学習強化 ✅

- [x] Play Again（クイズ）→ `pop()` で `WordRangeSelectorScreen` に戻る
- [x] Home ボタン（クイズ）→ `popUntil(isFirst)` で `HomeScreen` まで戻る
- [x] 設定 Restart（クイズ）→ `pop()×2` で `WordRangeSelectorScreen` に戻る
- [x] 初回スワイプヒントUI
  - 初回プレイ時のみ4方向アニメーション矢印オーバーレイを表示
  - 各矢印のそばに選択肢テキストを表示
  - タップまたはスワイプで非表示（`SharedPreferences` で初回フラグ管理）
- [x] 不正解単語の優先出題
  - セッション内不正解単語の weight を一時的に2倍にして次ラウンドで優先
  - `resetSession()` を START ボタン押下時に呼ぶ

---

## 今後の候補タスク

### 高優先度

- [ ] **AdMob クイズモード制御**: クイズモード中のインタースティシャル表示を抑制（現状はゲームオーバー時に常に表示されてしまう）
- [ ] **ゲームオーバー苦手単語→再スタート連携**: 苦手単語リストの「このフィルターで再挑戦」ボタン追加
- [ ] **英語→日本語 以外の問題表示調整**: `jaToEn` 時にカードの文字サイズや折り返しが崩れないか検証

### 中優先度

- [ ] **クイズ設問数の調整**: 現状3問固定。難易度選択（3/5問）の追加
- [ ] **ゲームオーバー後の習熟度更新**: ゲームオーバー画面でのリアルタイム表示
- [ ] **WordRangeSelectorScreen の日本語テキスト**: 一部ハードコードされているラベルをi18nに移行
- [ ] **タイムアタック時間設定**: 5分ではなく90秒になっているラベル修正（i18n `timeAttackResult: "5分間の結果"` が不正確）

### 低優先度 / 将来構想

- [ ] **Phase 5: ソーシャル機能**: スコアランキング・フレンド機能
- [ ] **iCloud 同期**: 学習データのデバイス間同期
- [ ] **単語追加**: 165語から拡充（TOEIC中級・英検2級など）
- [ ] **学習統計画面**: 累計学習数・連続学習日数・カレンダーヒートマップ
- [ ] **通知**: 学習リマインダー
- [ ] **Apple Watch / Widget**: 今日の学習単語を表示

---

### リファクタリング ✅

- [x] 孤立ファイル削除（8ファイル）
  - `quiz_screen.dart`（旧クイズ画面、BlockPuzzleScreen に統合済み）
  - `dot_indicator.dart`（quiz_screen のみ参照）
  - `quiz_result_overlay.dart`（quiz_screen のみ参照）
  - `admob_native.dart`（未使用のネイティブ広告）
  - `context_extension.dart`（未使用の拡張メソッド）
  - `home_view_model.dart` + 生成ファイル2本（未使用ViewModel）
- [x] doc コメントの `[ClassName]` 参照エラー修正（2箇所）
- [x] `Switch.adaptive` の非推奨 `activeColor` → `activeThumbColor` へ修正

---

## コミット履歴（主要）

| コミット | 内容 |
|---------|------|
| `4486efb` | init |
| `c79cdb4` | セットアップ |
| `f73eb81` | fix |
| `300bc0f` | スキン追加 |
| `afe24c2` | ロゴ更新 |
| `d44764b` | refactor |
| `bf30e8a` | fix: クイズ出題方向変更バグ修正 |
| `71664ad` | feat: Phase 3 — 学習範囲選択・習熟度表示・セッション統計 |
| `9371927` | fix: クイズPlay Again/Restart動線修正 |
| `62441fa` | feat: 初回スワイプヒントUI |
| `9f38fc9` | feat: 不正解単語の優先出題 |
| `7dd48be` | docs: プロダクト・開発・タスクドキュメント新規作成 |
| *(次)* | refactor: 不要ファイル削除・コード整理 |

---

## ドキュメント管理ルール

- 機能実装・修正のたびに `docs/product.md` / `docs/development.md` / `docs/tasks.md` を更新する
- タスクの完了時: `tasks.md` の該当項目を `[x]` に変更
- 新機能追加時: `product.md` に機能仕様を追記、`development.md` に状態管理の変更を追記
- ドキュメントの更新は実装コミットと同じコミットに含める

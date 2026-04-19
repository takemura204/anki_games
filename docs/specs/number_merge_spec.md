# Number Merge（2048）仕様

> ステータス: Implemented / v1  
> 関連: [product.md](../product.md) の Word Mode ループ

## 概要

英単語クイズと連動した **2048 型ナンバーマージ** を `features/number_merge` に実装する。ホームでブロックパズルと切り替え可能。

## ゲームルール

- グリッド: **4×4**
- 操作: 上下左右スワイプ。タイルはその方向に可能な限りスライドし、**同じ値の隣接タイルは合体**（値が 2 倍、スコア加算）。
- 合法手が 1 つもない状態で **ゲームオーバー**
- 各「手」: 盤面が変化したスワイプの後、空きマスに **新タイル** を 1 つスポーン（ルールは下記クイズ報酬参照）。盤面が変化しなかったスワイプは手として数えない。

## クイズ連動

- **トリガー**: 有効なスワイプ（盤面が変化した手）を **3 回** 行うごとに `isQuizPhase = true`。盤面・スコアは維持。
- **クイズ UI**: [BlockPuzzleScreen] と同様、同一画面内でミニ盤面＋カードスワイプ（実装は `NumberMergeScreen` 側に配置。レイアウト共通化は後続 TODO）。
- **3 問終了後**: `isQuizPhase = false`。次の **3 スポーン** に対し、各問の成否に応じたバイアスを適用（ブロックの 3 ピース相当）。
- **`quizRoundSlots`（各スロットの正誤）**: 3 問埋まっても **クイズフェーズ終了（`endQuizPhase`）まではクリアしない**。トレイ表示・復元と VM の単一ソースを揃える。UI は `ref.listen` で VM の `quizRoundSlots` と同期する。

### スポーンバイアス（v1 固定）

| 結果   | 次 1 スポーン |
|--------|----------------|
| 正解   | **90% で 2、10% で 4**（乱数） |
| 不正解 | **必ず 4** |
| 手動デフォルト（キュー消費後） | **90% で 2、10% で 4**（2048 標準に近い） |

### SRS オーバーデューボーナス

- ブロックの `addQuizPiece` の `overdueBonus` と同様、クイズ回答時に `quiz_view_model` から算出されたボーナスを **スコアに加算**する。

## 永続化（SharedPreferences）

プレフィックス `nm_quiz_`、レベルキーは `LevelFilter.name`。

| キー例 | 内容 |
|--------|------|
| `nm_quiz_grid_v1_{level}` | 16 セルの値（0=空）を文字列化 |
| `nm_quiz_score_v1_{level}` | 現在スコア |
| `nm_quiz_high_v1_{level}` | そのレベルのベストスコア |
| `nm_quiz_moves_v1_{level}` | 直近クイズ以降の有効手数（0〜2、3 でクイズへ） |
| `nm_quiz_quiz_phase_v1_{level}` | クイズフェーズ中か |
| `nm_quiz_game_over_v1_{level}` | ゲームオーバー |
| `nm_quiz_spawn_queue_v1_{level}` | 残りスポーンバイアス（任意のエンコード） |
| `nm_quiz_session_*` | セッション用の正解/不正解単語はメモリ優先、必要に応じ保存 |

起動復元: `was_on_puzzle_screen` / `last_level_key` に加え **`last_game_kind`** が `number_merge` のときは `NumberMergeViewModel.startQuizMode` で復元。

## UI 方針

- `themeViewModelProvider` / `GameTheme` / `BackgroundEffectWidget` / スコアの Poppins / バナー広告の有無（プレミアム）は BlockPuzzle と揃える。
- ホーム上部: **PageView** でブロックモードとマージモードを選択。選択値は `home_selected_game` に保存。

## 後続 TODO

- クイズレイアウトのウィジェット共通化
- マージ専用 SE
- モード別ホームアート（現状はロゴ共有可）

# 単語習熟度 & 学習範囲選択 仕様書

**作成日**: 2026-03-20
**バージョン**: 1.0
**対象フェーズ**: Phase 3（学習機能強化）

---

## 1. コンセプト

### 追加する機能の全体像

```
ホーム画面
    │
    ▼ 「英単語 × パズル」タップ
    │
    ▼
┌─────────────────────────────────────────┐
│          学習範囲選択画面（新規）          │
│  ・習熟度サマリー（4段階分布）            │
│  ・資格レベル別フィルター                 │
│  ・スタート                              │
└─────────────────────────────────────────┘
    │
    ▼ スタートボタン
    │
    ▼
  英単語 × パズルゲーム（既存フロー）
```

---

## 2. 習熟度4段階定義

SRS weight 値（既存の `word_records.weight`）をそのまま利用する。

| ステージ | ラベル | 条件 | 色（参考） |
|---------|--------|------|-----------|
| **未学習** | New | DB にレコードなし | グレー |
| **苦手** | Hard | `weight ≥ 2.0` | 赤 |
| **得意** | Good | `0.5 ≤ weight < 2.0` | 青 |
| **完璧** | Perfect | `weight < 0.5`（かつ DB 登録済み） | 緑 |

> **根拠**: weight 初期値 = 1.0。正解すると ×0.7、不正解で ×1.5。
> - 2回連続不正解 → 1.0 × 1.5 × 1.5 = 2.25（苦手）
> - 2回連続正解 → 1.0 × 0.7 × 0.7 = 0.49（完璧に近い）

---

## 3. 学習範囲選択画面

### 3-1. 画面レイアウト（モックアップ）

```
┌────────────────────────────────────┐
│  ← 英単語 × パズル                  │
│                                    │
│  ──── 習熟度サマリー ────            │
│  ┌────┬────┬────┬────┐             │
│  │ 未 │苦手│得意│完璧│             │
│  │ 23 │ 12 │  8 │  5 │             │
│  └────┴────┴────┴────┘             │
│  ████░░░░░░░░░░░░░░░  23/48        │
│  （バー: 完璧率の進捗）              │
│                                    │
│  ──── 学習範囲を選ぶ ────            │
│  ○ すべての単語（48語）             │
│  ○ 苦手 + 未学習のみ（35語）        │
│  ─────────────                      │
│  ○ 英検5級（12語）   ██░░░░        │
│  ○ 英検4級（18語）   ████░░        │
│  ○ 英検3級（30語）   ██░░░░        │
│  ○ TOEIC 基礎（24語）  ███░░░       │
│                                    │
│         ▶ スタート                  │
└────────────────────────────────────┘
```

### 3-2. 習熟度サマリーセクション

- 全単語（選択中の範囲）の 4 段階カウントを表示
- 進捗バー: `完璧数 / 全単語数` の割合
- 範囲を変更すると即時更新

### 3-3. 学習範囲フィルター

| 選択肢 | 出題対象 |
|--------|---------|
| すべて | 登録全単語 |
| 苦手 + 未学習 | `weight ≥ 2.0 or DB未登録` のみ |
| 苦手のみ | `weight ≥ 2.0` のみ |
| 英検5級 | `level = "eiken5"` |
| 英検4級 | `level = "eiken4"` |
| 英検3級 | `level = "eiken3"` |
| TOEIC 基礎 | `level = "toeic_basic"` |

選択中の範囲で出題可能な単語が **3語未満** の場合はスタートボタンを無効化してメッセージ表示。

---

## 4. CSVスキーマ変更

### 現行

```
id, en, ja, category
1, apple, りんご, fruit
```

### 変更後

```
id, en, ja, category, level
1, apple, りんご, fruit, eiken5
```

| フィールド | 型 | 説明 |
|-----------|-----|------|
| `level` | String | `eiken5` / `eiken4` / `eiken3` / `toeic_basic` / `general` 等 |

> **Phase 3 時点の暫定対応**: 現在の 60 語には `level = "general"` を割り当て、資格別フィルターを選ぶと「対象なし」の状態でスタート不可表示にする。
> **Phase 4** で単語を大幅増加（500 語以上）し、各資格レベルへの正式割り当てを行う。

### QuizWord モデル変更

```dart
// 変更前
@freezed
abstract class QuizWord with _$QuizWord {
  const factory QuizWord({
    required int id,
    required String en,
    required String ja,
    required String category,
  }) = _QuizWord;
}

// 変更後
@freezed
abstract class QuizWord with _$QuizWord {
  const factory QuizWord({
    required int id,
    required String en,
    required String ja,
    required String category,
    @Default('general') String level,  // ← 追加
  }) = _QuizWord;
}
```

---

## 5. 状態管理の変更

### 5-1. 学習範囲選択の状態

新規ViewModel or QuizViewState に追加:

```dart
/// 選択中の学習範囲フィルター。
enum WordRangeFilter {
  all,         // すべて
  weakOnly,    // 苦手のみ
  weakAndNew,  // 苦手 + 未学習
  eiken5,
  eiken4,
  eiken3,
  toiecBasic,
}
```

`QuizViewState` に `@Default(WordRangeFilter.all) WordRangeFilter wordRangeFilter` を追加し、SharedPreferences に永続化。

### 5-2. セッション統計（ゲームオーバー用）

`BlockPuzzleState` or `QuizViewState` に追加:

```dart
/// 現在ゲームセッション中の正解単語リスト。
@Default([]) List<QuizWord> sessionCorrectWords,

/// 現在ゲームセッション中の不正解単語リスト。
@Default([]) List<QuizWord> sessionIncorrectWords,
```

- クイズフェーズで回答するたびに `addQuizPiece()` と連動して更新
- ゲームオーバー時にゲームオーバーオーバーレイに渡す
- `startQuizMode()` または `resetGame()` で空にリセット

---

## 6. ゲームオーバー画面の学習情報

### 6-1. 追加表示内容

現行のゲームオーバー画面（スコア + Play Again のみ）に以下を追加:

```
┌──────────────────────────────┐
│          GAME OVER           │
│                              │
│           1234               │
│           SCORE              │
│                              │
│  今回: 15問回答 / 10問正解    │  ← 正解率
│                              │
│  今回の苦手単語               │  ← 不正解リスト
│  × apple    りんご           │
│  × run      走る             │
│                              │
│       [ Play Again ]         │
│            Home              │
└──────────────────────────────┘
```

### 6-2. 正解率計算

```
セッション全体の正解数 / セッション全体の回答数
（例: 3ラウンド × 3問 = 9問中 6問正解 → 66%）
```

### 6-3. 苦手単語リスト

- `sessionIncorrectWords` をそのまま列挙
- 最大 5 件表示（超える場合は「他 N 語」と省略）
- 同じ単語が複数回不正解でも重複排除して表示

---

## 7. 変更ファイル一覧

| ファイル | 変更内容 |
|---------|---------|
| `assets/quiz/words.csv` | `level` フィールド追加（全語に `general` を仮割り当て） |
| `lib/features/quiz/model/quiz_word.dart` | `level` フィールド追加 |
| `lib/features/quiz/datasource/csv_word_datasource.dart` | `level` カラム読み込み対応 |
| `lib/features/quiz/view_model/quiz_view_model.dart` | `WordRangeFilter` 追加・`wordRangeFilter` state追加・`_pickWeightedWords` フィルター対応 |
| `lib/features/block_puzzle/model/block_puzzle_state.dart` | `sessionCorrectWords` / `sessionIncorrectWords` 追加 |
| `lib/features/block_puzzle/view_model/block_puzzle_view_model.dart` | セッション統計の更新・リセット処理 |
| `lib/features/block_puzzle/view/widgets/game_over_overlay.dart` | 正解率・苦手単語リスト表示追加 |
| `lib/features/quiz/view/word_range_selector_screen.dart` | **新規**: 学習範囲選択画面 |
| `lib/features/home/view/home_screen.dart` | 英単語モードの遷移先を学習範囲選択画面に変更 |

---

## 8. Phase 3 / Phase 4 の境界

| 項目 | Phase 3 | Phase 4 |
|------|---------|---------|
| 習熟度4段階表示 | ✅ 実装 | — |
| 学習範囲選択画面 | ✅ 実装（UI・フィルター） | — |
| 資格レベルフィルター UI | ✅ 実装（但し対象単語は general のみ） | 各資格への正式割り当て |
| 単語数 | 60語（仮） | 500語以上に拡充 |
| ゲームオーバー学習情報 | ✅ 実装 | — |
| カテゴリ選択（fruit/verb等） | — | 検討 |

---

## 9. 未解決の設計課題

| 課題 | 優先度 | 方針 |
|------|--------|------|
| 学習範囲を変えるとSRSの weight 選出と整合するか | 高 | フィルタリング後の単語プールだけで重み付き選出すれば問題なし |
| 選択範囲が3語未満の場合の UX | 中 | スタートボタン無効化 + 「この範囲には単語が少なすぎます」表示 |
| 資格レベルとカテゴリの二重管理 | 低 | Phase 4 まで保留。`level` フィールドで一元管理する方向で進む |
| セッション統計のリセットタイミング | 中 | `startQuizMode()` 呼び出し時にリセット |

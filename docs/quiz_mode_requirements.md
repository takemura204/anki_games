# Quiz Mode 要件書 (最終版)

**作成日**: 2026-03-17
**バージョン**: 2.0 (要件確定)

---

## 概要

既存の「ブロックパズル (ASMR)」に **英単語クイズモード** を追加する。
ブロックパズルをプレイしながら英単語を繰り返し学習できる設計。

---

## ゲームサイクル

```
[Quiz Phase: 3問]
      ↓ 正誤数を集計
[結果サマリー]
      ↓ タップ
[Block Phase: ピース3つを全部配置したら自動でQuizへ]
      ↓ ゲームオーバー条件: ボードにピースが置けなくなったら（既存と同じ）
[Quiz Phase: 3問] → 繰り返し
```

---

## 1. Quiz Phase

### 1-1. カードUI (flutter_card_swiper)

- **スタイル**: シンプルな白/黒ベースのフラッシュカード風
  - ライトモード: 白背景・濃いグレー文字
  - ダークモード: 黒背景・白文字
- **カード内**: 英単語（または日本語、設定で切り替え）を中央に大きく表示
- **4方向チップ**: カード外周の上下左右にチップUI (小さいラベル) を表示
  - 各方向にデコイを含む4択の日本語訳（または英単語）を配置
  - 正解はランダムな1方向に配置
  - デコイは同カテゴリから優先的に選出

```
           ┌───────┐
           │りんご │  ← チップ(上)
           └───────┘
┌──────┐              ┌──────────┐
│走る  │  [ apple ]  │ 幸せな   │
└──────┘              └──────────┘
           ┌──────┐
           │バナナ│  ← チップ(下)
           └──────┘
```

### 1-2. スワイプ動作

- 各方向にスワイプすることでその方向の選択肢を選択
- **スワイプ中フィードバック**: カードが方向に傾き、対応するチップがハイライト
- **スワイプ後**: 正誤判定オーバーレイ (0.8秒) → 次のカードへ
- **サウンド**: クイズフェーズは無音

### 1-3. 進捗表示

- 画面上部にドットインジケーター (○●○ スタイル)
  - 現在の問題: 塗りつぶしドット
  - 未回答: 空ドット

### 1-4. 問題方向設定

- **英→日** (英単語を見て日本語訳を選ぶ) / **日→英** を設定画面で切り替え可能
- デフォルト: 英→日

---

## 2. 結果サマリー画面

3問終了後に表示するオーバーレイ/画面。

### 表示内容

1. **正解数バッジ**: 例 `2 / 3`（大きく強調）
2. **3問の正誤一覧**: 単語 + 正解の訳を一覧表示
   - 不正解の単語は赤/アイコンで強調表示
3. **次のブロック難易度プレビュー**: 「次はこのブロック構成です」的な小さなプレビュー
4. **「ブロックへ」ボタン**: タップで Block Phase へ遷移

---

## 3. ブロック難易度マッピング

| 正解数 | 3ブロックの合計マス数上限 | 使用ピースプール |
|--------|--------------------------|-----------------|
| 3/3   | ≤ 6 マス                 | `easyPool` のみ |
| 2/3   | ≤ 9 マス                 | `easyPool` + 一部 medium |
| 1/3   | ≤ 12 マス                | `mediumPool` |
| 0/3   | ≤ 15 マス（上限なし）     | `allPieces` |

- 既存の `PieceDefinitions` を流用
- 3ブロックをランダム選択する際、**合計マス数が上限以下**になるよう再抽選

---

## 4. Block Phase (既存流用)

- 既存の `block_puzzle` ゲームエンジンをそのまま利用
- `GameMode.quiz` を新設し、ピーストレイ生成時に上記マッピングを適用
- **ゲームオーバー条件**: ボードにピースが1つも置けなくなった時（既存と同じ）
- **クイズ→ブロック遷移**: ピース3つを全部配置したら自動で Quiz Phase へ
- **スコア**: 既存ロジックと同じ（ライン消去 + コンボ）

---

## 5. 学習アルゴリズム

### 重み付きランダム選出

```
出題確率 ∝ weight

初期 weight = 1.0
正解時:   weight = max(0.1, weight * 0.7)
不正解時: weight = min(5.0, weight * 1.5)
```

- ゲーム起動時、`weight` が高い順に候補を絞り込み、その中からランダム3問を選択
- 全単語プレイ後もリセットせず継続（累積学習）

---

## 6. データモデル

### 6-1. CSVフォーマット (デモデータ)

**ファイル**: `assets/quiz/words.csv`

```csv
id,en,ja,category
1,apple,りんご,fruit
2,banana,バナナ,fruit
3,run,走る,verb
4,happy,幸せな,adjective
...
```

- デモデータ: **50単語** 以上
- カテゴリ: `fruit`, `verb`, `adjective`, `noun`, `animal`, `color`, `body`, `food`

### 6-2. DB設計 (Drift + SQLite)

**`word_records` テーブル**

| カラム | 型 | 説明 |
|--------|----|------|
| `id` | int PK | CSV の id と一致 |
| `correct_count` | int | 正解回数 (初期 0) |
| `incorrect_count` | int | 不正解回数 (初期 0) |
| `weight` | real | 出題重み (初期 1.0) |
| `last_seen_at` | datetime? | 最終出題日時 |

**Repository パターン** (Firestore移行対応):

```dart
abstract interface class WordRecordRepository {
  Future<List<WordRecord>> getAll();
  Future<void> upsert(WordRecord record);
  Future<void> resetWeights();
}

// 実装: LocalWordRecordRepository (Drift)
// 将来: FirestoreWordRecordRepository
```

---

## 7. フィーチャー構成

### 新規ファイル

```
lib/features/
└── quiz/
    ├── model/
    │   ├── quiz_word.dart              # QuizWord (Freezed) - CSV行に対応
    │   └── quiz_result.dart            # QuizResult (正誤3問分, Freezed)
    ├── datasource/
    │   └── csv_word_datasource.dart    # CSVロード・パース
    ├── repository/
    │   ├── word_record_repository.dart         # abstract interface
    │   └── local_word_record_repository.dart   # Drift実装
    ├── db/
    │   └── app_database.dart           # Drift DB定義
    ├── view/
    │   ├── quiz_screen.dart            # 3問クイズ画面
    │   └── widgets/
    │       ├── quiz_card.dart          # スワイプカード本体
    │       ├── direction_chip.dart     # 4方向チップUI
    │       ├── dot_indicator.dart      # 進捗ドット
    │       └── quiz_result_overlay.dart # 結果サマリー
    └── view_model/
        └── quiz_view_model.dart        # クイズ状態管理 (Riverpod)

assets/
└── quiz/
    └── words.csv                       # デモデータ
```

### 変更ファイル

| ファイル | 変更内容 |
|----------|----------|
| `block_puzzle_view_model.dart` | `GameMode.quiz` 追加、ピース生成に難易度マッピング追加 |
| `block_puzzle_screen.dart` | Quiz モード時にピース全配置でQuizへ自動遷移 |
| `home_screen.dart` | 「英単語×パズル」ModeCard を追加 |
| `pubspec.yaml` | `flutter_card_swiper`, `drift`, `sqlite3_flutter_libs` 追加 |
| `assets` section | `assets/quiz/` を追加 |

---

## 8. 追加パッケージ

| パッケージ | 用途 |
|------------|------|
| `flutter_card_swiper` | 4方向スワイプカードUI |
| `drift` | SQLite ORM (Repository抽象化でFirestore移行しやすい) |
| `sqlite3_flutter_libs` | drift用ネイティブSQLiteライブラリ |

---

## 9. i18n キー追加

`en.i18n.json` / `ja.i18n.json`:

```json
{
  "quiz": {
    "swipeInstruction": "Swipe to answer",
    "correct": "Correct!",
    "incorrect": "Incorrect",
    "result": "{correct} / 3 correct",
    "startBlock": "Start Block Phase",
    "loading": "Loading...",
    "questionDirection": {
      "enToJa": "EN → JA",
      "jaToEn": "JA → EN"
    }
  }
}
```

---

## 10. 実装フェーズ

### Phase 1: データ基盤
1. `pubspec.yaml` にパッケージ追加
2. `drift` DB セットアップ (`app_database.dart`)
3. CSV パース (`csv_word_datasource.dart`)
4. `LocalWordRecordRepository` 実装
5. `assets/quiz/words.csv` 作成 (50単語)

### Phase 2: クイズUI
6. `QuizWord` / `QuizResult` モデル (Freezed)
7. `QuizViewModel` (重み付き選出 + 4択生成ロジック)
8. `DirectionChip` + `DotIndicator` ウィジェット
9. `QuizCard` (スワイプ + 傾き + チップハイライト)
10. `QuizScreen` (3問ループ)
11. `QuizResultOverlay` (正誤一覧 + 難易度プレビュー)

### Phase 3: ブロック統合
12. `GameMode.quiz` 追加 + 難易度マッピングロジック
13. `BlockPuzzleScreen` にピース全配置検知 → Quiz自動遷移
14. `HomeScreen` に新ModeCard追加

### Phase 4: 仕上げ
15. i18n キー追加 (`build_runner`)
16. 設定画面に英→日/日→英 切り替え追加
17. E2Eでゲームサイクル確認

---

## 未決事項 (将来機能)

- [ ] CEFR / TOEIC レベル分け
- [ ] 不正解単語の「復習モード」
- [ ] Firestore 移行
- [ ] BGM / SE（クイズ正誤時のASMR音）

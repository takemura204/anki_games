# ピース割り当てロジック 仕様書

**作成日**: 2026-03-20
**対象ファイル**: `lib/features/block_puzzle/view_model/block_puzzle_view_model.dart`

---

## 1. 設計ゴール

| 軸 | ゴール |
|----|-------|
| 学習 | 正解するほどパズルが楽になり、「英単語を覚えた」ことが直接の報酬になる |
| ゲーム | 手詰まり（ゲームオーバー）を適度に避けながら緊張感を維持する |
| 公平性 | 苦手な単語（高weight）に多く直面するほどゲームも少し難しくなるが、ゲームオーバーには直結させない |

### 前提設計

- **1問 = 1ピース固定**（3問で必ず3ピース。欠けることなし）→ 実装済み
- **倍率（quizMultiplier）はピース難易度に使わない**（ライン消去でも上がるため、難易度制御には不向き）
- **難易度は「正誤 × 充填率」の2軸で決定する**

---

## 2. 3ティア定義

| ティア | セル数 | 代表ピース | 配置難易度 |
|--------|--------|-----------|-----------|
| **Easy（小）** | 1〜3 cells | dot, dominoH/V, triominoH/V, cornerA〜D | 低：どこでも置きやすい |
| **Medium（中）** | 4 cells | square2x2, L字4セル, S/Z字 | 中：ある程度スペースが必要 |
| **Hard（大）** | 5+ cells | pentomino各種, 長L, 長I | 高：盤面管理が重要になる |

---

## 3. 新ロジック：決定フロー

```
addQuizPiece(slot, isCorrect)
        │
        ▼
【STEP 1】充填率チェック（安全弁）
        │
        ├─ fillRate ≥ 75% ──→ Easy（サバイバル優先。正誤問わず）
        │
        └─ fillRate < 75% ──→ STEP 2へ
                │
                ▼
        【STEP 2】正誤 × 充填率で判定
                │
                ├─ 正解 ──────────────────────────→ Easy
                │
                └─ 不正解
                        │
                        ├─ fillRate ≥ 65% ──→ Medium（緩和ペナルティ）
                        │
                        └─ fillRate < 65% ──→ Hard（通常ペナルティ）
```

### 決定テーブル

| 充填率 | 正解 | 不正解 |
|--------|------|--------|
| < 65% | Easy | Hard |
| 65〜75% | Easy | Medium |
| ≥ 75% | Easy | Easy |

---

## 4. 閾値の設計根拠

### 現行との比較

| 境界 | 現行 | 新設計 | 変更理由 |
|------|------|--------|---------|
| 安全弁（常にEasy） | 70% | **75%** | 8×8=64マスで70%≒45マス。Medium4枚追加で62%(99%)になり詰まりやすい。75%で安全弁をやや遅らせることで緊張感を延ばす |
| ペナルティ緩和 | 50% | **65%** | 50%（32マス）では余裕があり緩和が早すぎる。65%(42マス)まで引き上げ、中盤以降にのみ緩和が効くようにする |

### Flow理論との対応

Csikszentmihalyiの「フロー状態」に当てはめると：

```
            高
             │    ゲームオーバー
    難   難  │    の恐怖感
    易   し  │                   ← Hard（fillRate<65% + 不正解）
    度   い  │──────────────────
    の   ↑  │    フロー・ゾーン    ← Medium（fillRate 65-75% + 不正解）
    変      │──────────────────
    動      │    余裕・達成感      ← Easy（正解 or fillRate>75%）
             │
             └──────────────── 学習進捗（SRSで単語を覚えるほど正解率↑）
                  低            高
```

- 初心者（単語未習得）: 不正解多い → Hard頻発 → 緊張感
- 中級者（一部習得）: 正誤混在 → Easy/Hard交互 → フロー状態
- 上級者（ほぼ習得）: 正解多い → Easyメイン → 達成感・爽快感

---

## 5. 学習アルゴリズムとの連動

SRS（スペーシングリピティション）の weight 管理と組み合わさることで、**学習するほどゲームが楽になる**自然なカーブを形成する。

```
        正解率
         ↑
    高   │                    ／─── Easyばかり（楽）
         │                ／
         │            ／
         │        ／
    低   │────／
         └─────────────────── プレイ時間・学習継続
             初期   中期    長期
```

- **初期**: 単語未習得 → 不正解多い → Hard/Mediumが増える → 盤面が圧迫 → 緊張感
- **中期**: 一部の単語を習得 → 正解/不正解混在 → Easyと難しいのが交互に → フロー
- **長期**: ほぼ全単語習得 → 正解ばかり → Easyメイン → 爽快感・達成報酬

quizMultiplierはスコア倍率として機能するが、ピースサイズには影響しない。

---

## 6. 実装詳細

### 変更前（現行）

```dart
void addQuizPiece(int slot, {required bool isCorrect}) {
  final fillRate = _boardFillRate(board);
  if (fillRate > 0.70) {           // ← 70%
    piece = _pickEasyPiece(board);
  } else if (!isCorrect && fillRate > 0.50) {  // ← 50%
    piece = _pickMediumPiece(board);
  } else {
    piece = isCorrect ? _pickEasyPiece(board) : _pickHardPiece(board);
  }
}
```

### 変更後（新設計）

```dart
void addQuizPiece(int slot, {required bool isCorrect}) {
  final board = Board.from(state.board);
  final fillRate = _boardFillRate(board);
  final Piece piece;

  if (fillRate >= 0.75) {                         // ← 75%: 安全弁
    piece = _pickEasyPiece(board);
  } else if (!isCorrect && fillRate >= 0.65) {    // ← 65%: ペナルティ緩和
    piece = _pickMediumPiece(board);
  } else {
    piece = isCorrect ? _pickEasyPiece(board) : _pickHardPiece(board);
  }

  final newPieces = List<Piece?>.from(state.pieces);
  newPieces[slot] = piece;
  state = state.copyWith(pieces: newPieces);
  _saveGame();
}
```

### 変更箇所サマリー

| 変更点 | 現行値 | 新設計値 |
|--------|--------|---------|
| 安全弁の閾値 | `> 0.70` (70%) | `>= 0.75` (75%) |
| ペナルティ緩和の閾値 | `> 0.50` (50%) | `>= 0.65` (65%) |
| ロジック構造 | 変更なし | 変更なし |

---

## 7. ピースプール定義（参考：現行のまま）

### Easy（小ピース：≤3セル）
```
dot(1), dominoH(2), dominoV(2),
triominoH(3), triominoV(3),
cornerA(3), cornerB(3), cornerC(3), cornerD(3)
```

### Medium（中ピース：4セル）
```
square2x2(4), L字4セル各種, S字(4), Z字(4)
```
→ `PieceDefinitions.allPieces.where((p) => p.offsets.length == 4)`

### Hard（大ピース：≥5セル）
```
pentomino各種(5), 長L(5), 長I(5), より大きな形
```
→ `PieceDefinitions.allPieces.where((p) => p.offsets.length >= 5)`

---

## 8. フォールバック

ピース候補がボードに1つも配置できない場合：

| ティア | フォールバック |
|--------|--------------|
| Easy | `PieceDefinitions.dot`（必ず置ける）|
| Medium | Easy に降格して再選出 |
| Hard | Medium に降格、それも無ければ Easy |

---

## 9. 今後の調整候補

| 候補 | 内容 | 優先度 |
|------|------|--------|
| 閾値のゲーム内チューニング | 75%/65%をプレイデータで検証後に微調整 | 中 |
| ラウンド正解数による事前決定 | 3問終了後に正解数で次3ピース全体の難易度を決定 | 低 |
| カテゴリ別難易度補正 | 苦手カテゴリ（高weight）の不正解は特に大きいピース | 低 |

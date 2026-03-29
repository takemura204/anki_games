# SRS 出題アルゴリズム刷新 仕様書

> 作成日: 2026-03-23 / 更新日: 2026-03-25 / ステータス: Implemented

## 概要

現状の weight-only ランダム出題（4点/10点）を、忘却曲線・認知負荷制御・飽き防止を兼ね備えた
SM-2 インスパイア型アルゴリズムに刷新し、各体験指標を 10/10 に引き上げる。

---

## 要件

### 機能要件

#### 1. SRS インターバル管理（長期記憶定着）
- DB に `next_review_at` (DateTime nullable) / `interval_hours` (Real default 4.0) を追加
- ステージ別の基準インターバルを定義（下表）
- weight による適応係数：`intervalMultiplier = (1.0 / weight).clamp(0.3, 4.0)`
  - 低 weight（定着済み）→ 長い間隔
  - 高 weight（苦手）  → 短い間隔
- `nextInterval = baseIntervalHours[newStage] × intervalMultiplier`
- 正解時: `next_review_at = now + Duration(hours: nextInterval.round())`
- 不正解時: `next_review_at = now`（即座に期限超過 = 次セッションで優先）

| Stage | 0→1 | 1→2 | 2→3 | 3→4 | 4→5 | 5→ |
|-------|-----|-----|-----|-----|-----|-----|
| 基準 (h) | 4 | 24 | 72 | 168 | 336 | 720 |

#### 2. セッション内クールダウン（繰り返し防止・第2弾で強化）
- `_sessionCorrectIds: Set<int>` — 正解語の永続除外セット
- `_sessionIncorrectIds: Set<int>` — 不正解語の高優先度セット
- 正解語: 同一セッション中に絶対再出題しない
- 不正解語: `effectiveWeight` に `missedBoostFactor=2.0` を乗算（実質 ×3 倍）し優先出題
- プールが枯渇した場合（全語正解済み）は両セットをクリアして再開
- `resetSession()` で両セットをクリア

#### 3. 新規単語ゲーティング（認知負荷制御）
- 1 ラウンド（3 問）に新規単語（stage 0）は最大 1 語
- セッション内で stage 0/1 の単語を既に `_srsSessionHardCap` 語以上見た場合 → 新規導入停止（0 語）

#### 4. 複合出題優先スコア（苦手単語優先）
```
historicalDifficulty = incorrectCount / (correctCount + incorrectCount + 1)
overdueDays          = max(0, now.diff(next_review_at).inHours / 24)
effectiveWeight      = baseWeight
                       × (1 + overdueDays × _overdueUrgencyFactor)
                       × (1 + historicalDifficulty × _histDifficultyFactor)
```
- `_overdueUrgencyFactor = 1.0`（1日超過で weight 2倍）
- `_histDifficultyFactor = 0.5`

#### 5. 3スロット構成（飽き防止・インターリービング）
```
[slot A] 復習語 (stage ≥ 1, next_review_at ≤ now)  effectiveWeight で選出
[slot B] 復習語 (同上)                               effectiveWeight で選出
[slot C] 新規語 (stage == 0, 新規枠が許可されている場合)
         ↓ 新規語がない or 許可されない場合
         バッファ語 (stage ≥ 1, next_review_at > now) baseWeight × 0.3 で選出
```
- 最後に shuffle して出題順をランダム化
- テーマ多様化: 3 問中に同一 `theme` が 2 つ以上ある場合、バッファから別テーマを補充して差し替え

#### 6. 降格条件と緊急キュー処理（第2弾で変更）
- 降格条件: `weight ≥ 3.5`（`_demotionWeightThreshold`）かつ `stage > 0`
  - 旧: 連続不正解 −3回 → 廃止
- 降格発生時: weight を `_demotionWeightReset = 1.5` にリセット、streak = 0
- `next_review_at = now`（即座に期限超過、不正解時の共通処理）

#### 8. ステージ昇格条件（第2弾で変更）
- `consecutiveStreak` フィールドを「ステージ変更後の累計正解数」として再利用
- 昇格閾値: stage 0→2回、1→3回、2→4回、3→5回、4→6回
- 不正解時は累計数を変化させない（ペナルティなし）
- ステージ変更時（昇格・降格）は streak = 0 にリセット

#### 9. 期限超過ボーナス（第2弾で追加）
- 期限切れ単語（`now > next_review_at`）を正解したとき:
  `overdueBonus = clamp(overdueDays × 10, 10, 100).round()`
- `QuizAnswerResult.overdueBonus` フィールドに格納

#### 7. コード構造（堅牢性）
`_pickQuestions` を以下のプライベートメソッドに分割:
- `_buildWordPool()` — フィルター・クールダウン適用後の単語プールを構築
- `_categorizePool()` — due/buffer/new に分類
- `_computeEffectiveWeight()` — 単語 1 件の effectiveWeight を計算
- `_weightedPick()` — 重み付きランダム選出ユーティリティ
- `_applyThemeVariety()` — テーマ多様化チェック・差し替え

### 非機能要件
- DB スキーマ v2 → v3 マイグレーション。既存データ維持
- `next_review_at = null` の既存レコードは「即出題可能」として扱う
- `build_runner` 再実行で生成コード更新

---

## 実装方針

| ファイル | 変更内容 |
|---------|---------|
| `app_database.dart` | `nextReviewAt` / `intervalHours` カラム追加、schema v3 マイグレーション |
| `quiz_view_model.dart` | 定数追加、`_sessionSeenIds` 追加、`_pickQuestions` 全面再設計、`_updateRecord` 更新 |

---

## 定数一覧

```dart
// SRS 基準インターバル（ステージ昇格後の間隔、単位: 時間）
const _srsBaseIntervalHours = [4.0, 24.0, 72.0, 168.0, 336.0, 720.0];

// weight による適応乗数の範囲
const _srsIntervalMultMin = 0.3;
const _srsIntervalMultMax = 4.0;

// セッション内の苦手語上限（超えると新規導入を停止）
const _srsSessionHardCap = 5;

// 期限超過urgencyの係数（1日超過でeffectiveWeight × 2倍）
const _overdueUrgencyFactor = 1.0;

// 不正解率の影響係数
const _histDifficultyFactor = 0.5;

// バッファ語の重み係数（not-due だが補填に使う）
const _bufferWeightFactor = 0.3;

// ステージ降格時の weight リセット値
const _demotionWeightReset = 1.5;
```

---

## 完了条件

- [x] DB schema v3 マイグレーション成功（既存データ保持）
- [x] `next_review_at` が正解・不正解時に正しく保存される
- [x] 同一セッション内で同語が再出題されない
- [x] 1 ラウンドの新規語が最大 1 語
- [x] セッション内 hard 語 ≥ 5 で新規語が出なくなる
- [x] 期限超過語が期限前語より優先出題される
- [x] テーマ重複がある場合にバッファで差し替えが試みられる
- [x] ステージ降格時に weight = 1.5 にリセットされ next_review_at = now になる
- [x] `flutter analyze` エラーゼロ

### 第2弾完了条件（2026-03-25）

- [x] `_sessionCorrectIds` に正解語を追加、同セッション内で再出題しない
- [x] `_sessionIncorrectIds` に不正解語を追加、effectiveWeight × 3倍でブースト
- [x] プール枯渇時（全語正解）のみ両セットをリセット
- [x] ステージ昇格が累計正解数方式で動作する
- [x] ステージ降格が weight ≥ 3.5 閾値で発動する
- [x] 期限超過正解時に `overdueBonus` が 10〜100 の範囲で計算される
- [x] `QuizAnswerResult` に `overdueBonus` フィールドが追加された
- [x] `flutter analyze` エラーゼロ

# TOEIC単語コンテンツ整備 仕様書

> 作成日: 2026-03-30 / ステータス: Approved

## 概要

TOEIC 500〜900 スコアを目標とするビジネス英単語を段階的に整備する。
既存の英検単語（eiken5〜eiken2）と重複しない、ビジネス・業務文脈に特化した語彙を対象とする。

---

## レベル設計

| level 値     | TOEIC スコア目標 | CEFR 目安 | 目標語数 | 現在 | 追加必要 |
|-------------|--------------|---------|---------|-----|--------|
| toeic500    | 500 点突破     | B1 下位   | 200 語  | 0語  | 200語   |
| toeic600    | 600 点突破     | B1 上位   | 200 語  | 0語  | 200語   |
| toeic700    | 700 点突破     | B2 下位   | 200 語  | 0語  | 200語   |
| toeic800    | 800 点突破     | B2 上位   | 200 語  | 0語  | 200語   |
| toeic900    | 900 点突破     | C1      | 200 語  | 0語  | 200語   |

**累計目標: 1,000 語**（toeic_basic 30 語は別途管理）

---

## ドメイン設計（英検との差別化）

TOEIC 単語は以下のビジネスシーン文脈を優先する。
一般的な日常・自然・学術語は英検レベルでカバー済みのため除外する。

| シーン            | 優先度 | 例                                     |
|----------------|-----|---------------------------------------|
| オフィス・人事        | ★★★ | payroll, workforce, internship         |
| 経理・財務          | ★★★ | billing, transaction, procurement      |
| 物流・在庫          | ★★★ | shipment, warehouse, vendor            |
| 会議・文書          | ★★★ | memo, briefing, workflow               |
| マーケティング・営業     | ★★  | retailer, prospect, subscription       |
| 法務・コンプライアンス   | ★★  | compliance, mandatory, confidential    |
| プロジェクト管理       | ★★  | milestone, outsource, finalize         |

---

## CSV スキーマ

既存 words.csv と同一スキーマを使用する。

```csv
id,en,ja,pos,theme,level,is_frequent
```

### theme 値の TOEIC 向け活用

TOEIC ビジネス文脈での推奨マッピング:

| ビジネスシーン | theme |
|-----------|-------|
| 会社・組織・人事 | people |
| 場所・施設・物流 | place |
| 動作・プロセス  | action |
| 状態・性質    | mind  |
| 汎用ビジネス語  | general |

> ※ `school` は既存 toeic_basic に誤用されているが、新規追加では使用しない。

---

## ドラフト生成方針

CEFR-J Wordlist はビジネス特化語を網羅していないため、
AI によるキュレーション + 人間レビューの方式を採用する。

**生成基準**:
1. 既存 words.csv と重複しない（重複チェック必須）
2. TOEIC 公式問題集・頻出語リストに準拠
3. 品詞バランス: noun 50% / verb 30% / adjective 15% / other 5%
4. 1 バッチ 50 語以内（レビュー精度確保）

### 確信度の基準

| マーク | 条件                                   |
|-----|--------------------------------------|
| ✅  | TOEIC 頻出 + 訳語が明確（1 義）               |
| ⚠️  | 訳語が複数 / スコア境界付近 / 品詞が文脈依存            |

---

## フェーズ計画

| Phase | 対象        | 目標    | バッチ数 |
|-------|-----------|-------|------|
| 1     | toeic500  | 200 語 | 4 回  |
| 2     | toeic600  | 200 語 | 4 回  |
| 3     | toeic700  | 200 語 | 4 回  |
| 4     | toeic800  | 200 語 | 4 回  |
| 5     | toeic900  | 200 語 | 4 回  |

---

## ツール使用手順

### ドラフト生成

```
/add-eiken-words draft toeic500 50
```

### レビュー後の取り込み

```
/add-eiken-words import toeic500 tools/draft_toeic500.csv
```

### バリデーション

import 時に以下をチェックする:
- `level` が `toeic500` / `toeic600` / `toeic700` / `toeic800` / `toeic900` のいずれか
- `theme` が有効値（nature / daily / people / place / action / mind / general）
- `en` が既存 words.csv と重複しない

---

## 完了条件

- [ ] toeic500〜toeic900 が各 200 語に到達（累計 1,000 語）
- [ ] `LevelFilter` に toeic500〜toeic900 が追加される
- [ ] i18n（en/ja）に TOEIC レベルラベルが追加される

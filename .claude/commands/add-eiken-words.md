# /add-eiken-words — 英検単語追加フロー

英検5〜2級（準2含む）の単語を `assets/quiz/words.csv` に半自動で追加するコマンド。
仕様書: `docs/specs/eiken_vocabulary_spec.md`

## 使い方

```
/add-eiken-words [mode] [level] [count]
```

| 引数    | 値                                                | 省略時    |
|-------|--------------------------------------------------|--------|
| mode  | `draft` / `import`                               | draft  |
| level | eiken5 / eiken4 / eiken3 / eiken_pre2 / eiken2  | eiken5 |
| count | 追加語数（import は上限 100 語）                          | 50     |

### モード説明

- `draft`: CEFR-J データ × Jisho API でドラフトリストを生成してユーザーに提示する（CSV は変更しない）
- `import`: 承認済みリストを受け取り words.csv に追記する

### 例

```
/add-eiken-words draft eiken5 50
/add-eiken-words draft eiken3 30
/add-eiken-words import eiken5
```

---

## フロー詳細

### [draft モード] Step 1: 現状確認

`assets/quiz/words.csv` を読み込み、指定レベルの現在語数と進捗を表示する。

```
[eiken5] 現在: 42語 / 目標: 250語 / 残り: 208語
```

目標語数（仕様書より）:

| level       | 目標  |
|-------------|-----|
| eiken5      | 250 |
| eiken4      | 350 |
| eiken3      | 500 |
| eiken_pre2  | 600 |
| eiken2      | 800 |

### [draft モード] Step 2: 候補語リスト生成

指定レベルの CEFR 対応に基づき、以下の優先順で英単語候補を選定する。

**CEFR ↔ 英検対応**:
- eiken5 → A1
- eiken4 → A2
- eiken3 → B1（下位）
- eiken_pre2 → B1（上位）
- eiken2 → B2

**生成ルール**:
1. 既存 words.csv に含まれる単語は除外（重複防止）
2. 高頻度語（でる順パス単の頻出順）を優先
3. 品詞バランスを考慮（noun 50% / verb 30% / adjective 15% / other 5% 目安）
4. 同じテーマが偏らないよう分散させる

### [draft モード] Step 3: Jisho API で品詞・訳語を自動取得

各候補語について以下を自動付与する:
- `ja`: Jisho の最初の日本語訳（意味ズレがある場合は ⚠️ で明記）
- `pos`: Jisho の parts_of_speech から変換
- `theme`: Jisho のタグと品詞から仕様書のルールで推定

**Jisho API エンドポイント**:
```
https://jisho.org/api/v1/search/words?keyword={word}
```

**pos 変換ルール**:
| Jisho parts_of_speech | → pos |
|----------------------|-------|
| Noun / Suru verb | noun |
| Godan verb / Ichidan verb / Irregular verb | verb |
| い-adjective / な-adjective / Adjective | adjective |
| Adverb | adverb |
| Particle / Preposition | preposition |
| Conjunction | conjunction |

### [draft モード] Step 4: ドラフト出力

以下の形式でテーブルを表示する:

```
| # | en | ja | pos | theme | level | 確信度 | notes |
|---|----|----|-----|-------|-------|------|-------|
| 1 | cloud | 雲 | noun | nature | eiken5 | ✅ | |
| 2 | spend | 使う / 過ごす | verb | action | eiken5 | ⚠️ | 訳語が複数、「費やす」も有力 |
```

**確信度の基準**:
- ✅: CEFR-J 掲載済み + Jisho 品詞・訳語が明確
- ⚠️: 訳語が複数ある / CEFR レベルが境界付近 / 品詞が不明確

ドラフト出力後に以下を案内する:

```
【レビュー手順】
1. でる順パス単（該当級）で頻出単語か確認する
2. ⚠️ の単語は Weblio / Cambridge で訳語・品詞を確認する
3. 不要な単語は削除、訳語・品詞・テーマの修正があれば修正して返信する
4. 確認後「/add-eiken-words import eiken5」でCSVに取り込む
```

---

### [import モード] Step 1: 承認リストの受け取り

ユーザーが修正済み CSV ファイルのパスを指定する（例: `tools/draft_eiken5.csv`）。
`confidence` 列と `notes` 列は import 時に無視する。

### [import モード] Step 2: バリデーション

以下を全行チェックする:

| チェック項目 | 許可値 |
|-----------|------|
| pos | noun / verb / adjective / adverb / preposition / conjunction / phrase |
| theme | nature / daily / people / place / action / mind / general |
| level | eiken5 / eiken4 / eiken3 / eiken_pre2 / eiken2 / toeic_basic |
| en | 空でない、既存 CSV と重複なし |
| ja | 空でない |

エラーがある行は CSV に追記せず、ユーザーに修正を依頼する。

### [import モード] Step 3: ID 採番 + CSV 追記

- 現在の最大 ID + 1 から連番で採番
- `assets/quiz/words.csv` の末尾に追記

### [import モード] Step 4: 完了報告

```
✅ 追記完了: 48 語
[eiken5] 90語 / 250語 (36%)
次のバッチ: /add-eiken-words draft eiken5 50
```

---

## スキーマ移行が必要な場合

words.csv が旧フォーマット（`category` カラムあり）のままの場合は、
`docs/specs/eiken_vocabulary_spec.md` の「既存 165 語の移行マッピング」に従って移行を提案する。

移行は import モードの前提条件（Phase 0）として先に完了させる。

---

## 注意事項

- 1バッチ 100 語以内（レビュー精度が下がるため）
- でる順パス単との照合なしに import しない
- 準2級は level 値 `eiken_pre2` を使う（`eiken_pre` は誤り）

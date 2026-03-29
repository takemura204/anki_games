# tools/ — 単語データ整備ツール

## 初回セットアップ（一度だけ）

```bash
# CEFR-J Wordlist CSV（~4,000語、CEFR レベル + 品詞 + テーマ付き）
curl -L -o tools/data/cefrj.csv \
  "https://raw.githubusercontent.com/openlanguageprofiles/olp-en-cefrj/master/cefrj-vocabulary-profile-1.5.csv"

# JMdict-simplified JSON（英語→日本語辞書、約100MB）
# 1. https://github.com/scriptin/jmdict-simplified/releases/latest を開く
# 2. jmdict-eng-x.x.x.json をダウンロード
# 3. tools/data/ に置く
```

`tools/data/` は .gitignore 対象（大容量ファイルのため）。

## generate_eiken_words.py — ドラフト生成

```bash
python3 tools/generate_eiken_words.py \
    --level eiken5 \
    --count 50 \
    --existing assets/quiz/words.csv \
    --cefrj tools/data/cefrj.csv \
    --jmdict "tools/data/jmdict-eng-*.json" \
    --output tools/draft_eiken5.csv
```

### 引数

| 引数 | 説明 |
|------|------|
| `--level` | eiken5 / eiken4 / eiken3 / eiken_pre2 / eiken2 |
| `--count` | 出力語数（デフォルト: 50） |
| `--existing` | 既存 words.csv（重複除外に使用） |
| `--cefrj` | CEFR-J CSV のパス |
| `--jmdict` | JMdict JSON のパス（ワイルドカード可） |
| `--output` | 出力ドラフト CSV のパス |

### 出力フォーマット

```csv
id,en,ja,pos,theme,level,confidence,notes
166,cloud,雲,noun,nature,eiken5,✅,Weather and climate
167,spend,費やす / 過ごす,verb,action,eiken5,⚠️  訳語複数,Time
```

- `confidence`: ✅ = そのまま採用可 / ⚠️ = でる順パス単で確認
- `notes`: CEFR-J の CoreInventory（参考情報）

### レビュー手順

1. `tools/draft_eiken5.csv` を Excel / Numbers / VSCode で開く
2. `⚠️` の単語を**英検でる順パス単**で頻出確認・訳語確認
3. 不要な行を削除、訳語・品詞・テーマを修正
4. `confidence` と `notes` 列を削除して保存
5. `/add-eiken-words import` コマンドでアプリに取り込む

## ワークフロー全体

```
generate_eiken_words.py（自動）
    ↓
ドラフト CSV をレビュー（でる順パス単で ⚠️ を確認）
    ↓
/add-eiken-words import（バリデーション + CSV 追記）
```

詳細: `docs/specs/eiken_vocabulary_spec.md`

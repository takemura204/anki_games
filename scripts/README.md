# scripts/

開発・データ整備用のユーティリティ群。

## fetch_it_pass_kakomon.py

[ITパスポート試験ドットコム](https://www.itpassportsiken.com/) の過去問ページをスクレイピングし、
問題・選択肢・分類・正解・解説をまとめた JSON を `assets/quiz/it_pass_<era_id>.json` に書き出す。

年度ごと（春期／秋期がある年度はセッションごと）に 1 ファイルを生成する。
和暦ベースのファイル ID は以下のとおり:

| era_id | 試験 | slug |
|---|---|---|
| `r07` | 令和7年 | `07_haru` |
| `r06` | 令和6年 | `06_haru` |
| `r03`〜`r07` | 令和3〜7年 | `0N_haru` |
| `r01_aki` / `r02_aki` | 令和元年秋期 / 令和2年秋期 | `0N_aki` |
| `h21_haru` / `h21_aki` | 平成21年春期／秋期 | `21_haru` / `21_aki` |
| `h23_toku` | 平成23年特別 | `23_toku` |
| `sample1` / `sample2` | サンプル問題１ / ２ | `01_sample` / `02_sample` |

### セットアップ

```bash
pip3 install -r scripts/requirements.txt
```

### 使い方

```bash
# 全年度 + サンプル問題を一括取得（約45分・約2800問）
python3 scripts/fetch_it_pass_kakomon.py --all

# 既存ファイルはスキップして差分のみ取得
python3 scripts/fetch_it_pass_kakomon.py --all --skip-existing

# 特定年度のみ（問題数は自動検出）
python3 scripts/fetch_it_pass_kakomon.py --exam 07_haru --label "令和7年" --era-id r07
```

### 主なオプション

| オプション | デフォルト | 説明 |
|---|---|---|
| `--all` | off | `EXAMS` に含まれる全試験を順次取得（30試験） |
| `--skip-existing` | off | `--all` 時、既存の出力ファイルをスキップ |
| `--exam` | — | URL 末尾のスラグ。`https://.../kakomon/<exam>/qN.html` の `<exam>` |
| `--label` | `--exam` 値 | JSON に書き込む試験ラベル |
| `--era-id` | `--exam` 値 | 出力ファイル ID（`it_pass_<era-id>.json`） |
| `--count` | 自動検出 | 取得する問題数。未指定時はインデックスから推定 |
| `--wait` | `1.0` | リクエスト間のウェイト秒。サーバー負荷軽減のため 1 秒以上推奨 |
| `--output-dir` | `assets/quiz` | 出力ディレクトリ（相対パスはリポジトリルート基準） |

### 出力 JSON スキーマ

```jsonc
{
  "exam": "令和7年",
  "era_id": "r07",
  "slug": "07_haru",
  "source_url": "https://www.itpassportsiken.com/kakomon/07_haru/",
  "fetched_at": "2026-04-17T00:00:00+00:00",
  "count": 100,
  "questions": [
    {
      "no": 1,
      "url": "https://.../q1.html",
      "title": "偽装請負とみなされる状態はどれか",
      "body": {
        "text": "A社がB社に...どれか。",
        "sub_items": ["B社の従業員が...", "...", "..."],
        "images": []
      },
      "choices": [
        { "label": "ア", "text": "a", "images": [] },
        { "label": "イ", "text": "a，b", "images": [] },
        { "label": "ウ", "text": "a，c", "images": [] },
        { "label": "エ", "text": "b，c", "images": [] }
      ],
      "category": {
        "raw": "ストラテジ系 » 法務 » 労働関連・取引関連法規",
        "system": "ストラテジ系",
        "major": "法務",
        "minor": "労働関連・取引関連法規"
      },
      "answer": "ウ",
      "explanation": {
        "text": "請負契約は、...",
        "choice_comments": ["該当する。...", "該当しない。...", "該当する。..."],
        "images": []
      }
    }
  ]
}
```

### 注意事項

- サーバー負荷軽減のため、デフォルトで各リクエスト間に 1 秒のウェイトを入れる。
- 過去問の著作権は IPA および ITパスポート試験ドットコムに帰属する。
  取得データの二次利用はそれぞれの規約に従うこと。
- HTML 構造が変わった場合はパーサーの調整が必要。

# 英検単語コンテンツ整備 仕様書

> 作成日: 2026-03-22 / 更新日: 2026-03-22 / ステータス: Approved

## 概要

英検5級〜2級（準2級含む）の単語データを段階的に整備する。
CEFR-J オープンデータ × JMdict-simplified によるローカル一括処理で下書きを自動生成し、でる順パス単による人間レビューで信頼性を担保する。

---

## アプローチ評価（調査結果）

| アプローチ | 効率性 | 信頼性 | 実装コスト | 保守性 | **合計** |
|---------|:-----:|:-----:|:------:|:----:|:------:|
| A: 完全手動（辞書1語ずつ） | 1 | 5 | 1 | 3 | **10/20** |
| B: AI下書き + Jisho API（旧案） | 3 | 2 | 3 | 2 | **10/20** |
| C: CEFR-J + Jisho API（中間案） | 4 | 2 | 3 | 2 | **11/20** |
| **D: CEFR-J + JMdict ローカル（採用）** | **5** | **5** | **4** | **5** | **19/20** |

**Jisho.org を採用しない理由**: 非公式 API・HTML スクレイピングのため 1,000 語以上のバッチ処理で破壊的に壊れるリスクが高い。
**Google スプレッドシートを採用しない理由**: バージョン管理不可・大量データで動作が遅い。

---

## レベル設計

| level 値      | 英検レベル | CEFR 目安 | 目標語数 | 現在 | 追加必要 |
|--------------|---------|---------|---------|-----|--------|
| eiken5       | 英検5級   | A1      | 250 語  | ~40語 | ~210語 |
| eiken4       | 英検4級   | A2      | 350 語  | ~40語 | ~310語 |
| eiken3       | 英検3級   | B1 下位  | 500 語  | ~50語 | ~450語 |
| eiken_pre2   | 英検準2級  | B1 上位  | 600 語  | 0語  | 600語  |
| eiken2       | 英検2級   | B2      | 800 語  | 0語  | 800語  |

**累計目標: 約 2,500 語**（現行 165 語を含む）

---

## CSV スキーマ（新）

```csv
id,en,ja,pos,theme,level
1,apple,りんご,noun,nature,eiken5
```

### `pos` 値（7種）

| 値            | 意味       |
|-------------|----------|
| noun        | 名詞       |
| verb        | 動詞       |
| adjective   | 形容詞      |
| adverb      | 副詞       |
| preposition | 前置詞      |
| conjunction | 接続詞      |
| phrase      | 熟語・フレーズ  |

### `theme` 値（7種）

同テーマの単語からデコイ（誤答選択肢）を選ぶため意味的まとまりを重視する。

| 値       | 意味                    | CEFR-J CoreInventory 対応（例）             |
|--------|----------------------|-----------------------------------------|
| nature | 自然・動植物・食べ物・色・天気       | Animals, Food and drink, Plants, Weather |
| daily  | 日常生活・家・時間・身体          | Body and health, The home, Time          |
| people | 人・家族・学校・仕事・社会         | Education, Work, Family, Society, Sport  |
| place  | 場所・移動・旅行              | Travel, Transport, Places and buildings  |
| action | 動作（動詞中心）              | ― (品詞 verb から推定)                       |
| mind   | 感情・状態・性質              | Feelings, Personality                    |
| general| 汎用（上記に当てはまらない）        | Language, ― 等                           |

### 既存 165 語の移行マッピング

| 旧 category | 新 pos      | 新 theme  |
|-----------|-----------|---------|
| fruit     | noun      | nature  |
| animal    | noun      | nature  |
| food      | noun      | nature  |
| body      | noun      | daily   |
| color     | adjective | nature  |
| verb      | verb      | action  |
| adjective | adjective | mind    |
| noun      | noun      | general |

---

## 半自動パイプライン

### 使用データソース（すべて無料・オフライン）

| ソース | 用途 | ライセンス | 入手方法 |
|------|------|---------|--------|
| [CEFR-J Wordlist](https://github.com/openlanguageprofiles/olp-en-cefrj) | CEFR レベル・品詞・CoreInventory テーマが付いた英単語リスト（4,000語以上） | CC BY-SA 4.0 | GitHub から CSV ダウンロード |
| [JMdict-simplified](https://github.com/scriptin/jmdict-simplified) | 英語→日本語 訳語・品詞の一括ルックアップ（214,000語） | CC BY-SA 4.0 | GitHub Releases から JSON ダウンロード |
| 英検でる順パス単（旺文社） | 頻出度・レベル分類の最終確認（⚠️ 単語を重点確認） | 書籍 | 手元に準備 |

### パイプライン全体像

```
[1] CEFR-J CSV
    └─ レベル・品詞・CoreInventory が付いた英単語リスト
         ↓
[2] tools/generate_eiken_words.py（自動）
    ├─ 指定レベルの単語を抽出
    ├─ JMdict JSON でローカル一括ルックアップ
    │   └─ 日本語訳・品詞を取得（API 不要）
    ├─ CoreInventory → 7テーマ に変換
    ├─ 既存 words.csv と照合して重複除外
    └─ 確信度付き ドラフト CSV を出力
         ↓
[3] 人間レビュー（でる順パス単で ⚠️ を確認）
    └─ ドラフト CSV を直接編集
         ↓
[4] /add-eiken-words import で words.csv に追記
    ├─ スキーマバリデーション
    ├─ 重複チェック
    └─ ID 自動採番 → CSV 追記
```

### 確信度の基準

| マーク | 条件 | 対応 |
|-----|------|-----|
| ✅ | CEFR-J 掲載 + JMdict 訳語が明確（1義） | レビュー不要でそのまま採用可 |
| ⚠️  | 訳語が複数 / CEFR レベル境界付近 / 品詞不明確 | でる順パス単で確認必須 |

### CoreInventory → theme 変換ルール（スクリプト内）

```python
CORE_INVENTORY_TO_THEME = {
    "Animals": "nature",
    "Food and drink": "nature",
    "Plants and environment": "nature",
    "Weather and climate": "nature",
    "Colour and shape": "nature",
    "Body and health": "daily",
    "The home": "daily",
    "Time": "daily",
    "Physical description": "daily",
    "Education": "people",
    "Work and Jobs": "people",
    "Family and friends": "people",
    "Society": "people",
    "Sport and leisure": "people",
    "Travel and transport": "place",
    "Places and buildings": "place",
    "Feelings and opinions": "mind",
    "Personality and character": "mind",
    "Language and communication": "general",
    "": "general",  # 未分類
}
# 品詞が verb の場合は theme を action に上書き
```

---

## 実装ファイル構成

### 新規作成

| ファイル | 内容 |
|-------|------|
| `tools/generate_eiken_words.py` | CEFR-J + JMdict パイプラインスクリプト |
| `tools/README.md` | スクリプトの使い方 |

### 変更（Phase 0: スキーマ移行）

| ファイル | 変更内容 |
|-------|------|
| `assets/quiz/words.csv` | category → pos + theme（移行マッピング適用）|
| `lib/features/quiz/model/quiz_word.dart` | `category` → `pos` + `theme` |
| `lib/features/quiz/datasource/csv_word_datasource.dart` | 新カラム対応 |
| `lib/features/quiz/view_model/quiz_view_model.dart` | デコイ選択を theme ベースに変更、LevelFilter.eikenPre2 追加 |
| `lib/i18n/en.i18n.json` / `ja.i18n.json` | 準2級ラベル追加 |

### `QuizWord` 新モデル

```dart
@freezed
abstract class QuizWord with _$QuizWord {
  const factory QuizWord({
    required int id,
    required String en,
    required String ja,
    required String pos,    // noun / verb / adjective / adverb / preposition / conjunction / phrase
    required String theme,  // nature / daily / people / place / action / mind / general
    @Default('general') String level,
  }) = _QuizWord;
}
```

### `LevelFilter` 更新

```dart
enum LevelFilter { eiken5, eiken4, eiken3, eikenPre2, eiken2, toiecBasic }
```

### デコイ選択ロジック変更

```
優先順:
1. theme が同じ && pos が同じ
2. theme が同じ
3. pos が同じ
4. ランダム
```

---

## フェーズ計画

### Phase 0: スキーマ移行（コード変更）

- [ ] `assets/quiz/words.csv` を新スキーマに変換（category → pos + theme）
- [ ] `QuizWord` モデル更新 + build_runner 再生成
- [ ] CSV datasource の新カラム対応
- [ ] デコイ選択ロジック更新（theme ベース）
- [ ] `LevelFilter.eikenPre2` 追加 + i18n + UI 表示

### Phase 1〜5: 単語追加（ツール活用）

各レベルを 50〜100 語バッチで繰り返す。

```
generate_eiken_words.py 実行
  → ドラフト CSV 確認（⚠️ をでる順パス単でチェック）
    → /add-eiken-words import で追記
```

| Phase | 対象       | 目標  |
|-------|----------|-----|
| 1     | eiken5   | 250 |
| 2     | eiken4   | 350 |
| 3     | eiken3   | 500 |
| 4     | eiken_pre2 | 600 |
| 5     | eiken2   | 800 |

---

## ツール使用手順（Phase 1 以降）

### 0. 初回のみ: データ準備

```bash
# CEFR-J CSV
curl -L -o tools/data/cefrj.csv \
  "https://raw.githubusercontent.com/openlanguageprofiles/olp-en-cefrj/master/cefrj-vocabulary-profile-1.5.csv"

# JMdict-simplified JSON（~100MB）
# https://github.com/scriptin/jmdict-simplified/releases/latest
# → jmdict-eng-3.x.x.json をダウンロードして tools/data/ に置く
```

### 1. ドラフト生成

```bash
python3 tools/generate_eiken_words.py \
  --level eiken5 \
  --count 50 \
  --existing assets/quiz/words.csv \
  --cefrj tools/data/cefrj.csv \
  --jmdict tools/data/jmdict-eng-*.json \
  --output tools/draft_eiken5.csv
```

### 2. レビュー

```
tools/draft_eiken5.csv を開く
⚠️ の単語をでる順パス単で確認して修正・削除
```

### 3. 取り込み

```
/add-eiken-words import eiken5 tools/draft_eiken5.csv
```

---

## 完了条件

- [ ] Phase 0 スキーマ移行完了（既存 165 語が新フォーマットで動作）
- [ ] `tools/generate_eiken_words.py` が動作する（README あり）
- [ ] 5〜2 級（準2含む）が目標語数に到達（累計 ~2,500 語）
- [ ] `LevelFilter.eikenPre2` が UI に表示される

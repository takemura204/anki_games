#!/usr/bin/env python3
"""
英検単語候補リスト生成スクリプト

CEFR-J Wordlist から指定レベルの英単語候補を抽出し、
pos・theme を自動付与したドラフト CSV を生成する。

日本語訳(ja)は空欄で出力する。
次のステップで Claude が訳語を付与する（/add-eiken-words draft）。

使い方:
    python3 tools/generate_eiken_words.py \\
        --level eiken5 \\
        --count 50 \\
        --existing assets/quiz/words.csv \\
        --cefrj tools/data/cefrj.csv \\
        --output tools/draft_eiken5.csv

初回のみ必要なデータ準備:
    curl -L -o tools/data/cefrj.csv \\
      "https://raw.githubusercontent.com/openlanguageprofiles/olp-en-cefrj/master/cefrj-vocabulary-profile-1.5.csv"
"""

import argparse
import csv
import os
import re
import sys

# ──────────────────────────────────────────────
# 定数
# ──────────────────────────────────────────────

LEVEL_TO_CEFR = {
    'eiken5':    ['A1'],
    'eiken4':    ['A2'],
    'eiken3':    ['B1'],
    'eiken_pre2': ['B1'],
    'eiken2':    ['B2'],
}

# 英検で頻出する品詞優先度（機能語を後回しにする）
POS_PRIORITY = {
    'noun': 0,
    'verb': 1,
    'adjective': 2,
    'adverb': 3,
    'preposition': 4,
    'conjunction': 5,
    'determiner': 6,
    'pronoun': 7,
    'interjection': 8,
}

# CEFR-J CoreInventory → アプリ theme
CORE_INVENTORY_TO_THEME = {
    'Animals': 'nature',
    'Food and drink': 'nature',
    'Plants and environment': 'nature',
    'Weather and climate': 'nature',
    'Colour and shape': 'nature',
    'Natural features': 'nature',
    'Body and health': 'daily',
    'The home': 'daily',
    'Time': 'daily',
    'Physical description': 'daily',
    'Clothes': 'daily',
    'Education': 'people',
    'Work and Jobs': 'people',
    'Family and friends': 'people',
    'Society': 'people',
    'Sport and leisure': 'people',
    'Entertainment': 'people',
    'Travel and transport': 'place',
    'Places and buildings': 'place',
    'Geography and environment': 'place',
    'Feelings and opinions': 'mind',
    'Personality and character': 'mind',
    'Thoughts and thinking': 'mind',
    'Language and communication': 'general',
    'Numbers and quantity': 'general',
    'Technology': 'general',
}

# CEFR-J pos → アプリ pos
CEFR_POS_TO_APP_POS = {
    'noun': 'noun',
    'verb': 'verb',
    'adjective': 'adjective',
    'adverb': 'adverb',
    'preposition': 'preposition',
    'conjunction': 'conjunction',
    'determiner': 'conjunction',
    'pronoun': 'noun',
    'number': 'noun',
    'interjection': 'general',
}

# 除外: 機能語・記号・略語パターン
EXCLUDE_PATTERNS = [
    re.compile(r'^[a-z]\.$'),              # "a." 等
    re.compile(r'[/\.]'),                   # スラッシュ・ピリオド含む ("a.m./A.M.")
    re.compile(r'\s'),                      # スペース含む複合語 ("all right")
    re.compile(r"'"),                       # アポストロフィ含む ("I'll")
]

FUNCTION_WORDS = {
    'a', 'an', 'the', 'is', 'are', 'was', 'were', 'be', 'been', 'being',
    'have', 'has', 'had', 'do', 'does', 'did', 'will', 'would', 'could',
    'should', 'may', 'might', 'shall', 'can', 'must', 'need', 'dare',
    'this', 'that', 'these', 'those', 'i', 'you', 'he', 'she', 'it',
    'we', 'they', 'me', 'him', 'her', 'us', 'them', 'my', 'your',
    'his', 'its', 'our', 'their', 'who', 'which', 'what', 'when',
    'where', 'why', 'how', 'and', 'or', 'but', 'so', 'if', 'then',
    'all', 'both', 'each', 'any', 'some', 'no', 'not', 'very',
}


# ──────────────────────────────────────────────
# ユーティリティ
# ──────────────────────────────────────────────

def is_excluded(word: str) -> bool:
    if word.lower() in FUNCTION_WORDS:
        return True
    return any(p.search(word) for p in EXCLUDE_PATTERNS)


def infer_theme(core_inventory: str, pos: str) -> str:
    if pos == 'verb':
        return 'action'
    if pos in ('adjective', 'adverb') and 'Feeling' in core_inventory:
        return 'mind'
    return CORE_INVENTORY_TO_THEME.get(core_inventory, 'general')


# ──────────────────────────────────────────────
# メイン
# ──────────────────────────────────────────────

def load_existing(path: str) -> tuple[set[str], int]:
    existing: set[str] = set()
    max_id = 0
    with open(path, newline='', encoding='utf-8') as f:
        for row in csv.DictReader(f):
            existing.add(row.get('en', '').lower().strip())
            try:
                max_id = max(max_id, int(row.get('id', 0)))
            except ValueError:
                pass
    return existing, max_id


def load_cefrj(path: str) -> list[dict]:
    with open(path, newline='', encoding='utf-8') as f:
        return list(csv.DictReader(f))


def main():
    parser = argparse.ArgumentParser(description='英検単語候補リスト生成')
    parser.add_argument('--level', required=True, choices=list(LEVEL_TO_CEFR.keys()))
    parser.add_argument('--count', type=int, default=50)
    parser.add_argument('--existing', required=True)
    parser.add_argument('--cefrj', required=True)
    parser.add_argument('--output', required=True)
    args = parser.parse_args()

    for p, name in [(args.existing, '--existing'), (args.cefrj, '--cefrj')]:
        if not os.path.exists(p):
            print(f'ERROR: {name} が見つかりません: {p}', file=sys.stderr)
            sys.exit(1)

    existing_words, max_id = load_existing(args.existing)
    cefrj_rows = load_cefrj(args.cefrj)

    target_cefr = LEVEL_TO_CEFR[args.level]

    # 候補を抽出・重複除去・機能語除去
    seen_words: set[str] = set()
    candidates = []
    for row in cefrj_rows:
        if row.get('CEFR', '').strip() not in target_cefr:
            continue
        word = row.get('headword', '').strip()
        if not word or word.lower() in existing_words or word.lower() in seen_words:
            continue
        if is_excluded(word):
            continue
        seen_words.add(word.lower())
        candidates.append(row)

    # 品詞優先度でソート（名詞・動詞・形容詞を先に）
    candidates.sort(
        key=lambda r: POS_PRIORITY.get(r.get('pos', '').lower(), 9)
    )

    results = []
    next_id = max_id + 1

    for row in candidates[:args.count]:
        word = row.get('headword', '').strip()
        cefr_pos = row.get('pos', '').strip().lower()
        core_inv = row.get('CoreInventory', '').strip()

        app_pos = CEFR_POS_TO_APP_POS.get(cefr_pos, 'noun')
        theme = infer_theme(core_inv, app_pos)

        results.append({
            'id': next_id,
            'en': word,
            'ja': '',           # Claude が次ステップで付与
            'pos': app_pos,
            'theme': theme,
            'level': args.level,
            'notes': core_inv,  # レビュー参考用
        })
        next_id += 1

    # CSV 出力
    with open(args.output, 'w', newline='', encoding='utf-8') as f:
        writer = csv.DictWriter(
            f,
            fieldnames=['id', 'en', 'ja', 'pos', 'theme', 'level', 'notes'],
        )
        writer.writeheader()
        writer.writerows(results)

    # サマリー
    pos_counts: dict[str, int] = {}
    for r in results:
        pos_counts[r['pos']] = pos_counts.get(r['pos'], 0) + 1

    print(f'\n✅ 候補抽出完了: {len(results)} 語 → {args.output}')
    print(f'   品詞内訳: {dict(sorted(pos_counts.items()))}')
    print()
    print('【次のステップ】')
    print(f'Claude に以下を貼り付けて日本語訳を追加してください:')
    print()
    print('─' * 60)
    print(f'以下の英単語リストに日本語訳(ja列)を付けてください。')
    print(f'英検{args.level}レベルの単語です。')
    print(f'訳語は短く自然な日本語で。複数ある場合は最もよく使われるもの1つだけ。')
    print()
    word_list = ', '.join(r['en'] for r in results)
    print(f'{word_list}')
    print('─' * 60)
    print()
    print('訳語が揃ったら /add-eiken-words import で取り込んでください。')


if __name__ == '__main__':
    main()

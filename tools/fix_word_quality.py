#!/usr/bin/env python3
"""
単語品質修正スクリプト
- 同一訳語の重複を差別化
- 品詞に合わない訳語を修正
- マイナー単語を削除・補完
"""

import csv
import re
from pathlib import Path

# (en, level) → 新しい ja
TRANSLATION_FIXES: dict[tuple[str, str], str] = {
    # ===== eiken5 =====
    ("like", "eiken5"): "好む",
    ("want", "eiken5"): "欲しがる",
    ("see", "eiken5"): "見える",
    ("look", "eiken5"): "見る（意識的に）",
    ("slow", "eiken5"): "遅い（速度）",
    ("late", "eiken5"): "遅い（時刻）",
    ("month", "eiken5"): "月（ひと月）",
    ("moon", "eiken5"): "月（つき）",
    ("fall", "eiken5"): "秋（米）",
    ("autumn", "eiken5"): "秋（英）",
    ("stomach", "eiken5"): "胃・お腹",
    ("taxi", "eiken5"): "タクシー",

    # ===== eiken4 =====
    ("exciting", "eiken4"): "わくわくさせる",
    ("proud", "eiken4"): "誇らしい",
    ("force", "eiken4"): "力（物理的な）",
    ("power", "eiken4"): "力（能力・権力）",
    ("bookshelf", "eiken4"): "本棚",
    ("bookcase", "eiken4"): "本箱",
    ("consequence", "eiken4"): "（悪い）結果",
    ("result", "eiken4"): "結果",
    ("drug", "eiken4"): "薬物",
    ("medicine", "eiken4"): "薬（医薬品）",
    ("describe", "eiken4"): "描写する",
    ("explain", "eiken4"): "説明する",
    ("commitment", "eiken4"): "約束・コミット",
    ("responsibility", "eiken4"): "責任",
    ("fridge", "eiken4"): "冷蔵庫（略）",
    ("refrigerator", "eiken4"): "冷蔵庫",
    ("clever", "eiken4"): "賢い",
    ("smart", "eiken4"): "頭の良い",
    ("terrible", "eiken4"): "ひどい",
    ("horrible", "eiken3"): "嫌な・ひどい",
    ("belly", "eiken4"): "お腹（くだけた）",
    ("chin", "eiken4"): "あご",
    ("cab", "eiken4"): "タクシー（略）",
    ("chart", "eiken4"): "図表",
    ("graph", "eiken3"): "グラフ",
    ("boss", "eiken4"): "上司（くだけた）",
    ("baker", "eiken4"): "パン職人",
    ("bakery", "eiken3"): "パン屋",
    ("boots", "eiken4"): "ブーツ（両足）",
    ("bite", "eiken4"): "かじること",
    ("pigeon", "eiken4"): "ハト",
    ("motorcycle", "eiken4"): "バイク",
    ("ferry", "eiken4"): "フェリー",
    ("cigarette", "eiken4"): "タバコ（紙巻き）",

    # ===== eiken3 =====
    ("beloved", "eiken3"): "いとしい",
    ("concerned", "eiken3"): "心配している",
    ("dependent", "eiken3"): "依存している",
    ("firm", "eiken3"): "確固とした",
    ("jealous", "eiken3"): "嫉妬している",
    ("satisfied", "eiken3"): "満足している",
    ("sticky", "eiken3"): "ベタベタする",
    ("thankful", "eiken3"): "感謝している",
    ("controversial", "eiken3"): "議論を呼ぶ",
    ("remarkable", "eiken3"): "注目に値する",
    ("similar", "eiken3"): "似た",
    ("resemble", "eiken3"): "〜に似ている",
    ("alike", "eiken3"): "互いに似た",
    ("valuable", "eiken3"): "貴重な",
    ("worthwhile", "eiken3"): "やりがいのある",
    ("convenient", "eiken3"): "便利な",
    ("handy", "eiken3"): "手軽な",
    ("accomplish", "eiken3"): "成し遂げる",
    ("achieve", "eiken3"): "達成する",
    ("attain", "eiken3"): "到達する",
    ("stable", "eiken3"): "安定した",
    ("steady", "eiken3"): "着実な",
    ("apparent", "eiken3"): "見かけ上の",
    ("evident", "eiken3"): "明白な",
    ("obvious", "eiken3"): "明らかな",
    ("accurate", "eiken3"): "正確な",
    ("exact", "eiken3"): "厳密な",
    ("calm", "eiken3"): "穏やかな",
    ("mild", "eiken3"): "温和な",
    ("amusing", "eiken3"): "面白い",
    ("delightful", "eiken3"): "楽しい",
    ("enjoyable", "eiken3"): "楽しめる",
    ("giant", "eiken3"): "巨大な",
    ("huge", "eiken3"): "大きい",
    ("massive", "eiken3"): "大量の",
    ("chuckle", "eiken3"): "くっくと笑う",
    ("giggle", "eiken3"): "くすくす笑う",
    ("grab", "eiken3"): "つかむ",
    ("seize", "eiken3"): "捕らえる",
    ("scared", "eiken3"): "恐れている",
    ("scary", "eiken3"): "恐ろしい",
    ("ashamed", "eiken3"): "恥じている",
    ("embarrassed", "eiken3"): "恥ずかしい",
    ("foolish", "eiken3"): "愚かな",
    ("stupid", "eiken3"): "ばかな",
    ("faithful", "eiken3"): "誠実な",
    ("loyal", "eiken3"): "忠実な",
    ("appreciation", "eiken3"): "感謝",
    ("gratitude", "eiken3"): "深い感謝",
    ("own", "eiken3"): "所有する",
    ("possess", "eiken3"): "所持する",
    ("gifted", "eiken3"): "生まれつき才能のある",
    ("talented", "eiken3"): "才能のある",
    ("aid", "eiken3"): "援助（物資）",
    ("assistance", "eiken3"): "援助（手伝い）",
    ("establishment", "eiken3"): "設立",
    ("facility", "eiken3"): "施設",
    ("renew", "eiken3"): "更新する",
    ("update", "eiken3"): "更新する（デジタル）",
    ("chaos", "eiken3"): "無秩序",
    ("confusion", "eiken3"): "混乱",
    ("lessen", "eiken3"): "和らげる",
    ("reduce", "eiken3"): "削減する",
    ("eager", "eiken3"): "熱心な",
    ("enthusiastic", "eiken3"): "情熱的な",
    ("eagerness", "eiken3"): "熱意",
    ("enthusiasm", "eiken3"): "情熱",
    ("current", "eiken3"): "現在の",
    ("present", "eiken3"): "今の",
    ("painful", "eiken3"): "痛い（辛い）",
    ("sore", "eiken3"): "ひりひり痛い",
    ("mental", "eiken3"): "精神的な",
    ("spiritual", "eiken3"): "霊的な",
    ("amazing", "eiken3"): "驚くほど素晴らしい",
    ("terrific", "eiken3"): "素晴らしい",
    ("fasten", "eiken3"): "固定する",
    ("tighten", "eiken3"): "締める",
    ("conflict", "eiken3"): "対立",
    ("crash", "eiken3"): "衝突",
    ("bare", "eiken3"): "むき出しの",
    ("naked", "eiken3"): "裸の",
    ("complex", "eiken3"): "複雑な",
    ("complicated", "eiken3"): "込み入った",
    ("liberate", "eiken3"): "自由にする",
    ("release", "eiken3"): "放つ",
    ("resolve", "eiken3"): "解決する",
    ("settle", "eiken3"): "落ち着かせる",
    ("excuse", "eiken3"): "大目に見る",
    ("pardon", "eiken3"): "許す",
    ("convince", "eiken3"): "信じさせる",
    ("persuade", "eiken3"): "説得する",
    ("agriculture", "eiken3"): "農業",
    ("farming", "eiken3"): "農作業",
    ("shiver", "eiken3"): "震える（寒さで）",
    ("tremble", "eiken3"): "震える（恐れで）",
    ("attraction", "eiken3"): "引き付けるもの",
    ("charm", "eiken3"): "魅力",
    ("rational", "eiken3"): "合理的な",
    ("reasonable", "eiken3"): "理にかなった",
    ("recover", "eiken3"): "回復する",
    ("restore", "eiken3"): "元に戻す",
    ("reclaim", "eiken3"): "権利を取り戻す",
    ("regain", "eiken3"): "状態を取り戻す",
    ("remove", "eiken3"): "除去する",
    ("rid", "eiken3"): "取り除く",
    ("basis", "eiken3"): "根拠",
    ("foundation", "eiken3"): "基盤",
    ("declare", "eiken3"): "宣言する",
    ("proclaim", "eiken3"): "公式に宣言する",
    ("unfortunate", "eiken3"): "不運な",
    ("unlucky", "eiken3"): "運の悪い",
    ("disgusting", "eiken3"): "不快な（嫌悪感）",
    ("nasty", "eiken3"): "不快な（意地悪）",
    ("companion", "eiken3"): "連れ",
    ("fellow", "eiken3"): "仲間",
    ("boot", "eiken3"): "ブーツ（片方）",
    ("flu", "eiken3"): "インフルエンザ（略）",
    ("ridiculous", "eiken3"): "ばかげた",
    ("outweigh", "eiken3"): "（重みで）上回る",
    ("essential", "eiken3"): "不可欠な",

    # ===== eiken_pre2 =====
    ("lasting", "eiken_pre2"): "永続的な",
    ("pregnant", "eiken_pre2"): "妊娠している",
    ("prosperous", "eiken_pre2"): "繁栄している",
    ("unemployed", "eiken_pre2"): "失業している",
    ("continuous", "eiken_pre2"): "継続的な",
    ("hasty", "eiken_pre2"): "性急な",
    ("noticeable", "eiken_pre2"): "目立つ",
    ("afterward", "eiken_pre2"): "その後（米）",
    ("afterwards", "eiken_pre2"): "その後（英）",
    ("compile", "eiken_pre2"): "まとめる（集める）",
    ("summarize", "eiken_pre2"): "要約する",
    ("largely", "eiken_pre2"): "大部分は",
    ("primarily", "eiken_pre2"): "主に",
    ("humanity", "eiken_pre2"): "人類（人間性も）",
    ("mankind", "eiken_pre2"): "人類（歴史的語）",
    ("tendency", "eiken_pre2"): "傾向",
    ("trend", "eiken_pre2"): "流行",
    ("limitation", "eiken_pre2"): "上限・制限",
    ("restriction", "eiken_pre2"): "禁止・制限",
    ("proportion", "eiken_pre2"): "比率",
    ("percentage", "eiken_pre2"): "パーセンテージ",
    ("collaborate", "eiken_pre2"): "共同作業する",
    ("cooperate", "eiken_pre2"): "協力する",
    ("income", "eiken_pre2"): "収入",
    ("revenue", "eiken_pre2"): "売上収入",
    ("variety", "eiken_pre2"): "種類の多さ",
    ("diversity", "eiken_pre2"): "多様性",
    ("altogether", "eiken_pre2"): "全部で",
    ("completely", "eiken_pre2"): "完全に",
    ("entirely", "eiken_pre2"): "全体的に",
    ("lab", "eiken_pre2"): "実験室（略）",
    ("laboratory", "eiken_pre2"): "実験室",
    ("hut", "eiken_pre2"): "粗末な小屋",
    ("lodge", "eiken_pre2"): "宿泊施設",
    ("ingredient", "eiken_pre2"): "食材",
    ("material", "eiken_pre2"): "素材",
    ("divine", "eiken_pre2"): "神の",
    ("sacred", "eiken_pre2"): "神聖な",
    ("nervousness", "eiken_pre2"): "緊張（心理的）",
    ("strain", "eiken_pre2"): "疲労・緊張",
    ("tension", "eiken_pre2"): "緊張（対立）",
    ("herd", "eiken_pre2"): "群れ（大型動物）",
    ("swarm", "eiken_pre2"): "群れ（虫）",
    ("package", "eiken_pre2"): "小包",
    ("luggage", "eiken_pre2"): "旅行荷物",
    ("settlement", "eiken_pre2"): "和解",
    ("resolution", "eiken_pre2"): "解決",
    ("allow", "eiken_pre2"): "許可する",
    ("authorize", "eiken_pre2"): "権限を与える",
    ("assess", "eiken_pre2"): "査定する",
    ("evaluate", "eiken_pre2"): "評価する",
    ("adjust", "eiken_pre2"): "微調整する",
    ("coordinate", "eiken_pre2"): "調整する",
    ("investigate", "eiken_pre2"): "徹底的に調査する",
    ("survey", "eiken_pre2"): "調査する",
    ("pick", "eiken_pre2"): "選ぶ",
    ("selection", "eiken_pre2"): "選択",
    ("haven", "eiken_pre2"): "安全な場所",
    ("shelter", "eiken_pre2"): "避難施設",
    ("lorry", "eiken_pre2"): "大型トラック（英）",
    ("jumper", "eiken_pre2"): "セーター（英）",
    ("lift", "eiken_pre2"): "エレベーター（英）",
    ("rubbish", "eiken_pre2"): "ゴミ（英）",
    ("supervisor", "eiken_pre2"): "上司（監督者）",
    ("tobacco", "eiken_pre2"): "タバコ（葉・植物）",
    ("barely", "eiken_pre2"): "ほぼ〜ない",
    ("rarely", "eiken_pre2"): "めったに〜ない",
    ("misery", "eiken_pre2"): "悲惨",
    ("consistent", "eiken_pre2"): "一貫した",
    ("deceive", "eiken_pre2"): "欺く",

    # ===== eiken2 =====
    ("appreciative", "eiken2"): "感謝している",
    ("convinced", "eiken2"): "確信している",
    ("determined", "eiken2"): "決意した",
    ("enduring", "eiken2"): "永続的な",
    ("tiresome", "eiken2"): "うんざりする",
    ("breathtaking", "eiken2"): "息をのむような",
    ("deceptive", "eiken2"): "欺くような",
    ("hospitable", "eiken2"): "もてなし上手な",
    ("indulgent", "eiken2"): "甘やかす",
    ("misleading", "eiken2"): "誤解を招く",
    ("satisfactory", "eiken2"): "満足のいく",
    ("sparkling", "eiken2"): "輝くような",
    ("admirable", "eiken2"): "称賛に値する",
    ("astonishing", "eiken2"): "驚くべき",
    ("promptly", "eiken2"): "即座に",
    ("readily", "eiken2"): "容易に",
    ("flip", "eiken2"): "ひっくり返す",
    ("overturn", "eiken2"): "転覆させる",
    ("dreadful", "eiken2"): "恐ろしい",
    ("foul", "eiken2"): "汚い",
    ("lousy", "eiken2"): "粗悪な",
    ("inadequate", "eiken2"): "不適切な",
    ("insufficient", "eiken2"): "量が足りない",
    ("irrational", "eiken2"): "非論理的な",
    ("unreasonable", "eiken2"): "常識外れな",
    ("needless", "eiken2"): "無駄な",
    ("redundant", "eiken2"): "余剰の",
    ("petty", "eiken2"): "些細な",
    ("trivial", "eiken2"): "取るに足らない",
    ("corporation", "eiken2"): "大企業",
    ("enterprise", "eiken2"): "事業体",
    ("indignity", "eiken2"): "品位を傷つける行為",
    ("insult", "eiken2"): "侮辱",
    ("candidate", "eiken2"): "候補者（選挙）",
    ("nominee", "eiken2"): "指名された候補",
    ("elegance", "eiken2"): "品格",
    ("gracefulness", "eiken2"): "動きの優雅さ",
    ("forcefully", "eiken2"): "強制的に",
    ("powerfully", "eiken2"): "力強く",
    ("outshine", "eiken2"): "輝きで勝る",
    ("prevail", "eiken2"): "最終的に勝つ",
    ("adequately", "eiken2"): "適切に",
    ("sufficiently", "eiken2"): "十分な量で",
    ("hazardous", "eiken2"): "有害な",
    ("risky", "eiken2"): "リスクがある",
    ("range", "eiken2"): "範囲が及ぶ",
    ("span", "eiken2"): "時間・距離が及ぶ",
    ("benevolence", "eiken2"): "慈悲心",
    ("goodwill", "eiken2"): "善意",
    ("revolve", "eiken2"): "公転する",
    ("spin", "eiken2"): "回転する",
    ("bizarre", "eiken2"): "常軌を逸した",
    ("odd", "eiken2"): "変な",
    ("drapery", "eiken2"): "カーテン生地",
    ("fabric", "eiken2"): "布地",
    ("mighty", "eiken2"): "強大な",
    ("potent", "eiken2"): "強力な",
    ("caring", "eiken2"): "思いやりのある",
    ("compassionate", "eiken2"): "深い共感を持つ",
    ("fearsome", "eiken2"): "脅威的な",
    ("terrifying", "eiken2"): "恐怖を与える",
    ("imply", "eiken2"): "暗示する",
    ("signify", "eiken2"): "象徴する",
    ("embrace", "eiken2"): "抱擁（広い）",
    ("hug", "eiken2"): "抱きしめ",
    ("persist", "eiken2"): "持続する",
    ("deduction", "eiken2"): "演繹的推論",
    ("inference", "eiken2"): "推論",
    ("deduce", "eiken2"): "演繹的に推論する",
    ("infer", "eiken2"): "推論する",
    ("desirable", "eiken2"): "望ましい",
    ("preferable", "eiken2"): "より好まれる",
    ("authoritative", "eiken2"): "専門的権威のある",
    ("prestigious", "eiken2"): "評判の高い",
    ("correctness", "eiken2"): "正しさ",
    ("exactness", "eiken2"): "厳密さ",
    ("bitterly", "eiken2"): "苦々しく",
    ("furiously", "eiken2"): "激怒して",
    ("blaze", "eiken2"): "大きな炎",
    ("flame", "eiken2"): "炎",
    ("eagerly", "eiken2"): "待ち望んで",
    ("enthusiastically", "eiken2"): "情熱的に",
    ("doubtful", "eiken2"): "確信が持てない",
    ("suspicious", "eiken2"): "怪しい",
    ("exalt", "eiken2"): "高める",
    ("glorify", "eiken2"): "賛美する",
    ("actively", "eiken2"): "活発に",
    ("aggressively", "eiken2"): "攻撃的に",
    ("lawmaker", "eiken2"): "法律立案者",
    ("legislator", "eiken2"): "立法議員",
    ("shatter", "eiken2"): "砕け散る",
    ("smash", "eiken2"): "打ち砕く",
    ("fabulous", "eiken2"): "驚くほど素晴らしい",
    ("superb", "eiken2"): "最高の",
    ("capability", "eiken2"): "潜在的能力",
    ("competence", "eiken2"): "実際の能力",
    ("compute", "eiken2"): "コンピュータで計算する",
    ("reckon", "eiken2"): "見積もる",
    ("assessment", "eiken2"): "査定",
    ("evaluation", "eiken2"): "総合評価",
    ("exaggeration", "eiken2"): "誇張",
    ("hyperbole", "eiken2"): "誇張法",
    ("controversy", "eiken2"): "公的な論争",
    ("dispute", "eiken2"): "対立・論争",
    ("aristocracy", "eiken2"): "貴族階級",
    ("nobility", "eiken2"): "高貴な階層",
    ("destiny", "eiken2"): "宿命",
    ("fate", "eiken2"): "運命",
    ("achievable", "eiken2"): "達成可能な",
    ("attainable", "eiken2"): "到達可能な",
    ("appropriately", "eiken2"): "状況に合って",
    ("suitably", "eiken2"): "適切に",
    ("duplication", "eiken2"): "複製",
    ("overlap", "eiken2"): "重複",
    ("acute", "eiken2"): "鋭敏な",
    ("keen", "eiken2"): "意欲的な",
    ("cheerfulness", "eiken2"): "明るさ",
    ("gaiety", "eiken2"): "陽気な雰囲気",
    ("informal", "eiken2"): "くだけた",
    ("unofficial", "eiken2"): "非公認の",
    ("hugely", "eiken2"): "巨大に",
    ("tremendously", "eiken2"): "驚くほど",
    ("coherent", "eiken2"): "論理的に一貫した",
    ("absurd", "eiken2"): "不条理な",
    ("seldom", "eiken2"): "めったに〜ない（文語）",
    ("influenza", "eiken2"): "インフルエンザ（正式名称）",
    ("motorbike", "eiken2"): "バイク（英）",
    ("ferryboat", "eiken2"): "フェリーボート",
    ("gulp", "eiken2"): "一口（飲み込む）",
    ("outdo", "eiken2"): "能力で上回る",
    ("indispensable", "eiken2"): "欠かせない",
    ("misfortune", "eiken2"): "不幸（悪い出来事）",
    ("jaw", "eiken2"): "顎（あご）",
    ("lap", "eiken2"): "膝の上",
    ("bend", "eiken2"): "曲がり",
    ("thereafter", "eiken2"): "それ以後",
    ("trick", "eiken2"): "うまく騙す",
    ("jog", "eiken2"): "ゆっくり走る",
    ("dove", "eiken2"): "鳩（平和の象徴）",
    ("gleam", "eiken2"): "かすかに光る",
}

# pos の修正 (en, level) → 新しい pos
POS_FIXES: dict[tuple[str, str], str] = {
    ("fix", "eiken4"): "verb",
    ("jog", "eiken2"): "verb",
    ("gleam", "eiken2"): "verb",
    ("sparkle", "eiken_pre2"): "verb",
    ("glint", "eiken3"): "verb",
    ("chuckle", "eiken3"): "verb",
    ("giggle", "eiken3"): "verb",
}

# ja の追加修正（pos fix に伴う場合）
POS_AND_JA_FIXES: dict[tuple[str, str], tuple[str, str]] = {
    ("fix", "eiken4"): ("verb", "直す"),
    ("jog", "eiken2"): ("verb", "ゆっくり走る"),
    ("gleam", "eiken2"): ("verb", "かすかに光る"),
    ("sparkle", "eiken_pre2"): ("verb", "きらめく"),
    ("glint", "eiken3"): ("verb", "ちらっと光る"),
    ("chuckle", "eiken3"): ("verb", "くっくと笑う"),
    ("giggle", "eiken3"): ("verb", "くすくす笑う"),
}

# 削除する単語（en, level）→ 理由
REMOVE_WORDS: dict[tuple[str, str], str] = {
    ("fortnight", "eiken3"): "英国英語・日本の試験に出ない",
    ("jogging", "eiken_pre2"): "jog(eiken2)と重複・pos修正",
    ("ferryboat", "eiken2"): "ferry(eiken4)と重複・フォーマルすぎ",
    ("afterward", "eiken_pre2"): "afterwards(eiken_pre2)と重複・米国スペル",
}

# 補完する単語（削除した分を補完）
ADD_WORDS: list[dict] = [
    # fortnight の代替 (eiken3)
    {"en": "dozen", "ja": "12個", "pos": "noun", "theme": "general", "level": "eiken3"},
    # jogging の代替 (eiken_pre2) - 既に jog を verb に修正したので noun も必要
    {"en": "hiking", "ja": "ハイキング", "pos": "noun", "theme": "action", "level": "eiken_pre2"},
    # ferryboat の代替 (eiken2)
    {"en": "vessel", "ja": "船・容器", "pos": "noun", "theme": "place", "level": "eiken2"},
    # afterward の代替 (eiken_pre2)
    {"en": "thereafter", "ja": "それ以後", "pos": "adverb", "theme": "general", "level": "eiken_pre2"},
]


def main():
    csv_path = Path("assets/quiz/words.csv")
    backup_path = Path("assets/quiz/words.csv.bak_quality")

    with open(csv_path) as f:
        reader = csv.DictReader(f)
        rows = list(reader)

    # バックアップ
    import shutil
    shutil.copy(csv_path, backup_path)
    print(f"Backed up to {backup_path}")

    # 削除予定の単語IDを収集
    remove_ids: set[str] = set()
    for (en, level), reason in REMOVE_WORDS.items():
        for r in rows:
            if r["en"] == en and r["level"] == level:
                remove_ids.add(r["id"])
                print(f"REMOVE: id={r['id']} {en}({level}) - {reason}")

    # 修正適用
    fix_count = 0
    pos_fix_count = 0
    for r in rows:
        key = (r["en"], r["level"])

        # pos + ja 同時修正
        if key in POS_AND_JA_FIXES:
            new_pos, new_ja = POS_AND_JA_FIXES[key]
            old = f"pos={r['pos']}, ja={r['ja']}"
            r["pos"] = new_pos
            r["ja"] = new_ja
            print(f"POS+JA FIX: {r['en']}({r['level']}) {old} → pos={new_pos}, ja={new_ja}")
            fix_count += 1
            pos_fix_count += 1
            continue

        # ja のみ修正
        if key in TRANSLATION_FIXES:
            new_ja = TRANSLATION_FIXES[key]
            if r["ja"] != new_ja:
                print(f"JA FIX: {r['en']}({r['level']}) '{r['ja']}' → '{new_ja}'")
                r["ja"] = new_ja
                fix_count += 1

    # 削除
    original_count = len(rows)
    rows = [r for r in rows if r["id"] not in remove_ids]
    removed_count = original_count - len(rows)

    # 補完単語を追加
    max_id = max(int(r["id"]) for r in rows)
    for word in ADD_WORDS:
        max_id += 1
        new_row = {"id": str(max_id), "is_frequent": "0", **word}
        rows.append(new_row)
        print(f"ADD: id={max_id} {word['en']}({word['level']}) = {word['ja']}")

    # IDでソート
    rows.sort(key=lambda r: int(r["id"]))

    # 書き込み
    fieldnames = ["id", "en", "ja", "pos", "theme", "level", "is_frequent"]
    with open(csv_path, "w", newline="") as f:
        writer = csv.DictWriter(f, fieldnames=fieldnames)
        writer.writeheader()
        writer.writerows(rows)

    print(f"\n=== Summary ===")
    print(f"Translation fixes: {fix_count}")
    print(f"Pos fixes: {pos_fix_count}")
    print(f"Removed: {removed_count}")
    print(f"Added: {len(ADD_WORDS)}")
    print(f"Final total: {len(rows)} words")

    # レベル別カウント
    from collections import Counter
    cnt = Counter(r["level"] for r in rows)
    for level in ["eiken5", "eiken4", "eiken3", "eiken_pre2", "eiken2", "toeic_basic"]:
        print(f"  {level}: {cnt[level]}")


if __name__ == "__main__":
    main()

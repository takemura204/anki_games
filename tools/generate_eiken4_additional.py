#!/usr/bin/env python3
"""
英検4級 追加単語生成スクリプト

処理内容:
  1. eiken5 と重複している eiken4 単語を削除
  2. 候補プールから未収録語を選んで 600 語になるまで追加
  3. 下書き CSV を出力（tools/draft_eiken4_additional.csv）

実行:
  python3 tools/generate_eiken4_additional.py
"""

import csv, sys

# ── 候補プール（A2相当 / 英検4級レベル）─────────────────────────
# eiken5 / 既存 eiken4 にない語のみ実際に使われる（スクリプト内でフィルタ）

CANDIDATES = [
    # ── 動詞 ────────────────────────────────────────────────
    ("arrive","到着する","verb","action"),
    ("borrow","借りる","verb","action"),
    ("break","壊す","verb","action"),
    ("build","建てる","verb","action"),
    ("catch","捕まえる","verb","action"),
    ("climb","登る","verb","action"),
    ("collect","集める","verb","action"),
    ("continue","続ける","verb","action"),
    ("cross","渡る","verb","action"),
    ("describe","説明する","verb","action"),
    ("die","死ぬ","verb","action"),
    ("discover","発見する","verb","action"),
    ("drop","落とす","verb","action"),
    ("earn","稼ぐ","verb","action"),
    ("escape","逃げる","verb","action"),
    ("explain","説明する","verb","action"),
    ("fail","失敗する","verb","action"),
    ("fill","満たす","verb","action"),
    ("fix","修理する","verb","action"),
    ("follow","従う","verb","action"),
    ("forget","忘れる","verb","action"),
    ("forgive","許す","verb","action"),
    ("grow","育つ","verb","action"),
    ("guess","推測する","verb","action"),
    ("hurt","傷つける","verb","action"),
    ("improve","改善する","verb","action"),
    ("increase","増える","verb","action"),
    ("introduce","紹介する","verb","action"),
    ("invite","招待する","verb","action"),
    ("lend","貸す","verb","action"),
    ("mention","述べる","verb","action"),
    ("miss","恋しく思う","verb","action"),
    ("offer","申し出る","verb","action"),
    ("perform","演じる","verb","action"),
    ("plan","計画する","verb","action"),
    ("prepare","準備する","verb","action"),
    ("produce","生産する","verb","action"),
    ("promise","約束する","verb","action"),
    ("protect","守る","verb","action"),
    ("pull","引く","verb","action"),
    ("push","押す","verb","action"),
    ("raise","上げる","verb","action"),
    ("realize","気づく","verb","action"),
    ("receive","受け取る","verb","action"),
    ("relax","くつろぐ","verb","action"),
    ("remember","覚えている","verb","action"),
    ("repair","直す","verb","action"),
    ("repeat","繰り返す","verb","action"),
    ("report","報告する","verb","action"),
    ("rest","休む","verb","action"),
    ("shout","叫ぶ","verb","action"),
    ("spend","過ごす","verb","action"),
    ("spread","広がる","verb","action"),
    ("steal","盗む","verb","action"),
    ("succeed","成功する","verb","action"),
    ("support","支える","verb","action"),
    ("throw","投げる","verb","action"),
    ("travel","旅行する","verb","action"),
    ("understand","理解する","verb","action"),
    ("wake","起きる","verb","action"),
    ("warn","警告する","verb","action"),
    ("wonder","不思議に思う","verb","action"),
    ("worry","心配する","verb","action"),
    ("wrap","包む","verb","action"),
    ("shake","振る","verb","action"),
    ("knock","ノックする","verb","action"),
    ("suggest","提案する","verb","action"),
    ("accept","受け入れる","verb","action"),
    ("celebrate","祝う","verb","action"),
    ("compete","競争する","verb","action"),
    # ── 形容詞 ──────────────────────────────────────────────
    ("active","活発な","adjective","general"),
    ("afraid","怖い","adjective","mind"),
    ("alone","一人の","adjective","mind"),
    ("brave","勇敢な","adjective","mind"),
    ("careful","注意深い","adjective","general"),
    ("cheap","安い","adjective","general"),
    ("cheerful","陽気な","adjective","mind"),
    ("clever","賢い","adjective","general"),
    ("comfortable","快適な","adjective","general"),
    ("curious","好奇心旺盛な","adjective","mind"),
    ("dangerous","危険な","adjective","general"),
    ("dark","暗い","adjective","general"),
    ("dead","死んだ","adjective","general"),
    ("delicious","おいしい","adjective","daily"),
    ("empty","空の","adjective","general"),
    ("excellent","優秀な","adjective","general"),
    ("excited","興奮した","adjective","mind"),
    ("exciting","わくわくする","adjective","mind"),
    ("expensive","高価な","adjective","general"),
    ("famous","有名な","adjective","people"),
    ("foreign","外国の","adjective","general"),
    ("friendly","友好的な","adjective","people"),
    ("glad","嬉しい","adjective","mind"),
    ("healthy","健康な","adjective","daily"),
    ("heavy","重い","adjective","general"),
    ("large","大きい","adjective","general"),
    ("lonely","孤独な","adjective","mind"),
    ("lucky","運の良い","adjective","general"),
    ("nervous","緊張した","adjective","mind"),
    ("perfect","完璧な","adjective","general"),
    ("popular","人気の","adjective","people"),
    ("proud","誇りに思う","adjective","mind"),
    ("quiet","静かな","adjective","general"),
    ("safe","安全な","adjective","general"),
    ("serious","真剣な","adjective","general"),
    ("smart","賢い","adjective","general"),
    ("special","特別な","adjective","general"),
    ("strange","不思議な","adjective","general"),
    ("strong","強い","adjective","general"),
    ("sudden","突然の","adjective","general"),
    ("surprised","驚いた","adjective","mind"),
    ("terrible","ひどい","adjective","general"),
    ("weak","弱い","adjective","general"),
    ("wide","広い","adjective","general"),
    ("wonderful","すばらしい","adjective","general"),
    ("worried","心配した","adjective","mind"),
    ("dark","暗い","adjective","general"),  # dup, will be filtered
    ("wild","野生の","adjective","nature"),
    ("bright","明るい","adjective","general"),
    # ── 食べ物・料理 ─────────────────────────────────────────
    ("butter","バター","noun","daily"),
    ("flour","小麦粉","noun","daily"),
    ("noodle","麺","noun","daily"),
    ("sushi","寿司","noun","daily"),
    ("curry","カレー","noun","daily"),
    ("seafood","海鮮","noun","daily"),
    ("pasta","パスタ","noun","daily"),
    ("steak","ステーキ","noun","daily"),
    ("sauce","ソース","noun","daily"),
    ("chocolate","チョコレート","noun","daily"),  # may be in eiken5, filtered
    ("snack","スナック","noun","daily"),
    ("dessert","デザート","noun","daily"),
    ("cereal","シリアル","noun","daily"),
    ("sausage","ソーセージ","noun","daily"),
    ("melon","メロン","noun","nature"),  # may be in eiken5, filtered
    ("grape","ぶどう","noun","nature"),  # in eiken5, filtered
    # ── 動物（上位）───────────────────────────────────────────
    ("whale","クジラ","noun","nature"),
    ("eagle","ワシ","noun","nature"),
    ("parrot","オウム","noun","nature"),
    ("penguin","ペンギン","noun","nature"),
    ("wolf","オオカミ","noun","nature"),
    ("deer","シカ","noun","nature"),
    ("bat","コウモリ","noun","nature"),
    ("crab","カニ","noun","nature"),
    ("shark","サメ","noun","nature"),
    ("octopus","タコ","noun","nature"),
    ("crocodile","ワニ","noun","nature"),
    ("parrot","オウム","noun","nature"),  # dup
    ("pigeon","ハト","noun","nature"),
    # ── 職業 ─────────────────────────────────────────────────
    ("nurse","看護師","noun","people"),
    ("chef","シェフ","noun","people"),
    ("engineer","エンジニア","noun","people"),
    ("lawyer","弁護士","noun","people"),
    ("coach","コーチ","noun","people"),
    ("journalist","ジャーナリスト","noun","people"),
    ("baker","パン屋","noun","people"),
    ("barber","床屋","noun","people"),
    ("designer","デザイナー","noun","people"),
    ("vet","獣医","noun","people"),
    ("firefighter","消防士","noun","people"),
    ("scientist","科学者","noun","people"),
    ("carpenter","大工","noun","people"),
    ("pharmacist","薬剤師","noun","people"),
    # ── 交通 ─────────────────────────────────────────────────
    ("subway","地下鉄","noun","place"),
    ("helicopter","ヘリコプター","noun","place"),  # may be in eiken2, filtered
    ("motorcycle","バイク","noun","place"),
    ("truck","トラック","noun","place"),
    ("ferry","フェリー","noun","place"),
    # ── 体・健康 ──────────────────────────────────────────────
    ("throat","のど","noun","daily"),
    ("chest","胸","noun","daily"),
    ("shoulder","肩","noun","daily"),
    ("neck","首","noun","daily"),
    ("brain","脳","noun","daily"),
    ("heart","心臓","noun","daily"),
    ("blood","血","noun","daily"),
    ("skin","肌","noun","daily"),
    ("bone","骨","noun","daily"),
    ("muscle","筋肉","noun","daily"),
    ("temperature","体温","noun","daily"),
    ("medicine","薬","noun","daily"),
    ("pain","痛み","noun","daily"),
    ("injury","けが","noun","daily"),
    # ── 家・家具 ──────────────────────────────────────────────
    ("curtain","カーテン","noun","daily"),
    ("mirror","鏡","noun","daily"),
    ("shelf","棚","noun","daily"),
    ("carpet","カーペット","noun","daily"),
    ("bathtub","浴槽","noun","daily"),
    ("refrigerator","冷蔵庫","noun","daily"),
    ("toothbrush","歯ブラシ","noun","daily"),
    ("towel","タオル","noun","daily"),
    ("cushion","クッション","noun","daily"),
    ("blanket","毛布","noun","daily"),
    ("pillow","枕","noun","daily"),
    ("garbage","ゴミ","noun","daily"),
    ("trash","ごみ","noun","daily"),
    # ── 学校 ─────────────────────────────────────────────────
    ("lesson","レッスン","noun","daily"),
    ("grade","成績","noun","daily"),
    ("semester","学期","noun","daily"),
    ("exam","試験","noun","daily"),
    ("textbook","教科書","noun","daily"),
    ("project","プロジェクト","noun","daily"),
    ("schedule","スケジュール","noun","daily"),
    ("course","コース","noun","daily"),
    ("campus","キャンパス","noun","place"),
    ("quiz","クイズ","noun","daily"),
    # ── 仕事 ─────────────────────────────────────────────────
    ("meeting","会議","noun","people"),
    ("office","オフィス","noun","place"),
    ("company","会社","noun","people"),
    ("boss","上司","noun","people"),
    ("salary","給料","noun","general"),
    ("customer","お客さん","noun","people"),
    ("staff","スタッフ","noun","people"),
    ("department","部署","noun","people"),
    ("interview","面接","noun","people"),
    # ── 自然・環境 ────────────────────────────────────────────
    ("earthquake","地震","noun","nature"),
    ("volcano","火山","noun","nature"),
    ("hurricane","ハリケーン","noun","nature"),
    ("tornado","竜巻","noun","nature"),
    ("sand","砂","noun","nature"),
    ("mud","泥","noun","nature"),
    ("cliff","崖","noun","nature"),
    ("cave","洞窟","noun","nature"),
    ("waterfall","滝","noun","nature"),
    ("soil","土","noun","nature"),
    ("coast","海岸","noun","nature"),
    ("horizon","地平線","noun","nature"),
    ("environment","環境","noun","nature"),
    ("pollution","汚染","noun","nature"),
    ("energy","エネルギー","noun","general"),
    # ── 服・アクセサリー ──────────────────────────────────────
    ("tie","ネクタイ","noun","daily"),
    ("scarf","スカーフ","noun","daily"),
    ("vest","ベスト","noun","daily"),
    ("blouse","ブラウス","noun","daily"),
    ("belt","ベルト","noun","daily"),
    ("boots","ブーツ","noun","daily"),
    ("apron","エプロン","noun","daily"),
    # ── スポーツ・レジャー ────────────────────────────────────
    ("volleyball","バレーボール","noun","people"),
    ("golf","ゴルフ","noun","people"),
    ("cycling","サイクリング","noun","people"),
    ("gymnastics","体操","noun","people"),
    ("yoga","ヨガ","noun","people"),
    ("championship","選手権","noun","people"),
    ("tournament","トーナメント","noun","people"),
    # ── 人・社会 ──────────────────────────────────────────────
    ("neighbor","隣人","noun","people"),
    ("stranger","見知らぬ人","noun","people"),
    ("guest","ゲスト","noun","people"),
    ("relative","親戚","noun","people"),
    ("colleague","同僚","noun","people"),
    ("principal","校長","noun","people"),
    ("teenager","ティーンエイジャー","noun","people"),
    ("citizen","市民","noun","people"),
    ("volunteer","ボランティア","noun","people"),
    ("tourist","観光客","noun","people"),
    # ── 抽象名詞・一般 ───────────────────────────────────────
    ("journey","旅","noun","place"),
    ("joy","喜び","noun","mind"),
    ("knowledge","知識","noun","mind"),
    ("leader","リーダー","noun","people"),
    ("level","レベル","noun","general"),
    ("luck","運","noun","general"),
    ("meaning","意味","noun","general"),
    ("mistake","間違い","noun","general"),
    ("moment","瞬間","noun","general"),
    ("mood","気分","noun","mind"),
    ("mystery","謎","noun","general"),
    ("noise","騒音","noun","general"),
    ("peace","平和","noun","mind"),
    ("poem","詩","noun","general"),
    ("possibility","可能性","noun","general"),
    ("power","力","noun","general"),
    ("program","プログラム","noun","general"),
    ("progress","進歩","noun","general"),
    ("reason","理由","noun","general"),
    ("record","記録","noun","general"),
    ("relationship","関係","noun","people"),
    ("responsibility","責任","noun","general"),
    ("reward","報酬","noun","general"),
    ("risk","リスク","noun","general"),
    ("role","役割","noun","people"),
    ("rule","ルール","noun","general"),
    ("safety","安全","noun","general"),
    ("scene","場面","noun","general"),
    ("shape","形","noun","general"),
    ("situation","状況","noun","general"),
    ("skill","スキル","noun","general"),
    ("society","社会","noun","people"),
    ("solution","解決策","noun","general"),
    ("space","宇宙","noun","general"),
    ("speed","速度","noun","general"),
    ("step","ステップ","noun","general"),
    ("success","成功","noun","general"),
    ("suggestion","提案","noun","general"),
    ("symbol","シンボル","noun","general"),
    ("talent","才能","noun","mind"),
    ("target","目標","noun","general"),
    ("task","課題","noun","general"),
    ("thought","考え","noun","mind"),
    ("tradition","伝統","noun","people"),
    ("trust","信頼","noun","mind"),
    ("truth","真実","noun","general"),
    ("value","価値","noun","general"),
    ("view","眺め","noun","place"),
    ("voice","声","noun","general"),
    ("war","戦争","noun","general"),
    ("wealth","富","noun","general"),
    ("youth","若者","noun","people"),
    ("topic","話題","noun","general"),
    ("theme","テーマ","noun","general"),
    ("attitude","態度","noun","mind"),  # may already be in eiken4
    ("behavior","行動","noun","general"),
    ("belief","信念","noun","mind"),
    ("challenge","チャレンジ","noun","general"),
    ("choice","選択","noun","general"),
    ("condition","状態","noun","general"),
    ("connection","つながり","noun","general"),
    ("control","管理","noun","general"),
    ("conversation","会話","noun","people"),
    ("custom","習慣","noun","people"),
    ("damage","ダメージ","noun","general"),
    ("danger","危険","noun","general"),
    ("decision","決断","noun","general"),
    ("difference","違い","noun","general"),
    ("difficulty","困難","noun","general"),
    ("direction","方向","noun","place"),
    ("discovery","発見","noun","general"),
    ("disease","病気","noun","daily"),
    ("distance","距離","noun","general"),
    ("emotion","感情","noun","mind"),
    ("event","イベント","noun","general"),
    ("example","例","noun","general"),
    ("experience","経験","noun","general"),
    ("failure","失敗","noun","general"),
    ("freedom","自由","noun","mind"),
    ("friendship","友情","noun","people"),
    ("growth","成長","noun","general"),
    ("habit","習慣","noun","daily"),
    ("happiness","幸福","noun","mind"),
    ("health","健康","noun","daily"),
    ("invitation","招待","noun","people"),
    ("law","法律","noun","general"),
    ("opportunity","機会","noun","general"),
    ("opinion","意見","noun","mind"),
    ("problem","問題","noun","general"),  # may be in eiken5
    ("result","結果","noun","general"),
    ("tradition","伝統","noun","people"),  # dup
    ("trouble","トラブル","noun","general"),
    ("victory","勝利","noun","people"),
    ("weight","重さ","noun","general"),
    # ── 場所・建物 ────────────────────────────────────────────
    ("factory","工場","noun","place"),
    ("bank","銀行","noun","place"),
    ("bakery","パン屋","noun","place"),
    ("bookstore","本屋","noun","place"),
    ("pharmacy","薬局","noun","place"),
    ("apartment","アパート","noun","place"),
    ("harbor","港","noun","place"),
    ("castle","城","noun","place"),
    ("palace","宮殿","noun","place"),
    ("cemetery","墓地","noun","place"),
    ("skyscraper","超高層ビル","noun","place"),
    ("neighborhood","近所","noun","place"),
    # ── 乗り物・交通 ──────────────────────────────────────────
    ("highway","高速道路","noun","place"),
    ("crossing","横断歩道","noun","place"),
    ("traffic","交通","noun","place"),
    ("parking","駐車場","noun","place"),
    # ── 学校教科・追加 ────────────────────────────────────────
    ("geography","地理","noun","daily"),
    ("biology","生物","noun","daily"),
    ("chemistry","化学","noun","daily"),
    ("literature","文学","noun","general"),
    ("physical education","体育","noun","daily"),
    # ── メディア・エンタメ ────────────────────────────────────
    ("channel","チャンネル","noun","general"),
    ("episode","エピソード","noun","general"),
    ("review","レビュー","noun","general"),
    ("interview","インタビュー","noun","people"),  # dup
    ("headline","見出し","noun","general"),
    ("advertisement","広告","noun","general"),  # may be in eiken4
    ("commercial","コマーシャル","noun","general"),
    # ── お金・買い物 ──────────────────────────────────────────
    ("bill","お札","noun","general"),
    ("tax","税金","noun","general"),
    ("receipt","領収書","noun","general"),
    ("discount","割引","noun","general"),
    ("budget","予算","noun","general"),
    ("debt","借金","noun","general"),
    # ── その他日常 ────────────────────────────────────────────
    ("address","住所","noun","daily"),
    ("envelope","封筒","noun","daily"),
    ("package","小包","noun","daily"),
    ("furniture","家具","noun","daily"),
    ("electricity","電気","noun","daily"),
    ("password","パスワード","noun","general"),
    ("screen","スクリーン","noun","general"),
    ("website","ウェブサイト","noun","general"),
    ("application","アプリ","noun","general"),
    ("username","ユーザー名","noun","general"),
]


def main():
    out = "tools/draft_eiken4_additional.csv"

    # ── 既存語を読み込み ─────────────────────────────────────
    with open("assets/quiz/words.csv", newline="", encoding="utf-8") as f:
        rows = list(csv.DictReader(f))

    eiken5_words  = {r["en"].lower() for r in rows if r["level"] == "eiken5"}
    eiken4_kept   = [r for r in rows if r["level"] == "eiken4"
                     and r["en"].lower() not in eiken5_words]
    eiken4_words  = {r["en"].lower() for r in eiken4_kept}

    target = 600
    need   = target - len(eiken4_kept)
    print(f"重複削除後 eiken4: {len(eiken4_kept)}語")
    print(f"追加必要数: {need}語")

    # ── 候補をフィルタ ───────────────────────────────────────
    seen_candidates: set[str] = set()
    selected = []
    skipped_dup = []

    for en, ja, pos, theme in CANDIDATES:
        key = en.lower()
        if key in seen_candidates:
            continue
        seen_candidates.add(key)

        if key in eiken5_words:
            skipped_dup.append(f"eiken5重複: {en}")
            continue
        if key in eiken4_words:
            skipped_dup.append(f"eiken4既存: {en}")
            continue
        # 複合語（スペース含む）をスキップ
        if " " in en:
            skipped_dup.append(f"複合語スキップ: {en}")
            continue

        selected.append({"en": en, "ja": ja, "pos": pos, "theme": theme,
                         "level": "eiken4"})
        if len(selected) >= need:
            break

    print(f"候補から選出: {len(selected)}語")
    if len(selected) < need:
        print(f"⚠ 候補不足: {need - len(selected)}語 足りません")

    # ── 下書き CSV 出力 ──────────────────────────────────────
    with open(out, "w", newline="", encoding="utf-8") as f:
        w = csv.DictWriter(f, fieldnames=["id","en","ja","pos","theme","level","notes"])
        w.writeheader()
        for i, row in enumerate(selected, 1):
            w.writerow({**row, "id": i, "notes": ""})

    # ── サマリー ─────────────────────────────────────────────
    by_pos = {}
    for r in selected:
        by_pos[r["pos"]] = by_pos.get(r["pos"], 0) + 1
    print(f"\n✅ 下書き生成: {len(selected)}語 → {out}")
    print(f"   品詞内訳: {dict(sorted(by_pos.items()))}")
    print(f"\n   eiken4既存(重複削除後): {len(eiken4_kept)}語")
    print(f"   追加後の合計: {len(eiken4_kept) + len(selected)}語")


if __name__ == "__main__":
    main()

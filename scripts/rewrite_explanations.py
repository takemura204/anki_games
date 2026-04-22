#!/usr/bin/env python3
"""
IT パスポート過去問 JSON の explanation.text と explanation.choice_comments を
OpenAI API で書き換えます。
処理済みの問題はスキップするため、途中で中断しても再開できます。

使い方:
  # 1ファイルのみ試す（動作確認用）
  python3 scripts/rewrite_explanations.py --file it_pass_r07.json

  # 全ファイル処理
  python3 scripts/rewrite_explanations.py --all

  # APIキーを直接指定
  python3 scripts/rewrite_explanations.py --all --api-key sk-...

  # 処理済みマーカーを全ファイルから除去（完了後のクリーンアップ）
  python3 scripts/rewrite_explanations.py --clean
"""

import json
import os
import time
import argparse
from pathlib import Path
from openai import OpenAI

ASSETS_DIR = Path(__file__).parent.parent / "packages" / "app_it_pass" / "assets" / "quiz"
PROGRESS_KEY = "_rewritten"          # text + choice_comments 両方完了
LEGACY_KEY = "_explanation_rewritten"  # 旧スクリプトで text のみ完了済み
DEFAULT_MODEL = "gpt-4o-mini"

SYSTEM_PROMPT = (
    "あなたはITパスポート試験の解説文を書き直すアシスタントです。\n"
    "以下のルールに従って書き直してください：\n"
    "- 技術的な内容・意味・結論は一切変えない\n"
    "- 専門用語・固有名詞・アルファベットの略語はそのまま使用する\n"
    "- 文の構造・語順・言い回しを変える（同義語の使用、文の分割・統合など）\n"
    "- 自然な日本語を維持する\n"
    "- 指定された JSON 形式のみを出力する（余計な説明は不要）"
)


def rewrite_question_explanation(
    client: OpenAI,
    text: str,
    choice_comments: list[str],
    model: str,
) -> tuple[str, list[str]]:
    """
    text と choice_comments を1回の API 呼び出しでまとめて書き換える。
    トークン節約のため両方を JSON で一括送信し、JSON で受け取る。
    """
    has_text = bool(text and text.strip())
    has_comments = bool(choice_comments)

    if not has_text and not has_comments:
        return text, choice_comments

    payload: dict = {}
    if has_text:
        payload["text"] = text
    if has_comments:
        payload["choice_comments"] = choice_comments

    user_message = (
        "以下の解説を書き直してください。\n"
        "入力と同じキーを持つ JSON のみを出力してください（```json ブロックは不要）:\n\n"
        + json.dumps(payload, ensure_ascii=False)
    )

    response = client.chat.completions.create(
        model=model,
        messages=[
            {"role": "system", "content": SYSTEM_PROMPT},
            {"role": "user", "content": user_message},
        ],
        temperature=0.7,
        max_tokens=3000,
        response_format={"type": "json_object"},
    )

    raw = response.choices[0].message.content.strip()
    result = json.loads(raw)

    new_text = result.get("text", text) if has_text else text
    new_comments = result.get("choice_comments", choice_comments) if has_comments else choice_comments

    return new_text, new_comments


def process_file(client: OpenAI, file_path: Path, model: str, dry_run: bool = False):
    """1つの JSON ファイルを処理する。"""
    print(f"\n📄 {file_path.name}")

    with open(file_path, encoding="utf-8") as f:
        data = json.load(f)

    questions = data.get("questions", [])
    total = len(questions)
    processed = 0
    skipped = 0

    for i, q in enumerate(questions):
        no = q.get("no", i + 1)
        exp = q.get("explanation", {})
        text = exp.get("text", "")
        choice_comments = exp.get("choice_comments", [])

        # 新マーカーがあれば完全処理済み → スキップ
        if exp.get(PROGRESS_KEY):
            skipped += 1
            continue

        # 旧マーカー(text のみ完了)がある場合は choice_comments だけ処理
        text_already_done = bool(exp.get(LEGACY_KEY))

        # text も choice_comments も空なら処理不要
        if (text_already_done or not text.strip()) and not choice_comments:
            exp[PROGRESS_KEY] = True
            skipped += 1
            continue

        has_comments = bool(choice_comments)

        if text_already_done:
            label = f"comments のみ ({len(choice_comments)}件)"
        elif has_comments:
            label = f"text + {len(choice_comments)}件のコメント"
        else:
            label = "text のみ"

        print(f"  [{i+1:3}/{total}] Q{no:3} ({label}) 書き換え中...", end=" ", flush=True)

        if dry_run:
            print("(dry-run)")
            continue

        try:
            # text が既に書き換え済みの場合は空文字を渡して choice_comments だけ処理
            rewrite_text = "" if text_already_done else text
            new_text, new_comments = rewrite_question_explanation(
                client, rewrite_text, choice_comments, model
            )
            if not text_already_done:
                exp["text"] = new_text
            if has_comments:
                exp["choice_comments"] = new_comments
            exp[PROGRESS_KEY] = True
            processed += 1
            print("✓")

            # 1問ごとに保存（途中再開のため）
            with open(file_path, "w", encoding="utf-8") as f:
                json.dump(data, f, ensure_ascii=False, indent=2)

            time.sleep(0.3)  # レートリミット対策

        except Exception as e:
            print(f"✗ エラー: {e}")
            time.sleep(10)

    print(f"  → 書き換え {processed}件 / スキップ {skipped}件 / 合計 {total}件")


def clean_progress_markers(files: list[Path]):
    """処理済みマーカー(_explanation_rewritten)を全ファイルから除去する。"""
    print("🧹 処理済みマーカーを除去します...")
    for file_path in files:
        with open(file_path, encoding="utf-8") as f:
            data = json.load(f)

        modified = False
        for q in data.get("questions", []):
            exp = q.get("explanation", {})
            for key in (PROGRESS_KEY, LEGACY_KEY):
                if key in exp:
                    del exp[key]
                    modified = True

        if modified:
            with open(file_path, "w", encoding="utf-8") as f:
                json.dump(data, f, ensure_ascii=False, indent=2)
            print(f"  ✓ {file_path.name}")

    print("完了")


def main():
    parser = argparse.ArgumentParser(
        description="IT パスポート過去問の解説文を OpenAI API で書き換えます"
    )
    parser.add_argument("--api-key", help="OpenAI API キー（未指定時は OPENAI_API_KEY 環境変数を参照）")
    parser.add_argument("--model", default=DEFAULT_MODEL, help=f"使用するモデル（デフォルト: {DEFAULT_MODEL}）")
    parser.add_argument("--all", action="store_true", help="全ファイルを処理")
    parser.add_argument("--file", help="特定のファイル名（例: it_pass_r07.json）")
    parser.add_argument("--dry-run", action="store_true", help="API を呼ばずに動作確認")
    parser.add_argument("--clean", action="store_true", help="処理済みマーカーを全ファイルから除去")
    args = parser.parse_args()

    all_files = sorted(
        f for f in ASSETS_DIR.glob("it_pass_*.json") if "sample" not in f.name
    )

    if not all_files:
        print(f"エラー: JSON ファイルが見つかりません: {ASSETS_DIR}")
        return

    # クリーンアップモード
    if args.clean:
        clean_progress_markers(all_files)
        return

    # API キーの確認
    api_key = args.api_key or os.environ.get("OPENAI_API_KEY")
    if not api_key and not args.dry_run:
        print("エラー: OpenAI API キーが必要です。")
        print("  --api-key sk-... で指定するか、OPENAI_API_KEY 環境変数に設定してください。")
        return

    client = OpenAI(api_key=api_key) if api_key else None

    if args.file:
        file_path = ASSETS_DIR / args.file
        if not file_path.exists():
            print(f"ファイルが見つかりません: {file_path}")
            return
        process_file(client, file_path, model=args.model, dry_run=args.dry_run)

    elif args.all:
        print(f"対象ファイル: {len(all_files)} 件（sample ファイルを除く）")
        for file_path in all_files:
            process_file(client, file_path, model=args.model, dry_run=args.dry_run)
        print("\n✅ 全ファイルの処理が完了しました。")
        print("   処理済みマーカーを除去するには: python3 scripts/rewrite_explanations.py --clean")

    else:
        parser.print_help()


if __name__ == "__main__":
    main()

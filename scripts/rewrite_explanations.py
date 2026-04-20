#!/usr/bin/env python3
"""
IT パスポート過去問 JSON の explanation.text を OpenAI API で書き換えます。
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

ASSETS_DIR = Path(__file__).parent.parent / "assets" / "quiz" / "it_pass"
PROGRESS_KEY = "_explanation_rewritten"
DEFAULT_MODEL = "gpt-4o"

SYSTEM_PROMPT = (
    "あなたはITパスポート試験の解説文を書き直すアシスタントです。\n"
    "以下のルールに従って解説文を書き直してください：\n"
    "- 技術的な内容・意味・結論は一切変えない\n"
    "- 専門用語・固有名詞・アルファベットの略語はそのまま使用する\n"
    "- 文の構造・語順・言い回しを変える（同義語の使用、文の分割・統合など）\n"
    "- 自然な日本語を維持する\n"
    "- 書き直した文章のみを出力する（前置きや説明は不要）"
)


def rewrite_explanation(client: OpenAI, text: str, model: str) -> str:
    """OpenAI API で解説文を書き換えて返す。"""
    if not text or not text.strip():
        return text

    response = client.chat.completions.create(
        model=model,
        messages=[
            {"role": "system", "content": SYSTEM_PROMPT},
            {"role": "user", "content": f"以下の解説文を書き直してください:\n\n{text}"},
        ],
        temperature=0.7,
        max_tokens=2048,
    )
    return response.choices[0].message.content.strip()


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

        # 既に処理済みはスキップ
        if exp.get(PROGRESS_KEY):
            skipped += 1
            continue

        # 空の解説もスキップ
        if not text.strip():
            exp[PROGRESS_KEY] = True
            skipped += 1
            continue

        print(f"  [{i+1:3}/{total}] Q{no:3} 書き換え中...", end=" ", flush=True)

        if dry_run:
            print("(dry-run)")
            continue

        try:
            new_text = rewrite_explanation(client, text, model)
            exp["text"] = new_text
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
            if PROGRESS_KEY in exp:
                del exp[PROGRESS_KEY]
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

#!/usr/bin/env python3
"""
Cursor stop hook: Agent 完了後に flutter analyze を実行し、
エラーがあれば Agent に自己修正を依頼する。

最大 MAX_ITERATIONS 回まで繰り返す（無限ループ防止）。
"""

import json
import subprocess
import sys

FLUTTER = "/Users/takemurataiki/.local/share/mise/installs/flutter/latest/bin/flutter"
MAX_ITERATIONS = 3
PROJECT_DIR = "/Users/takemurataiki/Development/anki_games"


def main() -> None:
    try:
        data = json.loads(sys.stdin.read())
    except (json.JSONDecodeError, ValueError):
        print(json.dumps({}))
        return

    status = data.get("status", "")
    loop_count = int(data.get("loop_count", 0))

    # Agent がエラー・中断した場合、または上限に達した場合は終了
    if status != "completed" or loop_count >= MAX_ITERATIONS:
        print(json.dumps({}))
        return

    result = subprocess.run(
        [FLUTTER, "analyze"],
        capture_output=True,
        text=True,
        cwd=PROJECT_DIR,
    )

    output = (result.stdout + result.stderr).strip()

    # error レベルの行だけ抽出（info / warning は無視）
    error_lines = [
        line for line in output.splitlines()
        if "   error •" in line or line.strip().startswith("error •")
    ]

    if not error_lines:
        print(json.dumps({}))
        return

    error_summary = "\n".join(error_lines)
    followup = (
        f"flutter analyze で error が見つかりました（自動チェック）。"
        f"以下のエラーを修正してください。修正後は再度 flutter analyze を実行して確認してください。\n\n"
        f"```\n{error_summary}\n```"
    )
    print(json.dumps({"followup_message": followup}))


if __name__ == "__main__":
    main()

"""ITパスポート過去問 JSON の images URL を Firebase Cloud Storage に移行するスクリプト。

## 処理の流れ
1. it_pass_<era_id>.json を読み込み、全 images URL を収集する
2. 各画像を元 URL からダウンロードし Firebase Cloud Storage にアップロード
3. JSON の images 配列の URL を Cloud Storage の公開 URL に置き換えて上書き保存

## ストレージパス形式
  it_pass/<slug>/q<no>/<filename>
  例: it_pass/01_sample/q2/02.png

## 使い方

# サービスアカウントキーを用意してから実行
python3 scripts/upload_it_pass_images.py \\
    --key-file path/to/service_account.json \\
    --file assets/quiz/it_pass/it_pass_sample1.json

# --all で全ファイルを一括処理（既存はスキップ）
python3 scripts/upload_it_pass_images.py \\
    --key-file path/to/service_account.json \\
    --all

# 強制上書き
python3 scripts/upload_it_pass_images.py \\
    --key-file path/to/service_account.json \\
    --all --overwrite

## サービスアカウントキーの取得方法
1. Firebase Console → プロジェクト設定 → サービスアカウント タブ
2. 「新しい秘密鍵の生成」をクリック → JSON をダウンロード
3. --key-file にそのパスを渡す

依存: firebase-admin (pip install firebase-admin)
"""

from __future__ import annotations

import argparse
import json
import mimetypes
import sys
import time
import urllib.parse
from concurrent.futures import ThreadPoolExecutor, as_completed
from pathlib import Path
from typing import Optional

import requests as req_lib

try:
    import firebase_admin
    from firebase_admin import credentials, storage
except ImportError:
    print("ERROR: firebase-admin が未インストールです。", file=sys.stderr)
    print("  pip3 install firebase-admin", file=sys.stderr)
    raise SystemExit(1)

BUCKET = "anki-quiz-dev.firebasestorage.app"
STORAGE_PREFIX = "it_pass"
DOWNLOAD_TIMEOUT = 20
UPLOAD_RETRIES = 3


# ------------------------------------------------------------------
# Firebase 初期化
# ------------------------------------------------------------------

def init_firebase(key_file: str) -> None:
    if not firebase_admin._apps:
        cred = credentials.Certificate(key_file)
        firebase_admin.initialize_app(cred, {"storageBucket": BUCKET})


# ------------------------------------------------------------------
# 公開 URL 生成
# ------------------------------------------------------------------

def public_url(blob) -> str:
    """Blob を公開設定にして公開 URL を返す。"""
    blob.make_public()
    return blob.public_url


# ------------------------------------------------------------------
# 1枚の画像を処理（ダウンロード → アップロード）
# ------------------------------------------------------------------

def _storage_path(slug: str, question_no: int, image_url: str) -> str:
    filename = image_url.split("/")[-1]
    return f"{STORAGE_PREFIX}/{slug}/q{question_no}/{filename}"


def process_image(
    original_url: str,
    slug: str,
    question_no: int,
    bucket_handle,
    overwrite: bool,
    session: req_lib.Session,
) -> Optional[str]:
    """
    original_url → Cloud Storage にアップロードし、公開 URL を返す。
    skip 判定や失敗時は None を返す。
    """
    path = _storage_path(slug, question_no, original_url)
    blob = bucket_handle.blob(path)

    if not overwrite and blob.exists():
        return public_url(blob)

    content_type = mimetypes.guess_type(original_url)[0] or "image/png"

    for attempt in range(1, UPLOAD_RETRIES + 1):
        try:
            resp = session.get(original_url, timeout=DOWNLOAD_TIMEOUT)
            resp.raise_for_status()
            blob.upload_from_string(resp.content, content_type=content_type)
            return public_url(blob)
        except Exception as e:
            if attempt >= UPLOAD_RETRIES:
                print(f"  WARN: upload failed ({original_url}): {e}", file=sys.stderr)
                return None
            time.sleep(attempt)
    return None


# ------------------------------------------------------------------
# JSON ファイル 1 件の処理
# ------------------------------------------------------------------

def process_json_file(
    json_path: Path,
    bucket_handle,
    overwrite: bool,
    workers: int,
) -> dict:
    """JSON の全 images を Cloud Storage に移行し、ファイルを上書きする。"""

    data = json.load(open(json_path, encoding="utf-8"))
    slug = data.get("slug", json_path.stem)

    # (original_url, question_no, field_type, choice_index_or_None) のタスクリストを構築
    tasks: list[tuple[str, int]] = []
    for q in data["questions"]:
        no = q["no"]
        for url in q["body"].get("images", []):
            tasks.append((url, no))
        for c in q.get("choices", []):
            for url in c.get("images", []):
                tasks.append((url, no))
        for url in q["explanation"].get("images", []):
            tasks.append((url, no))

    unique_tasks = list(dict.fromkeys(tasks))
    print(f"  {json_path.name}: {len(unique_tasks)} unique images to process")

    if not unique_tasks:
        print(f"  {json_path.name}: no images, skip")
        return {"file": str(json_path), "processed": 0, "failed": 0}

    session = req_lib.Session()
    session.headers.update({"User-Agent": "Mozilla/5.0 (ankigames dev)"})

    url_map: dict[str, str | None] = {}

    with ThreadPoolExecutor(max_workers=workers) as pool:
        future_map = {
            pool.submit(process_image, url, slug, no, bucket_handle, overwrite, session): url
            for url, no in unique_tasks
        }
        done = 0
        for fut in as_completed(future_map):
            orig = future_map[fut]
            try:
                result = fut.result()
            except Exception as e:
                result = None
                print(f"  WARN: exception for {orig}: {e}", file=sys.stderr)
            url_map[orig] = result
            done += 1
            if done % 10 == 0 or done == len(unique_tasks):
                print(f"  {json_path.name}: {done}/{len(unique_tasks)} done")

    # JSON の images を置き換え
    for q in data["questions"]:
        q["body"]["images"] = [
            url_map.get(u, u) or u for u in q["body"].get("images", [])
        ]
        for c in q.get("choices", []):
            c["images"] = [
                url_map.get(u, u) or u for u in c.get("images", [])
            ]
        q["explanation"]["images"] = [
            url_map.get(u, u) or u for u in q["explanation"].get("images", [])
        ]

    # 上書き保存
    json_path.write_text(
        json.dumps(data, ensure_ascii=False, indent=2) + "\n",
        encoding="utf-8",
    )

    failed = sum(1 for v in url_map.values() if v is None)
    print(f"  {json_path.name}: saved (failed={failed})")
    return {"file": str(json_path), "processed": len(unique_tasks) - failed, "failed": failed}


# ------------------------------------------------------------------
# エントリポイント
# ------------------------------------------------------------------

def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument(
        "--key-file",
        required=True,
        help="Firebase サービスアカウントキー JSON のパス",
    )
    parser.add_argument(
        "--file",
        help="処理する JSON ファイルのパス（単一ファイルモード）",
    )
    parser.add_argument(
        "--all",
        dest="all_files",
        action="store_true",
        help="assets/quiz/it_pass/ 内の全 it_pass_*.json を処理",
    )
    parser.add_argument(
        "--input-dir",
        default="assets/quiz/it_pass",
        help="--all 時の入力ディレクトリ（リポジトリルート相対）",
    )
    parser.add_argument(
        "--overwrite",
        action="store_true",
        help="Cloud Storage に同名ファイルが存在しても上書き",
    )
    parser.add_argument(
        "--workers",
        type=int,
        default=8,
        help="並列アップロード数（デフォルト: 8）",
    )
    args = parser.parse_args()

    key_path = Path(args.key_file).expanduser()
    if not key_path.exists():
        print(f"ERROR: key-file not found: {key_path}", file=sys.stderr)
        return 1

    init_firebase(str(key_path))
    bucket_handle = storage.bucket()

    repo_root = Path(__file__).resolve().parent.parent

    if args.all_files:
        in_dir = Path(args.input_dir)
        if not in_dir.is_absolute():
            in_dir = repo_root / in_dir
        files = sorted(in_dir.glob("it_pass_*.json"))
        if not files:
            print(f"ERROR: no files found in {in_dir}", file=sys.stderr)
            return 1
        print(f"Processing {len(files)} files …")
    elif args.file:
        p = Path(args.file)
        if not p.is_absolute():
            p = repo_root / p
        files = [p]
    else:
        parser.error("--file か --all のいずれかを指定してください")

    total_processed = 0
    total_failed = 0
    for i, f in enumerate(files, start=1):
        print(f"\n[{i}/{len(files)}] {f.name}")
        result = process_json_file(f, bucket_handle, args.overwrite, args.workers)
        total_processed += result["processed"]
        total_failed += result["failed"]

    print(f"\n=== 完了: uploaded={total_processed}, failed={total_failed} ===")
    return 0 if total_failed == 0 else 2


if __name__ == "__main__":
    raise SystemExit(main())

"""ITパスポート試験ドットコムの過去問ページをスクレイピングして JSON に保存する。

- 取得元: https://www.itpassportsiken.com/kakomon/<YEAR_SLUG>/qN.html
- 出力先: assets/quiz/it_pass.json（デフォルト）
- 礼儀としてリクエスト間に 1 秒のウェイトを入れる。

使い方::

    python3 scripts/fetch_it_pass_kakomon.py --exam 07_haru --label "令和7年" --count 100

依存: requests, beautifulsoup4
"""

from __future__ import annotations

import argparse
import json
import re
import sys
import time
from dataclasses import asdict, dataclass, field
from datetime import datetime, timezone
from pathlib import Path
from typing import Iterable
from urllib.parse import urljoin

import requests
from bs4 import BeautifulSoup, NavigableString, Tag

USER_AGENT = (
    "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) "
    "AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120 Safari/537.36 "
    "(anki_games/it_pass scraper; contact: local)"
)

BASE = "https://www.itpassportsiken.com/kakomon/"

# 取得対象の試験一覧。
# (url_slug, 表示ラベル, 和暦ベースのファイル ID)
# - R3〜R7 は試験実施が年間通年化したためラベルに季節がなく、スラグは _haru 固定
# - 令和/平成で era prefix を r / h にし、春秋両方ある年度のみ _haru/_aki を保持
EXAMS: list[tuple[str, str, str]] = [
    ("07_haru", "令和7年", "r07"),
    ("06_haru", "令和6年", "r06"),
    ("05_haru", "令和5年", "r05"),
    ("04_haru", "令和4年", "r04"),
    ("03_haru", "令和3年", "r03"),
    ("02_aki", "令和2年秋期", "r02_aki"),
    ("01_aki", "令和元年秋期", "r01_aki"),
    ("31_haru", "平成31年春期", "h31_haru"),
    ("30_aki", "平成30年秋期", "h30_aki"),
    ("30_haru", "平成30年春期", "h30_haru"),
    ("29_aki", "平成29年秋期", "h29_aki"),
    ("29_haru", "平成29年春期", "h29_haru"),
    ("28_aki", "平成28年秋期", "h28_aki"),
    ("28_haru", "平成28年春期", "h28_haru"),
    ("27_aki", "平成27年秋期", "h27_aki"),
    ("27_haru", "平成27年春期", "h27_haru"),
    ("26_aki", "平成26年秋期", "h26_aki"),
    ("26_haru", "平成26年春期", "h26_haru"),
    ("25_aki", "平成25年秋期", "h25_aki"),
    ("25_haru", "平成25年春期", "h25_haru"),
    ("24_aki", "平成24年秋期", "h24_aki"),
    ("24_haru", "平成24年春期", "h24_haru"),
    ("23_aki", "平成23年秋期", "h23_aki"),
    ("23_toku", "平成23年特別", "h23_toku"),
    ("22_aki", "平成22年秋期", "h22_aki"),
    ("22_haru", "平成22年春期", "h22_haru"),
    ("21_aki", "平成21年秋期", "h21_aki"),
    ("21_haru", "平成21年春期", "h21_haru"),
    ("01_sample", "サンプル問題１", "sample1"),
    ("02_sample", "サンプル問題２", "sample2"),
]


@dataclass
class Category:
    raw: str
    system: str = ""
    major: str = ""
    minor: str = ""


@dataclass
class QuestionBody:
    text: str
    sub_items: list[str] = field(default_factory=list)
    images: list[str] = field(default_factory=list)


@dataclass
class Choice:
    label: str
    text: str
    images: list[str] = field(default_factory=list)


@dataclass
class Explanation:
    text: str
    choice_comments: list[str] = field(default_factory=list)
    images: list[str] = field(default_factory=list)


@dataclass
class Question:
    no: int
    url: str
    title: str
    body: QuestionBody
    choices: list[Choice]
    category: Category
    answer: str
    explanation: Explanation


def _extract_images(node: Tag, page_url: str) -> list[str]:
    urls: list[str] = []
    for img in node.find_all("img"):
        src = img.get("src")
        if not src:
            continue
        urls.append(urljoin(page_url, src))
    return urls


def _text_with_breaks(node: Tag, skip_alpha_ol: bool = True) -> str:
    """`<br>` を改行として保持しつつテキストを抽出する。

    ``skip_alpha_ol=True`` のとき `<ol type="a">`（選択肢や小問 a/b/c 等）は
    除外する。それ以外の ``<ol>`` / ``<ul>`` はインラインの番号付きテキストとして
    残す（トレース、手順、箇条書きなど）。
    """

    parts: list[str] = []

    def walk(n) -> None:
        if isinstance(n, NavigableString):
            parts.append(str(n))
            return
        if not isinstance(n, Tag):
            return
        if n.name == "br":
            parts.append("\n")
            return
        if n.name in ("script", "style"):
            return
        if n.name == "ol" and (n.get("type") or "").lower() == "a" and skip_alpha_ol:
            return
        if n.name in ("ol", "ul"):
            parts.append("\n")
            is_ordered = n.name == "ol"
            for idx, li in enumerate(n.find_all("li", recursive=False), start=1):
                marker = f"{idx}. " if is_ordered else "・"
                parts.append(marker)
                for c in li.children:
                    walk(c)
                parts.append("\n")
            parts.append("\n")
            return
        for child in n.children:
            walk(child)

    for child in node.children:
        walk(child)
    text = "".join(parts)
    text = re.sub(r"[ \t\u3000]+\n", "\n", text)
    text = re.sub(r"\n{3,}", "\n\n", text)
    return text.strip()


def _parse_category(div: Tag) -> Category:
    raw = div.get_text(" ", strip=True)
    parts = [p.strip() for p in re.split(r"»|\u00bb", raw) if p.strip()]
    cat = Category(raw=raw)
    if parts:
        cat.system = parts[0]
    if len(parts) > 1:
        cat.major = parts[1]
    if len(parts) > 2:
        cat.minor = parts[2]
    return cat


def _extract_title(soup: BeautifulSoup, no: int) -> str:
    og = soup.find("meta", attrs={"property": "og:title"})
    raw = og.get("content") if og else (soup.title.get_text() if soup.title else "")
    m = re.search(rf"問{no}\s*(.+?)[｜|\|]", raw)
    if m:
        return m.group(1).strip()
    m = re.search(rf"問{no}\s*(.+)$", raw or "")
    return m.group(1).strip() if m else ""


def _sibling_div_after(h3: Tag) -> Tag | None:
    sib = h3
    while True:
        sib = sib.next_sibling
        if sib is None:
            return None
        if isinstance(sib, Tag) and sib.name == "div":
            return sib


def parse_question(html: str, page_url: str, no: int) -> Question:
    soup = BeautifulSoup(html, "html.parser")
    main = soup.select_one(".kako") or soup

    qno = main.select_one("h3.qno")
    if qno is None:
        raise RuntimeError(f"qno not found for {page_url}")

    q_body_div = _sibling_div_after(qno)
    if q_body_div is None:
        raise RuntimeError(f"question body not found for {page_url}")

    body_text = _text_with_breaks(q_body_div, skip_alpha_ol=True)
    body_alpha_ol = q_body_div.find("ol", attrs={"type": "a"})
    sub_items = (
        [li.get_text(" ", strip=True) for li in body_alpha_ol.find_all("li", recursive=False)]
        if body_alpha_ol
        else []
    )
    body_images = _extract_images(q_body_div, page_url)

    ul = main.select_one("ul.selectList")
    choices: list[Choice] = []
    if ul:
        lis = ul.find_all("li", recursive=False)
        if len(lis) == 1 and len(lis[0].find_all("button")) >= 2:
            li = lis[0]
            shared_imgs = _extract_images(li, page_url)
            for btn in li.find_all("button"):
                label = btn.get_text(" ", strip=True)
                choices.append(Choice(label=label, text="", images=list(shared_imgs)))
        else:
            for li in lis:
                btn = li.find("button")
                span = li.find("span")
                if btn and span:
                    label = btn.get_text(" ", strip=True)
                    text = span.get_text(" ", strip=True)
                else:
                    full = li.get_text(" ", strip=True)
                    m = re.match(r"^([ア-ンA-Za-z])[\s\.．、]*(.*)$", full)
                    label = m.group(1) if m else ""
                    text = m.group(2).strip() if m else full
                choices.append(
                    Choice(label=label, text=text, images=_extract_images(li, page_url))
                )

    category = Category(raw="")
    answer = ""
    explanation_div: Tag | None = None
    for h3 in main.find_all("h3"):
        label = h3.get_text(strip=True)
        if label.startswith("分類"):
            d = _sibling_div_after(h3)
            if d:
                category = _parse_category(d)
        elif label.startswith("正解"):
            d = _sibling_div_after(h3)
            if d:
                span = d.find("span")
                answer = (span.get_text(strip=True) if span else d.get_text(" ", strip=True)).strip()
                answer = re.sub(r"正解を表示する", "", answer).strip()
        elif label.startswith("解説"):
            explanation_div = _sibling_div_after(h3)

    exp_text = ""
    choice_comments: list[str] = []
    exp_images: list[str] = []
    if explanation_div is not None:
        exp_text = _text_with_breaks(explanation_div, skip_alpha_ol=True)
        alpha_ol = explanation_div.find("ol", attrs={"type": "a"})
        if alpha_ol:
            choice_comments = [
                li.get_text(" ", strip=True) for li in alpha_ol.find_all("li", recursive=False)
            ]
        exp_images = _extract_images(explanation_div, page_url)

    title = _extract_title(soup, no)

    return Question(
        no=no,
        url=page_url,
        title=title,
        body=QuestionBody(text=body_text, sub_items=sub_items, images=body_images),
        choices=choices,
        category=category,
        answer=answer,
        explanation=Explanation(
            text=exp_text, choice_comments=choice_comments, images=exp_images
        ),
    )


def fetch(session: requests.Session, url: str, retries: int = 3, delay: float = 1.0) -> str:
    last_exc: Exception | None = None
    for attempt in range(1, retries + 1):
        try:
            resp = session.get(url, timeout=20)
            resp.encoding = resp.apparent_encoding or "utf-8"
            if resp.status_code == 200:
                return resp.text
            raise RuntimeError(f"status={resp.status_code}")
        except Exception as e:
            last_exc = e
            if attempt < retries:
                time.sleep(delay * attempt)
    raise RuntimeError(f"failed to fetch {url}: {last_exc}")


def iter_questions(
    session: requests.Session, exam_slug: str, count: int, wait: float
) -> Iterable[Question]:
    for n in range(1, count + 1):
        url = f"{BASE}{exam_slug}/q{n}.html"
        print(f"  [{n}/{count}] GET {url}", file=sys.stderr)
        html = fetch(session, url)
        yield parse_question(html, url, n)
        if n < count:
            time.sleep(wait)


def discover_question_count(session: requests.Session, exam_slug: str) -> int:
    """試験インデックスページから q*.html のリンクを数えて問題数を推定する。"""

    index_url = f"{BASE}{exam_slug}/"
    html = fetch(session, index_url)
    numbers = {int(m) for m in re.findall(r"q(\d+)\.html", html)}
    if not numbers:
        raise RuntimeError(f"no questions found at {index_url}")
    return max(numbers)


def save_exam(
    session: requests.Session,
    exam_slug: str,
    label: str,
    era_id: str,
    count: int,
    wait: float,
    out_dir: Path,
) -> Path:
    questions = list(iter_questions(session, exam_slug, count, wait))
    payload = {
        "exam": label,
        "era_id": era_id,
        "slug": exam_slug,
        "source_url": f"{BASE}{exam_slug}/",
        "fetched_at": datetime.now(timezone.utc).isoformat(timespec="seconds"),
        "count": len(questions),
        "questions": [asdict(q) for q in questions],
    }
    out_path = out_dir / f"it_pass_{era_id}.json"
    out_path.parent.mkdir(parents=True, exist_ok=True)
    out_path.write_text(
        json.dumps(payload, ensure_ascii=False, indent=2) + "\n",
        encoding="utf-8",
    )
    return out_path


def _repo_root() -> Path:
    return Path(__file__).resolve().parent.parent


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--exam", help="URL slug, e.g. 07_haru (single-exam mode)")
    parser.add_argument("--label", help="Human readable exam label")
    parser.add_argument("--era-id", help="Era based file id (e.g. r07, h30_haru)")
    parser.add_argument("--count", type=int, help="Number of questions (default: auto detect)")
    parser.add_argument("--wait", type=float, default=1.0, help="Seconds between requests")
    parser.add_argument(
        "--output-dir",
        default="assets/quiz",
        help="Directory for output JSON files (repo relative or absolute)",
    )
    parser.add_argument(
        "--all",
        dest="all_exams",
        action="store_true",
        help="Fetch every exam listed in EXAMS (overwrites existing files)",
    )
    parser.add_argument(
        "--skip-existing",
        action="store_true",
        help="In --all mode, skip exams whose output file already exists",
    )
    args = parser.parse_args()

    out_dir = Path(args.output_dir)
    if not out_dir.is_absolute():
        out_dir = _repo_root() / out_dir

    session = requests.Session()
    session.headers.update({"User-Agent": USER_AGENT, "Accept-Language": "ja,en;q=0.8"})

    if args.all_exams:
        total = len(EXAMS)
        failures: list[tuple[str, str]] = []
        for idx, (slug, label, era_id) in enumerate(EXAMS, start=1):
            out_path = out_dir / f"it_pass_{era_id}.json"
            prefix = f"({idx}/{total}) {era_id} [{label}]"
            if args.skip_existing and out_path.exists():
                print(f"{prefix} -> skip (exists)")
                continue
            try:
                count = discover_question_count(session, slug)
                print(f"{prefix} -> fetch {count} questions from {slug}")
                time.sleep(args.wait)
                path = save_exam(session, slug, label, era_id, count, args.wait, out_dir)
                print(f"{prefix} -> saved {path}")
            except Exception as e:
                print(f"{prefix} -> FAILED: {e}", file=sys.stderr)
                failures.append((slug, str(e)))
                continue
            if idx < total:
                time.sleep(args.wait)
        if failures:
            print("\nFAILED EXAMS:")
            for slug, err in failures:
                print(f" - {slug}: {err}")
            return 1
        return 0

    if not args.exam:
        parser.error("either --exam or --all is required")
    label = args.label or args.exam
    era_id = args.era_id or args.exam
    count = args.count or discover_question_count(session, args.exam)
    if args.count is None:
        time.sleep(args.wait)
    path = save_exam(session, args.exam, label, era_id, count, args.wait, out_dir)
    print(f"saved {count} questions to {path}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())

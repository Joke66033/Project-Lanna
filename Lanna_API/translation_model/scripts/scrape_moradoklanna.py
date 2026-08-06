from __future__ import annotations

import argparse
import concurrent.futures
import html as html_stdlib
import itertools
import json
import re
import sys
import threading
import time
from pathlib import Path
from urllib.parse import quote

import requests
from lxml import html

from ln_tilok_to_unicode import convert_ln_tilok, visual_similarity


BASE_URL = "https://moradoklanna.com/dict/"
PAGE_RE = re.compile(r"[?&]page=(\d+)")
THREAD_LOCAL = threading.local()
HEADERS = {
    "User-Agent": "Lanna-translation-research/1.0 (dataset preparation; source attribution retained)",
    "Accept-Language": "th,en;q=0.8",
}


def clean(value: str) -> str:
    return re.sub(r"\s+", " ", html_stdlib.unescape(value or "")).strip()


def cell_text(cell) -> str:
    return clean("".join(cell.itertext()))


def parse_page(content: bytes) -> list[dict[str, str]]:
    root = html.fromstring(content)
    rows = []
    for row in root.xpath('//tr[contains(concat(" ", normalize-space(@class), " "), " clickable-row ")]'):
        cells = row.xpath("./td")
        if len(cells) < 4:
            continue
        rows.append(
            {
                "pronunciation": cell_text(cells[0]),
                "legacy_lanna": cell_text(cells[1]),
                "thai": cell_text(cells[2]).strip("[] "),
                "meaning": cell_text(cells[3]),
            }
        )
    return rows


def total_pages(content: bytes) -> int:
    text = content.decode("utf-8", errors="replace")
    pages = [int(match.group(1)) for match in PAGE_RE.finditer(text)]
    return max(pages, default=1)


def fetch(session: requests.Session, query: str, page: int, attempts: int = 4) -> bytes:
    url = f"{BASE_URL}?l=thai&s={quote(query)}&page={page}"
    for attempt in range(1, attempts + 1):
        try:
            response = session.get(url, timeout=40)
            response.raise_for_status()
            return response.content
        except requests.RequestException:
            if attempt == attempts:
                raise
            time.sleep(attempt * 2)
    raise RuntimeError("unreachable")


def fetch_page(query: str, page: int, delay: float) -> tuple[int, bytes]:
    session = getattr(THREAD_LOCAL, "session", None)
    if session is None:
        session = requests.Session()
        session.headers.update(HEADERS)
        THREAD_LOCAL.session = session
    content = fetch(session, query, page)
    if delay:
        time.sleep(delay)
    return page, content


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--output", required=True)
    parser.add_argument("--legacy-font", required=True)
    parser.add_argument("--unicode-font", required=True)
    parser.add_argument("--query", default="%")
    parser.add_argument("--start-page", type=int, default=1)
    parser.add_argument("--max-pages", type=int, default=0)
    parser.add_argument("--delay", type=float, default=0.35)
    parser.add_argument("--workers", type=int, default=1)
    parser.add_argument("--visual-threshold", type=float, default=0.86)
    args = parser.parse_args()

    output_path = Path(args.output)
    output_path.parent.mkdir(parents=True, exist_ok=True)
    session = requests.Session()
    session.headers.update(HEADERS)

    first_content = fetch(session, args.query, args.start_page)
    detected_pages = total_pages(first_content)
    last_page = detected_pages
    if args.max_pages:
        last_page = min(last_page, args.start_page + args.max_pages - 1)

    seen = set()
    if output_path.exists():
        for line in output_path.read_text(encoding="utf-8").splitlines():
            if not line.strip():
                continue
            record = json.loads(line)
            seen.add((record.get("thai"), record.get("legacy_lanna"), record.get("meaning")))

    counters = {"rows": 0, "written": 0, "approved": 0, "needs_review": 0}
    remaining_pages = list(range(args.start_page + 1, last_page + 1))
    page_stream: list[tuple[int, bytes]] | object = []
    executor = None
    if args.workers > 1 and remaining_pages:
        executor = concurrent.futures.ThreadPoolExecutor(max_workers=args.workers)
        page_stream = executor.map(
            lambda page: fetch_page(args.query, page, args.delay), remaining_pages
        )
    else:
        page_stream = (
            (page, fetch(session, args.query, page)) for page in remaining_pages
        )

    try:
        with output_path.open("a", encoding="utf-8") as handle:
            for page, content in itertools.chain(
                [(args.start_page, first_content)], page_stream
            ):
                for source in parse_page(content):
                    counters["rows"] += 1
                    if source["pronunciation"] == "ตั๋วอย่าง":
                        continue
                    key = (source["thai"], source["legacy_lanna"], source["meaning"])
                    if key in seen:
                        continue
                    seen.add(key)
                    converted, warnings = convert_ln_tilok(source["legacy_lanna"], args.legacy_font)
                    similarity = visual_similarity(
                        source["legacy_lanna"], converted, args.legacy_font, args.unicode_font
                    )
                    if similarity < args.visual_threshold:
                        warnings = sorted(set([*warnings, "rendered_shape_mismatch"]))
                    status = "approved" if not warnings else "needs_review"
                    counters[status] += 1
                    record = {
                        "thai": source["thai"] or source["pronunciation"],
                        "lanna": converted,
                        "pronunciation": source["pronunciation"],
                        "meaning": source["meaning"],
                        "legacy_lanna": source["legacy_lanna"],
                        "review_status": status,
                        "conversion_method": "ln_tilok_font_map_v1",
                        "conversion_warnings": warnings,
                        "visual_similarity": round(similarity, 4),
                        "source_id": "moradoklanna_dict",
                        "source_page": page,
                        "source_url": f"{BASE_URL}?l=thai&s={quote(args.query)}&page={page}",
                    }
                    handle.write(json.dumps(record, ensure_ascii=False) + "\n")
                    counters["written"] += 1
                handle.flush()
                print(
                    json.dumps(
                        {"page": page, "last_page": last_page, **counters}, ensure_ascii=False
                    ),
                    flush=True,
                )
                if args.workers <= 1 and page < last_page:
                    time.sleep(args.delay)
    finally:
        if executor:
            executor.shutdown(wait=True, cancel_futures=True)

    print(json.dumps({"detected_pages": detected_pages, **counters}, ensure_ascii=False, indent=2))


if __name__ == "__main__":
    try:
        main()
    except KeyboardInterrupt:
        print("Stopped safely. Re-run with the next --start-page to continue.", file=sys.stderr)
        raise

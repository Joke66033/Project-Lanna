"""Attach candidate scanned-dictionary pages to a letter review batch.

OCR is used only to locate pages.  A match never changes verification_status;
the rendered source page still has to be visually checked by a reviewer.
"""

from __future__ import annotations

import argparse
import json
import re
import unicodedata
from pathlib import Path


def searchable(value: str) -> str:
    value = unicodedata.normalize("NFC", value or "")
    return re.sub(r"[\s\[\](){}'\".,;:!?/\\|_-]+", "", value)


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--review-file", required=True, type=Path)
    parser.add_argument("--ocr-dir", required=True, type=Path)
    parser.add_argument("--output", required=True, type=Path)
    parser.add_argument("--pdf-id", default="lanna_dictionary_drive_672")
    args = parser.parse_args()

    pages = {}
    page_lines = {}
    for path in sorted(args.ocr_dir.glob("page-*.txt")):
        page = int(path.stem.split("-")[-1])
        raw_text = path.read_text(encoding="utf-8", errors="replace")
        pages[page] = searchable(raw_text)
        page_lines[page] = raw_text.splitlines()

    rows = []
    for line in args.review_file.read_text(encoding="utf-8").splitlines():
        if not line.strip():
            continue
        row = json.loads(line)
        needle = searchable(row["thai"])
        # One-letter headwords cause too many false positives in prose.
        context_pages = [] if len(needle) < 2 else [page for page, text in pages.items() if needle in text]
        # A dictionary headword is followed by its Lanna form and a bracketed
        # pronunciation on the same printed line. Thai-letter boundaries avoid
        # treating กด inside กกดก as a headword hit.
        headword_pattern = re.compile(
            r"(?<![\u0E00-\u0E7F])" + re.escape(normalize_word := unicodedata.normalize("NFC", row["thai"]))
            + r"(?![\u0E00-\u0E7F]).{0,80}\["
        ) if len(needle) >= 2 else None
        candidate_pages = [] if headword_pattern is None else [
            page for page, lines in page_lines.items()
            if any(headword_pattern.search(line) for line in lines)
        ]
        row["pdf_evidence"] = {
            "source_id": args.pdf_id,
            "candidate_pages": candidate_pages,
            "context_pages": context_pages,
            "match_method": "thai_headword_boundary_before_bracket_in_local_ocr",
            "visually_verified": False,
        }
        rows.append(row)

    args.output.parent.mkdir(parents=True, exist_ok=True)
    with args.output.open("w", encoding="utf-8") as handle:
        for row in rows:
            handle.write(json.dumps(row, ensure_ascii=False) + "\n")
    print(json.dumps({
        "rows": len(rows),
        "with_candidate_pages": sum(bool(row["pdf_evidence"]["candidate_pages"]) for row in rows),
        "without_candidate_pages": sum(not row["pdf_evidence"]["candidate_pages"] for row in rows),
        "visually_verified": 0,
    }, ensure_ascii=False, indent=2))


if __name__ == "__main__":
    main()

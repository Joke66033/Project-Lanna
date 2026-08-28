"""Suggest scanned-dictionary pages for manual review without verifying records.

The OCR is deliberately treated as a page locator only.  This script never
changes ``verification_status`` or ``candidate_pages``.
"""

from __future__ import annotations

import argparse
from difflib import SequenceMatcher
import json
from pathlib import Path
import re
import unicodedata


THAI_RUN = re.compile(r"[\u0E00-\u0E7F]+")


def thai_only(value: str) -> str:
    return "".join(THAI_RUN.findall(unicodedata.normalize("NFC", value or "")))


def threshold(word: str) -> float:
    if len(word) <= 3:
        return 0.92
    if len(word) <= 5:
        return 0.84
    return 0.76


def ngrams(value: str, size: int = 2) -> set[str]:
    return {value[index:index + size] for index in range(max(0, len(value) - size + 1))}


def headword_context_runs(line: str, max_runs: int = 3) -> list[tuple[str, int]]:
    """Return Thai OCR runs nearest each pronunciation bracket.

    The printed layout places a headword and its Lanna spelling immediately
    before ``[pronunciation]``. OCR can misread parts of the Lanna glyphs as
    Thai, so the nearest three runs are retained with a distance rank.
    """
    normalized = unicodedata.normalize("NFC", line)
    found: list[tuple[str, int]] = []
    segment_start = 0
    for match in re.finditer(r"\[", normalized):
        prefix = normalized[segment_start:match.start()]
        runs = THAI_RUN.findall(prefix)
        for rank, run in enumerate(reversed(runs[-max_runs:])):
            if len(run) >= 2:
                found.append((run, rank))
        segment_start = match.end()
    return found


def line_score(target: str, line: str) -> float:
    """Return a conservative similarity score against Thai OCR runs."""
    if not target:
        return 0.0
    runs = THAI_RUN.findall(unicodedata.normalize("NFC", line))
    if target in runs:
        return 1.0
    scores = []
    for run in runs:
        if target in run:
            scores.append(0.98)
        scores.append(SequenceMatcher(None, target, run).ratio())
    return max(scores, default=0.0)


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--evidence", required=True, type=Path)
    parser.add_argument("--ocr-dir", required=True, type=Path)
    parser.add_argument("--output", required=True, type=Path)
    parser.add_argument("--page-from", type=int, default=23)
    parser.add_argument("--page-to", type=int, default=60)
    parser.add_argument("--max-pages", type=int, default=3)
    args = parser.parse_args()

    pages: dict[int, list[str]] = {}
    for path in sorted(args.ocr_dir.glob("page-*.txt")):
        page = int(path.stem.rsplit("-", 1)[-1])
        if args.page_from <= page <= args.page_to:
            pages[page] = path.read_text(encoding="utf-8", errors="replace").splitlines()

    indexed_runs: list[tuple[int, str, str, int]] = []
    gram_index: dict[str, set[int]] = {}
    for page, lines in pages.items():
        for line in lines:
            for run, rank in headword_context_runs(line):
                item_id = len(indexed_runs)
                indexed_runs.append((page, line.strip(), run, rank))
                for gram in ngrams(run):
                    gram_index.setdefault(gram, set()).add(item_id)

    rows = []
    for raw in args.evidence.read_text(encoding="utf-8").splitlines():
        if not raw.strip():
            continue
        row = json.loads(raw)
        pdf = row.setdefault("pdf_evidence", {})
        if row.get("verification_status") != "auto_checked_needs_expert" or pdf.get("candidate_pages"):
            rows.append(row)
            continue

        targets = [thai_only(row.get("thai", "")), thai_only(row.get("pronunciation", ""))]
        targets = [item for item in dict.fromkeys(targets) if len(item) >= 2]
        best_by_page: dict[int, tuple[float, str, str]] = {}
        for target in targets:
            possible_ids: set[int] = set()
            for gram in ngrams(target):
                possible_ids.update(gram_index.get(gram, ()))
            minimum = threshold(target)
            for item_id in possible_ids:
                page, source_line, run, rank = indexed_runs[item_id]
                raw_score = 1.0 if target == run else (0.98 if target in run else SequenceMatcher(None, target, run).ratio())
                score = raw_score - (0.035 * rank)
                if page in pdf.get("false_positive_pages", []):
                    continue
                if score >= minimum and score > best_by_page.get(page, (0.0, "", ""))[0]:
                    best_by_page[page] = (score, target, source_line)
        page_hits = [
            {"pdf_page": page, "score": round(best[0], 3), "matched_target": best[1], "ocr_line": best[2][:240]}
            for page, best in best_by_page.items()
        ]
        page_hits.sort(key=lambda item: (-item["score"], item["pdf_page"]))
        pdf["suggested_pages"] = page_hits[:args.max_pages]
        pdf["suggestion_method"] = "thai_headword_context_before_pronunciation_bracket_manual_review_only"
        rows.append(row)

    args.output.parent.mkdir(parents=True, exist_ok=True)
    with args.output.open("w", encoding="utf-8") as handle:
        for row in rows:
            handle.write(json.dumps(row, ensure_ascii=False) + "\n")
    print(json.dumps({
        "rows": len(rows),
        "with_suggestions": sum(bool(row.get("pdf_evidence", {}).get("suggested_pages")) for row in rows),
    }, ensure_ascii=False, indent=2))


if __name__ == "__main__":
    main()

"""Remove visually checked false OCR page suggestions without rejecting words."""

from __future__ import annotations

import argparse
import json
from pathlib import Path


def apply_false_pages(rows: list[dict], decisions: list[dict]) -> int:
    by_thai: dict[str, list[dict]] = {}
    for row in rows:
        by_thai.setdefault(row["thai"], []).append(row)
    applied = 0
    for decision in decisions:
        matches = by_thai.get(decision["thai"], [])
        if len(matches) != 1:
            raise ValueError(f"Thai headword is missing or ambiguous: {decision['thai']}")
        row = matches[0]
        pdf = row.setdefault("pdf_evidence", {})
        candidate_pages = pdf.get("candidate_pages", [])
        suggestions = pdf.get("suggested_pages", [])
        suggested_pages = [item["pdf_page"] for item in suggestions]
        false_pages = pdf.setdefault("false_positive_pages", [])
        notes = pdf.setdefault("evidence_review_notes", [])
        for page in decision["pdf_pages"]:
            page = int(page)
            if page not in candidate_pages and page not in suggested_pages:
                raise ValueError(f"Page {page} is not currently proposed for {decision['thai']}")
            pdf["candidate_pages"] = [item for item in pdf.get("candidate_pages", []) if item != page]
            pdf["suggested_pages"] = [item for item in pdf.get("suggested_pages", []) if item["pdf_page"] != page]
            if page not in false_pages:
                false_pages.append(page)
                false_pages.sort()
            notes.append({"pdf_page": page, "decision": "evidence_false_positive", "note": decision.get("note", "")})
            applied += 1
    return applied


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--evidence", required=True, type=Path)
    parser.add_argument("--decisions", required=True, type=Path)
    parser.add_argument("--output", required=True, type=Path)
    args = parser.parse_args()
    rows = [json.loads(line) for line in args.evidence.read_text(encoding="utf-8").splitlines() if line]
    decisions = json.loads(args.decisions.read_text(encoding="utf-8"))
    count = apply_false_pages(rows, decisions)
    args.output.parent.mkdir(parents=True, exist_ok=True)
    with args.output.open("w", encoding="utf-8") as handle:
        for row in rows:
            handle.write(json.dumps(row, ensure_ascii=False) + "\n")
    print(json.dumps({"rows": len(rows), "false_page_reviews_applied": count}, ensure_ascii=False, indent=2))


if __name__ == "__main__":
    main()

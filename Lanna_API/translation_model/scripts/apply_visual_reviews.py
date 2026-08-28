"""Apply explicit page-image review decisions to an evidence JSONL file."""

from __future__ import annotations

import argparse
import json
from pathlib import Path


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--evidence", required=True, type=Path)
    parser.add_argument("--decisions", required=True, type=Path)
    parser.add_argument("--output", required=True, type=Path)
    args = parser.parse_args()

    rows = [json.loads(line) for line in args.evidence.read_text(encoding="utf-8").splitlines() if line.strip()]
    decisions = json.loads(args.decisions.read_text(encoding="utf-8"))
    by_pair = {(row["thai"], row["lanna"]): row for row in rows}
    applied = 0
    for decision in decisions:
        key = (decision["thai"], decision["lanna"])
        if key not in by_pair:
            raise ValueError(f"Review decision does not match an evidence row: {key}")
        row = by_pair[key]
        page = int(decision["pdf_page"])
        pdf_evidence = row.get("pdf_evidence", {})
        candidates = pdf_evidence.get("candidate_pages", [])
        suggestions = pdf_evidence.get("suggested_pages", [])
        suggested_page_numbers = [item["pdf_page"] for item in suggestions]
        reconsidered = page in pdf_evidence.get("false_positive_pages", []) and decision.get("reconsider_false_positive") is True
        manually_located = decision.get("manual_source_page") is True
        if page not in candidates and page not in suggested_page_numbers and not reconsidered and not manually_located:
            raise ValueError(f"Page {page} is neither an OCR candidate nor a review suggestion for {key}")
        review_decision = decision.get("decision")
        if review_decision not in {"source_image_verified", "rejected", "evidence_false_positive"}:
            raise ValueError(f"Unsupported decision for {key}: {decision.get('decision')}")
        if review_decision == "evidence_false_positive":
            row["pdf_evidence"]["candidate_pages"] = [item for item in candidates if item != page]
            row["pdf_evidence"]["suggested_pages"] = [
                item for item in suggestions if item["pdf_page"] != page
            ]
            false_positive_pages = row["pdf_evidence"].setdefault("false_positive_pages", [])
            if page not in false_positive_pages:
                false_positive_pages.append(page)
                false_positive_pages.sort()
            notes = row["pdf_evidence"].setdefault("evidence_review_notes", [])
            notes.append({"pdf_page": page, "decision": review_decision, "note": decision.get("note", "")})
        else:
            if reconsidered:
                row["pdf_evidence"]["false_positive_pages"] = [
                    item for item in row["pdf_evidence"].get("false_positive_pages", []) if item != page
                ]
                notes = row["pdf_evidence"].setdefault("evidence_review_notes", [])
                notes.append({
                    "pdf_page": page,
                    "decision": "false_positive_decision_reversed_after_high_resolution_review",
                    "note": decision.get("reconsider_note", ""),
                })
            row["verification_status"] = review_decision
            row["pdf_evidence"]["visually_verified"] = review_decision == "source_image_verified"
            row["pdf_evidence"]["verified_page"] = page
            row["pdf_evidence"]["checked_fields"] = decision.get("checked_fields", [])
            row["pdf_evidence"]["review_note"] = decision.get("note", "")
            row["pdf_evidence"]["reviewed_from"] = (
                "reconsidered_high_resolution_image" if reconsidered
                else "manual_high_resolution_image" if manually_located
                else "candidate" if page in candidates else "suggestion"
            )
            if decision.get("category"):
                row["category"] = decision["category"]
                row["category_confidence"] = 1.0
                row["category_reviewed"] = True
                row["category_review_source"] = "visual_source_review"
        applied += 1

    args.output.parent.mkdir(parents=True, exist_ok=True)
    with args.output.open("w", encoding="utf-8") as handle:
        for row in rows:
            handle.write(json.dumps(row, ensure_ascii=False) + "\n")
    print(json.dumps({"rows": len(rows), "visual_reviews_applied": applied}, ensure_ascii=False, indent=2))


if __name__ == "__main__":
    main()

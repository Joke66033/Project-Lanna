"""Apply auditable corrections to damaged source records before verification."""

from __future__ import annotations

import argparse
import json
from pathlib import Path


def apply_corrections(rows: list[dict], corrections: list[dict]) -> int:
    by_thai = {row["thai"]: row for row in rows}
    if len(by_thai) != len(rows):
        raise ValueError("Thai headwords are not unique; pair-based correction is required")
    applied = 0
    for correction in corrections:
        old_thai = correction["old_thai"]
        new_thai = correction["new_thai"]
        if old_thai not in by_thai:
            raise ValueError(f"Correction source not found: {old_thai}")
        if new_thai != old_thai and new_thai in by_thai:
            raise ValueError(f"Correction would create duplicate headword: {new_thai}")
        row = by_thai.pop(old_thai)
        if row.get("verification_status") != "auto_checked_needs_expert":
            raise ValueError(f"Only pending records can be corrected: {old_thai}")
        audit = row.setdefault("record_corrections", [])
        changed_fields = {}
        for field, correction_key in (
            ("pronunciation", "new_pronunciation"),
            ("meaning", "new_meaning"),
            ("lanna", "new_lanna"),
            ("category", "new_category"),
        ):
            if correction_key in correction and correction[correction_key] != row.get(field):
                changed_fields[field] = {"old": row.get(field), "new": correction[correction_key]}
        audit.append({
            "old_thai": old_thai,
            "new_thai": new_thai,
            "old_pronunciation": row.get("pronunciation", ""),
            "new_pronunciation": correction.get("new_pronunciation", row.get("pronunciation", "")),
            "source_pdf_page": correction["source_pdf_page"],
            "note": correction.get("note", ""),
            "changed_fields": changed_fields,
        })
        row["thai"] = new_thai
        if correction.get("new_pronunciation"):
            row["pronunciation"] = correction["new_pronunciation"]
        if "new_meaning" in correction:
            row["meaning"] = correction["new_meaning"]
        if "new_lanna" in correction:
            row["lanna"] = correction["new_lanna"]
        if "new_category" in correction:
            row["category"] = correction["new_category"]
            row["category_confidence"] = 1.0
            row["category_reviewed"] = True
            row["category_review_source"] = "visual_source_review"
        row["source_type"] = "source_image_corrected"
        by_thai[new_thai] = row
        applied += 1
    return applied


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--evidence", required=True, type=Path)
    parser.add_argument("--corrections", required=True, type=Path)
    parser.add_argument("--output", required=True, type=Path)
    args = parser.parse_args()
    rows = [json.loads(line) for line in args.evidence.read_text(encoding="utf-8").splitlines() if line]
    corrections = json.loads(args.corrections.read_text(encoding="utf-8"))
    count = apply_corrections(rows, corrections)
    args.output.parent.mkdir(parents=True, exist_ok=True)
    with args.output.open("w", encoding="utf-8") as handle:
        for row in rows:
            handle.write(json.dumps(row, ensure_ascii=False) + "\n")
    print(json.dumps({"rows": len(rows), "record_corrections_applied": count}, ensure_ascii=False, indent=2))


if __name__ == "__main__":
    main()

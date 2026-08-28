"""Merge separately printed dictionary senses into one runtime headword."""

from __future__ import annotations

import argparse
import json
from pathlib import Path


VERIFIED = {"source_image_verified", "owner_verified", "expert_verified"}


def merge_senses(rows: list[dict], merges: list[dict]) -> int:
    by_thai = {row["thai"]: row for row in rows}
    if len(by_thai) != len(rows):
        raise ValueError("Existing Thai headwords are not unique")
    count = 0
    for merge in merges:
        thai = merge["thai"]
        row = by_thai.get(thai)
        if row is None:
            raise ValueError(f"Sense merge headword is missing: {thai}")
        if row.get("verification_status") not in VERIFIED:
            raise ValueError(f"Sense merge headword is not source verified: {thai}")
        if row.get("lanna") != merge.get("lanna"):
            raise ValueError(f"Sense merge Lanna spelling mismatch: {thai}")
        senses = merge.get("senses", [])
        if [sense.get("sense_no") for sense in senses] != list(range(1, len(senses) + 1)):
            raise ValueError(f"Invalid sense numbering for {thai}")
        for sense in senses:
            for field in ("part_of_speech", "pronunciation", "meaning", "category", "source_page"):
                if sense.get(field) in (None, ""):
                    raise ValueError(f"Missing sense {field} for {thai}#{sense.get('sense_no')}")
        row["pronunciation"] = merge["pronunciation"]
        row["meaning"] = merge["meaning"]
        row["category"] = merge.get("category", "คำศัพท์ทั่วไป")
        row["senses"] = senses
        pages = sorted({int(sense["source_page"]) for sense in senses})
        evidence = row.setdefault("pdf_evidence", {})
        evidence["verified_pages"] = pages
        evidence["context_pages"] = sorted(set(evidence.get("context_pages", [])) | set(pages))
        evidence["review_note"] = merge.get("note", "รวมบทนิยามหัวคำเดียวกันจากภาพต้นฉบับหลายตำแหน่ง")
        row["category_reviewed"] = True
        row["category_review_source"] = "visual_source_review"
        row["category_review_note"] = "เก็บหมวดเฉพาะของแต่ละบทนิยามไว้ใน senses"
        count += 1
    return count


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--evidence", required=True, type=Path)
    parser.add_argument("--merges", required=True, type=Path)
    parser.add_argument("--output", required=True, type=Path)
    args = parser.parse_args()
    rows = [json.loads(line) for line in args.evidence.read_text(encoding="utf-8").splitlines() if line]
    merges = json.loads(args.merges.read_text(encoding="utf-8"))
    count = merge_senses(rows, merges)
    args.output.parent.mkdir(parents=True, exist_ok=True)
    with args.output.open("w", encoding="utf-8") as handle:
        for row in rows:
            handle.write(json.dumps(row, ensure_ascii=False) + "\n")
    print(json.dumps({"rows": len(rows), "sense_merges_applied": count}, ensure_ascii=False, indent=2))


if __name__ == "__main__":
    main()

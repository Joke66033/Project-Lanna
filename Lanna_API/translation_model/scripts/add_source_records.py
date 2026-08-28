"""Add explicitly transcribed dictionary headwords with image evidence."""

from __future__ import annotations

import argparse
import json
from pathlib import Path


def add_records(rows: list[dict], records: list[dict]) -> int:
    by_thai = {row["thai"]: row for row in rows}
    if len(by_thai) != len(rows):
        raise ValueError("Existing Thai headwords are not unique")
    count = 0
    for record in records:
        thai = record["thai"]
        if thai in by_thai:
            if record.get("merge_existing_page") is True:
                existing = by_thai[thai]
                for field in ("lanna", "pronunciation", "meaning", "category"):
                    if existing.get(field) != record.get(field):
                        raise ValueError(f"Cannot merge conflicting {field} for {thai}")
                page = int(record["pdf_page"])
                evidence = existing.setdefault("pdf_evidence", {})
                verified_pages = {
                    int(value)
                    for value in evidence.get("verified_pages", [])
                    if value is not None
                }
                if evidence.get("verified_page") is not None:
                    verified_pages.add(int(evidence["verified_page"]))
                verified_pages.add(page)
                evidence["verified_pages"] = sorted(verified_pages)
                context_pages = {
                    int(value)
                    for value in evidence.get("context_pages", [])
                    if value is not None
                }
                context_pages.update(verified_pages)
                evidence["context_pages"] = sorted(context_pages)
                continue
            raise ValueError(f"Source headword already exists: {thai}")
        for field in ("lanna", "pronunciation", "meaning", "initial", "category", "pdf_page"):
            if record.get(field) in (None, ""):
                raise ValueError(f"Missing {field} for {thai}")
        page = int(record["pdf_page"])
        context_pages = sorted({int(value) for value in record.get("context_pages", [page])})
        if page not in context_pages:
            raise ValueError(f"Verified page missing from context_pages for {thai}")
        senses = record.get("senses", [])
        if senses:
            expected_numbers = list(range(1, len(senses) + 1))
            actual_numbers = [sense.get("sense_no") for sense in senses]
            if actual_numbers != expected_numbers:
                raise ValueError(f"Invalid sense numbering for {thai}: {actual_numbers}")
            for sense in senses:
                for field in ("part_of_speech", "pronunciation", "meaning", "category", "source_page"):
                    if sense.get(field) in (None, ""):
                        raise ValueError(f"Missing sense {field} for {thai}#{sense.get('sense_no')}")
        row = {
            "thai": thai,
            "lanna": record["lanna"],
            "pronunciation": record["pronunciation"],
            "meaning": record["meaning"],
            "initial": record["initial"],
            "category": record["category"],
            "category_confidence": 1.0,
            "source_type": "source_dictionary_image",
            "source_id": record.get("source_id", "lanna_dictionary_drive_672"),
            "source_page": page,
            "source_url": "",
            "verification_status": "source_image_verified",
            "pdf_evidence": {
                "source_id": record.get("source_id", "lanna_dictionary_drive_672"),
                "candidate_pages": [],
                "context_pages": context_pages,
                "visually_verified": True,
                "verified_page": page,
                "checked_fields": ["thai", "lanna_glyph_shape", "pronunciation", "meaning"],
                "review_note": record.get("note", "เพิ่มหัวคำที่ถอดจากภาพต้นฉบับ"),
                "reviewed_from": "manual_high_resolution_image",
            },
            "category_reviewed": True,
            "category_review_source": "visual_source_review",
            "category_review_note": record.get("category_note", "จัดหมวดจากความหมายในภาพต้นฉบับ"),
            "source_search_status": "source_image_verified",
            "source_search_note": "ตรวจพบและยืนยันหัวคำจากภาพต้นฉบับความละเอียดสูง",
            "source_record_added": True,
        }
        if senses:
            row["senses"] = senses
        if record.get("lanna_variants"):
            row["lanna_variants"] = record["lanna_variants"]
        rows.append(row)
        by_thai[thai] = row
        count += 1
    return count


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--evidence", required=True, type=Path)
    parser.add_argument("--records", required=True, type=Path)
    parser.add_argument("--output", required=True, type=Path)
    args = parser.parse_args()
    rows = [json.loads(line) for line in args.evidence.read_text(encoding="utf-8").splitlines() if line]
    records = json.loads(args.records.read_text(encoding="utf-8"))
    count = add_records(rows, records)
    args.output.parent.mkdir(parents=True, exist_ok=True)
    with args.output.open("w", encoding="utf-8") as handle:
        for row in rows:
            handle.write(json.dumps(row, ensure_ascii=False) + "\n")
    print(json.dumps({"rows": len(rows), "source_records_added": count}, ensure_ascii=False, indent=2))


if __name__ == "__main__":
    main()

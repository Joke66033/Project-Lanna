"""Apply explicit corrections to records already verified against a source image."""

from __future__ import annotations

import argparse
import json
from copy import deepcopy
from pathlib import Path


VERIFIED = {"source_image_verified", "owner_verified", "expert_verified"}
FIELDS = ("lanna", "pronunciation", "meaning", "category", "source_type", "source_id", "source_page")


def revise_records(rows: list[dict], revisions: list[dict]) -> int:
    by_thai = {row["thai"]: row for row in rows}
    if len(by_thai) != len(rows):
        raise ValueError("Existing Thai headwords are not unique")
    count = 0
    for revision in revisions:
        thai = revision["thai"]
        row = by_thai.get(thai)
        if row is None:
            raise ValueError(f"Verified source revision headword is missing: {thai}")
        restore_rejected = bool(revision.get("restore_rejected"))
        promote_pending = bool(revision.get("promote_pending"))
        if row.get("verification_status") not in VERIFIED:
            allowed_transition = (
                (restore_rejected and row.get("verification_status") == "rejected")
                or (promote_pending and row.get("verification_status") == "auto_checked_needs_expert")
            )
            if not allowed_transition:
                raise ValueError(f"Refusing to revise unverified headword: {thai}")
        evidence = row.get("pdf_evidence", {})
        expected_page = int(revision["expected_verified_page"])
        if not promote_pending and evidence.get("verified_page") != expected_page:
            raise ValueError(f"Verified page mismatch for {thai}")
        if promote_pending and int(revision.get("source_page", expected_page)) != expected_page:
            raise ValueError(f"Pending promotion page mismatch for {thai}")
        history = row.setdefault("source_revision_history", [])
        history.append({
            "previous": {field: deepcopy(row.get(field)) for field in FIELDS},
            "reason": revision["reason"],
        })
        for field in FIELDS:
            if field in revision:
                row[field] = revision[field]
        evidence["verified_page"] = int(revision.get("source_page", expected_page))
        requested_context = {int(value) for value in revision.get("context_pages", [])}
        evidence["context_pages"] = sorted(set(evidence.get("context_pages", [])) | requested_context | {evidence["verified_page"]})
        evidence["visually_verified"] = True
        evidence["checked_fields"] = ["thai", "lanna_glyph_shape", "pronunciation", "meaning"]
        evidence["review_note"] = revision["reason"]
        evidence["reviewed_from"] = "manual_high_resolution_image"
        row["category_reviewed"] = True
        row["category_review_source"] = "visual_source_review"
        row["category_review_note"] = revision.get("category_note", "จัดหมวดจากนิยามที่ตรวจในภาพต้นฉบับ")
        if "senses" in revision:
            senses = revision["senses"]
            if not senses or [sense.get("sense_no") for sense in senses] != list(range(1, len(senses) + 1)):
                raise ValueError(f"Invalid sense numbering for {thai}")
            row["senses"] = deepcopy(senses)
        if restore_rejected or promote_pending:
            row["verification_status"] = "source_image_verified"
            row["source_search_status"] = "source_image_verified"
            row["source_search_note"] = (
                "ยืนยันระเบียนรอตรวจจากภาพต้นฉบับ"
                if promote_pending
                else "คืนสถานะหลังตรวจพบหัวคำชัดเจนในภาพต้นฉบับ"
            )
        count += 1
    return count


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--evidence", required=True, type=Path)
    parser.add_argument("--revisions", required=True, type=Path)
    parser.add_argument("--output", required=True, type=Path)
    args = parser.parse_args()
    rows = [json.loads(line) for line in args.evidence.read_text(encoding="utf-8").splitlines() if line]
    revisions = json.loads(args.revisions.read_text(encoding="utf-8"))
    count = revise_records(rows, revisions)
    args.output.parent.mkdir(parents=True, exist_ok=True)
    with args.output.open("w", encoding="utf-8") as handle:
        for row in rows:
            handle.write(json.dumps(row, ensure_ascii=False) + "\n")
    print(json.dumps({"rows": len(rows), "verified_source_revisions": count}, ensure_ascii=False, indent=2))


if __name__ == "__main__":
    main()

"""Record source-search coverage without changing linguistic verification."""

from __future__ import annotations

import argparse
import json
from pathlib import Path


def mark_search_status(rows: list[dict]) -> dict[str, int]:
    counts: dict[str, int] = {}
    for row in rows:
        verification = row.get("verification_status")
        evidence = row.get("pdf_evidence", {})
        if verification in {"source_image_verified", "owner_verified", "expert_verified"}:
            status = "source_image_verified"
            note = "ตรวจเทียบภาพหน้าพจนานุกรมแล้ว"
        elif verification == "verified_alias_to_source":
            status = "verified_alias_to_source"
            note = "คำค้นพ้องเชื่อมกับหัวคำพจนานุกรมที่ตรวจภาพแล้ว"
        elif verification == "rejected":
            status = "reviewed_rejected"
            note = "ตรวจทบทวนแล้วและปฏิเสธระเบียน"
        elif evidence.get("candidate_pages") or evidence.get("suggested_pages"):
            status = "candidate_pages_need_manual_review"
            note = "มีหน้าที่อาจตรงกันและยังต้องตรวจภาพด้วยคน"
        else:
            status = "not_located_after_dual_ocr_needs_manual_review"
            note = (
                "ยังไม่พบหัวคำหลังค้น OCR แบบเต็มหน้าและแบบแยกคอลัมน์; "
                "ผลนี้ไม่ใช่หลักฐานว่าคำไม่มีในพจนานุกรม"
            )
        row["source_search_status"] = status
        row["source_search_note"] = note
        counts[status] = counts.get(status, 0) + 1
    return counts


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--evidence", required=True, type=Path)
    parser.add_argument("--output", required=True, type=Path)
    args = parser.parse_args()
    rows = [json.loads(line) for line in args.evidence.read_text(encoding="utf-8").splitlines() if line]
    counts = mark_search_status(rows)
    args.output.parent.mkdir(parents=True, exist_ok=True)
    with args.output.open("w", encoding="utf-8") as handle:
        for row in rows:
            handle.write(json.dumps(row, ensure_ascii=False) + "\n")
    print(json.dumps({"rows": len(rows), "source_search_statuses": counts}, ensure_ascii=False, indent=2))


if __name__ == "__main__":
    main()

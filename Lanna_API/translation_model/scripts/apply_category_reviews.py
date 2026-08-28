"""Apply explicit semantic-category reviews to already source-verified rows."""

from __future__ import annotations

import argparse
import json
from pathlib import Path


ALLOWED_CATEGORIES = {
    "อาหารและเครื่องดื่ม", "พืชและเกษตร", "สัตว์", "บุคคลและเครือญาติ",
    "สถานที่และชุมชน", "ศาสนาและความเชื่อ", "ภาษาและอักษร",
    "ร่างกายและสุขภาพ", "ธรรมชาติและสิ่งแวดล้อม", "สิ่งของและเครื่องมือ",
    "ศิลปะ ดนตรี และการละเล่น", "การกระทำ", "ลักษณะและอาการ",
    "เวลาและจำนวน", "คำไวยากรณ์และคำเชื่อม", "คำศัพท์ทั่วไป",
}


def apply_reviews(rows: list[dict], decisions: list[dict]) -> int:
    by_pair = {(row["thai"], row["lanna"]): row for row in rows}
    applied = 0
    for decision in decisions:
        key = (decision["thai"], decision["lanna"])
        if key not in by_pair:
            raise ValueError(f"Category decision does not match a row: {key}")
        row = by_pair[key]
        if row.get("verification_status") not in {
            "source_image_verified", "owner_verified", "expert_verified"
        }:
            raise ValueError(f"Cannot source-review category of unverified row: {key}")
        category = decision.get("category", "").strip()
        if not category:
            raise ValueError(f"Missing category for {key}")
        if category not in ALLOWED_CATEGORIES:
            raise ValueError(f"Category is outside the controlled taxonomy for {key}: {category}")
        row["category"] = category
        row["category_confidence"] = 1.0
        row["category_reviewed"] = True
        row["category_review_source"] = decision.get("review_source", "dictionary_meaning_review")
        row["category_review_note"] = decision.get("note", "")
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
    applied = apply_reviews(rows, decisions)
    args.output.parent.mkdir(parents=True, exist_ok=True)
    with args.output.open("w", encoding="utf-8") as handle:
        for row in rows:
            handle.write(json.dumps(row, ensure_ascii=False) + "\n")
    print(json.dumps({"rows": len(rows), "category_reviews_applied": applied}, ensure_ascii=False, indent=2))


if __name__ == "__main__":
    main()

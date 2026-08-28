"""Build a reviewable Thai→Tai Tham lexicon one initial letter at a time.

This command never writes to the application database.  It combines only
project-owner overrides and already-approved external dictionary rows, applies
strict Unicode/provenance checks, assigns a conservative semantic category,
and emits a JSONL review batch for one requested Thai initial.
"""

from __future__ import annotations

import argparse
import json
import re
import unicodedata
from collections import Counter
from pathlib import Path


TAI_THAM_RANGE = range(0x1A20, 0x1AB0)
THAI_RANGE = range(0x0E00, 0x0E80)
THAI_INITIALS = "กขฃคฅฆงจฉชซฌญฎฏฐฑฒณดตถทธนบปผฝพฟภมยรลวศษสหฬอฮ"
SAKOT = "᩠"
MAI_SAT = "ᩢ"

CATEGORY_RULES = {
    "ภาษาและอักษร": ("อักษร", "พยัญชนะ", "สระ", "วรรณยุกต์", "ภาษา", "คำศัพท์", "อ่านว่า"),
    "อาหารและเครื่องดื่ม": ("กิน", "อาหาร", "ข้าว", "แกง", "ผัก", "ผลไม้", "เนื้อ", "ปลา", "ขนม", "น้ำ", "เหล้า"),
    "พืชและเกษตร": ("ต้นไม้", "พืช", "ดอก", "ใบ", "ราก", "เมล็ด", "นา", "ไร่", "สวน", "เพาะ", "ปลูก"),
    "สัตว์": ("สัตว์", "นก", "ปลา", "แมลง", "งู", "ควาย", "วัว", "หมู", "ไก่"),
    "บุคคลและเครือญาติ": ("บุคคล", "คน", "ชาย", "หญิง", "พ่อ", "แม่", "ลูก", "ญาติ", "ผู้"),
    "สถานที่": ("สถานที่", "บ้าน", "เมือง", "วัด", "โรง", "ห้อง", "ถนน", "ดอย", "แม่น้ำ"),
    "ศาสนาและความเชื่อ": ("พระ", "ธรรม", "ศาสนา", "บุญ", "บาป", "พิธี", "ผี", "คาถา", "วัด"),
    "ร่างกายและสุขภาพ": ("ร่างกาย", "อวัยวะ", "โรค", "เจ็บ", "ป่วย", "ยา", "รักษา"),
    "ธรรมชาติและสิ่งแวดล้อม": ("ธรรมชาติ", "ดิน", "น้ำ", "ลม", "ไฟ", "ฝน", "ฟ้า", "ป่า", "ภูเขา"),
    "สิ่งของและเครื่องใช้": ("สิ่งของ", "เครื่องมือ", "เครื่องใช้", "ภาชนะ", "ผ้า", "อาวุธ"),
    "การกระทำ": ("ก.", "กระทำ", "ทำ", "เดิน", "พูด", "มอง", "จับ", "ใช้"),
    "ลักษณะและอาการ": ("ว.", "ลักษณะ", "อาการ", "สภาพ"),
}


def normalize(value: object) -> str:
    return unicodedata.normalize("NFC", str(value or "")).strip()


def load_records(path: Path) -> list[dict]:
    if path.suffix.lower() == ".jsonl":
        return [json.loads(line) for line in path.read_text(encoding="utf-8").splitlines() if line.strip()]
    value = json.loads(path.read_text(encoding="utf-8"))
    if not isinstance(value, list):
        raise ValueError(f"{path} must contain a JSON array")
    return value


def thai_initial(word: str) -> str:
    # Leading Thai vowels belong to the following consonant for review batches.
    for character in normalize(word):
        if character in THAI_INITIALS:
            return character
    return ""


def validate_record(record: dict) -> list[str]:
    thai = normalize(record.get("thai"))
    lanna = normalize(record.get("lanna"))
    meaning = normalize(record.get("meaning") or record.get("definition"))
    pronunciation = normalize(record.get("pronunciation"))
    issues = []
    if not thai:
        issues.append("missing_thai")
    if not lanna:
        issues.append("missing_lanna")
    if not pronunciation:
        issues.append("missing_pronunciation")
    if not meaning:
        issues.append("missing_meaning")
    if ".." in thai or "…" in thai:
        issues.append("damaged_headword_placeholder")
    if ".." in pronunciation or "…" in pronunciation:
        issues.append("damaged_pronunciation_placeholder")
    if "<ctrl" in lanna.lower():
        issues.append("control_placeholder")
    if any(ord(char) in THAI_RANGE for char in lanna):
        issues.append("thai_character_in_lanna")
    if lanna and not any(ord(char) in TAI_THAM_RANGE for char in lanna):
        issues.append("no_tai_tham")
    if lanna.startswith(SAKOT) or lanna.endswith(SAKOT):
        issues.append("orphan_sakot")
    if SAKOT + SAKOT in lanna:
        issues.append("repeated_sakot")
    # Canonical cluster order in this project is base + MAI SAT + SAKOT + final,
    # as owner-confirmed by วัด = ᩅᩢ᩠ᨯ. A MAI SAT after a subjoined final is a
    # damaged legacy-font conversion and must be checked against the page image.
    if re.search(SAKOT + r"[\U00001A20-\U00001A5E]" + MAI_SAT, lanna):
        issues.append("noncanonical_mai_sat_order")
    if record.get("_external") and normalize(record.get("review_status")).lower() != "approved":
        issues.append("external_not_approved")
    return issues


def classify(meaning: str) -> tuple[str, float]:
    text = normalize(meaning).lower()
    scores = {
        category: sum(1 for keyword in keywords if keyword in text)
        for category, keywords in CATEGORY_RULES.items()
    }
    best, score = max(scores.items(), key=lambda item: item[1])
    if score == 0:
        return "คำศัพท์ทั่วไป", 0.0
    ties = sum(1 for value in scores.values() if value == score)
    return best, round(min(0.95, 0.55 + score * 0.12 - (0.10 if ties > 1 else 0)), 2)


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--letter", required=True, choices=list(THAI_INITIALS))
    parser.add_argument("--approved", required=True, type=Path)
    parser.add_argument("--overrides", required=True, type=Path)
    parser.add_argument("--output-dir", required=True, type=Path)
    args = parser.parse_args()

    rows_by_pair: dict[tuple[str, str], dict] = {}
    for source_type, path in (("approved_external", args.approved), ("owner_verified", args.overrides)):
        for raw in load_records(path):
            record = dict(raw)
            record["_external"] = source_type == "approved_external"
            record["source_type"] = source_type
            if source_type == "owner_verified":
                record.setdefault("review_status", "owner_verified")
                record.setdefault("source_id", "project_owner")
            thai = normalize(record.get("thai"))
            lanna = normalize(record.get("lanna"))
            key = (thai, lanna)
            # Owner-confirmed records intentionally take precedence.
            if key not in rows_by_pair or source_type == "owner_verified":
                rows_by_pair[key] = record

    accepted = []
    rejected = []
    lanna_by_thai: dict[str, set[str]] = {}
    for record in rows_by_pair.values():
        thai = normalize(record.get("thai"))
        lanna_by_thai.setdefault(thai, set()).add(normalize(record.get("lanna")))

    for record in rows_by_pair.values():
        thai = normalize(record.get("thai"))
        if thai_initial(thai) != args.letter:
            continue
        issues = validate_record(record)
        if len(lanna_by_thai.get(thai, set())) > 1 and record.get("source_type") != "owner_verified":
            issues.append("conflicting_lanna_spellings")
        meaning = normalize(record.get("meaning") or record.get("definition"))
        category, category_confidence = classify(meaning)
        cleaned = {
            "thai": thai,
            "lanna": normalize(record.get("lanna")),
            "pronunciation": normalize(record.get("pronunciation")),
            "meaning": meaning,
            "initial": args.letter,
            "category": category,
            "category_confidence": category_confidence,
            "source_type": record.get("source_type"),
            "source_id": normalize(record.get("source_id")),
            "source_page": record.get("source_page"),
            "source_url": normalize(record.get("source_url")),
            "verification_status": (
                "owner_verified" if record.get("source_type") == "owner_verified" else "auto_checked_needs_expert"
            ),
        }
        if issues:
            cleaned["issues"] = issues
            rejected.append(cleaned)
        else:
            accepted.append(cleaned)

    accepted.sort(key=lambda row: (row["thai"], row["lanna"]))
    rejected.sort(key=lambda row: (row["thai"], row["lanna"]))
    args.output_dir.mkdir(parents=True, exist_ok=True)
    accepted_path = args.output_dir / f"{args.letter}_review.jsonl"
    rejected_path = args.output_dir / f"{args.letter}_rejected.jsonl"
    for path, rows in ((accepted_path, accepted), (rejected_path, rejected)):
        with path.open("w", encoding="utf-8") as handle:
            for row in rows:
                handle.write(json.dumps(row, ensure_ascii=False) + "\n")

    report = {
        "letter": args.letter,
        "accepted_for_review": len(accepted),
        "rejected": len(rejected),
        "owner_verified": sum(row["verification_status"] == "owner_verified" for row in accepted),
        "needs_expert_review": sum(row["verification_status"] == "auto_checked_needs_expert" for row in accepted),
        "categories": dict(Counter(row["category"] for row in accepted)),
        "important": "No row is approved for production merely by this script.",
    }
    (args.output_dir / f"{args.letter}_report.json").write_text(
        json.dumps(report, ensure_ascii=False, indent=2), encoding="utf-8"
    )
    print(json.dumps(report, ensure_ascii=False, indent=2))


if __name__ == "__main__":
    main()

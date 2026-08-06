import argparse
import json
import unicodedata
from collections import Counter
from pathlib import Path


TAI_THAM_START = 0x1A20
TAI_THAM_END = 0x1AAF


def normalize(value: object) -> str:
    return unicodedata.normalize("NFC", str(value or "")).strip()


def has_tai_tham(value: str) -> bool:
    return any(TAI_THAM_START <= ord(char) <= TAI_THAM_END for char in value)


def has_thai(value: str) -> bool:
    return any(0x0E00 <= ord(char) <= 0x0E7F for char in value)


def load_jsonl(path: Path) -> list[dict]:
    records = []
    for line_number, line in enumerate(path.read_text(encoding="utf-8").splitlines(), 1):
        if not line.strip():
            continue
        value = json.loads(line)
        if not isinstance(value, dict):
            raise ValueError(f"{path}:{line_number} is not an object")
        value["_line"] = line_number
        records.append(value)
    return records


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--input", required=True)
    parser.add_argument("--accepted", required=True)
    parser.add_argument("--rejected", required=True)
    parser.add_argument("--report", required=True)
    args = parser.parse_args()

    accepted = []
    rejected = []
    reasons = Counter()
    seen = set()
    for record in load_jsonl(Path(args.input)):
        clean = {
            "thai": normalize(record.get("thai")),
            "lanna": normalize(record.get("lanna")),
            "pronunciation": normalize(record.get("pronunciation")),
            "meaning": normalize(record.get("meaning")),
            "source_id": normalize(record.get("source_id")),
            "source_page": record.get("source_page"),
            "review_status": normalize(record.get("review_status")).lower(),
        }
        row_reasons = []
        if clean["review_status"] != "approved":
            row_reasons.append("not_automatically_verified")
        if not clean["thai"] or not has_thai(clean["thai"]):
            row_reasons.append("missing_thai_source")
        if not clean["lanna"] or not has_tai_tham(clean["lanna"]):
            row_reasons.append("missing_tai_tham_unicode")
        if has_thai(clean["lanna"]):
            row_reasons.append("thai_codepoint_in_lanna")
        if not clean["pronunciation"]:
            row_reasons.append("missing_pronunciation")
        if not clean["meaning"]:
            row_reasons.append("missing_meaning")
        if not clean["source_id"] or not clean["source_page"]:
            row_reasons.append("missing_provenance")
        pair = (clean["thai"], clean["lanna"])
        if pair in seen:
            row_reasons.append("duplicate_pair")

        if row_reasons:
            rejected.append({"line": record["_line"], **clean, "reasons": row_reasons})
            reasons.update(row_reasons)
        else:
            seen.add(pair)
            accepted.append(clean)

    for output_path, rows in [(Path(args.accepted), accepted), (Path(args.rejected), rejected)]:
        output_path.parent.mkdir(parents=True, exist_ok=True)
        with output_path.open("w", encoding="utf-8") as handle:
            for row in rows:
                handle.write(json.dumps(row, ensure_ascii=False) + "\n")

    report = {
        "input_records": len(accepted) + len(rejected),
        "accepted_records": len(accepted),
        "rejected_records": len(rejected),
        "rejection_reasons": dict(reasons),
    }
    report_path = Path(args.report)
    report_path.parent.mkdir(parents=True, exist_ok=True)
    report_path.write_text(json.dumps(report, ensure_ascii=False, indent=2), encoding="utf-8")
    print(json.dumps(report, ensure_ascii=False, indent=2))


if __name__ == "__main__":
    main()

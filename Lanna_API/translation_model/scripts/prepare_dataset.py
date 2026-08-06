import argparse
import hashlib
import json
import random
import unicodedata
from collections import Counter
from pathlib import Path


TAI_THAM_START = 0x1A20
TAI_THAM_END = 0x1AAF


def normalize(value: object) -> str:
    return unicodedata.normalize("NFC", str(value or "")).strip()


def has_thai_characters(value: str) -> bool:
    return any(0x0E00 <= ord(char) <= 0x0E7F for char in value)


def has_tai_tham(value: str) -> bool:
    return any(TAI_THAM_START <= ord(char) <= TAI_THAM_END for char in value)


def load_records(path: Path) -> list[dict]:
    """Load either a JSON array or newline-delimited JSON records."""
    if path.suffix.lower() == ".jsonl":
        records = []
        for line_number, line in enumerate(path.read_text(encoding="utf-8").splitlines(), 1):
            if not line.strip():
                continue
            value = json.loads(line)
            if not isinstance(value, dict):
                raise ValueError(f"{path}:{line_number} is not a JSON object")
            records.append(value)
        return records

    value = json.loads(path.read_text(encoding="utf-8"))
    if not isinstance(value, list) or not all(isinstance(item, dict) for item in value):
        raise ValueError(f"{path} must contain a JSON array of objects")
    return value


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--input", required=True)
    parser.add_argument("--verified-overrides")
    parser.add_argument(
        "--external-input",
        action="append",
        default=[],
        help="Reviewed external .json or .jsonl file. Only records with review_status=approved are eligible.",
    )
    parser.add_argument("--output-dir", required=True)
    parser.add_argument("--seed", type=int, default=20260802)
    args = parser.parse_args()

    source_path = Path(args.input)
    output_dir = Path(args.output_dir)
    output_dir.mkdir(parents=True, exist_ok=True)
    records = load_records(source_path)
    override_count = 0
    if args.verified_overrides:
        override_path = Path(args.verified_overrides)
        overrides = load_records(override_path)
        override_count = len(overrides)
        records.extend(overrides)

    external_input_files = [Path(value) for value in args.external_input]
    external_raw_records = 0
    external_approved_records = 0
    for external_path in external_input_files:
        external_records = load_records(external_path)
        external_raw_records += len(external_records)
        for record in external_records:
            record = dict(record)
            record["_external"] = True
            record["_external_file"] = str(external_path)
            if normalize(record.get("review_status")).lower() != "approved":
                record["_not_approved"] = True
            else:
                external_approved_records += 1
            records.append(record)

    accepted = []
    rejected = []
    seen_pairs = set()
    rejection_reasons = Counter()

    for index, record in enumerate(records):
        thai = normalize(record.get("thai"))
        lanna = normalize(record.get("lanna"))
        reasons = []
        if record.get("_not_approved"):
            reasons.append("external_record_not_approved")
        if not thai or not lanna:
            reasons.append("empty_text")
        if "<ctrl" in lanna.lower():
            reasons.append("control_placeholder")
        if has_thai_characters(lanna):
            reasons.append("thai_character_in_lanna_target")
        if lanna and not has_tai_tham(lanna):
            reasons.append("no_tai_tham_character")
        pair = (thai, lanna)
        if pair in seen_pairs:
            reasons.append("duplicate_pair")

        if reasons:
            rejected.append({"source_index": index, "thai": thai, "lanna": lanna, "reasons": reasons})
            rejection_reasons.update(reasons)
            continue

        seen_pairs.add(pair)
        pair_id = hashlib.sha256(f"{thai}\0{lanna}".encode("utf-8")).hexdigest()[:16]
        accepted.append(
            {
                "pair_id": pair_id,
                "thai": thai,
                "lanna": lanna,
                "pronunciation": normalize(record.get("pronunciation")),
                "meaning": normalize(record.get("meaning")),
                "source_id": normalize(record.get("source_id")) or "project_dictionary",
                "source_page": record.get("source_page"),
            }
        )

    random.Random(args.seed).shuffle(accepted)
    test_count = max(1, round(len(accepted) * 0.10))
    validation_count = max(1, round(len(accepted) * 0.10))
    split_pairs = {
        "test": accepted[:test_count],
        "validation": accepted[test_count : test_count + validation_count],
        "train": accepted[test_count + validation_count :],
    }

    for split, pairs in split_pairs.items():
        rows = []
        for pair in pairs:
            rows.extend(
                [
                    {
                        "pair_id": pair["pair_id"],
                        "direction": "th_to_lanna",
                        "source": pair["thai"],
                        "target": pair["lanna"],
                        "pronunciation": pair["pronunciation"],
                        "meaning": pair["meaning"],
                        "source_id": pair["source_id"],
                        "source_page": pair["source_page"],
                    },
                    {
                        "pair_id": pair["pair_id"],
                        "direction": "lanna_to_th",
                        "source": pair["lanna"],
                        "target": pair["thai"],
                        "pronunciation": pair["pronunciation"],
                        "meaning": pair["meaning"],
                        "source_id": pair["source_id"],
                        "source_page": pair["source_page"],
                    },
                ]
            )
        with (output_dir / f"{split}.jsonl").open("w", encoding="utf-8") as handle:
            for row in rows:
                handle.write(json.dumps(row, ensure_ascii=False) + "\n")

    (output_dir / "rejected.json").write_text(
        json.dumps(rejected, ensure_ascii=False, indent=2), encoding="utf-8"
    )
    report = {
        "source_file": str(source_path),
        "seed": args.seed,
        "raw_records": len(records),
        "verified_override_records": override_count,
        "external_input_files": [str(path) for path in external_input_files],
        "external_raw_records": external_raw_records,
        "external_approved_records": external_approved_records,
        "accepted_pairs": len(accepted),
        "rejected_records": len(rejected),
        "rejection_reasons": dict(rejection_reasons),
        "pair_splits": {key: len(value) for key, value in split_pairs.items()},
        "training_rows_bidirectional": len(split_pairs["train"]) * 2,
        "warning": "This word-level dataset is suitable only for a proof of concept, not production sentence translation.",
    }
    (output_dir / "data_report.json").write_text(
        json.dumps(report, ensure_ascii=False, indent=2), encoding="utf-8"
    )
    print(json.dumps(report, ensure_ascii=False, indent=2))


if __name__ == "__main__":
    main()

from __future__ import annotations

import argparse
import json
from collections import Counter, defaultdict
from pathlib import Path


def load_jsonl(path: Path) -> list[dict]:
    return [
        json.loads(line)
        for line in path.read_text(encoding="utf-8").splitlines()
        if line.strip()
    ]


def has_thai(value: str) -> bool:
    return any(0x0E00 <= ord(character) <= 0x0E7F for character in value)


def has_tai_tham(value: str) -> bool:
    return any(0x1A20 <= ord(character) <= 0x1AAF for character in value)


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--data-dir", required=True)
    parser.add_argument("--report", required=True)
    args = parser.parse_args()

    data_dir = Path(args.data_dir)
    rows_by_split = {
        split: load_jsonl(data_dir / f"{split}.jsonl")
        for split in ("train", "validation", "test")
    }
    violations: list[dict] = []
    pair_sets = {
        split: {row["pair_id"] for row in rows}
        for split, rows in rows_by_split.items()
    }
    for left, right in (("train", "validation"), ("train", "test"), ("validation", "test")):
        overlap = pair_sets[left] & pair_sets[right]
        if overlap:
            violations.append({"type": "pair_split_leakage", "splits": [left, right], "count": len(overlap)})

    direction_counts = Counter()
    rows_per_pair: dict[tuple[str, str], list[dict]] = defaultdict(list)
    verified_greeting_found = False
    for split, rows in rows_by_split.items():
        for row in rows:
            direction = row.get("direction")
            direction_counts[f"{split}:{direction}"] += 1
            rows_per_pair[(split, row.get("pair_id", ""))].append(row)
            source = row.get("source", "")
            target = row.get("target", "")
            if direction == "th_to_lanna":
                if not has_thai(source) or not has_tai_tham(target) or has_thai(target):
                    violations.append({"type": "invalid_th_to_lanna", "pair_id": row.get("pair_id")})
                if source == "สวัสดี" and target == "ᩈ᩠ᩅᩢᩈ᩠ᨯᩦ":
                    verified_greeting_found = True
            elif direction == "lanna_to_th":
                if not has_tai_tham(source) or not has_thai(target):
                    violations.append({"type": "invalid_lanna_to_th", "pair_id": row.get("pair_id")})
            else:
                violations.append({"type": "unknown_direction", "pair_id": row.get("pair_id")})

    incomplete_pairs = [
        {"split": split, "pair_id": pair_id, "rows": len(rows)}
        for (split, pair_id), rows in rows_per_pair.items()
        if len(rows) != 2 or {row.get("direction") for row in rows} != {"th_to_lanna", "lanna_to_th"}
    ]
    violations.extend({"type": "incomplete_bidirectional_pair", **value} for value in incomplete_pairs)
    if not verified_greeting_found:
        violations.append({"type": "missing_owner_verified_greeting"})

    report = {
        "rows": {split: len(rows) for split, rows in rows_by_split.items()},
        "pairs": {split: len(pair_ids) for split, pair_ids in pair_sets.items()},
        "directions": dict(direction_counts),
        "owner_verified_greeting_found": verified_greeting_found,
        "violations": violations,
        "passed": not violations,
    }
    report_path = Path(args.report)
    report_path.parent.mkdir(parents=True, exist_ok=True)
    report_path.write_text(json.dumps(report, ensure_ascii=False, indent=2), encoding="utf-8")
    print(json.dumps(report, ensure_ascii=True, indent=2))
    if violations:
        raise SystemExit(1)


if __name__ == "__main__":
    main()

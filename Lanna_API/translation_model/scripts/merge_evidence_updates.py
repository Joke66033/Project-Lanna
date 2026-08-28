"""Replace reviewed evidence rows by Thai headword while preserving row order."""

from __future__ import annotations

import argparse
import json
from pathlib import Path


def load_jsonl(path: Path) -> list[dict]:
    return [
        json.loads(line)
        for line in path.read_text(encoding="utf-8").splitlines()
        if line.strip()
    ]


def merge_rows(base: list[dict], updates: list[dict]) -> list[dict]:
    update_by_thai = {row["thai"]: row for row in updates}
    if len(update_by_thai) != len(updates):
        raise ValueError("Update Thai headwords are not unique")
    merged = []
    seen = set()
    for row in base:
        thai = row["thai"]
        merged.append(update_by_thai.get(thai, row))
        seen.add(thai)
    merged.extend(row for row in updates if row["thai"] not in seen)
    return merged


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--base", required=True, type=Path)
    parser.add_argument("--updates", required=True, type=Path)
    parser.add_argument("--output", required=True, type=Path)
    args = parser.parse_args()
    merged = merge_rows(load_jsonl(args.base), load_jsonl(args.updates))
    args.output.parent.mkdir(parents=True, exist_ok=True)
    with args.output.open("w", encoding="utf-8") as handle:
        for row in merged:
            handle.write(json.dumps(row, ensure_ascii=False) + "\n")
    print(json.dumps({"rows": len(merged)}, ensure_ascii=True))


if __name__ == "__main__":
    main()

"""Export only verified source records and verified aliases for runtime lookup."""

from __future__ import annotations

import argparse
import json
from pathlib import Path


SOURCE_VERIFIED = {"source_image_verified", "owner_verified", "expert_verified"}


def export_rows(rows: list[dict]) -> list[dict]:
    exported: list[dict] = []
    seen: set[str] = set()
    for row in rows:
        status = row.get("verification_status")
        if status not in SOURCE_VERIFIED | {"verified_alias_to_source"}:
            continue
        thai = row["thai"]
        if thai in seen:
            raise ValueError(f"Duplicate runtime lookup key: {thai}")
        is_alias = status == "verified_alias_to_source"
        lanna = row.get("canonical_lanna") if is_alias else row.get("lanna")
        if not lanna:
            raise ValueError(f"Verified runtime row has no output: {thai}")
        evidence = row.get("pdf_evidence", {})
        exported.append({
            "thai": thai,
            "lanna": lanna,
            "pronunciation": row.get("pronunciation", ""),
            "definition": row.get("meaning", ""),
            "category": row.get("category", "คำศัพท์ทั่วไป"),
            "source_type": status,
            "source_id": row.get("source_id", ""),
            "source_pdf_page": (
                evidence.get("canonical_verified_page") if is_alias
                else evidence.get("verified_page")
            ),
            "canonical_thai": row.get("canonical_thai") if is_alias else thai,
            "is_alias": is_alias,
            "alias_relation": row.get("alias_relation") if is_alias else None,
            "needs_review": False,
            "senses": row.get("senses", []),
            "lanna_variants": row.get("lanna_variants", []),
        })
        seen.add(thai)
    exported.sort(key=lambda item: item["thai"])
    return exported


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--evidence", required=True, nargs="+", type=Path)
    parser.add_argument("--output", required=True, type=Path)
    args = parser.parse_args()
    rows = []
    for path in args.evidence:
        rows.extend(json.loads(line) for line in path.read_text(encoding="utf-8").splitlines() if line)
    exported = export_rows(rows)
    args.output.parent.mkdir(parents=True, exist_ok=True)
    args.output.write_text(json.dumps(exported, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
    print(json.dumps({
        "input_rows": len(rows),
        "runtime_rows": len(exported),
        "source_headwords": sum(not item["is_alias"] for item in exported),
        "aliases": sum(item["is_alias"] for item in exported),
    }, ensure_ascii=False, indent=2))


if __name__ == "__main__":
    main()

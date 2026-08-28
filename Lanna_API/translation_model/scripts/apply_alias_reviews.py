"""Link a searchable non-headword alias to a verified dictionary headword."""

from __future__ import annotations

import argparse
import json
from pathlib import Path


VERIFIED_TARGETS = {"source_image_verified", "owner_verified", "expert_verified"}


def apply_aliases(rows: list[dict], aliases: list[dict]) -> int:
    by_thai = {row["thai"]: row for row in rows}
    if len(by_thai) != len(rows):
        raise ValueError("Thai headwords are not unique")
    count = 0
    for decision in aliases:
        alias = by_thai.get(decision["alias_thai"])
        target = by_thai.get(decision["canonical_thai"])
        if alias is None or target is None:
            raise ValueError(f"Alias or canonical target is missing: {decision}")
        if alias.get("verification_status") != "auto_checked_needs_expert":
            raise ValueError(f"Alias is not pending: {alias['thai']}")
        if target.get("verification_status") not in VERIFIED_TARGETS:
            raise ValueError(f"Canonical target is not source verified: {target['thai']}")
        alias["verification_status"] = "verified_alias_to_source"
        alias["canonical_thai"] = target["thai"]
        alias["canonical_lanna"] = target["lanna"]
        alias["alias_relation"] = decision.get("relation", "semantic_alias")
        alias["alias_review_note"] = decision.get("note", "")
        alias["category"] = target["category"]
        alias["category_confidence"] = 1.0
        alias["category_reviewed"] = True
        alias["category_review_source"] = "canonical_source_headword"
        evidence = alias.setdefault("pdf_evidence", {})
        evidence["canonical_source_id"] = target.get("source_id")
        evidence["canonical_verified_page"] = target.get("pdf_evidence", {}).get("verified_page")
        evidence["alias_verified"] = True
        evidence["visually_verified"] = False
        evidence["review_note"] = decision.get("note", "")
        count += 1
    return count


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--evidence", required=True, type=Path)
    parser.add_argument("--aliases", required=True, type=Path)
    parser.add_argument("--output", required=True, type=Path)
    args = parser.parse_args()
    rows = [json.loads(line) for line in args.evidence.read_text(encoding="utf-8").splitlines() if line]
    aliases = json.loads(args.aliases.read_text(encoding="utf-8"))
    count = apply_aliases(rows, aliases)
    args.output.parent.mkdir(parents=True, exist_ok=True)
    with args.output.open("w", encoding="utf-8") as handle:
        for row in rows:
            handle.write(json.dumps(row, ensure_ascii=False) + "\n")
    print(json.dumps({"rows": len(rows), "aliases_verified": count}, ensure_ascii=False, indent=2))


if __name__ == "__main__":
    main()

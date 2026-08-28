"""Append newly verified dictionary senses to an existing reviewed headword."""

from __future__ import annotations

import argparse
import json
from pathlib import Path


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--evidence", required=True, type=Path)
    parser.add_argument("--records", required=True, type=Path)
    parser.add_argument("--output", required=True, type=Path)
    args = parser.parse_args()
    rows = [json.loads(line) for line in args.evidence.read_text(encoding="utf-8").splitlines() if line]
    by_thai = {row["thai"]: row for row in rows}
    additions = json.loads(args.records.read_text(encoding="utf-8"))
    for addition in additions:
        thai = addition["thai"]
        row = by_thai.get(thai)
        if row is None:
            raise ValueError(f"Existing source headword not found: {thai}")
        if row["lanna"] != addition["lanna"]:
            if not addition.get("replace_lanna"):
                raise ValueError(f"Conflicting Lanna spelling for {thai}")
            variants = row.setdefault("lanna_variants", [])
            old_variant = {"lanna": row["lanna"], "source_page": row["source_page"]}
            if old_variant not in variants:
                variants.append(old_variant)
            row["lanna"] = addition["lanna"]
            new_variant = {"lanna": row["lanna"], "source_page": int(addition["canonical_source_page"])}
            if new_variant not in variants:
                variants.append(new_variant)
        senses = row.get("senses")
        if not senses:
            old_pos, separator, old_meaning = row["meaning"].partition(" ")
            senses = [{
                "sense_no": 1,
                "part_of_speech": old_pos if separator and old_pos.endswith(".") else "ไม่ระบุ",
                "pronunciation": row["pronunciation"],
                "meaning": old_meaning if separator and old_pos.endswith(".") else row["meaning"],
                "category": row["category"],
                "source_page": row["source_page"],
            }]
        for sense in addition["senses"]:
            sense = dict(sense)
            sense["sense_no"] = len(senses) + 1
            senses.append(sense)
        row["senses"] = senses
        row["meaning"] = "; ".join(f'{sense["part_of_speech"]} {sense["meaning"]}' for sense in senses)
        pronunciations = list(dict.fromkeys(sense["pronunciation"] for sense in senses))
        row["pronunciation"] = "; ".join(pronunciations)
        pages = {int(row["source_page"]), *(int(sense["source_page"]) for sense in senses)}
        evidence = row.setdefault("pdf_evidence", {})
        pages.update(int(page) for page in evidence.get("verified_pages", []))
        if evidence.get("verified_page") is not None:
            pages.add(int(evidence["verified_page"]))
        evidence["verified_pages"] = sorted(pages)
        evidence["context_pages"] = sorted(pages)
        evidence["review_note"] = addition.get("note", evidence.get("review_note", ""))
    args.output.parent.mkdir(parents=True, exist_ok=True)
    with args.output.open("w", encoding="utf-8") as handle:
        for row in rows:
            handle.write(json.dumps(row, ensure_ascii=False) + "\n")
    print(json.dumps({"rows": len(rows), "headwords_extended": len(additions)}, ensure_ascii=False))


if __name__ == "__main__":
    main()

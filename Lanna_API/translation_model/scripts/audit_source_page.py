"""Audit that an explicitly transcribed source page is complete and verified."""

from __future__ import annotations

import argparse
import json
from pathlib import Path


VERIFIED = {"source_image_verified", "owner_verified", "expert_verified"}


def audit_page(rows: list[dict], manifest: dict) -> dict:
    page = int(manifest["pdf_page"])
    expected = manifest["headwords"]
    if len(expected) != len(set(expected)):
        raise ValueError("Page manifest contains duplicate headwords")
    by_thai = {row["thai"]: row for row in rows}
    missing = [thai for thai in expected if thai not in by_thai]
    unverified = [
        thai for thai in expected
        if thai in by_thai and by_thai[thai].get("verification_status") not in VERIFIED
    ]
    wrong_page = []
    for thai in expected:
        row = by_thai.get(thai)
        if not row or row.get("verification_status") not in VERIFIED:
            continue
        evidence = row.get("pdf_evidence", {})
        row_pages = {evidence.get("verified_page")}
        row_pages.update(evidence.get("verified_pages", []))
        row_pages.update(sense.get("source_page") for sense in row.get("senses", []))
        if page not in row_pages:
            wrong_page.append(thai)
    verified = len(expected) - len(set(missing + unverified + wrong_page))
    expected_senses = manifest.get("senses", {})
    missing_senses = []
    normalized_senses = {}
    for thai, specification in expected_senses.items():
        if isinstance(specification, int):
            normalized_senses[thai] = {"count": specification, "page_sense_nos": []}
        else:
            normalized_senses[thai] = specification
    for thai, specification in normalized_senses.items():
        count = int(specification["count"])
        row = by_thai.get(thai)
        senses = row.get("senses", []) if row else []
        actual = len(senses)
        required_for_page = set(specification.get("page_sense_nos", []))
        present_for_page = {
            sense.get("sense_no") for sense in senses
            if sense.get("source_page") == page
        }
        if actual != count or not required_for_page.issubset(present_for_page):
            missing_senses.append({
                "thai": thai,
                "expected": count,
                "actual": actual,
                "required_for_page": sorted(required_for_page),
                "present_for_page": sorted(present_for_page),
            })
    def entries_on_page(thai: str) -> int:
        specification = normalized_senses.get(thai)
        if not specification:
            return 1
        if "entry_count_on_page" in specification:
            return int(specification["entry_count_on_page"])
        page_sense_nos = specification.get("page_sense_nos", [])
        return len(page_sense_nos) if page_sense_nos else int(specification["count"])

    expected_entries = sum(entries_on_page(thai) for thai in expected)
    invalid_headwords = set(missing + unverified + wrong_page)
    invalid_headwords.update(item["thai"] for item in missing_senses)
    verified_entries = sum(entries_on_page(thai) for thai in expected if thai not in invalid_headwords)
    return {
        "pdf_page": page,
        "expected_headwords": len(expected),
        "verified_headwords": verified,
        "expected_entries": expected_entries,
        "verified_entries": verified_entries,
        "missing": missing,
        "unverified": unverified,
        "wrong_verified_page": wrong_page,
        "missing_senses": missing_senses,
        "complete": not missing and not unverified and not wrong_page and not missing_senses,
        "review_note": manifest.get("review_note", ""),
    }


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--evidence", required=True, type=Path)
    parser.add_argument("--manifest", required=True, type=Path)
    parser.add_argument("--output", required=True, type=Path)
    args = parser.parse_args()
    rows = [json.loads(line) for line in args.evidence.read_text(encoding="utf-8").splitlines() if line]
    manifest = json.loads(args.manifest.read_text(encoding="utf-8"))
    report = audit_page(rows, manifest)
    args.output.parent.mkdir(parents=True, exist_ok=True)
    args.output.write_text(json.dumps(report, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
    print(json.dumps(report, ensure_ascii=False, indent=2))
    if not report["complete"]:
        raise SystemExit(2)


if __name__ == "__main__":
    main()

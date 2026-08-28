"""Create a reproducible progress report for one reviewed initial."""

from __future__ import annotations

import argparse
from collections import Counter
import json
from pathlib import Path


def summarize(rows: list[dict]) -> dict:
    statuses = Counter(row.get("verification_status", "missing") for row in rows)
    search_statuses = Counter(row.get("source_search_status", "missing") for row in rows)
    verified = [
        row for row in rows
        if row.get("verification_status") in {"source_image_verified", "owner_verified", "expert_verified"}
    ]
    aliases = [row for row in rows if row.get("verification_status") == "verified_alias_to_source"]
    return {
        "rows": len(rows),
        "verification_statuses": dict(sorted(statuses.items())),
        "source_search_statuses": dict(sorted(search_statuses.items())),
        "verified_rows": len(verified),
        "verified_alias_rows": len(aliases),
        "verified_with_reviewed_category": sum(bool(row.get("category_reviewed")) for row in verified),
        "verified_without_reviewed_category": sum(not row.get("category_reviewed") for row in verified),
        "reviewed_category_counts": dict(sorted(Counter(
            row.get("category", "missing") for row in verified if row.get("category_reviewed")
        ).items())),
        "false_positive_pdf_pages": sum(
            len(row.get("pdf_evidence", {}).get("false_positive_pages", [])) for row in rows
        ),
        "pending_with_page_suggestions": sum(
            row.get("verification_status") == "auto_checked_needs_expert"
            and bool(row.get("pdf_evidence", {}).get("suggested_pages"))
            for row in rows
        ),
    }


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--evidence", required=True, type=Path)
    parser.add_argument("--output", required=True, type=Path)
    args = parser.parse_args()
    rows = [json.loads(line) for line in args.evidence.read_text(encoding="utf-8").splitlines() if line]
    report = summarize(rows)
    args.output.parent.mkdir(parents=True, exist_ok=True)
    args.output.write_text(json.dumps(report, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
    print(json.dumps(report, ensure_ascii=False, indent=2))


if __name__ == "__main__":
    main()

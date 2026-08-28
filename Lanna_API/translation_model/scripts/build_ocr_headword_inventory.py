"""Extract likely printed headwords from column OCR for manual review routing.

OCR output is never treated as linguistic verification. The generated inventory
only points a reviewer to source pages that must still be checked visually.
"""

from __future__ import annotations

import argparse
from difflib import SequenceMatcher
import json
from pathlib import Path
import re
import unicodedata


THAI_RUN = r"[\u0E01-\u0E7F]+"
HEADWORD = re.compile(rf"^[\s|¦ๅๆ0-9๑-๙.)]*(?P<word>{THAI_RUN})\s{{2,}}")


def normalize(value: str) -> str:
    value = unicodedata.normalize("NFC", value)
    return "".join(char for char in value if "\u0e01" <= char <= "\u0e7f")


def extract_headwords(text: str) -> list[dict]:
    found: list[dict] = []
    seen: set[tuple[str, int]] = set()
    lines = text.splitlines()
    matches: list[tuple[int, re.Match]] = []
    for index, line in enumerate(lines, start=1):
        match = HEADWORD.match(line)
        if not match:
            continue
        matches.append((index, match))
    for position, (index, match) in enumerate(matches):
        line = lines[index - 1]
        word = normalize(match.group("word"))
        # Single-character items are usually page furniture or OCR noise.
        if len(word) < 2:
            continue
        # Headword rows normally introduce a reading, part of speech, or glyph.
        next_index = matches[position + 1][0] - 1 if position + 1 < len(matches) else len(lines)
        context_end = min(next_index, index + 7)
        context = " ".join(lines[index - 1:context_end])
        if "[" not in context and not re.search(r"\b[นกวส]\s*[.๑๒]", context):
            continue
        key = (word, index)
        if key not in seen:
            found.append({"ocr_headword": word, "line": index, "ocr_context": context.strip()})
            seen.add(key)
    return found


def semantic_tokens(value: str) -> list[str]:
    tokens = re.findall(THAI_RUN, unicodedata.normalize("NFC", value))
    ignored = {"และ", "หรือ", "เรียกว่า", "หมายถึง", "ชนิดหนึ่ง", "ลักษณะ", "เช่น", "เป็น", "ที่", "ของ", "ใช้"}
    result = []
    for token in tokens:
        if len(normalize(token)) >= 3 and token not in ignored and token not in result:
            result.append(token)
    return result[:20]


def containment_score(value: str, context: str) -> float:
    tokens = semantic_tokens(value)
    normalized_context = normalize(context)
    if not tokens or not normalized_context:
        return 0.0
    return sum(normalize(token) in normalized_context for token in tokens) / len(tokens)


def rank_candidates(
    thai: str,
    inventory: list[dict],
    meaning: str = "",
    pronunciation: str = "",
    limit: int = 5,
) -> list[dict]:
    target = normalize(thai)
    ranked = []
    for item in inventory:
        candidate = normalize(item["ocr_headword"])
        headword_score = SequenceMatcher(None, target, candidate).ratio()
        if target == candidate:
            headword_score = 1.0
        elif target in candidate or candidate in target:
            headword_score = max(headword_score, min(len(target), len(candidate)) / max(len(target), len(candidate)))
        if headword_score >= 0.45:
            meaning_score = containment_score(meaning, item.get("ocr_context", ""))
            reading_score = containment_score(pronunciation, item.get("ocr_context", ""))
            score = 0.65 * headword_score + 0.25 * meaning_score + 0.10 * reading_score
            ranked.append({
                **item,
                "score": round(score, 4),
                "headword_score": round(headword_score, 4),
                "meaning_score": round(meaning_score, 4),
                "reading_score": round(reading_score, 4),
            })
    ranked.sort(key=lambda item: (-item["score"], -item["headword_score"], item["pdf_page"], item["line"]))
    return ranked[:limit]


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--ocr-dir", required=True, type=Path)
    parser.add_argument("--evidence", required=True, type=Path)
    parser.add_argument("--inventory-output", required=True, type=Path)
    parser.add_argument("--suggestions-output", required=True, type=Path)
    args = parser.parse_args()

    inventory: list[dict] = []
    for path in sorted(args.ocr_dir.glob("page-*.txt")):
        page = int(path.stem.split("-")[-1])
        for item in extract_headwords(path.read_text(encoding="utf-8")):
            inventory.append({"pdf_page": page, **item})

    rows = [json.loads(line) for line in args.evidence.read_text(encoding="utf-8").splitlines() if line]
    suggestions = []
    for row in rows:
        if row.get("verification_status") != "auto_checked_needs_expert":
            continue
        candidates = rank_candidates(
            row["thai"], inventory,
            meaning=row.get("meaning", ""),
            pronunciation=row.get("pronunciation", ""),
        )
        if candidates:
            suggestions.append({"thai": row["thai"], "candidates": candidates})

    args.inventory_output.parent.mkdir(parents=True, exist_ok=True)
    args.suggestions_output.parent.mkdir(parents=True, exist_ok=True)
    args.inventory_output.write_text(json.dumps(inventory, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
    args.suggestions_output.write_text(json.dumps(suggestions, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
    print(json.dumps({"inventory_rows": len(inventory), "pending_with_candidates": len(suggestions)}, indent=2))


if __name__ == "__main__":
    main()

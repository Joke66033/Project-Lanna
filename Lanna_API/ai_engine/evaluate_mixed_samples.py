"""Evaluate curated labelled words, negatives, and transparent samples."""

from __future__ import annotations

import json
from pathlib import Path

import numpy as np

from evaluate_field_signs import crop_by_ratio, read_image
from lanna_ocr import LannaOCR


ROOT = Path(__file__).resolve().parent / "evaluation_samples" / "field_mixed"


def normalized(text: str) -> str:
    return "".join(character for character in text if not character.isspace())


def main() -> None:
    manifest = json.loads((ROOT / "manifest.json").read_text(encoding="utf-8"))
    ocr = LannaOCR()
    results = []
    for sample in manifest:
        image = crop_by_ratio(read_image(ROOT / sample["file"]), sample["crop"])
        result = ocr.recognize(image)
        expected = sample["expected_thai"]
        exact = (
            normalized(result.thai_text) == normalized(expected)
            if sample["kind"] == "labeled_word" and expected
            else None
        )
        results.append({
            **sample,
            "candidate_text": result.thai_text,
            "mean_confidence": round(result.confidence, 6),
            "component_count": len(result.characters),
            "accepted_at_0_65": not result.is_low_confidence,
            "exact_word_match": exact,
        })

    labeled = [item for item in results if item["kind"] == "labeled_word"]
    negatives = [item for item in results if item["kind"] == "negative"]
    output = ROOT / "baseline_results.json"
    output.write_text(
        json.dumps(results, ensure_ascii=False, indent=2),
        encoding="utf-8",
    )
    print(json.dumps({
        "curated_crop_count": len(results),
        "labeled_word_count": len(labeled),
        "exact_word_matches": sum(bool(item["exact_word_match"]) for item in labeled),
        "accepted_labeled_words": sum(item["accepted_at_0_65"] for item in labeled),
        "rejected_negatives": sum(not item["accepted_at_0_65"] for item in negatives),
        "mean_labeled_confidence": round(float(np.mean([
            item["mean_confidence"] for item in labeled
        ])), 6),
        "output": str(output),
    }, ensure_ascii=True))


if __name__ == "__main__":
    main()


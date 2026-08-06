"""Run the real-world sign regression set without treating context as labels."""

from __future__ import annotations

import json
from pathlib import Path

import cv2
import numpy as np

from lanna_ocr import LannaOCR


ROOT = Path(__file__).resolve().parent / "evaluation_samples" / "field_signs"


def read_image(path: Path) -> np.ndarray:
    encoded = np.fromfile(str(path), dtype=np.uint8)
    image = cv2.imdecode(encoded, cv2.IMREAD_UNCHANGED)
    if image is None:
        raise ValueError(f"Unreadable image: {path}")
    if image.ndim == 2:
        image = cv2.cvtColor(image, cv2.COLOR_GRAY2BGR)
    elif image.shape[2] == 4:
        color = image[:, :, :3].astype(np.float32)
        alpha = image[:, :, 3:4].astype(np.float32) / 255.0
        image = (color * alpha + 255.0 * (1.0 - alpha)).astype(np.uint8)
    return image


def crop_by_ratio(image: np.ndarray, ratios: list[float]) -> np.ndarray:
    x1, y1, x2, y2 = ratios
    height, width = image.shape[:2]
    return image[
        int(height * y1) : int(height * y2),
        int(width * x1) : int(width * x2),
    ]


def main() -> None:
    manifest = json.loads((ROOT / "manifest.json").read_text(encoding="utf-8"))
    ocr = LannaOCR()
    results = []
    for sample in manifest:
        image = read_image(ROOT / sample["file"])
        crop = crop_by_ratio(image, sample["crop"])
        result = ocr.recognize(crop)
        results.append({
            **sample,
            "candidate_text": result.thai_text,
            "mean_confidence": round(result.confidence, 6),
            "minimum_confidence": round(
                min(item.confidence for item in result.characters),
                6,
            ),
            "component_count": len(result.characters),
            "accepted_at_0_65": not result.is_low_confidence,
        })
    output = ROOT / "baseline_results.json"
    output.write_text(
        json.dumps(results, ensure_ascii=False, indent=2),
        encoding="utf-8",
    )
    print(json.dumps({
        "sample_count": len(results),
        "independent_groups": len({item["group"] for item in results}),
        "accepted_count": sum(item["accepted_at_0_65"] for item in results),
        "mean_confidence": round(
            float(np.mean([item["mean_confidence"] for item in results])),
            6,
        ),
        "output": str(output),
    }, ensure_ascii=True))


if __name__ == "__main__":
    main()

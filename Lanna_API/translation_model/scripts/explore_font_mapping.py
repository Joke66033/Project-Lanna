from __future__ import annotations

import hashlib
import json
from collections import defaultdict
from pathlib import Path

import numpy as np
from fontTools.pens.recordingPen import DecomposingRecordingPen
from fontTools.ttLib import TTFont
from PIL import Image, ImageDraw, ImageFont
from scipy.ndimage import distance_transform_edt


LEGACY_FONT = Path(r"C:\tmp\LN_TILOK_V6_05.TTF")
UNICODE_FONT = Path(r"C:\tmp\Pali_Tilok.ttf")


def render_mask(font_path: Path, character: str, size: int = 180) -> np.ndarray | None:
    font = ImageFont.truetype(str(font_path), size=size)
    canvas = Image.new("L", (size * 3, size * 3), 0)
    draw = ImageDraw.Draw(canvas)
    draw.text((size, size), character, font=font, fill=255, anchor="mm")
    bbox = canvas.getbbox()
    if not bbox:
        return None
    crop = canvas.crop(bbox)
    width, height = crop.size
    scale = min(88 / max(width, 1), 88 / max(height, 1))
    resized = crop.resize(
        (max(1, round(width * scale)), max(1, round(height * scale))),
        Image.Resampling.LANCZOS,
    )
    normalized = Image.new("L", (96, 96), 0)
    normalized.paste(resized, ((96 - resized.width) // 2, (96 - resized.height) // 2))
    return np.asarray(normalized) >= 96


def chamfer_score(first: np.ndarray, second: np.ndarray) -> float:
    first_distance = distance_transform_edt(~first)
    second_distance = distance_transform_edt(~second)
    return float(
        (second_distance[first].mean() if first.any() else 100)
        + (first_distance[second].mean() if second.any() else 100)
    )


def outline_signature(font: TTFont, glyph_name: str) -> str:
    glyph_set = font.getGlyphSet()
    pen = DecomposingRecordingPen(glyph_set)
    glyph_set[glyph_name].draw(pen)

    points = []
    for _, operands in pen.value:
        for operand in operands:
            if isinstance(operand, tuple) and len(operand) == 2:
                points.append(operand)

    if not points:
        return ""

    min_x = min(point[0] for point in points)
    min_y = min(point[1] for point in points)
    upem = font["head"].unitsPerEm
    normalized = []
    for command, operands in pen.value:
        normalized_operands = []
        for operand in operands:
            if isinstance(operand, tuple) and len(operand) == 2:
                normalized_operands.append(
                    (
                        round((operand[0] - min_x) / upem, 5),
                        round((operand[1] - min_y) / upem, 5),
                    )
                )
            else:
                normalized_operands.append(operand)
        normalized.append((command, normalized_operands))

    return hashlib.sha256(repr(normalized).encode("utf-8")).hexdigest()


def main() -> None:
    legacy = TTFont(LEGACY_FONT)
    unicode_font = TTFont(UNICODE_FONT)
    legacy_cmap = legacy.getBestCmap()
    unicode_cmap = unicode_font.getBestCmap()

    unicode_by_signature: dict[str, list[int]] = defaultdict(list)
    for codepoint, glyph_name in unicode_cmap.items():
        if 0x1A20 <= codepoint <= 0x1AAF:
            signature = outline_signature(unicode_font, glyph_name)
            if signature:
                unicode_by_signature[signature].append(codepoint)

    matches = {}
    ambiguous = {}
    for codepoint, glyph_name in legacy_cmap.items():
        if not (0x20 <= codepoint <= 0xFFFF):
            continue
        candidates = unicode_by_signature.get(outline_signature(legacy, glyph_name), [])
        if len(candidates) == 1:
            matches[codepoint] = candidates[0]
        elif candidates:
            ambiguous[codepoint] = candidates

    unicode_masks = {
        codepoint: render_mask(UNICODE_FONT, chr(codepoint))
        for codepoint in unicode_cmap
        if 0x1A20 <= codepoint <= 0x1AAF
    }
    fuzzy = {}
    interesting = [
        codepoint
        for codepoint in legacy_cmap
        if 0x0E01 <= codepoint <= 0x0E5B or 0x00A1 <= codepoint <= 0x00FF
    ]
    for source in interesting:
        source_mask = render_mask(LEGACY_FONT, chr(source))
        if source_mask is None:
            continue
        ranked = sorted(
            (
                (chamfer_score(source_mask, target_mask), target)
                for target, target_mask in unicode_masks.items()
                if target_mask is not None
            )
        )[:3]
        fuzzy[f"U+{source:04X} {chr(source)}"] = [
            {"target": f"U+{target:04X} {chr(target)}", "score": round(score, 3)}
            for score, target in ranked
        ]

    print(
        json.dumps(
            {
                "legacy_cmap": len(legacy_cmap),
                "unicode_tai_tham_cmap": sum(
                    0x1A20 <= codepoint <= 0x1AAF for codepoint in unicode_cmap
                ),
                "exact_unique_matches": len(matches),
                "ambiguous_matches": len(ambiguous),
                "matches": {
                    f"U+{source:04X} {chr(source)}": f"U+{target:04X} {chr(target)}"
                    for source, target in sorted(matches.items())
                },
                "fuzzy_top3": fuzzy,
            },
            ensure_ascii=False,
            indent=2,
        )
    )


if __name__ == "__main__":
    main()

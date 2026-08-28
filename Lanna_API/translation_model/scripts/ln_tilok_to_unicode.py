from __future__ import annotations

import argparse
import json
import re
import unicodedata
from functools import lru_cache
from pathlib import Path

import numpy as np
from fontTools.ttLib import TTFont
from PIL import Image, ImageDraw, ImageFont, features
from scipy.ndimage import binary_dilation


SAKOT = "\u1A60"

# LN Tilok uses Thai keyboard code points for Lanna glyphs.  These mappings
# were verified against the same outlines in the Unicode Pali Tilok font.
THAI_TO_TAI_THAM = {
    **{source: target for source, target in zip(range(0x0E01, 0x0E0E), range(0x1A20, 0x1A2D))},
    0x0E0E: 0x1A2F,
    0x0E0F: 0x1A2D,
    0x0E10: 0x1A2E,
    0x0E11: 0x1A2F,
    0x0E12: 0x1A30,
    0x0E13: 0x1A31,
    0x0E14: 0x1A2F,
    0x0E15: 0x1A32,
    0x0E16: 0x1A33,
    0x0E17: 0x1A34,
    0x0E18: 0x1A35,
    0x0E19: 0x1A36,
    0x0E1A: 0x1A37,
    0x0E1B: 0x1A38,
    0x0E1C: 0x1A39,
    0x0E1D: 0x1A3A,
    0x0E1E: 0x1A3B,
    0x0E1F: 0x1A3C,
    0x0E20: 0x1A3D,
    0x0E21: 0x1A3E,
    0x0E22: 0x1A3F,
    0x0E23: 0x1A41,
    0x0E24: 0x1A42,
    0x0E25: 0x1A43,
    0x0E26: 0x1A44,
    0x0E27: 0x1A45,
    0x0E28: 0x1A46,
    0x0E29: 0x1A47,
    0x0E2A: 0x1A48,
    0x0E2B: 0x1A49,
    0x0E2C: 0x1A4A,
    0x0E2D: 0x1A4B,
    0x0E2E: 0x1A4C,
    0x0E30: 0x1A61,
    0x0E31: 0x1A62,
    0x0E32: 0x1A63,
    0x0E34: 0x1A65,
    0x0E35: 0x1A66,
    0x0E36: 0x1A67,
    0x0E37: 0x1A68,
    0x0E38: 0x1A69,
    0x0E39: 0x1A6A,
    0x0E3A: 0x1A7F,
    0x0E3F: 0x1A6B,
    0x0E40: 0x1A6E,
    0x0E41: 0x1A6F,
    0x0E42: 0x1A70,
    0x0E43: 0x1A72,
    0x0E44: 0x1A71,
    0x0E45: 0x1A64,
    0x0E46: 0x1A7B,
    0x0E47: 0x1A62,
    0x0E48: 0x1A75,
    0x0E49: 0x1A76,
    0x0E4A: 0x1A74,
    0x0E4B: 0x1A73,
    0x0E4C: 0x1A7A,
    0x0E4D: 0x1A74,
    **{source: target for source, target in zip(range(0x0E50, 0x0E5A), range(0x1A90, 0x1A9A))},
    0x0E5A: 0x1AAB,
}

SPECIAL_TO_TAI_THAM = {
    0x00A2: 0x1A36,  # C.NAA
    0x00A3: 0x1A40,  # C.AAYA
    0x00A6: 0x1A53,  # C.LAE1
    0x00AA: 0x1A54,  # C.SASA
    0x00B1: 0x1A4D,  # V.I
    0x00B2: 0x1A4E,  # V.II
    0x00B3: 0x1A4F,  # V.U
    0x00B4: 0x1A50,  # V.UU
    0x00B6: 0x1A64,  # V.KAWONG
    0x00B7: 0x1A58,  # V.KANGLAI
    0x00B8: 0x1A58,
    0x00BA: 0x1A58,
    0x00BB: 0x1A58,
}

# Reverse map for displaying Unicode database values with LN-TILOK-6.10.ttf.
TAI_THAM_TO_LEGACY = {}
for _legacy, _tai in {**THAI_TO_TAI_THAM, **SPECIAL_TO_TAI_THAM}.items():
    TAI_THAM_TO_LEGACY.setdefault(_tai, _legacy)
TAI_THAM_TO_LEGACY[0x1A60] = 0x0E2F  # SAKOT / LN-TILOK paiyannoi key


def convert_tai_tham_to_ln_tilok(value: str) -> tuple[str, list[str]]:
    """Convert Unicode Tai Tham text to LN-TILOK legacy keyboard codes."""
    output: list[str] = []
    warnings: list[str] = []
    for character in unicodedata.normalize("NFC", value or ""):
        codepoint = ord(character)
        legacy = TAI_THAM_TO_LEGACY.get(codepoint)
        if legacy is None:
            output.append(character)
            if codepoint >= 0x1A20 and codepoint <= 0x1AAF:
                warnings.append(f"unmapped_U+{codepoint:04X}")
        else:
            output.append(chr(legacy))
    return "".join(output), sorted(set(warnings))

CONSONANTS = set(range(0x1A20, 0x1A55))
MOVE_AFTER_SUBJOINED = {0x1A62, 0x1A65, 0x1A66, 0x1A67, 0x1A68}
GLYPH_BASE_RE = re.compile(r"(?:^|\.)E([0-9A-F]{2})(?:\.|$)", re.IGNORECASE)


def _insert_subjoined(output: list[str], consonant: str, warnings: list[str]) -> None:
    movable = []
    while output and ord(output[-1]) in MOVE_AFTER_SUBJOINED:
        movable.append(output.pop())
    output.extend([SAKOT, consonant])
    output.extend(reversed(movable))


def convert_ln_tilok(
    value: str,
    legacy_font_path: str | Path | None = None,
) -> tuple[str, list[str]]:
    cmap = None
    if legacy_font_path:
        cmap = TTFont(str(legacy_font_path), lazy=True).getBestCmap()

    output: list[str] = []
    warnings: list[str] = []
    source_text = unicodedata.normalize("NFC", value or "")
    source_index = 0
    while source_index < len(source_text):
        source_character = source_text[source_index]
        source = ord(source_character)

        # LN TILOK types the visual medial-ra sign with the legacy key sequence
        # "ระฯ" *before* its host consonant.  Unicode Tai Tham instead stores
        # the host first and U+1A55 MEDIAL RA after it.  For example the source
        # dictionary encodes ครก as "ระฯค฿กฯ", which must become
        # KHA + MEDIAL RA + O + SAKOT + KA, not an independent leading "ra".
        if (
            source_text.startswith("ระฯ", source_index)
            and source_index + 3 < len(source_text)
            and ord(source_text[source_index + 3]) in THAI_TO_TAI_THAM
            and THAI_TO_TAI_THAM[ord(source_text[source_index + 3])] in CONSONANTS
        ):
            output.extend(
                [
                    chr(THAI_TO_TAI_THAM[ord(source_text[source_index + 3])]),
                    "\u1A55",
                ]
            )
            source_index += 4
            continue

        # LN TILOK uses the Thai SARA AM key for the Lanna /am/ cluster.
        # Tai Tham has no precomposed AM character; Unicode encodes it as
        # VOWEL SIGN AA followed by SIGN MAI KANG (L2/19-365).
        if source == 0x0E33:
            output.extend(["\u1A63", "\u1A74"])
            source_index += 1
            continue

        # Keep text that is already encoded as Unicode Tai Tham unchanged.
        # Some dictionary rows mix legacy LN Tilok code points with Unicode.
        if 0x1A20 <= source <= 0x1AAF:
            output.append(source_character)
            source_index += 1
            continue

        if source == 0x0E2F:  # paiyannoi is the LN Tilok subjoining control
            target_index = next(
                (index for index in range(len(output) - 1, -1, -1) if ord(output[index]) in CONSONANTS),
                None,
            )
            if target_index is None:
                warnings.append("orphan_subjoining_control")
                source_index += 1
                continue
            consonant = output.pop(target_index)
            movable = []
            while target_index > 0 and ord(output[target_index - 1]) in MOVE_AFTER_SUBJOINED:
                movable.append(output.pop(target_index - 1))
                target_index -= 1
            output[target_index:target_index] = [SAKOT, consonant, *reversed(movable)]
            source_index += 1
            continue

        target = THAI_TO_TAI_THAM.get(source) or SPECIAL_TO_TAI_THAM.get(source)
        if target:
            output.append(chr(target))
            source_index += 1
            continue

        glyph_name = cmap.get(source) if cmap else None
        glyph_match = GLYPH_BASE_RE.search(glyph_name or "")
        if glyph_match:
            base_source = 0x0E00 + int(glyph_match.group(1), 16)
            base_target = THAI_TO_TAI_THAM.get(base_source)
            if base_target:
                if (glyph_name or "").startswith(("t1.", "t2.", "t3.")):
                    _insert_subjoined(output, chr(base_target), warnings)
                else:
                    output.append(chr(base_target))
                source_index += 1
                continue

        if source_character.isspace() or source_character in ",;:()[]{}-/":
            output.append(source_character)
        else:
            warnings.append(f"unmapped_U+{source:04X}")
        source_index += 1

    converted = unicodedata.normalize("NFC", "".join(output)).strip()
    if not any(0x1A20 <= ord(character) <= 0x1AAF for character in converted):
        warnings.append("no_tai_tham_output")
    return converted, sorted(set(warnings))


@lru_cache(maxsize=8)
def _load_font(font_path: str, size: int, layout: int) -> ImageFont.FreeTypeFont:
    return ImageFont.truetype(font_path, size=size, layout_engine=layout)


def _render_text(font_path: str | Path, text: str, size: int = 180) -> np.ndarray | None:
    layout = ImageFont.Layout.RAQM if features.check_feature("raqm") else ImageFont.Layout.BASIC
    font = _load_font(str(font_path), size, int(layout))
    canvas = Image.new("L", (max(600, size * max(4, len(text))), size * 3), 0)
    draw = ImageDraw.Draw(canvas)
    bbox = draw.textbbox((20, size), text, font=font)
    draw.text((20 - bbox[0], size - bbox[1]), text, font=font, fill=255)
    crop_bbox = canvas.getbbox()
    if not crop_bbox:
        return None
    crop = canvas.crop(crop_bbox)
    target_height = 128
    target_width = max(1, round(crop.width * target_height / crop.height))
    return np.asarray(crop.resize((target_width, target_height), Image.Resampling.LANCZOS)) >= 96


def visual_similarity(
    legacy_text: str,
    unicode_text: str,
    legacy_font_path: str | Path,
    unicode_font_path: str | Path,
) -> float:
    legacy = _render_text(legacy_font_path, legacy_text)
    unicode = _render_text(unicode_font_path, unicode_text)
    if legacy is None or unicode is None:
        return 0.0
    width = max(legacy.shape[1], unicode.shape[1])
    if min(legacy.shape[1], unicode.shape[1]) / width < 0.75:
        return 0.0
    first = np.zeros((128, width), dtype=bool)
    second = np.zeros((128, width), dtype=bool)
    first[:, : legacy.shape[1]] = legacy
    second[:, : unicode.shape[1]] = unicode
    first_dilated = binary_dilation(first, iterations=2)
    second_dilated = binary_dilation(second, iterations=2)
    first_coverage = float(second_dilated[first].mean()) if first.any() else 0.0
    second_coverage = float(first_dilated[second].mean()) if second.any() else 0.0
    return min(first_coverage, second_coverage)


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("text")
    parser.add_argument("--legacy-font")
    parser.add_argument("--unicode-font")
    args = parser.parse_args()
    converted, warnings = convert_ln_tilok(args.text, args.legacy_font)
    result = {"input": args.text, "output": converted, "warnings": warnings}
    if args.legacy_font and args.unicode_font:
        result["visual_similarity"] = round(
            visual_similarity(args.text, converted, args.legacy_font, args.unicode_font), 4
        )
    print(json.dumps(result, ensure_ascii=False))


if __name__ == "__main__":
    main()

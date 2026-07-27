"""Thai to Tai Tham transliteration backed by Aksharamukha.

Aksharamukha currently leaves a small number of Thai signs unchanged for some
Thai inputs.  The post-processing table below only replaces those residual
Thai code points with their Tai Tham Unicode equivalents.  It does not replace
or alter the source Thai text.
"""

from __future__ import annotations

import unicodedata
from dataclasses import dataclass

from aksharamukha import transliterate


TAI_THAM_START = 0x1A20
TAI_THAM_END = 0x1AAF

# Residual characters observed after Aksharamukha Thai -> TaiTham conversion.
# Values follow the Tai Tham code points already used throughout this project.
_RESIDUAL_THAI_TO_TAI_THAM = {
    "\u0e01": "\u1a20",  # ก
    "\u0e02": "\u1a21",  # ข
    "\u0e04": "\u1a23",  # ค
    "\u0e06": "\u1a25",  # ฆ
    "\u0e07": "\u1a26",  # ง
    "\u0e08": "\u1a27",  # จ
    "\u0e09": "\u1a28",  # ฉ
    "\u0e0a": "\u1a2a",  # ช
    "\u0e0b": "\u1a2b",  # ซ
    "\u0e0c": "\u1a2c",  # ฌ
    "\u0e0d": "\u1a2d",  # ญ
    "\u0e0e": "\u1a32",  # ฎ
    "\u0e0f": "\u1a30",  # ฏ
    "\u0e10": "\u1a31",  # ฐ
    "\u0e11": "\u1a33",  # ฑ
    "\u0e12": "\u1a33",  # ฒ
    "\u0e13": "\u1a34",  # ณ
    "\u0e14": "\u1a35",  # ด
    "\u0e15": "\u1a36",  # ต
    "\u0e16": "\u1a37",  # ถ
    "\u0e17": "\u1a38",  # ท
    "\u0e18": "\u1a39",  # ธ
    "\u0e19": "\u1a3b",  # น
    "\u0e1a": "\u1a3c",  # บ
    "\u0e1b": "\u1a3d",  # ป
    "\u0e1c": "\u1a3f",  # ผ
    "\u0e1d": "\u1a40",  # ฝ
    "\u0e1e": "\u1a41",  # พ
    "\u0e1f": "\u1a42",  # ฟ
    "\u0e20": "\u1a43",  # ภ
    "\u0e21": "\u1a45",  # ม
    "\u0e22": "\u1a46",  # ย
    "\u0e23": "\u1a48",  # ร
    "\u0e25": "\u1a49",  # ล
    "\u0e27": "\u1a4a",  # ว
    "\u0e28": "\u1a4b",  # ศ
    "\u0e29": "\u1a4c",  # ษ
    "\u0e2a": "\u1a4d",  # ส
    "\u0e2b": "\u1a4e",  # ห
    "\u0e2d": "\u1a53",  # อ
    "\u0e2e": "\u1a54",  # ฮ
    "\u0e30": "\u1a61",  # ะ
    "\u0e31": "\u1a62",  # ั
    "\u0e32": "\u1a63",  # า
    "\u0e34": "\u1a65",  # ิ
    "\u0e35": "\u1a66",  # ี
    "\u0e36": "\u1a67",  # ึ
    "\u0e37": "\u1a68",  # ื
    "\u0e38": "\u1a69",  # ุ
    "\u0e39": "\u1a6a",  # ู
    "\u0e40": "\u1a6e",  # เ
    "\u0e41": "\u1a6f",  # แ
    "\u0e42": "\u1a70",  # โ
    "\u0e43": "\u1a72",  # ใ
    "\u0e44": "\u1a71",  # ไ
    "\u0e47": "\u1a7c",  # ็
    "\u0e48": "\u1a75",  # ่
    "\u0e49": "\u1a76",  # ้
    "\u0e4a": "\u1a77",  # ๊
    "\u0e4b": "\u1a78",  # ๋
    "\u0e4c": "\u1a7a",  # ์
}

_PASSTHROUGH = set(" \t\r\n.,!?;:()[]{}'\"-/")


@dataclass(frozen=True)
class TransliterationResult:
    source: str
    text: str
    is_valid: bool
    unsupported: tuple[str, ...]
    engine: str = "aksharamukha"


def _normalize_residual_thai(text: str) -> str:
    return "".join(_RESIDUAL_THAI_TO_TAI_THAM.get(char, char) for char in text)


def _unsupported_characters(text: str) -> tuple[str, ...]:
    unsupported: list[str] = []
    for char in text:
        codepoint = ord(char)
        if (
            TAI_THAM_START <= codepoint <= TAI_THAM_END
            or char in _PASSTHROUGH
            or char.isascii() and char.isdigit()
        ):
            continue
        if char not in unsupported:
            unsupported.append(char)
    return tuple(unsupported)


def validate_tai_tham_text(text: str) -> tuple[bool, tuple[str, ...]]:
    """Validate the final output, including dictionary-provided spellings."""
    unsupported = _unsupported_characters(text)
    has_tai_tham = any(
        TAI_THAM_START <= ord(char) <= TAI_THAM_END for char in text
    )
    return has_tai_tham and not unsupported, unsupported


def thai_to_tai_tham(text: str) -> TransliterationResult:
    source = unicodedata.normalize("NFC", text.strip())
    if not source:
        return TransliterationResult(source="", text="", is_valid=True, unsupported=())

    converted = transliterate.process(
        "Thai",
        "TaiTham",
        source,
        nativize=True,
    )
    normalized = unicodedata.normalize(
        "NFC",
        _normalize_residual_thai(converted),
    )
    unsupported = _unsupported_characters(normalized)
    return TransliterationResult(
        source=source,
        text=normalized,
        is_valid=not unsupported,
        unsupported=unsupported,
    )

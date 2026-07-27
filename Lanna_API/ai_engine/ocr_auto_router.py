"""Route an image to Lanna OCR or Thai OCR without guessing silently."""

from __future__ import annotations

from dataclasses import asdict
from typing import Callable

import cv2
import numpy as np


class AutoOCRRouter:
    def __init__(
        self,
        lanna_engine,
        thai_reader: Callable[[bytes, str], str],
        thai_converter: Callable[[str], dict],
        lanna_threshold: float = 0.65,
    ) -> None:
        self.lanna_engine = lanna_engine
        self.thai_reader = thai_reader
        self.thai_converter = thai_converter
        self.lanna_threshold = lanna_threshold

    @staticmethod
    def _decode(image_bytes: bytes) -> np.ndarray:
        encoded = np.frombuffer(image_bytes, dtype=np.uint8)
        image = cv2.imdecode(encoded, cv2.IMREAD_UNCHANGED)
        if image is None:
            raise ValueError("Unsupported image")
        if image.ndim == 2:
            image = cv2.cvtColor(image, cv2.COLOR_GRAY2BGR)
        elif image.shape[2] == 4:
            color = image[:, :, :3].astype(np.float32)
            alpha = image[:, :, 3:4].astype(np.float32) / 255.0
            image = (color * alpha + 255.0 * (1.0 - alpha)).astype(np.uint8)
        return image

    def route(self, image_bytes: bytes, mime_type: str) -> dict:
        image = self._decode(image_bytes)
        lanna_candidate = None
        if self.lanna_engine is not None:
            try:
                lanna_candidate = self.lanna_engine.recognize(image)
            except (ValueError, RuntimeError, OSError):
                pass

        if (
            lanna_candidate is not None
            and not lanna_candidate.is_low_confidence
            and lanna_candidate.confidence >= self.lanna_threshold
            and lanna_candidate.thai_text.strip()
        ):
            return {
                "direction": "lanna_to_thai",
                "source_text": None,
                "text": lanna_candidate.thai_text.strip(),
                "is_lanna_output": False,
                "confidence": lanna_candidate.confidence,
                "experimental": True,
                "warning": lanna_candidate.warning,
                "characters": [asdict(item) for item in lanna_candidate.characters],
                "provider": "ocr-lanna",
            }

        thai_text = self.thai_reader(image_bytes, mime_type).strip()
        if not thai_text:
            raise ValueError("No Thai text was detected")
        conversion = self.thai_converter(thai_text)
        lanna_text = str(conversion.get("lanna_script", "")).strip()
        if not lanna_text:
            raise ValueError("Thai text could not be converted to Lanna")
        if not conversion.get("is_valid_lanna_unicode", False):
            raise ValueError("Converted output contains unsupported characters")

        return {
            "direction": "thai_to_lanna",
            "source_text": thai_text,
            "text": lanna_text,
            "is_lanna_output": True,
            "confidence": None,
            "experimental": False,
            "warning": None,
            "characters": [],
            "provider": "typhoon-ocr+aksharamukha",
        }

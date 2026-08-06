import unittest

import cv2
import numpy as np

from lanna_ocr import BoundingBox, CharacterPrediction, LannaOCRResult
from ocr_auto_router import AutoOCRRouter


def png_bytes():
    image = np.full((80, 160, 3), 255, dtype=np.uint8)
    ok, encoded = cv2.imencode(".png", image)
    assert ok
    return encoded.tobytes()


class _LannaEngine:
    def __init__(self, confidence, low, text="ภาษาไทย"):
        self.confidence = confidence
        self.low = low
        self.text = text

    def recognize(self, image):
        character = CharacterPrediction(
            "K", "ก", self.confidence, BoundingBox(0, 0, 10, 10), "base"
        )
        return LannaOCRResult(
            thai_text=self.text,
            confidence=self.confidence,
            is_low_confidence=self.low,
            characters=(character,),
            image_width=160,
            image_height=80,
            warning="experimental",
        )


class AutoOCRRouterTests(unittest.TestCase):
    def test_confident_lanna_uses_lanna_to_thai_route(self):
        calls = []
        router = AutoOCRRouter(
            _LannaEngine(0.9, False),
            thai_reader=lambda *_: calls.append("thai") or "ข้อความ",
            thai_converter=lambda text: {},
        )
        result = router.route(png_bytes(), "image/png")
        self.assertEqual(result["direction"], "lanna_to_thai")
        self.assertFalse(result["is_lanna_output"])
        self.assertEqual(calls, [])

    def test_low_confidence_lanna_falls_back_to_thai_to_lanna(self):
        router = AutoOCRRouter(
            _LannaEngine(0.3, True),
            thai_reader=lambda *_: "ข้อความไทย",
            thai_converter=lambda text: {
                "lanna_script": "ᨡᩴ᩶ᨣ᩠ᩅᩣᨾ",
                "is_valid_lanna_unicode": True,
            },
        )
        result = router.route(png_bytes(), "image/png")
        self.assertEqual(result["direction"], "thai_to_lanna")
        self.assertTrue(result["is_lanna_output"])
        self.assertEqual(result["source_text"], "ข้อความไทย")

    def test_invalid_conversion_is_rejected(self):
        router = AutoOCRRouter(
            _LannaEngine(0.2, True),
            thai_reader=lambda *_: "ข้อความไทย",
            thai_converter=lambda text: {
                "lanna_script": "ข้อความไทย",
                "is_valid_lanna_unicode": False,
            },
        )
        with self.assertRaises(ValueError):
            router.route(png_bytes(), "image/png")

    def test_missing_lanna_model_still_routes_thai(self):
        router = AutoOCRRouter(
            None,
            thai_reader=lambda *_: "ข้อความไทย",
            thai_converter=lambda text: {
                "lanna_script": "ᨡᩴ᩶ᨣ᩠ᩅᩣᨾ",
                "is_valid_lanna_unicode": True,
            },
        )
        result = router.route(png_bytes(), "image/png")
        self.assertEqual(result["direction"], "thai_to_lanna")


if __name__ == "__main__":
    unittest.main()

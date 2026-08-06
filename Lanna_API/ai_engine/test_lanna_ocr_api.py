import base64
import io
import json
import threading
import unittest
import urllib.request
from http.server import HTTPServer

import cv2
import numpy as np

import ai_server


class _FakeResult:
    thai_text = "ก"
    confidence = 0.2
    is_low_confidence = True
    characters = ()
    warning = "experimental"

    def to_dict(self):
        return {
            "thai_text": "ก",
            "confidence": 0.9,
            "is_low_confidence": False,
            "characters": [],
            "image_width": 100,
            "image_height": 100,
            "warning": "experimental",
        }


class _FakeOCR:
    def recognize(self, image):
        if image is None:
            raise ValueError("missing")
        return _FakeResult()


class _FakeAI:
    def convert_thai_to_lanna(self, text):
        return {
            "lanna_script": "ᨡᩴ᩶ᨣ᩠ᩅᩣᨾ",
            "is_valid_lanna_unicode": True,
        }


class LannaOCRApiTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        ai_server.LANNA_OCR_ENGINE = _FakeOCR()
        ai_server.AI_ENGINE = _FakeAI()
        cls.original_thai_reader = ai_server.LannaAIServerHandler._run_typhoon_reader
        ai_server.LannaAIServerHandler._run_typhoon_reader = staticmethod(
            lambda image_bytes, mime_type: "ข้อความไทย"
        )
        cls.server = HTTPServer(("127.0.0.1", 0), ai_server.LannaAIServerHandler)
        cls.thread = threading.Thread(target=cls.server.serve_forever, daemon=True)
        cls.thread.start()
        cls.base_url = f"http://127.0.0.1:{cls.server.server_port}"

    @classmethod
    def tearDownClass(cls):
        cls.server.shutdown()
        cls.server.server_close()
        cls.thread.join(timeout=2)
        ai_server.LannaAIServerHandler._run_typhoon_reader = cls.original_thai_reader

    def test_lanna_ocr_endpoint_accepts_base64_image(self):
        image = np.full((100, 100, 3), 255, dtype=np.uint8)
        ok, encoded = cv2.imencode(".png", image)
        self.assertTrue(ok)
        payload = json.dumps({
            "image_base64": base64.b64encode(encoded.tobytes()).decode("ascii"),
        }).encode("utf-8")
        request = urllib.request.Request(
            self.base_url + "/api/ocr-lanna",
            data=payload,
            headers={"Content-Type": "application/json"},
            method="POST",
        )
        with urllib.request.urlopen(request, timeout=5) as response:
            body = json.loads(response.read().decode("utf-8"))
        self.assertEqual(body["status"], "success")
        self.assertTrue(body["experimental"])
        self.assertEqual(body["result"]["thai_text"], "ก")

    def test_auto_endpoint_routes_low_confidence_image_through_thai(self):
        image = np.full((100, 100, 3), 255, dtype=np.uint8)
        ok, encoded = cv2.imencode(".png", image)
        self.assertTrue(ok)
        payload = json.dumps({
            "image_base64": base64.b64encode(encoded.tobytes()).decode("ascii"),
            "mime_type": "image/png",
        }).encode("utf-8")
        request = urllib.request.Request(
            self.base_url + "/api/ocr-auto",
            data=payload,
            headers={"Content-Type": "application/json"},
            method="POST",
        )
        with urllib.request.urlopen(request, timeout=5) as response:
            body = json.loads(response.read().decode("utf-8"))
        self.assertEqual(body["status"], "success")
        self.assertEqual(body["result"]["direction"], "thai_to_lanna")
        self.assertTrue(body["result"]["is_lanna_output"])


if __name__ == "__main__":
    unittest.main()

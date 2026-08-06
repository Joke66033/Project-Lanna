import unittest

import cv2
import numpy as np

from lanna_ocr import BoundingBox, CharacterPrediction, LannaOCR


class LannaOCRPipelineTests(unittest.TestCase):
    def setUp(self):
        self.ocr = LannaOCR()

    def test_assets_and_class_mapping_match_model_contract(self):
        self.assertEqual(len(self.ocr.class_names), 35)
        self.assertTrue(self.ocr.model_path.is_file())

    def test_blank_image_has_no_components(self):
        blank = np.full((200, 500, 3), 255, dtype=np.uint8)
        binary = self.ocr._binarize(blank)
        self.assertEqual(self.ocr._component_boxes(binary), [])

    def test_components_are_detected_on_synthetic_shapes(self):
        image = np.full((200, 500, 3), 255, dtype=np.uint8)
        cv2.rectangle(image, (50, 60), (120, 160), (0, 0, 0), 8)
        cv2.rectangle(image, (220, 60), (300, 160), (0, 0, 0), 8)
        boxes = self.ocr._component_boxes(self.ocr._binarize(image))
        self.assertGreaterEqual(len(boxes), 2)

    def test_spatial_order_attaches_marks_to_nearest_base(self):
        items = [
            CharacterPrediction("K", "ก", 0.9, BoundingBox(20, 70, 40, 70), "base"),
            CharacterPrediction("EI", "ิ", 0.8, BoundingBox(28, 30, 18, 15), "above"),
            CharacterPrediction("M", "ม", 0.9, BoundingBox(100, 70, 45, 70), "base"),
        ]
        ordered = self.ocr._reading_order(items)
        self.assertEqual("".join(item.thai for item in ordered), "กิม")


if __name__ == "__main__":
    unittest.main()

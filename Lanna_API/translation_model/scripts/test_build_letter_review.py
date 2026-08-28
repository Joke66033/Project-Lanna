import json
import tempfile
import unittest
from pathlib import Path

from build_letter_review import classify, thai_initial, validate_record


class LetterReviewTests(unittest.TestCase):
    def test_leading_vowel_is_grouped_by_consonant(self):
        self.assertEqual(thai_initial("เก๊า"), "ก")

    def test_valid_tai_tham_pair(self):
        self.assertEqual(
            validate_record({"thai": "ก", "lanna": "ᨠ", "pronunciation": "กะ", "meaning": "พยัญชนะ"}),
            [],
        )

    def test_rejects_thai_and_placeholder_in_target(self):
        issues = validate_record(
            {"thai": "ก", "lanna": "ᨠิ<ctrl42>", "pronunciation": "กะ", "meaning": "พยัญชนะ"}
        )
        self.assertIn("thai_character_in_lanna", issues)
        self.assertIn("control_placeholder", issues)

    def test_rejects_damaged_legacy_headword(self):
        issues = validate_record(
            {"thai": "ก..ด", "lanna": "ᨠᩩᨯ", "pronunciation": "ก..๋ด", "meaning": "พืชชนิดหนึ่ง"}
        )
        self.assertIn("damaged_headword_placeholder", issues)
        self.assertIn("damaged_pronunciation_placeholder", issues)

    def test_owner_confirmed_wat_has_canonical_order(self):
        self.assertEqual(
            validate_record({"thai": "วัด", "lanna": "ᩅᩢ᩠ᨯ", "pronunciation": "วัด", "meaning": "ศาสนสถาน"}),
            [],
        )

    def test_rejects_sakot_before_mai_sat(self):
        issues = validate_record(
            {"thai": "วัด", "lanna": "ᩅ᩠ᨯᩢ", "pronunciation": "วัด", "meaning": "ศาสนสถาน"}
        )
        self.assertIn("noncanonical_mai_sat_order", issues)

    def test_rejects_repeated_sakot(self):
        issues = validate_record(
            {"thai": "คำ", "lanna": "ᨣ᩠᩠ᨾ", "pronunciation": "กำ", "meaning": "คำพูด"}
        )
        self.assertIn("repeated_sakot", issues)

    def test_food_category(self):
        category, confidence = classify("น. อาหารทำจากข้าว ใช้กินเป็นของหวาน")
        self.assertEqual(category, "อาหารและเครื่องดื่ม")
        self.assertGreater(confidence, 0.5)

    def test_alphabet_category(self):
        category, _ = classify("น. อักษร ก ใช้เป็นพยัญชนะต้น")
        self.assertEqual(category, "ภาษาและอักษร")


if __name__ == "__main__":
    unittest.main()

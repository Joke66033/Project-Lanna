import unittest

from apply_category_reviews import apply_reviews


class ApplyCategoryReviewsTests(unittest.TestCase):
    def test_applies_review_to_verified_row(self):
        rows = [{"thai": "กา", "lanna": "ᨠᩣ", "verification_status": "source_image_verified"}]
        count = apply_reviews(rows, [{"thai": "กา", "lanna": "ᨠᩣ", "category": "คำศัพท์ทั่วไป"}])
        self.assertEqual(count, 1)
        self.assertTrue(rows[0]["category_reviewed"])
        self.assertEqual(rows[0]["category_confidence"], 1.0)

    def test_rejects_unverified_row(self):
        rows = [{"thai": "กา", "lanna": "ᨠᩣ", "verification_status": "auto_checked_needs_expert"}]
        with self.assertRaises(ValueError):
            apply_reviews(rows, [{"thai": "กา", "lanna": "ᨠᩣ", "category": "คำศัพท์ทั่วไป"}])

    def test_rejects_category_outside_taxonomy(self):
        rows = [{"thai": "กา", "lanna": "ᨠᩣ", "verification_status": "source_image_verified"}]
        with self.assertRaises(ValueError):
            apply_reviews(rows, [{"thai": "กา", "lanna": "ᨠᩣ", "category": "หมวดสะกดผิด"}])


if __name__ == "__main__":
    unittest.main()

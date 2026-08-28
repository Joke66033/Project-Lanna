import unittest

from apply_alias_reviews import apply_aliases


class ApplyAliasReviewsTests(unittest.TestCase):
    def test_links_pending_alias_to_verified_target(self):
        rows = [
            {"thai": "กินเข้างาย", "verification_status": "auto_checked_needs_expert", "pdf_evidence": {}},
            {"thai": "กินงาย", "lanna": "canonical", "category": "อาหารและเครื่องดื่ม", "source_id": "dict", "verification_status": "source_image_verified", "pdf_evidence": {"verified_page": 43}},
        ]
        self.assertEqual(apply_aliases(rows, [{"alias_thai": "กินเข้างาย", "canonical_thai": "กินงาย"}]), 1)
        self.assertEqual(rows[0]["verification_status"], "verified_alias_to_source")
        self.assertEqual(rows[0]["canonical_lanna"], "canonical")
        self.assertFalse(rows[0]["pdf_evidence"]["visually_verified"])


if __name__ == "__main__":
    unittest.main()

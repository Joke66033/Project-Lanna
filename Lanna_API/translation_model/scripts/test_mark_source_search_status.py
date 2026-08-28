import unittest

from mark_source_search_status import mark_search_status


class MarkSourceSearchStatusTests(unittest.TestCase):
    def test_marks_search_coverage_without_changing_verification(self):
        rows = [
            {"verification_status": "source_image_verified", "pdf_evidence": {}},
            {"verification_status": "rejected", "pdf_evidence": {}},
            {"verification_status": "auto_checked_needs_expert", "pdf_evidence": {"suggested_pages": [{"pdf_page": 2}]}},
            {"verification_status": "auto_checked_needs_expert", "pdf_evidence": {}},
            {"verification_status": "verified_alias_to_source", "pdf_evidence": {}},
        ]
        before = [row["verification_status"] for row in rows]
        counts = mark_search_status(rows)
        self.assertEqual(before, [row["verification_status"] for row in rows])
        self.assertEqual(counts["source_image_verified"], 1)
        self.assertEqual(counts["reviewed_rejected"], 1)
        self.assertEqual(counts["candidate_pages_need_manual_review"], 1)
        self.assertEqual(counts["not_located_after_dual_ocr_needs_manual_review"], 1)
        self.assertEqual(counts["verified_alias_to_source"], 1)


if __name__ == "__main__":
    unittest.main()

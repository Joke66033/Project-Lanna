import unittest

from apply_false_page_reviews import apply_false_pages


class ApplyFalsePageReviewsTests(unittest.TestCase):
    def test_removes_suggestion_without_rejecting_word(self):
        rows = [{"thai": "กด", "verification_status": "auto_checked_needs_expert", "pdf_evidence": {"candidate_pages": [], "suggested_pages": [{"pdf_page": 3}]}}]
        count = apply_false_pages(rows, [{"thai": "กด", "pdf_pages": [3], "note": "not a headword"}])
        self.assertEqual(count, 1)
        self.assertEqual(rows[0]["verification_status"], "auto_checked_needs_expert")
        self.assertEqual(rows[0]["pdf_evidence"]["suggested_pages"], [])
        self.assertEqual(rows[0]["pdf_evidence"]["false_positive_pages"], [3])

    def test_rejects_page_not_currently_proposed(self):
        rows = [{"thai": "กด", "pdf_evidence": {"candidate_pages": [], "suggested_pages": []}}]
        with self.assertRaises(ValueError):
            apply_false_pages(rows, [{"thai": "กด", "pdf_pages": [9]}])


if __name__ == "__main__":
    unittest.main()

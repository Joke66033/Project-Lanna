import unittest

from summarize_letter_review import summarize


class SummarizeLetterReviewTests(unittest.TestCase):
    def test_counts_verification_and_category_coverage(self):
        rows = [
            {"verification_status": "source_image_verified", "source_search_status": "source_image_verified", "category_reviewed": True, "category": "สัตว์", "pdf_evidence": {}},
            {"verification_status": "auto_checked_needs_expert", "pdf_evidence": {"suggested_pages": [{"pdf_page": 2}]}},
            {"verification_status": "rejected", "pdf_evidence": {"false_positive_pages": [3]}},
            {"verification_status": "verified_alias_to_source", "source_search_status": "verified_alias_to_source", "pdf_evidence": {}},
        ]
        report = summarize(rows)
        self.assertEqual(report["rows"], 4)
        self.assertEqual(report["verified_with_reviewed_category"], 1)
        self.assertEqual(report["pending_with_page_suggestions"], 1)
        self.assertEqual(report["false_positive_pdf_pages"], 1)
        self.assertEqual(report["source_search_statuses"]["source_image_verified"], 1)
        self.assertEqual(report["verified_alias_rows"], 1)


if __name__ == "__main__":
    unittest.main()

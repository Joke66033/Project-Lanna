import unittest

from export_reviewed_lexicon import export_rows


class ExportReviewedLexiconTests(unittest.TestCase):
    def test_exports_verified_and_alias_but_not_pending(self):
        rows = [
            {"thai": "กินงาย", "lanna": "source", "pronunciation": "p", "meaning": "m", "verification_status": "source_image_verified", "pdf_evidence": {"verified_page": 43}},
            {"thai": "กินเข้างาย", "lanna": "literal", "canonical_lanna": "source", "canonical_thai": "กินงาย", "verification_status": "verified_alias_to_source", "pdf_evidence": {"canonical_verified_page": 43}},
            {"thai": "เดา", "lanna": "guess", "verification_status": "auto_checked_needs_expert"},
        ]
        result = export_rows(rows)
        self.assertEqual(len(result), 2)
        alias = next(item for item in result if item["is_alias"])
        self.assertEqual(alias["lanna"], "source")
        self.assertFalse(alias["needs_review"])

    def test_exports_dictionary_senses(self):
        senses = [{"sense_no": 1}, {"sense_no": 2}]
        result = export_rows([{"thai": "กีบ", "lanna": "x", "verification_status": "source_image_verified", "pdf_evidence": {"verified_page": 45}, "senses": senses}])
        self.assertEqual(result[0]["senses"], senses)


if __name__ == "__main__":
    unittest.main()

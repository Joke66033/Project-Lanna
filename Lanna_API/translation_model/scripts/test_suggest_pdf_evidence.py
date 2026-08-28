import unittest

from suggest_pdf_evidence import headword_context_runs, line_score, ngrams, thai_only, threshold


class SuggestPdfEvidenceTests(unittest.TestCase):
    def test_thai_only_removes_latin_and_spacing(self):
        self.assertEqual(thai_only("[ก๋อง - ปู่เจ่] /latin/"), "ก๋องปู่เจ่")

    def test_exact_run_scores_one(self):
        self.assertEqual(line_score("ไก่ชน", "ไก่ชน  [ไก่ - จน]"), 1.0)

    def test_minor_ocr_error_is_suggested_for_long_word(self):
        self.assertGreaterEqual(line_score("กลองปู่เจ่", "กลองปูเจ่ [ก๋อง]"), threshold("กลองปู่เจ่"))

    def test_unrelated_line_is_not_suggested(self):
        self.assertLess(line_score("กลองปู่เจ่", "อาหารและเครื่องดื่ม"), threshold("กลองปู่เจ่"))

    def test_short_words_require_high_confidence(self):
        self.assertEqual(threshold("กี่"), 0.92)

    def test_bigram_index_terms(self):
        self.assertEqual(ngrams("กลอง"), {"กล", "ลอ", "อง"})

    def test_headword_context_is_limited_to_before_bracket(self):
        runs = headword_context_runs("คำอธิบายเดิม  กลองปู่ชา  noise [ก๋อง - ปู่ - จา]")
        self.assertIn(("กลองปู่ชา", 0), runs)
        self.assertNotIn(("ก๋อง", 0), runs)


if __name__ == "__main__":
    unittest.main()

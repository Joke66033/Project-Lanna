import unittest

from build_ocr_headword_inventory import extract_headwords, rank_candidates


class OcrHeadwordInventoryTests(unittest.TestCase):
    def test_extracts_headword_but_not_definition_prose(self):
        text = "กก    cp   [กัก] น. โคน\nโคนต้นไม้ ชื่อเรียกนกเงือก\n| กงกอน     ตดูว๑ [กง - ก้อน] น. เครื่องยิง"
        self.assertEqual([x["ocr_headword"] for x in extract_headwords(text)], ["กก", "กงกอน"])

    def test_ranks_exact_match_first(self):
        inventory = [
            {"ocr_headword": "กลองต็อบ", "pdf_page": 27, "line": 1},
            {"ocr_headword": "กลองชุม", "pdf_page": 26, "line": 1},
        ]
        ranked = rank_candidates("กลองชุม", inventory)
        self.assertEqual(ranked[0]["ocr_headword"], "กลองชุม")
        self.assertEqual(ranked[0]["headword_score"], 1.0)

    def test_meaning_context_breaks_headword_tie(self):
        inventory = [
            {"ocr_headword": "กินงาย", "pdf_page": 43, "line": 1, "ocr_context": "ก. กินอาหารมื้อเช้า"},
            {"ocr_headword": "กินดาย", "pdf_page": 44, "line": 1, "ocr_context": "ก. กินอาหารเปล่าๆ โดยไม่มีข้าว"},
        ]
        ranked = rank_candidates("กินดาย", inventory, meaning="กินอาหารเปล่าๆ โดยไม่มีข้าว")
        self.assertEqual(ranked[0]["pdf_page"], 44)
        self.assertGreater(ranked[0]["meaning_score"], ranked[1]["meaning_score"])


if __name__ == "__main__":
    unittest.main()

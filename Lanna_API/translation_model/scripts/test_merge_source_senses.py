import unittest

from merge_source_senses import merge_senses


class MergeSourceSensesTests(unittest.TestCase):
    def test_merges_senses_and_preserves_each_source_page(self):
        rows = [{"thai": "กี", "lanna": "x", "verification_status": "source_image_verified", "pdf_evidence": {"verified_page": 44, "context_pages": [44]}}]
        senses = [
            {"sense_no": 1, "part_of_speech": "น.", "pronunciation": "กี", "meaning": "ฐานรอง", "category": "สิ่งของและเครื่องมือ", "source_page": 44},
            {"sense_no": 2, "part_of_speech": "ก.", "pronunciation": "กี", "meaning": "ประกบ", "category": "การกระทำ", "source_page": 45},
        ]
        merges = [{"thai": "กี", "lanna": "x", "pronunciation": "กี", "meaning": "สองความหมาย", "senses": senses}]
        self.assertEqual(merge_senses(rows, merges), 1)
        self.assertEqual(rows[0]["senses"], senses)
        self.assertEqual(rows[0]["pdf_evidence"]["verified_pages"], [44, 45])


if __name__ == "__main__":
    unittest.main()

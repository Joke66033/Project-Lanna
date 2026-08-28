import unittest

from add_source_records import add_records


class AddSourceRecordsTests(unittest.TestCase):
    def test_merge_existing_page_preserves_one_headword_and_adds_provenance(self):
        rows = [{
            "thai": "ข่าว",
            "lanna": "ᨡ᩵ᩣ᩠ᩅ",
            "pronunciation": "[ข่าว]",
            "meaning": "น. ข่าวสาร เรื่องราว ข่าว ก็ว่า",
            "category": "ภาษาและอักษร",
            "pdf_evidence": {"verified_page": 56, "context_pages": [56]},
        }]
        records = [{
            "thai": "ข่าว",
            "lanna": "ᨡ᩵ᩣ᩠ᩅ",
            "pronunciation": "[ข่าว]",
            "meaning": "น. ข่าวสาร เรื่องราว ข่าว ก็ว่า",
            "category": "ภาษาและอักษร",
            "pdf_page": 68,
            "merge_existing_page": True,
        }]

        count = add_records(rows, records)

        self.assertEqual(count, 0)
        self.assertEqual(len(rows), 1)
        self.assertEqual(rows[0]["pdf_evidence"]["verified_pages"], [56, 68])
        self.assertEqual(rows[0]["pdf_evidence"]["context_pages"], [56, 68])

    def test_merge_existing_page_rejects_conflicting_text(self):
        rows = [{
            "thai": "ข่าว", "lanna": "x", "pronunciation": "p",
            "meaning": "old", "category": "ภาษาและอักษร",
        }]
        records = [{
            "thai": "ข่าว", "lanna": "x", "pronunciation": "p",
            "meaning": "different", "category": "ภาษาและอักษร",
            "pdf_page": 68, "merge_existing_page": True,
        }]

        with self.assertRaisesRegex(ValueError, "conflicting meaning"):
            add_records(rows, records)

    def test_adds_verified_source_record(self):
        rows = []
        records = [{"thai": "กินงาย", "lanna": "x", "pronunciation": "กิน-งาย", "meaning": "อาหารเช้า", "initial": "ก", "category": "อาหารและเครื่องดื่ม", "pdf_page": 43}]
        self.assertEqual(add_records(rows, records), 1)
        self.assertEqual(rows[0]["verification_status"], "source_image_verified")
        self.assertEqual(rows[0]["source_search_status"], "source_image_verified")
        self.assertEqual(rows[0]["pdf_evidence"]["verified_page"], 43)

    def test_rejects_duplicate(self):
        with self.assertRaises(ValueError):
            add_records([{"thai": "กินงาย"}], [{"thai": "กินงาย"}])

    def test_preserves_cross_page_context(self):
        rows = []
        record = {"thai": "กล่องเข้าหลวง", "lanna": "x", "pronunciation": "ก่อง-เข้า-หลวง", "meaning": "นิยามข้ามหน้า", "initial": "ก", "category": "สิ่งของและเครื่องมือ", "pdf_page": 28, "context_pages": [28, 29]}
        add_records(rows, [record])
        self.assertEqual(rows[0]["pdf_evidence"]["context_pages"], [28, 29])

    def test_preserves_numbered_dictionary_senses(self):
        rows = []
        senses = [
            {"sense_no": 1, "part_of_speech": "น.", "pronunciation": "กีบ", "meaning": "เล็บเท้าสัตว์", "category": "สัตว์", "source_page": 45},
            {"sense_no": 2, "part_of_speech": "ก.", "pronunciation": "กีบ", "meaning": "ประกบ", "category": "การกระทำ", "source_page": 45},
        ]
        record = {"thai": "กีบ", "lanna": "x", "pronunciation": "กีบ", "meaning": "มีสองความหมาย", "initial": "ก", "category": "คำศัพท์ทั่วไป", "pdf_page": 45, "senses": senses}
        add_records(rows, [record])
        self.assertEqual(rows[0]["senses"], senses)


if __name__ == "__main__":
    unittest.main()

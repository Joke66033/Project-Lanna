import unittest

from apply_record_corrections import apply_corrections


class ApplyRecordCorrectionsTests(unittest.TestCase):
    def test_corrects_meaning_and_category_with_audit(self):
        rows = [{"thai": "ก่า", "lanna": "ᨠ᩵ᩣ", "pronunciation": "ก่า", "meaning": "old", "category": "old", "verification_status": "auto_checked_needs_expert"}]
        corrections = [{"old_thai": "ก่า", "new_thai": "ก่า", "new_meaning": "source meaning", "new_category": "เวลาและจำนวน", "source_pdf_page": 39}]
        self.assertEqual(apply_corrections(rows, corrections), 1)
        self.assertEqual(rows[0]["meaning"], "source meaning")
        self.assertTrue(rows[0]["category_reviewed"])
        self.assertEqual(rows[0]["record_corrections"][0]["changed_fields"]["meaning"]["old"], "old")

    def test_corrects_pending_record_and_keeps_audit(self):
        rows = [{"thai": "แกนฅอ", "pronunciation": "แก๋นคอ", "verification_status": "auto_checked_needs_expert"}]
        count = apply_corrections(rows, [{"old_thai": "แกนฅอ", "new_thai": "แกนคอ", "source_pdf_page": 50}])
        self.assertEqual(count, 1)
        self.assertEqual(rows[0]["thai"], "แกนคอ")
        self.assertEqual(rows[0]["record_corrections"][0]["old_thai"], "แกนฅอ")

    def test_refuses_to_correct_verified_record(self):
        rows = [{"thai": "แกนฅอ", "verification_status": "source_image_verified"}]
        with self.assertRaises(ValueError):
            apply_corrections(rows, [{"old_thai": "แกนฅอ", "new_thai": "แกนคอ", "source_pdf_page": 50}])


if __name__ == "__main__":
    unittest.main()

import unittest

from revise_verified_source_records import revise_records


class ReviseVerifiedSourceRecordsTests(unittest.TestCase):
    def test_preserves_cross_page_context_and_senses(self):
        rows = [{"thai": "กลั้น", "verification_status": "source_image_verified", "pdf_evidence": {"verified_page": 29, "context_pages": [29]}}]
        senses = [{"sense_no": 1, "part_of_speech": "ก.", "pronunciation": "กั้น", "meaning": "บังคับไว้", "category": "การกระทำ", "source_page": 29}]
        revisions = [{"thai": "กลั้น", "expected_verified_page": 29, "reason": "นิยามต่อหน้า 30", "context_pages": [29, 30], "senses": senses}]
        revise_records(rows, revisions)
        self.assertEqual(rows[0]["pdf_evidence"]["context_pages"], [29, 30])
        self.assertEqual(rows[0]["senses"], senses)

    def test_revises_only_matching_verified_source_and_keeps_history(self):
        rows = [{"thai": "กึ่งดึ่ง", "lanna": "x", "meaning": "เก่า", "verification_status": "source_image_verified", "pdf_evidence": {"verified_page": 45}}]
        revisions = [{"thai": "กึ่งดึ่ง", "expected_verified_page": 45, "meaning": "ใหม่", "source_page": 45, "reason": "ตรวจภาพซ้ำ"}]
        self.assertEqual(revise_records(rows, revisions), 1)
        self.assertEqual(rows[0]["meaning"], "ใหม่")
        self.assertEqual(rows[0]["source_revision_history"][0]["previous"]["meaning"], "เก่า")

    def test_rejects_wrong_verified_page(self):
        rows = [{"thai": "กึ่งดึ่ง", "verification_status": "source_image_verified", "pdf_evidence": {"verified_page": 44}}]
        with self.assertRaises(ValueError):
            revise_records(rows, [{"thai": "กึ่งดึ่ง", "expected_verified_page": 45, "reason": "ผิดหน้า"}])

    def test_restores_rejected_record_only_with_explicit_flag(self):
        rows = [{"thai": "เก้ากอง", "lanna": "old", "verification_status": "rejected", "pdf_evidence": {"verified_page": 48}}]
        revisions = [{"thai": "เก้ากอง", "expected_verified_page": 48, "lanna": "full", "reason": "เห็นหัวคำชัดเจน", "restore_rejected": True}]
        revise_records(rows, revisions)
        self.assertEqual(rows[0]["verification_status"], "source_image_verified")
        self.assertEqual(rows[0]["lanna"], "full")

    def test_promotes_pending_record_only_with_explicit_flag_and_matching_page(self):
        rows = [{"thai": "กะบี้", "lanna": "old", "verification_status": "auto_checked_needs_expert", "pdf_evidence": {"context_pages": [35]}}]
        revisions = [{"thai": "กะบี้", "expected_verified_page": 35, "source_page": 35, "lanna": "full", "reason": "ตรวจภาพชัดเจน", "promote_pending": True}]
        revise_records(rows, revisions)
        self.assertEqual(rows[0]["verification_status"], "source_image_verified")
        self.assertEqual(rows[0]["pdf_evidence"]["verified_page"], 35)
        self.assertTrue(rows[0]["pdf_evidence"]["visually_verified"])

    def test_rejects_pending_record_without_explicit_promotion(self):
        rows = [{"thai": "กะบี้", "verification_status": "auto_checked_needs_expert", "pdf_evidence": {"context_pages": [35]}}]
        with self.assertRaises(ValueError):
            revise_records(rows, [{"thai": "กะบี้", "expected_verified_page": 35, "reason": "ไม่มีธงยืนยัน"}])


if __name__ == "__main__":
    unittest.main()

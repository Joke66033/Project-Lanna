import unittest

from audit_source_page import audit_page


class AuditSourcePageTests(unittest.TestCase):
    def test_reports_complete_page(self):
        rows = [{"thai": "กิน", "verification_status": "source_image_verified", "pdf_evidence": {"verified_page": 43}}]
        report = audit_page(rows, {"pdf_page": 43, "headwords": ["กิน"]})
        self.assertTrue(report["complete"])
        self.assertEqual(report["verified_headwords"], 1)

    def test_reports_missing_and_wrong_page(self):
        rows = [{"thai": "กิน", "verification_status": "source_image_verified", "pdf_evidence": {"verified_page": 42}}]
        report = audit_page(rows, {"pdf_page": 43, "headwords": ["กิน", "กินงาย"]})
        self.assertFalse(report["complete"])
        self.assertEqual(report["missing"], ["กินงาย"])
        self.assertEqual(report["wrong_verified_page"], ["กิน"])

    def test_audits_multiple_entries_for_same_headword(self):
        rows = [{"thai": "กีบ", "verification_status": "source_image_verified", "pdf_evidence": {"verified_page": 45}, "senses": [{"sense_no": 1, "source_page": 45}, {"sense_no": 2, "source_page": 45}]}]
        report = audit_page(rows, {"pdf_page": 45, "headwords": ["กีบ"], "senses": {"กีบ": {"count": 2, "page_sense_nos": [1, 2]}}})
        self.assertTrue(report["complete"])
        self.assertEqual(report["expected_entries"], 2)
        self.assertEqual(report["verified_entries"], 2)

    def test_accepts_sense_verified_on_second_page(self):
        rows = [{"thai": "กี", "verification_status": "source_image_verified", "pdf_evidence": {"verified_page": 44, "verified_pages": [44, 45]}, "senses": [{"sense_no": 1, "source_page": 44}, {"sense_no": 2, "source_page": 45}]}]
        report = audit_page(rows, {"pdf_page": 45, "headwords": ["กี"], "senses": {"กี": {"count": 2, "page_sense_nos": [2]}}})
        self.assertTrue(report["complete"])

    def test_semantic_senses_can_belong_to_one_printed_entry(self):
        rows = [{"thai": "กุ่ม", "verification_status": "source_image_verified", "pdf_evidence": {"verified_page": 46}, "senses": [{"sense_no": 1, "source_page": 46}, {"sense_no": 2, "source_page": 46}]}]
        manifest = {"pdf_page": 46, "headwords": ["กุ่ม"], "senses": {"กุ่ม": {"count": 2, "page_sense_nos": [1, 2], "entry_count_on_page": 1}}}
        report = audit_page(rows, manifest)
        self.assertTrue(report["complete"])
        self.assertEqual(report["expected_entries"], 1)


if __name__ == "__main__":
    unittest.main()

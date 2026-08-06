import unittest

from inference import LannaAIInference


class HybridTranslationTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.engine = LannaAIInference()

    def test_owner_verified_word_wins(self):
        result = self.engine.convert_thai_to_lanna("สวัสดี")
        self.assertEqual(result["lanna_script"], "ᩈ᩠ᩅᩢᩈ᩠ᨯᩦ")
        self.assertEqual(result["segments"][0]["source"], "owner_verified")
        self.assertFalse(result["needs_review"])
        self.assertIn("[สะ-วัด-ดี]", result["details"][0])
        self.assertIn("คำทักทาย", result["details"][0])

    def test_unknown_text_returns_labeled_suggestion(self):
        result = self.engine.convert_thai_to_lanna("ทดสอบคำใหม่")
        self.assertTrue(result["lanna_script"])
        self.assertTrue(result["needs_review"])
        self.assertEqual(result["result_label"], "คำแนะนำอัตโนมัติ")

    def test_punctuation_is_preserved(self):
        result = self.engine.convert_thai_to_lanna("สวัสดี!")
        self.assertTrue(result["lanna_script"].endswith("!"))


if __name__ == "__main__":
    unittest.main()

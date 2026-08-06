import unittest

from aksharamukha_lanna import thai_to_tai_tham


class ThaiToTaiThamTests(unittest.TestCase):
    def test_common_phrases_do_not_leave_thai_codepoints(self):
        samples = [
            "\u0e25\u0e49\u0e32\u0e19\u0e19\u0e32",
            "\u0e2a\u0e27\u0e31\u0e2a\u0e14\u0e35",
            "\u0e40\u0e0a\u0e35\u0e22\u0e07\u0e43\u0e2b\u0e21\u0e48",
            "\u0e20\u0e32\u0e29\u0e32\u0e44\u0e17\u0e22",
            "\u0e21\u0e2b\u0e32\u0e27\u0e34\u0e17\u0e22\u0e32\u0e25\u0e31\u0e22"
            "\u0e23\u0e32\u0e0a\u0e20\u0e31\u0e0f\u0e40\u0e0a\u0e35\u0e22\u0e07"
            "\u0e23\u0e32\u0e22",
        ]
        for sample in samples:
            with self.subTest(sample=sample):
                result = thai_to_tai_tham(sample)
                self.assertTrue(result.is_valid)
                self.assertFalse(result.unsupported)
                self.assertFalse(
                    any(0x0E00 <= ord(char) <= 0x0E7F for char in result.text)
                )

    def test_spaces_and_punctuation_are_preserved(self):
        source = "\u0e20\u0e32\u0e29\u0e32\u0e44\u0e17\u0e22, "
        result = thai_to_tai_tham(source)
        self.assertTrue(result.is_valid)
        self.assertTrue(result.text.endswith(","))

    def test_empty_input(self):
        result = thai_to_tai_tham("  ")
        self.assertTrue(result.is_valid)
        self.assertEqual(result.text, "")


if __name__ == "__main__":
    unittest.main()

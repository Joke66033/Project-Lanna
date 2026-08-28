import unittest

from ln_tilok_to_unicode import convert_ln_tilok


class LnTilokToUnicodeTests(unittest.TestCase):
    def test_sara_am_becomes_unicode_tai_tham_aa_mai_kang(self):
        converted, warnings = convert_ln_tilok("ขำ")

        self.assertEqual(converted, "ᨡᩣᩴ")
        self.assertNotIn("unmapped_U+0E33", warnings)

    def test_sara_am_is_preserved_in_compound(self):
        converted, warnings = convert_ln_tilok("ขำเขิอฯก")

        self.assertEqual(converted, "ᨡᩣᩴᩮᨡ᩠ᩋᩥᨠ")
        self.assertEqual(warnings, [])

    def test_preposed_legacy_ra_cluster_becomes_unicode_medial_ra(self):
        converted, warnings = convert_ln_tilok("ระฯค฿กฯ")

        self.assertEqual(converted, "ᨣᩕᩫ᩠ᨠ")
        self.assertEqual(warnings, [])

    def test_preposed_legacy_ra_cluster_is_preserved_in_compound(self):
        converted, warnings = convert_ln_tilok("ระฯค฿กฯระฯพิกฯ")

        self.assertEqual(converted, "ᨣᩕᩫ᩠ᨠᨻᩕ᩠ᨠᩥ")
        self.assertEqual(warnings, [])


if __name__ == "__main__":
    unittest.main()

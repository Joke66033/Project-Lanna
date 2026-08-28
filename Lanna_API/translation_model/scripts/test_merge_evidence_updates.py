import unittest

from merge_evidence_updates import merge_rows


class MergeEvidenceUpdatesTests(unittest.TestCase):
    def test_replaces_existing_and_appends_new_rows(self):
        base = [{"thai": "ก", "value": 1}, {"thai": "ข", "value": 1}]
        updates = [{"thai": "ข", "value": 2}, {"thai": "ค", "value": 2}]

        self.assertEqual(
            merge_rows(base, updates),
            [
                {"thai": "ก", "value": 1},
                {"thai": "ข", "value": 2},
                {"thai": "ค", "value": 2},
            ],
        )

    def test_rejects_duplicate_updates(self):
        with self.assertRaisesRegex(ValueError, "not unique"):
            merge_rows([], [{"thai": "ข"}, {"thai": "ข"}])


if __name__ == "__main__":
    unittest.main()

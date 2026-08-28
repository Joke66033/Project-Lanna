import unittest

from inference import LannaAIInference


class ReviewedLexiconRuntimeTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.engine = LannaAIInference()

    def test_verified_source_headword_is_used(self):
        result = self.engine.convert_thai_to_lanna("กินงาย")
        self.assertEqual(result["lanna_script"], "ᨠ᩠ᨶᩥᨦᩣ᩠ᨿ")
        self.assertFalse(result["needs_review"])
        self.assertEqual(result["segments"][0]["source"], "source_image_verified")

    def test_alias_returns_canonical_spelling_and_provenance(self):
        result = self.engine.convert_thai_to_lanna("กินเข้างาย")
        self.assertEqual(result["lanna_script"], "ᨠ᩠ᨶᩥᨦᩣ᩠ᨿ")
        self.assertEqual(result["segments"][0]["canonical_thai"], "กินงาย")
        self.assertTrue(result["segments"][0]["is_alias"])
        self.assertFalse(result["needs_review"])

    def test_multiple_dictionary_senses_are_returned(self):
        result = self.engine.convert_thai_to_lanna("กีบ")
        self.assertEqual(result["lanna_script"], "ᨠᩦ᩠ᨷ")
        self.assertEqual(len(result["segments"][0]["senses"]), 2)
        self.assertEqual(result["segments"][0]["senses"][0]["part_of_speech"], "น.")
        self.assertEqual(result["segments"][0]["senses"][1]["part_of_speech"], "ก.")

    def test_cross_page_dictionary_senses_are_returned(self):
        result = self.engine.convert_thai_to_lanna("กี")
        pages = [sense["source_page"] for sense in result["segments"][0]["senses"]]
        self.assertEqual(pages, [44, 45])

    def test_page_46_semantic_senses_are_returned(self):
        result = self.engine.convert_thai_to_lanna("กุ้ม")
        self.assertEqual(result["lanna_script"], "ᨠᩩ᩠᩶ᨾ")
        self.assertEqual(len(result["segments"][0]["senses"]), 3)
        self.assertFalse(result["needs_review"])

    def test_page_46_verified_compound_is_used(self):
        result = self.engine.convert_thai_to_lanna("กูบพล้าว")
        self.assertEqual(result["lanna_script"], "ᨠᩪ᩠ᨷᨻ᩠ᩃ᩶ᩣ᩠ᩅ")
        self.assertEqual(result["segments"][0]["source_pdf_page"], 46)

    def test_page_47_special_cluster_is_used(self):
        result = self.engine.convert_thai_to_lanna("เกราะ")
        self.assertEqual(result["lanna_script"], "ᩮᨠᩕᩣᩡ")
        self.assertEqual(result["segments"][0]["source_pdf_page"], 47)

    def test_page_47_multiple_senses_are_returned(self):
        result = self.engine.convert_thai_to_lanna("เก็ด")
        self.assertEqual(result["lanna_script"], "ᩮᨠᩢ᩠ᨯ")
        self.assertEqual(len(result["segments"][0]["senses"]), 3)

    def test_page_47_preposed_vowel_compound_is_used(self):
        result = self.engine.convert_thai_to_lanna("เกลือโป่ง")
        self.assertEqual(result["lanna_script"], "ᩮᨠᩨᩋᩰᨸᩫ᩠᩵ᨦ")
        self.assertFalse(result["needs_review"])

    def test_page_48_restored_source_record_is_used(self):
        result = self.engine.convert_thai_to_lanna("เก้ากอง")
        self.assertEqual(result["lanna_script"], "ᩮᨠᩢ᩶ᩣᨠ᩠ᩋᨦ")
        self.assertEqual(result["segments"][0]["source_pdf_page"], 48)

    def test_page_48_tai_tham_repetition_mark_is_valid(self):
        result = self.engine.convert_thai_to_lanna("เกิ่งๆ กลางๆ")
        self.assertEqual(result["lanna_script"], "ᩮᨠᩥ᩠᩵ᨦᪧ ᨠᩖᩣ᩠ᨦᪧ")
        self.assertTrue(result["is_valid_lanna_unicode"])

    def test_page_48_tone_distinction_is_preserved(self):
        born = self.engine.convert_thai_to_lanna("เกิด")
        block = self.engine.convert_thai_to_lanna("เกิ๊ด")
        self.assertEqual(born["lanna_script"], "ᩮᨠᩥ᩠ᨯ")
        self.assertEqual(block["lanna_script"], "ᩮᨠᩥ᩠᩶ᨯ")
        self.assertNotEqual(born["lanna_script"], block["lanna_script"])

    def test_page_49_five_senses_are_returned(self):
        result = self.engine.convert_thai_to_lanna("เกียง")
        self.assertEqual(result["lanna_script"], "ᩮᨠ᩠ᨿ᩠ᨦ")
        self.assertEqual(len(result["segments"][0]["senses"]), 5)

    def test_page_49_tone_distinction_is_preserved(self):
        low = self.engine.convert_thai_to_lanna("เกี่ยว")
        high = self.engine.convert_thai_to_lanna("เกี้ยว")
        self.assertEqual(low["lanna_script"], "ᩮᨠ᩠ᨿ᩠᩵ᩅ")
        self.assertEqual(high["lanna_script"], "ᩮᨠ᩠ᨿ᩠᩶ᩅ")

    def test_page_49_corrected_cross_column_entry_is_used(self):
        result = self.engine.convert_thai_to_lanna("แก่")
        self.assertEqual(result["segments"][0]["source_pdf_page"], 49)
        self.assertEqual(len(result["segments"][0]["senses"]), 4)

    def test_page_49_definition_continued_on_page_50_is_used(self):
        result = self.engine.convert_thai_to_lanna("แกงฮังเลเชียงแสน")
        self.assertEqual(result["lanna_script"], "ᩯᨠ᩠ᨦᩉᩢ᩠ᨦᩮᩃᩮᨩ᩠ᨿᨦᩯᩈ᩠ᨶ")
        self.assertFalse(result["needs_review"])

    def test_page_50_verified_compound_is_used(self):
        result = self.engine.convert_thai_to_lanna("แกงฮังเลม่าน")
        self.assertEqual(result["lanna_script"], "ᩯᨠ᩠ᨦᩉᩢ᩠ᨦᩮᩃ᩠ᨾ᩵ᩣ᩠ᨶ")
        self.assertEqual(result["segments"][0]["source_pdf_page"], 50)

    def test_page_50_multiple_senses_are_returned(self):
        core = self.engine.convert_thai_to_lanna("แกน")
        essence = self.engine.convert_thai_to_lanna("แก่น")
        self.assertEqual(len(core["segments"][0]["senses"]), 2)
        self.assertEqual(len(essence["segments"][0]["senses"]), 3)

    def test_page_50_alias_still_resolves_to_canonical_headword(self):
        result = self.engine.convert_thai_to_lanna("แกนขวด")
        self.assertEqual(result["lanna_script"], "ᩯᨠ᩠ᨶᨻᩣ᩠ᨦ")
        self.assertEqual(result["segments"][0]["canonical_thai"], "แกนพาง")
        self.assertTrue(result["segments"][0]["is_alias"])

    def test_page_51_similar_headwords_remain_distinct(self):
        brave = self.engine.convert_thai_to_lanna("แกล้ว")
        vietnamese = self.engine.convert_thai_to_lanna("แกว")
        dice = self.engine.convert_thai_to_lanna("แก่ว")
        glass = self.engine.convert_thai_to_lanna("แก้ว")
        self.assertEqual(brave["lanna_script"], "ᩯᨠᩖ᩶ᩅ")
        self.assertEqual(vietnamese["lanna_script"], "ᩯᨠ᩠ᩅ")
        self.assertEqual(dice["lanna_script"], "ᩯᨠ᩠᩵ᩅ")
        self.assertEqual(glass["lanna_script"], "ᩯᨠ᩠᩶ᩅ")

    def test_page_51_multiple_glass_senses_are_returned(self):
        result = self.engine.convert_thai_to_lanna("แก้ว")
        self.assertEqual(len(result["segments"][0]["senses"]), 2)
        self.assertEqual(result["segments"][0]["source_pdf_page"], 51)

    def test_page_51_verified_compounds_are_used(self):
        result = self.engine.convert_thai_to_lanna("แก้วทั้งสาม")
        self.assertEqual(result["lanna_script"], "ᩯᨠ᩠᩶ᩅᨴᩢ᩠᩶ᨦᩈᩣ᩠ᨾ")
        self.assertEqual(result["segments"][0]["category"], "ศาสนาและความเชื่อ")

    def test_page_52_verified_gem_compound_is_used(self):
        result = self.engine.convert_thai_to_lanna("แก้ววิทรูน้ำผึ้ง")
        self.assertEqual(result["lanna_script"], "ᩯᨠ᩠᩶ᩅᩅᩥᨴᩪᩁ᩠ᨶᩣᩴ᩶ᨹᩧ᩠᩶ᨦ")
        self.assertEqual(result["segments"][0]["source_pdf_page"], 52)

    def test_page_52_multiple_senses_are_returned(self):
        for word in ("แก้วมาลูน", "แก้วลอดฟ้า", "แกว่ง", "โก", "โกฏิ", "โกไสย"):
            with self.subTest(word=word):
                result = self.engine.convert_thai_to_lanna(word)
                self.assertEqual(len(result["segments"][0]["senses"]), 2)

    def test_page_52_similar_kwaen_headwords_remain_distinct(self):
        swing = self.engine.convert_thai_to_lanna("แกว่ง")
        skilled = self.engine.convert_thai_to_lanna("แกว่น")
        self.assertEqual(swing["lanna_script"], "ᩯᨠ᩠᩵ᩅᨦ")
        self.assertEqual(skilled["lanna_script"], "ᩯᨠ᩠᩵ᩅᩁ")

    def test_page_53_multiple_senses_are_returned(self):
        for word in ("โกด", "โกน", "โกบ"):
            with self.subTest(word=word):
                result = self.engine.convert_thai_to_lanna(word)
                self.assertEqual(len(result["segments"][0]["senses"]), 2)

    def test_page_53_tone_and_final_distinctions_are_preserved(self):
        protruding = self.engine.convert_thai_to_lanna("โก้")
        cavity = self.engine.convert_thai_to_lanna("โกน")
        basket = self.engine.convert_thai_to_lanna("โกย")
        self.assertEqual(protruding["lanna_script"], "ᩰᨠ᩶")
        self.assertEqual(cavity["lanna_script"], "ᩰᨠᩫ᩠ᨶ")
        self.assertEqual(basket["lanna_script"], "ᩰᨠᩫ᩠ᨿ")

    def test_page_53_cross_page_definition_is_used(self):
        result = self.engine.convert_thai_to_lanna("ไก่เจ้าเล้า")
        self.assertEqual(result["lanna_script"], "ᩱᨠ᩵ᩮᨧᩢ᩶ᩣᩮᩃᩢ᩶ᩣ")
        self.assertIn("เห็นคนอื่นดีกว่าคนของตัวเอง", result["segments"][0]["definition"])

    def test_page_54_similar_chicken_headwords_remain_distinct(self):
        small_comb = self.engine.convert_thai_to_lanna("ไก่ชง")
        fighting = self.engine.convert_thai_to_lanna("ไก่ชน")
        self.assertEqual(small_comb["lanna_script"], "ᩱᨠ᩵ᨩᩫ᩠ᨦ")
        self.assertEqual(fighting["lanna_script"], "ᩱᨠ᩵ᨩᩫ᩠ᨶ")

    def test_page_54_verified_compound_is_used(self):
        result = self.engine.convert_thai_to_lanna("ไก่หน้อย")
        self.assertEqual(result["lanna_script"], "ᩱᨠ᩵ᩉ᩠᩶ᨶ᩠ᩋ᩠ᨿ")
        self.assertEqual(result["segments"][0]["source_pdf_page"], 54)

    def test_page_54_tone_distinguishes_kai_from_kai_animal(self):
        plant = self.engine.convert_thai_to_lanna("ไก")
        mouse_deer = self.engine.convert_thai_to_lanna("ไก้")
        self.assertEqual(plant["lanna_script"], "ᩱᨠ")
        self.assertEqual(mouse_deer["lanna_script"], "ᩱᨠ᩶")

    def test_page_68_sara_am_and_long_compound_are_preserved(self):
        short = self.engine.convert_thai_to_lanna("ขำ")
        compound = self.engine.convert_thai_to_lanna("ขำเขือกเงือกญ้าว")
        self.assertEqual(short["lanna_script"], "ᨡᩣᩴ")
        self.assertEqual(
            compound["lanna_script"],
            "ᨡᩣᩴᩮᨡ᩠ᩋᩥᨠᩮᨬ᩠ᩋᩥᨠᨬ᩶ᩣ᩠ᩅ",
        )
        self.assertEqual(compound["segments"][0]["source_pdf_page"], 68)

    def test_page_68_homograph_meaning_and_reading_are_used(self):
        result = self.engine.convert_thai_to_lanna("ขิงแดง")
        segment = result["segments"][0]
        self.assertEqual(result["lanna_script"], "ᨡ᩠ᨦᩥᩯᨣ᩠ᨦ")
        self.assertEqual(segment["pronunciation"], "[ขิง - แกง]")
        self.assertIn("ขิงพันธุ์เล็ก", segment["definition"])

    def test_page_68_multiple_senses_are_returned(self):
        for word in ("ขิน", "ขินใจ"):
            with self.subTest(word=word):
                result = self.engine.convert_thai_to_lanna(word)
                self.assertEqual(len(result["segments"][0]["senses"]), 2)

    def test_page_68_similar_headwords_remain_distinct(self):
        news = self.engine.convert_thai_to_lanna("ข่าว")
        framework = self.engine.convert_thai_to_lanna("ข้าว")
        suspicious = self.engine.convert_thai_to_lanna("ขิ่ง")
        constrained = self.engine.convert_thai_to_lanna("ขิน")
        self.assertNotEqual(news["lanna_script"], framework["lanna_script"])
        self.assertNotEqual(suspicious["lanna_script"], constrained["lanna_script"])

    def test_page_69_final_khor_compound_is_used(self):
        result = self.engine.convert_thai_to_lanna("ไขว่ขว้างขวิดขวาง")
        self.assertEqual(
            result["lanna_script"],
            "ᩱᨡ᩠᩵ᩅᨡ᩠᩶ᩅᩣ᩠ᨦᨡ᩠ᩅᩥᨯᨡ᩠ᩅᩣ᩠ᨦ",
        )
        self.assertEqual(result["segments"][0]["source_pdf_page"], 69)
        self.assertIn("ไม่มีระเบียบ", result["segments"][0]["definition"])

    def test_page_69_final_khor_ritual_entry_is_used(self):
        result = self.engine.convert_thai_to_lanna("ไขว่ผี")
        self.assertEqual(result["lanna_script"], "ᩱᨡ᩠᩵ᩅᨹᩦ")
        self.assertEqual(result["segments"][0]["source_pdf_page"], 69)
        self.assertIn("พิธีแต่งงาน", result["segments"][0]["definition"])

    def test_page_70_kho_khuat_entry_is_used_and_kept_distinct(self):
        kho_khuat = self.engine.convert_thai_to_lanna("ฃาบฃยาบ")
        kho_khai = self.engine.convert_thai_to_lanna("ขาบหยาบ")
        segment = kho_khuat["segments"][0]
        self.assertEqual(kho_khuat["lanna_script"], "ᨢᩣ᩠ᨷᨢ᩠ᨿᩣ᩠ᨷ")
        self.assertEqual(segment["source_pdf_page"], 70)
        self.assertIn("พิธีแต่งงาน", segment["definition"])
        self.assertEqual(segment["category"], "ศาสนาและความเชื่อ")
        self.assertNotEqual(kho_khuat["lanna_script"], kho_khai["lanna_script"])

    def test_page_71_first_verified_kho_khwai_records_are_used(self):
        expected = {
            "ค็": "ᨣᩴ",
            "ค็ข้าแล": "ᨣᩴᨡ᩶ᩣᩓ",
            "ค็ดี": "ᨣᩴᨯᩦ",
            "ค็มี": "ᨣᩴᨾᩦ",
            "ค็แล้วเท่านี้ก่อนแล": "ᨣᩴᩓ᩠ᩅᩮ᩠ᨴᩢ᩵ᩣᨶᩦ᩶ᨠ᩠᩵ᩋᩁᩓ",
            "คกงก": "ᨣᩫ᩠ᨠᨦᩫ᩠ᨠ",
            "คชปาละ": "ᨣᨩᨷᩣᩃᩡ",
            "คชะ": "ᨣᨩᩡ",
            "คณนา": "ᨣᨱᨶᩣ",
            "คณะ": "ᨣᨱᩡ",
            "คณะคะนัง": "ᨣᨱᩡᨣᨶᩢ᩠ᨦ",
            "คณา": "ᨣᨱᩣ",
            "คด": "ᨣᩫ᩠ᨯ",
            "คดเคี้ยว": "ᨣᩫ᩠ᨯᨣ᩠᩶ᨿᩅ",
            "คดหง้องคดแห้ง": "ᨣᩫ᩠ᨯᩉ᩠᩶ᨦ᩠ᩋᨦᨣᩫ᩠ᨯᩯᩉ᩠᩶ᨦᨦ",
            "คดโหง้งคดหง้าง": "ᨣᩫ᩠ᨯᩰᩉ᩶ᩫ᩠ᨦᨦᨣᩫ᩠ᨯᩉ᩠᩶ᨦᩣ᩠ᨦ",
            "คถา": "ᨣᨳᩣ",
            "คด้าง": "ᨣᨯ᩶ᩣ᩠ᨦ",
            "คน": "ᨣᩫ᩠ᨶ",
            "คนคุน": "ᨣᩫ᩠ᨶᨣᩩ᩠ᨶ",
            "ค้น": "ᨣ᩶ᩫ᩠ᨶ",
        }
        for word, lanna in expected.items():
            with self.subTest(word=word):
                result = self.engine.convert_thai_to_lanna(word)
                self.assertEqual(result["lanna_script"], lanna)
                self.assertEqual(result["segments"][0]["source_pdf_page"], 71)
                self.assertFalse(result["needs_review"])

    def test_page_71_similar_kho_khwai_headwords_remain_distinct(self):
        straightness = self.engine.convert_thai_to_lanna("คด")
        stirring = self.engine.convert_thai_to_lanna("คน")
        sprain = self.engine.convert_thai_to_lanna("ค้น")
        self.assertNotEqual(straightness["lanna_script"], stirring["lanna_script"])
        self.assertNotEqual(stirring["lanna_script"], sprain["lanna_script"])

    def test_page_72_verified_medial_ra_records_are_used(self):
        expected = {
            "ครก": "ᨣᩕᩫ᩠ᨠ",
            "ครกพริก": "ᨣᩕᩫ᩠ᨠᨻᩕ᩠ᨠᩥ",
            "ครกมอง": "ᨣᩕᩫ᩠ᨠᨾ᩠ᩋᨦ",
            "ครบ": "ᨣᩕᩫ᩠ᨸ",
            "ครบงัน": "ᨣᩕᩫ᩠ᨸᨦ᩠ᨶᩢ",
            "ครบยำ": "ᨣᩕᩫ᩠ᨸᨿᩣᩴ",
            "ครอก": "ᨣᩕ᩠ᩋᨠ",
            "ครอกเหล็ก": "ᨣᩕ᩠ᩋᨠᩮᩉ᩠ᩃᩢᨠ",
            "ครอง": "ᨣᩕ᩠ᩋᨦ",
            "ครอบ": "ᨣᩕ᩠ᩋᨷ",
            "ครอบครัว": "ᨣᩕ᩠ᩋᨷᨣᩕᩫ᩠ᩅ",
            "คร่อม": "ᨣᩕ᩠᩵ᩋᨾ",
            "คระซัง": "ᨣᩕᨪ᩠ᨦᩢ",
            "คระซิง": "ᨣᩕᨪ᩠ᨦᩥ",
            "คระเจ้า": "ᨣᩕᩮᨧᩢ᩶ᩣ",
            "คระดาน": "ᨣᩕᨯᩣ᩠ᨶ",
            "คระนอง": "ᨣᩕᨶ᩠ᩋᨦ",
            "คระนิง": "ᨣᩕᨶ᩠ᨦᩥ",
            "คระพุม": "ᨣᩕᨻ᩠ᨾᩩ",
            "คระมุย": "ᨣᩕᨾᩩᨿ",
            "คระหวัด": "ᨣᩕᩉ᩠ᩅᩢᨯ",
        }
        for word, lanna in expected.items():
            with self.subTest(word=word):
                result = self.engine.convert_thai_to_lanna(word)
                self.assertEqual(result["lanna_script"], lanna)
                self.assertEqual(result["segments"][0]["source_pdf_page"], 72)
                self.assertFalse(result["needs_review"])

    def test_page_72_verified_non_cluster_records_are_used(self):
        expected = {
            "คบ": "ᨣᩫ᩠ᨸ",
            "ค้มง้ม": "ᨣ᩶ᩫ᩠ᨾᨦ᩶ᩫ᩠ᨾ",
            "คมรบ": "ᨣᩴᩃᩫ᩠ᨷ",
        }
        for word, lanna in expected.items():
            with self.subTest(word=word):
                result = self.engine.convert_thai_to_lanna(word)
                self.assertEqual(result["lanna_script"], lanna)
                self.assertEqual(result["segments"][0]["source_pdf_page"], 72)

    def test_page_73_verified_records_are_used(self):
        expected = {
            "คัก": "ᨣ᩠ᨠᩢ",
            "ครั่ง": "ᨣᩕᩢ᩠᩵ᨦ",
            "ครัว": "ᨣᩕᩫ᩠ᩅ",
            "ครัวกิน": "ᨣᩕᩫ᩠ᩅᨠ᩠ᨶᩥ",
            "ครัวทรง": "ᨣᩕᩫ᩠ᩅᨴᩕᩫ᩠ᨦ",
            "ครัวท้อง": "ᨣᩕᩫ᩠ᩅᨴ᩠᩶ᩋᨦ",
            "ครัวท้องลง": "ᨣᩕᩫ᩠ᩅᨴ᩠᩶ᩋᨦᩃᩫ᩠ᨦ",
            "ครัวทาน": "ᨣᩕᩫ᩠ᩅ᩠ᨴᩣ᩠ᨶ",
            "ครัวใน": "ᨣᩕᩫ᩠ᩅᩱᨶ",
            "ครัวมือ": "ᨣᩕᩫ᩠ᩅᨾᩨ",
            "ครัวรอม": "ᨣᩕᩫ᩠ᩅᩁ᩠ᩋᨾ",
            "ครัวเรือน": "ᨣᩕᩫ᩠ᩅᩮᩁ᩠ᩋᩥᩁ",
            "ครัวหอครัวเรือน": "ᨣᩕᩫ᩠ᩅᩉᩴ᩠ᩋᨣᩕᩫ᩠ᩅᩮᩁ᩠ᩋᩥᩁ",
            "ครัวยา": "ᨣᩕᩫ᩠ᩅᨿᩣ",
            "ครา": "ᨣᩕᩣ",
            "คราก": "ᨣᩕᩣ᩠ᨠ",
            "คราง": "ᨣᩕᩣ᩠ᨦ",
            "คราด": "ᨣᩕᩣ᩠ᨯ",
            "คราน": "ᨣᩕᩣ᩠ᨶ",
            "คร้าน": "ᨣᩕ᩶ᩣ᩠ᨶ",
            "คราบ": "ᨣᩕᩣ᩠ᨸ",
        }
        for word, lanna in expected.items():
            with self.subTest(word=word):
                result = self.engine.convert_thai_to_lanna(word)
                self.assertEqual(result["lanna_script"], lanna)
                self.assertEqual(result["segments"][0]["source_pdf_page"], 73)
                self.assertFalse(result["needs_review"])

    def test_page_73_continued_definition_is_complete(self):
        result = self.engine.convert_thai_to_lanna("คราบ")
        definition = result["segments"][0]["definition"]
        self.assertIn("ซากศพ", definition)
        self.assertIn("รอยเปื้อน", definition)

    def test_page_74_verified_records_are_used(self):
        expected = {
            "คราบร้าย": "ᨣᩕᩣ᩠ᨸᩁ᩶ᩣ᩠ᨿ",
            "คราม": "ᨣᩕᩣ᩠ᨾ",
            "ครามหลวง": "ᨣᩕᩣ᩠ᨾᩉ᩠ᩃ᩠ᩅᨦ",
            "คร่าม": "ᨣᩕ᩵ᩣ᩠ᨾ",
            "คราว": "ᨣᩕᩣ᩠ᩅ",
            "คราวทาง": "ᨣᩕᩣ᩠ᩅᨴᩣ᩠ᨦ",
            "คร่าว": "ᨣᩕ᩵ᩣ᩠ᩅ",
            "คร่าวก้อม": "ᨣᩕ᩵ᩣ᩠ᩅᨠ᩠᩶ᩋᨾ",
            "คร่าวเครือ": "ᨣᩕ᩵ᩣ᩠ᩅᩮᨣᩕ᩠ᩋᩥᩋ",
            "คร่าวใช้": "ᨣᩕ᩵ᩣ᩠ᩅᩱᨩ᩶",
            "คร่าวซอ": "ᨣᩕ᩵ᩣ᩠ᩅᨪᩴ᩠ᩋ",
            "คร่าวธัมม์": "ᨣᩕ᩵ᩣ᩠ᩅᨵᩢᨾ᩠᩺ᨾ",
            "คร่าวร่ำ": "ᨣᩕ᩵ᩣ᩠ᩅᩁ᩵ᩣᩴ",
            "คร่าวว้อง": "ᨣᩕ᩵ᩣ᩠ᩅᩅ᩠᩶ᩋᨦ",
            "คร้าว": "ᨣᩕ᩶ᩣ᩠ᩅ",
            "คร่ำ": "ᨣᩕ᩵ᩣᩴ",
            "คร่ำชาราวี": "ᨣᩕ᩵ᩣᩴᨩᩣᩁᩣᩅᩦ",
            "คร่ำครัว": "ᨣᩕ᩵ᩣᩴᨣᩕᩫ᩠ᩅ",
            "คร่ำงำ": "ᨣᩕ᩵ᩣᩴᨦᩣᩴ",
        }
        for word, lanna in expected.items():
            with self.subTest(word=word):
                result = self.engine.convert_thai_to_lanna(word)
                self.assertEqual(result["lanna_script"], lanna)
                self.assertEqual(result["segments"][0]["source_pdf_page"], 74)
                self.assertFalse(result["needs_review"])

    def test_page_75_verified_records_are_used(self):
        expected = {
            "คร่ำชรา": "ᨣᩕ᩵ᩣᩴᨩᩁᩣ",
            "คริ่น": "ᨣᩕᩥ᩠᩵ᨶ",
            "ครี": "ᨣᩕᩦ",
            "ครีด": "ᨣᩕᩦᨯ",
            "ครืน": "ᨣᩕ᩠ᨶᩨ",
            "ครื่อ": "ᨣᩕᩨ᩵",
            "ครุ": "ᨣᩕᩩ",
            "ครุงคราว": "ᨣᩕᩩ᩠ᨦᨣᩕᩣ᩠ᩅ",
            "ครุฑ": "ᨣᩕᩩᨯ",
            "ครุบ": "ᨣᩕᩩ᩠ᨸ",
            "ครุบชิง": "ᨣᩕᩩ᩠ᨸᨩ᩠ᨦᩥ",
            "ครุ่ม": "ᨣᩕᩩ᩠᩵ᨾ",
            "ครุ่มเครือวัลย์": "ᨣᩕᩩ᩠᩵ᨾᩮᨣᩕ᩠ᩋᩥᩋᩅᩢ᩠ᩃ᩠ᨿ",
            "ครุ่มหน้อย": "ᨣᩕᩩ᩠᩵ᨾᩉ᩠ᨶ᩠᩶ᩋᨿ",
            "ครุ่มหลวง": "ᨣᩕᩩ᩠᩵ᨾᩉ᩠ᩃ᩠ᩅᨦ",
            "ครู": "ᨣᩕᩪ",
            "ครูบา": "ᨣᩕᩪᨷᩣ",
            "ครูด": "ᨣᩕᩪᨯ",
            "คลวง": "ᨣᩖ᩠ᩅᨦ",
            "คลอง": "ᨣᩖ᩠ᩋᨦ",
            "คลองกีด": "ᨣᩖ᩠ᩋᨦᨠ᩠ᨯᩦ",
            "คลองไคว่": "ᨣᩖ᩠ᩋᨦᩱᨣ᩵ᩅ",
            "คลองชาย": "ᨣᩖ᩠ᩋᨦᨩᩣ᩠ᨿ",
        }
        for word, lanna in expected.items():
            with self.subTest(word=word):
                result = self.engine.convert_thai_to_lanna(word)
                self.assertEqual(result["lanna_script"], lanna)
                self.assertEqual(result["segments"][0]["source_pdf_page"], 75)
                self.assertFalse(result["needs_review"])

    def test_page_75_khrum_keeps_both_dictionary_senses(self):
        result = self.engine.convert_thai_to_lanna("ครุ่ม")
        senses = result["segments"][0]["senses"]
        self.assertEqual(len(senses), 2)
        self.assertTrue(any("พุ่ม" in sense["meaning"] for sense in senses))
        self.assertTrue(any("ราชสำนัก" in sense["meaning"] for sense in senses))

    def test_page_76_verified_records_are_used(self):
        expected = {
            "คลองฮีบ": "ᨣᩖ᩠ᩋᨦᩌᩦ᩠ᨷ",
            "คลองหน้อย": "ᨣᩖ᩠ᩋᨦᩉ᩠᩶ᨶ᩠ᩋᨿ",
            "คลองหลวง": "ᨣᩖ᩠ᩋᨦᩉ᩠ᩃ᩠ᩅᨦ",
            "คล้อง": "ᨣᩖ᩠᩶ᩋᨦ",
            "คล้อม": "ᨣᩖ᩠᩶ᩋᨾ",
            "คล้อย": "ᨣᩖ᩠᩶ᩋᨿ",
            "คลั่ง": "ᨣᩖᩢ᩠᩵ᨦ",
            "คลั่งๆ จวังๆ": "ᨣᩖᩢ᩠᩵ᨦ᩻ ᨧ᩠ᩅᩢᨦ᩻",
            "คลา": "ᨣᩖᩣ",
            "คลาด": "ᨣᩖᩣ᩠ᨯ",
            "คลาดคล้อย": "ᨣᩖᩣ᩠ᨯᨣᩖ᩠᩶ᩋᨿ",
            "คลาดคลา": "ᨣᩖᩣ᩠ᨯᨣᩖᩣ",
            "คลาดแคล้ว": "ᨣᩖᩣ᩠ᨯᩯᨣᩖ᩠᩶ᩅ",
            "คลาน": "ᨣᩖᩣ᩠ᨶ",
            "คล่ำ": "ᨣᩖ᩵ᩣᩴ",
            "คลิก": "ᨣᩖ᩠ᨠᩥ",
            "คลี่": "ᨣᩖᩦ᩵",
            "คลื่นเค้า": "ᨣᩖ᩠᩵ᨶᩨᩮᨣᩢ᩶ᩣ",
            "คโลง": "ᨣᩡᩰᩃᩫ᩠ᨦ",
            "คโลงสลาก": "ᨣᩡᩰᩃᩫ᩠ᨦᩈᩃᩣ᩠ᨠ",
            "ควง": "ᨣ᩠ᩅᨦ",
            "ควงคว้าง": "ᨣ᩠ᩅᨦᨣ᩠ᩅ᩶ᩣ᩠ᨦ",
            "ควงพัด": "ᨣ᩠ᩅᨦᨻᩢᨯ",
        }
        for word, lanna in expected.items():
            with self.subTest(word=word):
                result = self.engine.convert_thai_to_lanna(word)
                self.assertEqual(result["lanna_script"], lanna)
                self.assertEqual(result["segments"][0]["source_pdf_page"], 76)
                self.assertFalse(result["needs_review"])

    def test_page_76_dictionary_spelling_khalong_is_preserved(self):
        result = self.engine.convert_thai_to_lanna("คโลง")
        self.assertEqual(result["segments"][0]["canonical_thai"], "คโลง")
        self.assertIn("คำประพันธ์", result["segments"][0]["definition"])

    def test_page_77_verified_records_are_used(self):
        expected = {
            "ควงยนต์": "ᨣ᩠ᩅᨦᨿᩫ᩠ᨶ᩠ᨲ",
            "ควม": "ᨣ᩠ᩅᨾ",
            "ควมงาย": "ᨣ᩠ᩅᨾᨦᩣ᩠ᨿ",
            "ควมตอน": "ᨣ᩠ᩅᨾᨲ᩠ᩋᨶ",
            "ควมร้อน": "ᨣ᩠ᩅᨾᩁ᩠᩶ᩋᩁ",
            "ควมแลง": "ᨣ᩠ᩅᨾᩯᩃ᩠ᨦ",
            "ควร": "ᨣ᩠ᩅᩁ",
            "ควรสนุกถูกเนื้อเพิงใจ": "ᨣ᩠ᩅᩁᩈᨶᩩᨠᨳᩪᨠᩮᨶ᩠ᩋᩥ᩶ᩮᨻᩥ᩠ᨦᩱᨧ",
            "ค่องแค่ง": "ᨣ᩠᩵ᩋᨦᩯᨣ᩠᩵ᨦ",
            "ควก": "ᨣ᩠ᩅᨠ",
            "ควกๆ จี้ๆ": "ᨣ᩠ᩅᨠ᩻ ᨧᩦ᩶᩻",
            "ควด": "ᨣ᩠ᩅᨯ",
            "คว่า": "ᨣ᩠ᩅ᩵ᩣ",
            "ควาน": "ᨣ᩠ᩅᩣ᩠ᨶ",
            "คว้าน": "ᨣ᩠ᩅ᩶ᩣ᩠ᨶ",
            "คว้านตีน": "ᨣ᩠ᩅ᩶ᩣ᩠ᨶᨲᩦ᩠ᨶ",
            "ควิน": "ᨣ᩠ᩅᩥ᩠ᨶ",
            "ควี": "ᨣ᩠ᩅᩦ",
            "ควิก": "ᨣ᩠ᩅ᩠ᨠᩥ",
            "คหะ": "ᨣᩉᩡ",
            "คอ": "ᨣᩴ᩠ᩋ",
        }
        for word, lanna in expected.items():
            with self.subTest(word=word):
                result = self.engine.convert_thai_to_lanna(word)
                self.assertEqual(result["lanna_script"], lanna)
                self.assertEqual(result["segments"][0]["source_pdf_page"], 77)
                self.assertFalse(result["needs_review"])

    def test_page_77_repeated_words_use_tai_tham_repetition_sign(self):
        result = self.engine.convert_thai_to_lanna("ควกๆ จี้ๆ")
        self.assertNotIn("ๆ", result["lanna_script"])
        self.assertEqual(result["lanna_script"].count("᩻"), 2)

    def test_page_78_verified_records_are_used(self):
        expected = {
            "ค้อ": "ᨣᩴ᩠᩶ᩋ",
            "ค็อก": "ᨣ᩠ᩋᩢᨠ",
            "ค็อกง็อก": "ᨣ᩠ᩋᩢᨠᨦ᩠ᩋᩢᨠ",
            "คอกวอก": "ᨣ᩠ᩋᨠᩅ᩠ᩋᨠ",
            "คอง": "ᨣ᩠ᩋᨦ",
            "คองถ้า": "ᨣ᩠ᩋᨦᨳ᩶ᩣ",
            "คองหา": "ᨣ᩠ᩋᨦᩉᩣ",
            "ค้อง": "ᨣ᩠᩶ᩋᨦ",
            "ค้องกบ": "ᨣ᩠᩶ᩋᨦᨠᩫ᩠ᨸ",
            "ค้องเก้า": "ᨣ᩠᩶ᩋᨦᨠᩢ᩶ᩣ",
            "ค้องแกบ": "ᨣ᩠᩶ᩋᨦᩯᨠ᩠ᨷ",
            "ค้องชัย": "ᨣ᩠᩶ᩋᨦᩱᨩ",
            "ค้องราง": "ᨣ᩠᩶ᩋᨦᩁᩣ᩠ᨦ",
            "ค้องวง": "ᨣ᩠᩶ᩋᨦᩅᩫ᩠ᨦ",
            "ค้องหน้อย": "ᨣ᩠᩶ᩋᨦᩉ᩠᩶ᨶ᩠ᩋ᩠ᨿ",
            "ค้องหม้อง": "ᨣ᩠᩶ᩋᨦᩉ᩠᩶ᨾ᩠ᩋᨦ",
            "ค้องหุย": "ᨣ᩠᩶ᩋᨦᩉᩩ᩠ᨿ",
            "ค้องแหม้ง": "ᨣ᩠᩶ᩋᨦᩯᩉ᩠᩶ᨾᨦ",
            "ค้องโหย้ง": "ᨣ᩠᩶ᩋᨦᩰᩉ᩶ᩫ᩠ᨿᨦ",
            "ค้องอุ้ย": "ᨣ᩠᩶ᩋᨦᩋᩩ᩠᩶ᨿ",
            "คอด": "ᨣ᩠ᩋᨯ",
            "คอน": "ᨣ᩠ᩋᩁ",
            "คอนกว้าง": "ᨣ᩠ᩋᩁᨠ᩠ᩅ᩶ᩣ᩠ᨦ",
        }
        for word, lanna in expected.items():
            with self.subTest(word=word):
                result = self.engine.convert_thai_to_lanna(word)
                self.assertEqual(result["lanna_script"], lanna)
                self.assertEqual(result["segments"][0]["source_pdf_page"], 78)
                self.assertFalse(result["needs_review"])

    def test_page_78_tone_distinguishes_khong_headwords(self):
        waiting = self.engine.convert_thai_to_lanna("คอง")
        gong = self.engine.convert_thai_to_lanna("ค้อง")
        self.assertNotEqual(waiting["lanna_script"], gong["lanna_script"])
        self.assertIn("รอ", waiting["segments"][0]["definition"])
        self.assertIn("ฆ้อง", gong["segments"][0]["definition"])

    def test_page_79_verified_records_are_used(self):
        expected = {
            "คอนว่า": "ᨣ᩠ᩋᩁ᩠ᩅ᩵ᩣ",
            "ค้อน": "ᨣ᩠᩶ᩋᩁ",
            "ค้อนไก้": "ᨣ᩠᩶ᩋᩁᩱᨠ᩶",
            "คอบ": "ᨣ᩠ᩋᨷ",
            "ค็อบ": "ᨣ᩠ᩋᩢᨷ",
            "ค็อบแค็บ": "ᨣ᩠ᩋᩢᨷᩯᨣ᩠ᨸᩢ",
            "คอม": "ᨣ᩠ᩋᨾ",
            "คอมค่อ": "ᨣ᩠ᩋᨾᨣᩴ᩠ᩋ᩵",
            "คอมค่อขาว": "ᨣ᩠ᩋᨾᨣᩴ᩠ᩋ᩵ᨡᩣ᩠ᩅ",
            "คอมค่อดำ": "ᨣ᩠ᩋᨾᨣᩴ᩠ᩋ᩵ᨯᩣᩴ",
            "คอมมอม": "ᨣ᩠ᩋᨾᨾ᩠ᩋᨾ",
            "ค่อม": "ᨣ᩠᩵ᩋᨾ",
            "ค่อมคำ": "ᨣ᩠᩵ᩋᨾᨣᩣᩴ",
            "ค่อมไซ้": "ᨣ᩠᩵ᩋᨾᩱᨪ᩶",
            "ค่อมพอ": "ᨣ᩠᩵ᩋᨾᨻᩴ᩠ᩋ",
            "ค้อม": "ᨣ᩠᩶ᩋᨾ",
            "ค้อมง้อม": "ᨣ᩠᩶ᩋᨾᨦ᩠᩶ᩋᨾ",
            "คอย": "ᨣ᩠ᩋ᩠ᨿ",
            "คอยเมื่อ": "ᨣ᩠ᩋ᩠ᨿᩮᨾᩥ᩠᩵ᩋᩋ",
            "ค่อย": "ᨣ᩠᩵ᩋ᩠ᨿ",
        }
        for word, lanna in expected.items():
            with self.subTest(word=word):
                result = self.engine.convert_thai_to_lanna(word)
                self.assertEqual(result["lanna_script"], lanna)
                self.assertEqual(result["segments"][0]["source_pdf_page"], 79)
                self.assertFalse(result["needs_review"])

    def test_page_79_similar_headwords_remain_distinct(self):
        khom = self.engine.convert_thai_to_lanna("คอม")
        short = self.engine.convert_thai_to_lanna("ค่อม")
        bend = self.engine.convert_thai_to_lanna("ค้อม")
        self.assertEqual(len({khom["lanna_script"], short["lanna_script"], bend["lanna_script"]}), 3)
        self.assertIn("แมลงปีกแข็ง", khom["segments"][0]["definition"])
        self.assertIn("ตั่งเตี้ย", short["segments"][0]["definition"])
        self.assertIn("โน้มลง", bend["segments"][0]["definition"])

    def test_page_80_verified_records_are_used(self):
        expected = {
            "ค่อย ๆ": "ᨣ᩠᩵ᩋ᩠ᨿ᩻", "ค้อย": "ᨣ᩠᩶ᩋ᩠ᨿ",
            "คะตึก": "ᨣᩡᨲᩧ᩠ᨠ", "คะเตน": "ᨣᩡᩮᨲ᩠ᨶ",
            "คะทั่ง": "ᨣᩡᨴᩢ᩠᩵ᨦ", "คะทิง": "ᨣᩡᨴᩥ᩠ᨦ",
            "คะล้อง": "ᨣᩡᩃ᩠᩶ᩋᨦ", "คะลิก": "ᨣᩡᩃᩥ᩠ᨠ",
            "คะลุม": "ᨣᩡᩃᩩ᩠ᨾ", "คัก": "ᨣ᩠ᨠᩢ", "คัง": "ᨣᩢᨦ",
            "คังคา": "ᨣ᩠ᨦ᩠ᨣᩢᩣ", "คั่ง": "ᨣᩢ᩠᩵ᨦ",
            "คั่งกิด": "ᨣᩢ᩠᩵ᨦᨠᩥ᩠ᨯ", "คั่งคลาด": "ᨣᩢ᩠᩵ᨦᨣᩖᩣ᩠ᨯ",
            "คัด": "ᨣᩢ᩠ᨯ", "คัดคั่งแค้น": "ᨣᩢ᩠ᨯᨣᩢ᩠᩵ᨦᩯᨣ᩠᩶ᨶ",
            "คัดท้อง": "ᨣᩢ᩠ᨯᨴ᩠᩶ᩋᨦ", "คัดอก": "ᨣᩢ᩠ᨯᩋᩫ᩠ᨠ",
            "คัดอึ้งอึ้ง": "ᨣᩢ᩠ᨯᩋᩧ᩠᩶ᨦᩋᩧ᩠᩶ᨦ", "คัน": "ᨣᩢ᩠ᨶ",
            "คันชัก": "ᨣᩢ᩠ᨶᨩᩢ᩠ᨠ", "คันตัง": "ᨣᩢ᩠ᨶᨲᩢᨦ",
        }
        for word, lanna in expected.items():
            with self.subTest(word=word):
                result = self.engine.convert_thai_to_lanna(word)
                self.assertEqual(result["lanna_script"], lanna)
                if word == "คัก":
                    self.assertIn(80, {sense["source_page"] for sense in result["segments"][0]["senses"]})
                else:
                    self.assertEqual(result["segments"][0]["source_pdf_page"], 80)
                self.assertFalse(result["needs_review"])

    def test_page_80_homograph_senses_are_preserved(self):
        result = self.engine.convert_thai_to_lanna("คัก")
        self.assertEqual(len(result["segments"][0]["senses"]), 3)
        definitions = " ".join(sense["meaning"] for sense in result["segments"][0]["senses"])
        self.assertIn("แน่ชัด", definitions)
        self.assertIn("ติดขัด", definitions)
        self.assertIn("พูดติดอ่าง", definitions)

    def test_page_80_khat_uses_one_final_sakot(self):
        result = self.engine.convert_thai_to_lanna("คัด")
        self.assertEqual(result["lanna_script"], "ᨣᩢ᩠ᨯ")
        self.assertNotIn("᩠᩠", result["lanna_script"])

    def test_page_81_verified_records_are_used(self):
        expected = {
            "คันธรรมาจารย์":"ᨣᩢ᩠ᨶᨵᨾ᩠ᨾᩣᨧᩣᩁ᩠ᨿ", "คันธะ":"ᨣᩢ᩠ᨶᨵ",
            "คันเถิง":"ᨣᩢ᩠ᨶᩮᨳᩥ᩠ᨦ", "คันธกุฎี":"ᨣᩢ᩠ᨶᨵᨠᩩᨭᩦ",
            "คันธัพพะ":"ᨣᩢ᩠ᨶᨵᩢᨻ᩠ᨻᩡ", "คันว่า":"ᨣᩢ᩠ᨶ᩠ᩅ᩵ᩣ",
            "คันอั้น":"ᨣᩢ᩠ᨶᩋᩢ᩠᩶ᨶ", "คั้น":"ᨣᩢ᩠᩶ᨶ", "คับ":"ᨣ᩠ᨸᩢ",
            "คับใจ":"ᨣ᩠ᨸᩢᩱᨧ", "คับท้อง":"ᨣ᩠ᨸᩢᨴ᩠᩶ᩋᨦ",
            "คัพภะ":"ᨣᩢᨻ᩠ᨽᩡ", "คัมภีระ":"ᨣᩢᨾ᩠ᨽᩦᩁᩡ", "คัล":"ᨣ᩠ᩃᩢ",
            "คัวใบ":"ᨣ᩠ᩅᩫᩱᨷ", "คา":"ᨣᩣ", "คาถา":"ᨣᩣᨳᩣ",
            "คาถาตาแดง":"ᨣᩣᨳᩣᨲᩣᩯᨯ᩠ᨦ",
            "คาถาทุตเลือด":"ᨣᩣᨳᩣᨴᩩ᩠ᨲᩮᩃᩥᩬ᩠ᨯ",
            "คาถาพัน":"ᨣᩣᨳᩣᨻ᩠ᨶᩢ", "คาถามหาทูบ":"ᨣᩣᨳᩣᨾᩉᩣᨴᩪ᩠ᨷ",
            "คาถามหาสันติ่งหลวง":"ᨣᩣᨳᩣᨾᩉᩣᩈᩢ᩠ᨶᨲᩥ᩠᩵ᨦᩉᩖ᩠ᩅᨦ",
        }
        for word, lanna in expected.items():
            with self.subTest(word=word):
                result = self.engine.convert_thai_to_lanna(word)
                self.assertEqual(result["lanna_script"], lanna)
                self.assertFalse(result["needs_review"])

    def test_page_81_kandha_and_katha_senses_are_preserved(self):
        kandha = self.engine.convert_thai_to_lanna("คันธะ")
        katha = self.engine.convert_thai_to_lanna("คาถา")
        self.assertEqual(len(kandha["segments"][0]["senses"]), 2)
        self.assertEqual(len(katha["segments"][0]["senses"]), 2)
        self.assertIn(81, {sense["source_page"] for sense in katha["segments"][0]["senses"]})
        self.assertNotIn("᩠᩠", katha["lanna_script"])

    def test_page_82_verified_records_are_used(self):
        expected = {
            "คาถาสาวหุม":"ᨣᩣᨳᩣᩈᩣ᩠ᩅᩉᩩᨾ",
            "คาถาหนังพันผืน":"ᨣᩣᨳᩣᩉ᩠ᨶᩢᨦᨻᩢ᩠ᨶᨹᩨ᩠ᨶ",
            "คามะ":"ᨣᩣᨾᩡ", "คารวะ":"ᨣᩣᩁᩅᩡ", "คาวา":"ᨣᩣᩅᩣ",
            "คาว่า":"ᨣᩣᩅ᩵ᩣ", "คาวุต":"ᨣᩣᩅᩩ᩠ᨲ", "คาหา":"ᨣᩣᩉᩣ",
            "ค่า":"ᨣ᩵ᩣ", "ค่าคิง":"ᨣ᩵ᩣᨣᩥ᩠ᨦ",
            "ค่าจ้าง":"ᨣ᩵ᩣᨧ᩶ᩣ᩠ᨦ", "ค่าจ้างค่าออน":"ᨣ᩵ᩣᨧ᩶ᩣ᩠ᨦᨣ᩵ᩣᩋ᩠ᩋᩁ",
            "ค่าช้าง":"ᨣ᩵ᩣᨩ᩶ᩣ᩠ᨦ", "ค่าตอ":"ᨣ᩵ᩣᨲᩴ᩠ᩋ",
            "ค่าตัว":"ᨣ᩵ᩣᨲᩫ᩠ᩅ", "ค่าตา":"ᨣ᩵ᩣᨲᩣ", "ค่ามือ":"ᨣ᩵ᩣᨾᩨ",
            "ค่ายาก":"ᨣ᩵ᩣᨿᩣ᩠ᨠ", "ค่าเลี้ยงผี":"ᨣ᩵ᩣᩮᩃᩦ᩠᩶ᨿᨦᨹᩦ",
        }
        for word, lanna in expected.items():
            with self.subTest(word=word):
                result = self.engine.convert_thai_to_lanna(word)
                self.assertEqual(result["lanna_script"], lanna)
                self.assertEqual(result["segments"][0]["source_pdf_page"], 82)
                self.assertFalse(result["needs_review"])

    def test_page_82_kha_and_value_are_distinct(self):
        stuck = self.engine.convert_thai_to_lanna("คา")
        value = self.engine.convert_thai_to_lanna("ค่า")
        self.assertEqual(stuck["lanna_script"], "ᨣᩣ")
        self.assertEqual(value["lanna_script"], "ᨣ᩵ᩣ")
        self.assertNotEqual(stuck["lanna_script"], value["lanna_script"])
        self.assertIn("ราคา", value["segments"][0]["definition"])

    def test_page_82_long_aa_entries_have_no_leading_sakot(self):
        for word in ("ค่า", "คาถาสาวหุม", "ค่าตัว", "ค่ายาก"):
            with self.subTest(word=word):
                result = self.engine.convert_thai_to_lanna(word)
                self.assertFalse(result["lanna_script"].startswith("᩠"))

    def test_page_83_verified_records_are_used(self):
        expected = {
            "ค่าสามสิก":"ᨣ᩵ᩣᩈᩣ᩠ᨾᩈ᩠ᨠᩥ", "ค่าหา":"ᨣ᩵ᩣᩉᩣ",
            "ค้า":"ᨣ᩶ᩣ", "ค้าก้อม":"ᨣ᩶ᩣᨠ᩠᩶ᩋᨾ",
            "คากวาก":"ᨣᩣᨠ᩠ᩅᩣ᩠ᨠ", "คาง":"ᨣᩣ᩠ᨦ",
            "คางกบ":"ᨣᩣ᩠ᨦᨠᩫ᩠ᨷ", "ค่าง":"ᨣ᩵ᩣ᩠ᨦ", "ค้าง":"ᨣ᩶ᩣ᩠ᨦ",
            "ค้างทุง":"ᨣ᩶ᩣ᩠ᨦᨴᩩ᩠ᨦ", "ค้างเทียน":"ᨣ᩶ᩣ᩠ᨦᨴ᩠ᨿᩁ",
            "ค้างธัมม์":"ᨣ᩶ᩣ᩠ᨦᨵ᩠ᨾᩢᨾ", "ค้างบอกไฟ":"ᨣ᩶ᩣ᩠ᨦᨷ᩠ᩋᨠᩱᨼ",
            "ค้างปอ":"ᨣ᩶ᩣ᩠ᨦᨸᩴ᩠ᩋ", "ค้างพวน":"ᨣ᩶ᩣ᩠ᨦᨻ᩠ᩅᨶ",
            "ค้างเฟือง":"ᨣ᩶ᩣ᩠ᨦᩮᨼ᩠ᩋᩥᨦ", "คาด":"ᨣᩣ᩠ᨯ",
            "คาน":"ᨣᩣ᩠ᨶ", "ค่านง่าน":"ᨣ᩵ᩣ᩠ᨶᨦ᩵ᩣ᩠ᨶ",
            "ค้าน":"ᨣ᩶ᩣ᩠ᨶ", "ค้านง่อยฟุ้ง":"ᨣ᩶ᩣ᩠ᨶᨦ᩠᩵ᩋ᩠ᨿᨼᩩ᩠᩶ᨦ",
            "คาบ":"ᨣᩣ᩠ᨸ",
        }
        for word, lanna in expected.items():
            with self.subTest(word=word):
                result = self.engine.convert_thai_to_lanna(word)
                self.assertEqual(result["lanna_script"], lanna)
                self.assertEqual(result["segments"][0]["source_pdf_page"], 83)
                self.assertFalse(result["needs_review"])

    def test_page_83_khang_tones_are_distinct(self):
        chin = self.engine.convert_thai_to_lanna("คาง")
        langur = self.engine.convert_thai_to_lanna("ค่าง")
        support = self.engine.convert_thai_to_lanna("ค้าง")
        self.assertEqual(len({chin["lanna_script"], langur["lanna_script"], support["lanna_script"]}), 3)
        self.assertIn("คาง", chin["segments"][0]["definition"])
        self.assertIn("ค่าง", langur["segments"][0]["definition"])
        self.assertIn("ที่เกาะ", support["segments"][0]["definition"])

    def test_page_83_long_aa_entries_have_no_leading_sakot(self):
        for word in ("ค้า", "คาง", "ค่าง", "ค้าง", "คาน", "ค้าน", "คาบ"):
            with self.subTest(word=word):
                self.assertFalse(self.engine.convert_thai_to_lanna(word)["lanna_script"].startswith("᩠"))

    def test_page_84_verified_records_are_used(self):
        expected = {
            "คาบงาบ":"ᨣᩣ᩠ᨸᨦᩣ᩠ᨸ", "คาบทื้น":"ᨣᩣ᩠ᨸᨴᩨ᩠᩶ᨶ",
            "คาม":"ᨣᩣ᩠ᨾ", "คามโภชกะ":"ᨣᩣᨾᨽᩰᨩᨠᩡ",
            "คามวาสี":"ᨣᩣᨾᩅᩣᩈᩦ", "คาย":"ᨣᩣ᩠ᨿ",
            "ค่าย":"ᨣ᩵ᩣ᩠ᨿ", "ค่ายแคน":"ᨣ᩵ᩣ᩠ᨿᩯᨣ᩠ᨶ",
            "ค้าว":"ᨣ᩶ᩣ᩠ᩅ", "คำ":"ᨣᩣᩴ",
            "คำกต่าง":"ᨣᩣᩴᨠᨲ᩵ᩣ᩠ᨦ", "คำกิน":"ᨣᩣᩴᨠᩥ᩠ᨶ",
            "คำขัน":"ᨣᩣᩴᨡᩢ᩠ᨶ", "คำขุณณา":"ᨣᩣᩴᨡᩩᨱ᩠ᨱᩣ",
            "คำเข้า":"ᨣᩣᩴᩮᨡ᩶ᩣ", "คำโขด":"ᨣᩣᩴᨡᩰᩫ᩠ᨯ",
            "คำค่าวคำเครือ":"ᨣᩣᩴᨣ᩵ᩣ᩠ᩅᨣᩣᩴᨣᩕᩮᩥᩋ",
            "คำคิด":"ᨣᩣᩴᨣᩥ᩠ᨯ", "คำเคียด":"ᨣᩣᩴᨣ᩠ᨿᨯ",
            "คำงาน":"ᨣᩣᩴᨦᩣ᩠ᨶ", "คำจุ":"ᨣᩣᩴᨧᩩ",
        }
        for word, lanna in expected.items():
            with self.subTest(word=word):
                result = self.engine.convert_thai_to_lanna(word)
                self.assertEqual(result["lanna_script"], lanna)
                self.assertEqual(result["segments"][0]["source_pdf_page"], 84)
                self.assertFalse(result["needs_review"])

    def test_page_84_khai_tones_are_distinct(self):
        irritation = self.engine.convert_thai_to_lanna("คาย")
        bored = self.engine.convert_thai_to_lanna("ค่าย")
        self.assertNotEqual(irritation["lanna_script"], bored["lanna_script"])
        self.assertIn("ระคาย", irritation["segments"][0]["definition"])
        self.assertIn("เบื่อ", bored["segments"][0]["definition"])

    def test_page_84_kham_uses_aa_then_mai_kang(self):
        result = self.engine.convert_thai_to_lanna("คำ")
        self.assertEqual(result["lanna_script"], "ᨣᩣᩴ")
        self.assertFalse(result["lanna_script"].startswith("᩠"))

    def test_page_84_lanna_variants_are_exposed(self):
        result = self.engine.convert_thai_to_lanna("คำขุณณา")
        variants = result["segments"][0]["lanna_variants"]
        self.assertEqual(len(variants), 2)
        self.assertEqual({item["source_page"] for item in variants}, {84})

    def test_page_85_verified_records_are_used(self):
        expected = {
            "คำเจี้ย":"ᨣᩣᩴᩮᨧᩦ᩶ᨿ", "คำแช่ง":"ᨣᩣᩴᩯᨩ᩠᩵ᨦ",
            "คำซอ":"ᨣᩣᩴᨪᩴ᩠ᩋ", "คำซื่อ":"ᨣᩣᩴᨪᩨ᩵ᩋ",
            "คำเดียว":"ᨣᩣᩴᨯ᩠ᨿᩅ", "คำเดียวก่อน":"ᨣᩣᩴᨯ᩠ᨿᩅᨠ᩠᩵ᩋᨶ",
            "คำตระหนี่":"ᨣᩣᩴᨲᩕᩡᩉ᩠ᨶᩦ᩵", "คำทวาย":"ᨣᩣᩴᨴ᩠ᩅᩣ᩠ᨿ",
            "คำปาก":"ᨣᩣᩴᨸᩣ᩠ᨠ", "คำผาถนา":"ᨣᩣᩴᨹᩣᨳᨶᩣ",
            "คำผาน":"ᨣᩣᩴᨹᩣ᩠ᨶ", "คำพรวง":"ᨣᩣᩴᨻᩕ᩠ᩅᨦ",
            "คำฟู่":"ᨣᩣᩴᨼᩪ᩵", "คำฟู่เก๊า":"ᨣᩣᩴᨼᩪ᩵ᩮᨠ᩶ᩣ",
            "คำฟู่สูง":"ᨣᩣᩴᨼᩪ᩵ᩈᩪ᩠ᨦ", "คำม่วน":"ᨣᩣᩴᨾ᩠᩵ᩅᨶ",
            "คำมัก":"ᨣᩣᩴᨾ᩠ᨠᩢ", "คำมักคำติ":"ᨣᩣᩴᨾ᩠ᨠᩢᨣᩣᩴᨲᩥ",
            "คำมักคำผาถนา":"ᨣᩣᩴᨾ᩠ᨠᩢᨣᩣᩴᨹᩣᨳᨶᩣ",
            "คำเมา":"ᨣᩣᩴᩮᨾᩣ", "คำเมือง":"ᨣᩣᩴᩮᨾᩥᩬ᩠ᨦ",
            "คำแม่ยิงไปท่าคำแม่ย่าไปสวน":"ᨣᩣᩴᩯᨾ᩵ᨿᩥ᩠ᨦᩱᨸᨴ᩵ᩣᨣᩣᩴᩯᨾ᩵ᨿ᩵ᩣᩱᨸᩈ᩠ᩅᨶ",
            "คำรหัส":"ᨣᩣᩴᩁᩉ᩠ᩈᩢ",
        }
        for word, lanna in expected.items():
            with self.subTest(word=word):
                result = self.engine.convert_thai_to_lanna(word)
                self.assertEqual(result["lanna_script"], lanna)
                self.assertEqual(result["segments"][0]["source_pdf_page"], 85)
                self.assertFalse(result["needs_review"])

    def test_page_85_kham_prefix_is_complete_and_not_leading_sakot(self):
        for word in ("คำแช่ง", "คำทวาย", "คำปาก", "คำฟู่", "คำมัก", "คำเมือง"):
            with self.subTest(word=word):
                output = self.engine.convert_thai_to_lanna(word)["lanna_script"]
                self.assertTrue(output.startswith("ᨣᩣᩴ"))
                self.assertFalse(output.startswith("᩠"))

    def test_page_85_long_proverb_is_one_reviewed_segment(self):
        result = self.engine.convert_thai_to_lanna("คำแม่ยิงไปท่าคำแม่ย่าไปสวน")
        self.assertEqual(len(result["segments"]), 1)
        self.assertIn("ไม่ควรเชื่อถือ", result["segments"][0]["definition"])

    def test_page_86_verified_records_are_used(self):
        expected = {
            "คำร่าย":"ᨣᩣᩴᩁ᩵ᩣ᩠ᨿ", "คำฮู้":"ᨣᩣᩴᩁᩪ᩶", "คำลม":"ᨣᩣᩴᩃᩫ᩠ᨾ",
            "คำลอ":"ᨣᩣᩴᩃᩴ᩠ᩋ", "คำล่าย":"ᨣᩣᩴᩃ᩵ᩣ᩠ᨿ", "คำลู":"ᨣᩣᩴᩃᩪ",
            "คำเล่าสือ":"ᨣᩣᩴᩮᩃᩢ᩵ᩣᩈᩨ", "คำเล่าอ้าง":"ᨣᩣᩴᩮᩃᩢ᩵ᩣᩋ᩶ᩣ᩠ᨦ",
            "คำแล้ว":"ᨣᩣᩴᩓ᩠ᩅ", "คำวอก":"ᨣᩣᩴᩅ᩠ᩋᨠ", "คำสบถ":"ᨣᩣᩴᩈᨷᩫ᩠ᨳ",
            "คำส่อ":"ᨣᩣᩴᩈᩴ᩠ᩋ᩵", "คำสั้น":"ᨣᩣᩴᩈᩢ᩠᩶ᨶ", "คำสุด":"ᨣᩣᩴᩈᩩ᩠ᨯ",
            "คำหัวหางกลางบ้าน":"ᨣᩣᩴᩉᩫ᩠ᩅᩉᩣ᩠ᨦᨠᩖᩣ᩠ᨦᨷ᩶ᩣ᩠ᨶ",
            "คำเหล้น":"ᨣᩣᩴᩮᩉᩖ᩠᩶ᨶ", "คำเหล้นเปนแท้":"ᨣᩣᩴᩮᩉᩖ᩠᩶ᨶᨸᩮ᩠ᨶᨴᩯ᩶",
            "คำไหว้":"ᨣᩣᩴᩱᩉ᩠ᩅ᩶", "คำอู้":"ᨣᩣᩴᩋᩪ᩶", "คำโอ่น่า":"ᨣᩣᩴᩰᩋ᩵ᨶ᩵ᩣ",
            "ค้ำ":"ᨣᩣᩴ᩶", "คิก":"ᨣᩥ᩠ᨠ", "คิมมิม":"ᨣᩥᨾ᩠ᨾᩥᨾ",
        }
        for word, lanna in expected.items():
            with self.subTest(word=word):
                result = self.engine.convert_thai_to_lanna(word)
                self.assertEqual(result["lanna_script"], lanna)
                self.assertEqual(result["segments"][0]["source_pdf_page"], 86)
                self.assertFalse(result["needs_review"])

    def test_page_86_kham_and_kham_support_are_distinct(self):
        speech = self.engine.convert_thai_to_lanna("คำอู้")
        support = self.engine.convert_thai_to_lanna("ค้ำ")
        self.assertNotEqual(speech["lanna_script"], support["lanna_script"])
        self.assertIn("คำพูด", speech["segments"][0]["definition"])
        self.assertIn("อุดหนุน", support["segments"][0]["definition"])

    def test_page_87_all_headwords_are_reviewed(self):
        words = [
            "คิลา", "คิ้ว", "คี่", "คี้มี่", "คิก", "คีบ", "คีม", "คีมนกแก้ว",
            "คีมปู", "คี", "คึง", "คึกงึก", "คิด", "คิดครอบ", "คิดคอง",
            "คิดค้าว", "คิดคืนหลัง", "คิดใจ", "คิดใจฮู้", "คิดถอกคิดถอน",
            "คิดเถิง", "คิดเทิงหา", "คิดบ่ลุก", "คิดยอกคิดถอน",
        ]
        for word in words:
            with self.subTest(word=word):
                result = self.engine.convert_thai_to_lanna(word)
                self.assertFalse(result["needs_review"])
                self.assertTrue(result["is_valid_lanna_unicode"])
                if word == "คิก":
                    self.assertIn(87, {sense["source_page"] for sense in result["segments"][0]["senses"]})
                else:
                    self.assertEqual(result["segments"][0]["source_pdf_page"], 87)

    def test_page_87_homograph_senses_are_preserved(self):
        odd = self.engine.convert_thai_to_lanna("คี่")
        roll = self.engine.convert_thai_to_lanna("คิก")
        self.assertEqual(len(odd["segments"][0]["senses"]), 2)
        self.assertEqual(len(roll["segments"][0]["senses"]), 2)
        meanings = " ".join(sense["meaning"] for sense in roll["segments"][0]["senses"])
        self.assertIn("คลึง", meanings)
        self.assertIn("จำนวนคี่", meanings)

    def test_page_87_similar_thought_phrases_remain_distinct(self):
        look_back = self.engine.convert_thai_to_lanna("คิดคืนหลัง")
        deliberate = self.engine.convert_thai_to_lanna("คิดใจ")
        indecisive = self.engine.convert_thai_to_lanna("คิดถอกคิดถอน")
        self.assertEqual(len({look_back["lanna_script"], deliberate["lanna_script"], indecisive["lanna_script"]}), 3)

    def test_page_88_all_headwords_are_reviewed(self):
        words = [
            "คิดยาก", "คิดฮอด", "คิดฮู้", "คิดล่ำ", "คึมงึม", "คีน", "คือว่า", "คุก",
            "คุง", "คุงฟ้า", "คุณ", "คุด", "คุดค้าว", "คุดน้ำอาบ", "คุด ๆ", "คุตตะ",
            "คุ้น", "คุบ", "คุม", "คุมชาง", "คุมเข้า", "คุมบาตร", "คุมมุม", "คุ่ม", "คุ่มขึ้นได",
        ]
        for word in words:
            with self.subTest(word=word):
                result = self.engine.convert_thai_to_lanna(word)
                self.assertFalse(result["needs_review"])
                self.assertTrue(result["is_valid_lanna_unicode"])
                self.assertEqual(result["segments"][0]["source_pdf_page"], 88)

    def test_page_88_repetition_and_variants_are_preserved(self):
        repeated = self.engine.convert_thai_to_lanna("คุด ๆ")
        kub = self.engine.convert_thai_to_lanna("คุบ")
        self.assertIn("᩻", repeated["lanna_script"])
        self.assertNotIn("ๆ", repeated["lanna_script"])
        variants = {item["lanna"] for item in kub["segments"][0]["lanna_variants"]}
        self.assertEqual(variants, {"ᨣᩩ᩠ᨷ", "ᨣᩩᨷ"})

    def test_page_88_khum_tone_forms_remain_distinct(self):
        khum = self.engine.convert_thai_to_lanna("คุม")
        khum_low = self.engine.convert_thai_to_lanna("คุ่ม")
        self.assertNotEqual(khum["lanna_script"], khum_low["lanna_script"])

    def test_page_89_all_headwords_are_reviewed(self):
        words = [
            "คุ่มคะลุม", "คุ่มจด", "คุ้ม", "คุ้มคว้า", "คุ้มคะลุม", "คุย", "คู",
            "คูลวา", "คูลวาขาว", "คูลา", "คู่", "คู่ข้าง", "คู่ซ็อกคู่แจ้ง",
            "คู่เชิงคู่ลาย", "คู่เชื้อคู่อัน", "คู่ซ้อน", "คู่ชะรอก", "คู่ถ้อง",
            "คู่ถู", "คู่บ้านคู่เรือน", "คู่ฝั้น", "คู่สะเหล้งแม่ง",
        ]
        for word in words:
            with self.subTest(word=word):
                result = self.engine.convert_thai_to_lanna(word)
                self.assertFalse(result["needs_review"])
                self.assertTrue(result["is_valid_lanna_unicode"])
                self.assertEqual(result["segments"][0]["source_pdf_page"], 89)

    def test_page_89_similar_forms_remain_distinct(self):
        low = self.engine.convert_thai_to_lanna("คุ่มคะลุม")
        high = self.engine.convert_thai_to_lanna("คุ้มคะลุม")
        self.assertNotEqual(low["lanna_script"], high["lanna_script"])

    def test_page_89_corrected_unicode_has_no_duplicate_sakot(self):
        for word in ("คุ้มคว้า", "คู่เชื้อคู่อัน"):
            with self.subTest(word=word):
                result = self.engine.convert_thai_to_lanna(word)
                self.assertNotIn("᩠᩠", result["lanna_script"])

    def test_page_90_all_headwords_are_reviewed(self):
        words = [
            "คู่ฮ้อน", "คู้", "คู้ดิน", "คูก", "คุด", "เคน", "เค้น", "เคม", "เคย",
            "เคร่ง", "เคร่งตึง", "เครา", "เคร่า", "เคร่าถ้า", "เคราะห์", "เคร็ง",
            "เคร็งเคียด", "เคร็งใจ", "เคิ่ง", "เครียว", "เครือ", "เครือขาเปีย",
            "เครือเขา", "เครือง้วนเหน", "เครือซอ", "เครือออน",
        ]
        for word in words:
            with self.subTest(word=word):
                result = self.engine.convert_thai_to_lanna(word)
                self.assertFalse(result["needs_review"])
                self.assertTrue(result["is_valid_lanna_unicode"])
                if word == "คุด":
                    pages = {sense["source_page"] for sense in result["segments"][0]["senses"]}
                    self.assertTrue({88, 90}.issubset(pages))
                else:
                    self.assertEqual(result["segments"][0]["source_pdf_page"], 90)

    def test_page_90_preposed_vowels_and_clusters_are_preserved(self):
        expected = {
            "เคน": "ᩮᨣ᩠ᨶ",
            "เคร่ง": "ᩮ᩠ᩁᩡᨣ᩠᩵ᨦ",
            "เครือ": "ᩮ᩠ᩁᩡᨣ᩠ᩋᩥᩋ",
        }
        for word, lanna in expected.items():
            with self.subTest(word=word):
                self.assertEqual(self.engine.convert_thai_to_lanna(word)["lanna_script"], lanna)

    def test_page_91_all_headwords_are_reviewed(self):
        words = [
            "เครื่อง", "เครื่องฆ่า", "เครื่องเคี่ยวของกิน", "เครื่องง้า", "เครื่องง้าอลังการ",
            "เครื่องท้าว", "เครื่องเทศ", "เครื่องประดับ", "เครื่องละอ่อนเหล้น", "เครื่องไล้ลา",
            "เครื่องหย้อง", "เคล้า", "เค้า", "เค้าคูก", "เค้าจาว", "เค้าเปิง", "เค้าผี",
            "เค้าเม้า", "เค้าไม้", "เค้าแยก", "เค้าแร้", "เค้าเว้า", "เค้าสนามหลวง",
        ]
        for word in words:
            with self.subTest(word=word):
                result = self.engine.convert_thai_to_lanna(word)
                self.assertFalse(result["needs_review"])
                self.assertTrue(result["is_valid_lanna_unicode"])
                self.assertEqual(result["segments"][0]["source_pdf_page"], 91)
                self.assertNotIn("᩠᩠", result["lanna_script"])

    def test_page_92_all_headwords_are_reviewed(self):
        words = [
            "เค้าหัวที", "เค้าเหง้า", "เค้าเหมย", "เคาะ", "เคาะแคะ", "เคิก", "เคิ้ง",
            "เคียด", "เคี้ยว", "เคี้ยวเอื้อง", "เคียะ", "แค", "แคถะหวา", "แคโยง",
            "แคก", "แคกแวก", "แค็ก", "แคง", "แคด", "แคน", "แคนใจ", "แคนตับ",
            "แคนตา", "แค้น",
        ]
        for word in words:
            with self.subTest(word=word):
                result = self.engine.convert_thai_to_lanna(word)
                self.assertFalse(result["needs_review"])
                self.assertTrue(result["is_valid_lanna_unicode"])
                self.assertEqual(result["segments"][0]["source_pdf_page"], 92)

    def test_page_92_similar_khae_forms_remain_distinct(self):
        words = ["แคก", "แค็ก", "แคด", "แคน", "แค้น"]
        scripts = [self.engine.convert_thai_to_lanna(word)["lanna_script"] for word in words]
        self.assertEqual(len(scripts), len(set(scripts)))

    def test_page_93_all_headwords_are_reviewed(self):
        words = [
            "แคบ", "แคบหลัว", "แคม", "แคร่", "แคร้ม", "แคร็ด", "โค", "โคโล่งโหน่ง",
            "โคหา", "โคก", "โคกโวก", "โค้ง", "โค่น", "โค่นก้าน", "โค้น", "โคม",
            "โคมบ๊อก", "โคมผัด", "โคมไฟ", "โคมไฟฉาย", "โคมรังมดส้ม", "โคมลอย",
        ]
        for word in words:
            with self.subTest(word=word):
                result = self.engine.convert_thai_to_lanna(word)
                self.assertFalse(result["needs_review"])
                self.assertTrue(result["is_valid_lanna_unicode"])
                self.assertEqual(result["segments"][0]["source_pdf_page"], 93)

    def test_page_94_all_headwords_are_reviewed(self):
        words = [
            "โคมหูกระต่าย", "โคร่ง", "โคะโงะ", "ไค", "ไค้", "ไคร่", "ไคร่ใจ", "ไคร่ท้น",
            "ไคร่ฮาก", "ไคร่หลับ", "ไคร่หัว", "ไคร่ขยาก", "ไคร้", "ไคร่นุ่น", "ไคร้บก",
            "ไคร้มด", "ไคร้เม็ด", "ไคล", "ไคลคลา",
        ]
        for word in words:
            with self.subTest(word=word):
                result = self.engine.convert_thai_to_lanna(word)
                self.assertFalse(result["needs_review"])
                self.assertTrue(result["is_valid_lanna_unicode"])
                self.assertEqual(result["segments"][0]["source_pdf_page"], 94)

    def test_pages_93_94_similar_forms_remain_distinct(self):
        words = ["โค่น", "โค้น", "ไค", "ไค้", "ไคร่", "ไคร้"]
        scripts = [self.engine.convert_thai_to_lanna(word)["lanna_script"] for word in words]
        self.assertEqual(len(scripts), len(set(scripts)))

    def test_page_95_kho_khon_headwords_are_reviewed(self):
        words = ["ฅ", "ฅนน้ำโตะ", "ฅนน้ำสุ่ย", "ฅอออม", "ฅอเอิม", "เฅียวเอา", "แฅวน", "แฅ้ว"]
        for word in words:
            with self.subTest(word=word):
                result = self.engine.convert_thai_to_lanna(word)
                self.assertFalse(result["needs_review"])
                self.assertTrue(result["is_valid_lanna_unicode"])
                self.assertEqual(result["segments"][0]["source_pdf_page"], 95)

    def test_page_95_preserves_kho_khon_spelling(self):
        old = self.engine.convert_thai_to_lanna("ฅนน้ำโตะ")
        common = self.engine.convert_thai_to_lanna("คนน้ำโตะ")
        self.assertFalse(old["needs_review"])
        self.assertTrue(common["needs_review"])
        self.assertEqual(old["segments"][0]["canonical_thai"], "ฅนน้ำโตะ")

    def test_page_95_corrects_kho_khon_letter_mapping(self):
        result = self.engine.convert_thai_to_lanna("ฅ")
        self.assertEqual(result["lanna_script"], "ᨤ")
        self.assertFalse(result["needs_review"])

    def test_page_96_kho_rakhang_letter_is_reviewed(self):
        result = self.engine.convert_thai_to_lanna("ฆ")
        self.assertEqual(result["lanna_script"], "ᨥ")
        self.assertEqual(result["segments"][0]["source_pdf_page"], 96)
        self.assertFalse(result["needs_review"])

    def test_page_97_all_ngo_headwords_are_reviewed(self):
        words = [
            "ง", "งก", "งง", "งด", "งม ๆ ซวาม ๆ", "ง้ม", "ง้มง่าว", "งวง", "งวงช้าง",
            "ง่วง", "ง้วน", "ง้วนดิน", "ง้วนพิษ", "ง้วนสาร", "ง่อย", "ง่อยง่วยสึง",
            "ง่วยสึง", "งว่า", "งว่า ๆ โซ้ง ๆ", "งวก", "งวกงว่าย", "งว่าย", "งวิก",
            "งอ", "งอกก๊องหง้อง", "ง้อ",
        ]
        for word in words:
            with self.subTest(word=word):
                result = self.engine.convert_thai_to_lanna(word)
                self.assertFalse(result["needs_review"])
                self.assertTrue(result["is_valid_lanna_unicode"])
                self.assertEqual(result["segments"][0]["source_pdf_page"], 97)
                self.assertNotIn("᩠᩠", result["lanna_script"])

    def test_page_97_repetition_uses_tai_tham_sign(self):
        for word in ("งม ๆ ซวาม ๆ", "งว่า ๆ โซ้ง ๆ"):
            with self.subTest(word=word):
                script = self.engine.convert_thai_to_lanna(word)["lanna_script"]
                self.assertIn("᩻", script)
                self.assertNotIn("ๆ", script)

    def test_page_98_all_ngo_headwords_are_reviewed(self):
        words = [
            "งอก", "ง็อก", "ง็อกแง็ก", "งอง", "ง้อง", "ง้องแง้ง", "งอด", "งอดแงด",
            "งอน", "ง่อน", "ง่อนงก", "ง่อนต่อ", "ง้อน", "ง้อนไถ", "งอม", "ง่อม",
            "ง่อมงัน", "ง่อมหา", "ง่อมเหงา", "ง้อม", "งอย", "งัด", "งัน", "งับ",
        ]
        for word in words:
            with self.subTest(word=word):
                result = self.engine.convert_thai_to_lanna(word)
                self.assertFalse(result["needs_review"])
                self.assertTrue(result["is_valid_lanna_unicode"])
                self.assertEqual(result["segments"][0]["source_pdf_page"], 98)

    def test_page_98_tone_forms_remain_distinct(self):
        words = ["งอก", "ง็อก", "งอง", "ง้อง", "งอน", "ง่อน", "ง้อน", "งอม", "ง่อม", "ง้อม"]
        scripts = [self.engine.convert_thai_to_lanna(word)["lanna_script"] for word in words]
        self.assertEqual(len(scripts), len(set(scripts)))

    def test_page_99_all_ngo_headwords_are_reviewed(self):
        words = [
            "งับแง", "งัว", "งัวก๊อก", "งัวต้อง", "งัวต่าง", "งัวถ่าว", "งัวเถ็ก", "งัวผู้",
            "งัวแม่", "งัวล้อ", "งัวลด", "งัวลาย", "งัวสือ", "งัวหนาน", "งัวไหม", "งั่ว",
            "งา", "งาขี้ม้อน", "งาไซ", "งาดำอ้อย", "งาหู", "ง่า", "ง่าอ้อย", "ง่าอ้าย",
        ]
        for word in words:
            with self.subTest(word=word):
                result = self.engine.convert_thai_to_lanna(word)
                self.assertFalse(result["needs_review"])
                self.assertTrue(result["is_valid_lanna_unicode"])
                self.assertEqual(result["segments"][0]["source_pdf_page"], 99)

    def test_page_99_corrects_bad_candidate_sequences(self):
        cart_ox = self.engine.convert_thai_to_lanna("งัวล้อ")["lanna_script"]
        branch = self.engine.convert_thai_to_lanna("ง่า")["lanna_script"]
        self.assertEqual(cart_ox, "ᨦᩫ᩠ᩅᩃᩴ᩠ᩋ᩶")
        self.assertNotIn("ᩯᨾ᩵", cart_ox)
        self.assertEqual(branch, "ᨦ᩵ᩣ")
        self.assertNotIn("ᨾ", branch)

    def test_page_100_all_ngo_headwords_are_reviewed(self):
        words = [
            "ง้า", "ง่าง", "ง่างเง่ง", "ง้าง", "งาน", "งาบเงิง", "งาม", "งามไบ้งามบอด",
            "ง่าม", "งาย", "ง่าย", "งาว", "ง่าว", "ง้าว", "งำ", "ง้ำ", "งิ", "งิน",
            "งินดี", "งิ้ว", "งิ้วผา", "งิ้วส้อย", "งีบ", "งืน", "งิด", "งิบงือ", "งุน", "งุ่น",
        ]
        for word in words:
            with self.subTest(word=word):
                result = self.engine.convert_thai_to_lanna(word)
                self.assertFalse(result["needs_review"])
                self.assertTrue(result["is_valid_lanna_unicode"])
                self.assertEqual(result["segments"][0]["source_pdf_page"], 100)

    def test_page_100_ngi_has_two_senses(self):
        result = self.engine.convert_thai_to_lanna("งิ")
        self.assertEqual(len(result["segments"][0]["senses"]), 2)
        meanings = " ".join(sense["meaning"] for sense in result["segments"][0]["senses"])
        self.assertIn("เมล็ดพืช", meanings)
        self.assertIn("ปริแตก", meanings)

    def test_page_100_tone_forms_remain_distinct(self):
        words = ["ง่า", "ง้า", "ง่าง", "ง้าง", "งาม", "ง่าม", "งาว", "ง่าว", "ง้าว", "งำ", "ง้ำ"]
        scripts = [self.engine.convert_thai_to_lanna(word)["lanna_script"] for word in words]
        self.assertEqual(len(scripts), len(set(scripts)))

    def test_page_100_corrects_bad_candidate_sequences(self):
        self.assertEqual(self.engine.convert_thai_to_lanna("งาม")["lanna_script"], "ᨦᩣ᩠ᨾ")
        self.assertEqual(self.engine.convert_thai_to_lanna("งำ")["lanna_script"], "ᨦᩣᩴ")
        self.assertEqual(self.engine.convert_thai_to_lanna("งีบ")["lanna_script"], "ᨦᩦ᩠ᨷ")

    def test_page_101_all_ngo_headwords_are_reviewed(self):
        words = [
            "งุ่นเผิ้งขาว", "งุ่นสะบันงา", "งุบ", "งุบงับ", "งุม", "งุ้ม", "งุ้มงว่า", "งู",
            "งูก่านป้อง", "งูเขียวหางไหม้", "งูค้อนก้อม", "งูจอง", "งูจองก้านพล้าว",
            "งูจองแจ้", "งูจองดาว", "งูจองละอาง", "งูจืน", "งูทับคา", "งูทับทาน",
            "งูเพา", "งูเพาคอแดง", "งูฟ้าเหลื้อม", "งูสิง", "งูสิงส้อย", "งูสิงหลวง",
            "งูเหลื้ม", "งูเห่าปวก",
        ]
        for word in words:
            with self.subTest(word=word):
                result = self.engine.convert_thai_to_lanna(word)
                self.assertFalse(result["needs_review"])
                self.assertTrue(result["is_valid_lanna_unicode"])
                self.assertEqual(result["segments"][0]["source_pdf_page"], 101)

    def test_page_101_ngup_variants_are_structured(self):
        result = self.engine.convert_thai_to_lanna("งุบ")
        variants = {item["lanna"] for item in result["segments"][0]["lanna_variants"]}
        self.assertEqual(result["lanna_script"], "ᨦᩩ᩠ᨷ")
        self.assertEqual(variants, {"ᨦᩩᨷ"})

    def test_page_102_all_ngo_headwords_are_reviewed(self):
        words = [
            "งูเห่าพวก", "งูเห่าม่อม", "งูเห่าห้อม", "งูบ", "เงง", "เงย", "เง่ว", "เง่วขึ้น",
            "เงา", "เงาะ", "เง็ก", "เง็กรุ้ง", "เงิน", "เงินกระจุ่ม", "เงินกีบม้า",
            "เงินขวยปู", "เงินแดง", "เงินแถบ", "เงินต๊อก", "เงินบ่าหล้าตำ", "เงินย่อย",
        ]
        for word in words:
            with self.subTest(word=word):
                result = self.engine.convert_thai_to_lanna(word)
                self.assertFalse(result["needs_review"])
                self.assertTrue(result["is_valid_lanna_unicode"])
                self.assertEqual(result["segments"][0]["source_pdf_page"], 102)

    def test_page_102_ngup_variants_are_structured(self):
        result = self.engine.convert_thai_to_lanna("งูบ")
        variants = {item["lanna"] for item in result["segments"][0]["lanna_variants"]}
        self.assertEqual(result["lanna_script"], "ᨦᩪ᩠ᨷ")
        self.assertEqual(variants, {"ᨦᩪᨷ"})

    def test_page_102_preposed_vowels_are_preserved(self):
        expected = {"เงง":"ᩮᨦ᩠ᨦ", "เงย":"ᩮᨦ᩠ᨿ", "เงิน":"ᩮᨦ᩠ᨶᩥ"}
        for word, script in expected.items():
            with self.subTest(word=word):
                self.assertEqual(self.engine.convert_thai_to_lanna(word)["lanna_script"], script)

    def test_page_103_all_ngo_headwords_are_reviewed(self):
        words = [
            "เงินราง", "เงินหัวหมด", "เงินหีหมา", "เงิบ", "เงิบเงอ", "เงิบเงิง", "เงิบผา",
            "เงิบเรือน", "เงิม", "เงียง", "เงียว", "เงียวเคาะ", "เงียวลา", "เงื้อ", "เงือก",
            "เงือกรุง", "เงือกรุ้ง", "เงือด", "เงือน", "เงื่อน",
        ]
        for word in words:
            with self.subTest(word=word):
                result = self.engine.convert_thai_to_lanna(word)
                self.assertFalse(result["needs_review"])
                self.assertTrue(result["is_valid_lanna_unicode"])
                self.assertEqual(result["segments"][0]["source_pdf_page"], 103)

    def test_page_103_preposed_vowels_are_preserved(self):
        expected = {
            "เงิบ": "ᩮᨦ᩠ᨸᩥ", "เงิม": "ᩮᨦ᩠ᨾᩥ", "เงียง": "ᩮᨦ᩠ᨿᨦ",
            "เงือก": "ᩮᨦ᩠ᩋᩥᨠ", "เงื่อน": "ᩮᨦ᩠ᩋᩥ᩵ᩁ",
        }
        for word, script in expected.items():
            with self.subTest(word=word):
                self.assertEqual(self.engine.convert_thai_to_lanna(word)["lanna_script"], script)

    def test_page_104_all_ngo_headwords_are_reviewed(self):
        words = [
            "เงื่อนสั้น", "เงื่อนสะทก", "เงื่อนเหง้า", "เงื้อม", "แง", "แงก", "แง็ก", "แงน",
            "แง่น", "แง็บ", "แง็บเรือน", "แงบแง", "แงม", "แง่ม", "แง้ม", "แง้ว", "แงะ",
            "โงกเงก", "โงง", "โง้ง", "โง่ย", "ไง",
        ]
        for word in words:
            with self.subTest(word=word):
                result = self.engine.convert_thai_to_lanna(word)
                self.assertFalse(result["needs_review"])
                self.assertTrue(result["is_valid_lanna_unicode"])
                self.assertEqual(result["segments"][0]["source_pdf_page"], 104)

    def test_page_104_preposed_vowels_are_in_canonical_order(self):
        expected = {"แง":"ᩯᨦ", "แง็ก":"ᩯᨦ᩠ᨠᩢ", "โงง":"ᩰᨦᩫ᩠ᨦ", "ไง":"ᩱᨦ"}
        for word, script in expected.items():
            with self.subTest(word=word):
                self.assertEqual(self.engine.convert_thai_to_lanna(word)["lanna_script"], script)

    def test_page_105_all_jo_headwords_are_reviewed(self):
        words = [
            "จ", "จก", "จกกะหลิ่ง", "จกกะหลี้", "จกเค้าแร้", "จกจ่าย", "จกใจ", "จกโจ้",
            "จกโจ้จกใจ", "จด", "จดละคุย", "จตุปัจจัย", "จตุรภูมิ", "จตุรอบาย", "จน", "จนแจ่ง",
            "จนใจ", "จนซ็อก", "จนตา", "จนตาย", "จ้น", "จ้นจ้า", "จ้น ๆ",
        ]
        for word in words:
            with self.subTest(word=word):
                result = self.engine.convert_thai_to_lanna(word)
                self.assertFalse(result["needs_review"])
                self.assertTrue(result["is_valid_lanna_unicode"])
                self.assertEqual(result["segments"][0]["source_pdf_page"], 105)

    def test_page_105_canonical_preposed_and_repetition_signs(self):
        expected = {"จกใจ":"ᨧᩫ᩠ᨠᨧᩱ", "จกโจ้":"ᨧᩫ᩠ᨠᩰᨧᩢ᩶", "จ้น ๆ":"ᨧᩫ᩠᩶ᨶ᩻"}
        for word, script in expected.items():
            with self.subTest(word=word):
                self.assertEqual(self.engine.convert_thai_to_lanna(word)["lanna_script"], script)
        self.assertNotIn("ๆ", self.engine.convert_thai_to_lanna("จ้น ๆ")["lanna_script"])

    def test_page_106_all_jo_headwords_are_reviewed(self):
        words = [
            "จบ", "จม", "จุ่ม", "จุ่มแซ่ม", "จุ่มส้าม", "จุ่มหา", "จุ่มอุ้ม ๆ", "จรด", "จรอก",
            "จระเดิน", "จระล่วงข้าม", "จลอง", "จลองนม", "จลองหน้า", "จลัด", "จลาด", "จวง",
            "จวงเครือ", "จวงจันทน์", "จวงเดือน", "จวงหอม", "จ้วง", "จวน", "จ้วน", "จ้วนจั้น",
        ]
        for word in words:
            with self.subTest(word=word):
                result = self.engine.convert_thai_to_lanna(word)
                self.assertFalse(result["needs_review"])
                self.assertTrue(result["is_valid_lanna_unicode"])
                self.assertEqual(result["segments"][0]["source_pdf_page"], 106)

    def test_page_106_repetition_sign_is_tai_tham(self):
        result = self.engine.convert_thai_to_lanna("จุ่มอุ้ม ๆ")
        self.assertEqual(result["lanna_script"], "ᨧᩩ᩵ᨾᩋᩩ᩶ᨾ᩻")
        self.assertNotIn("ๆ", result["lanna_script"])

    def test_page_107_all_jo_headwords_are_reviewed(self):
        words = [
            "จวบ", "จ้วย", "จวัง", "จวาง", "จวาบ", "จว้าย", "จ่อ", "จ้อ", "จ้อข้อ", "จ้อหว้อ", "จอก",
            "จ๊อก", "เข้าหนมจ๊อก", "จ๊อกป๊อก", "จอง", "จองกรม", "จ่อง", "จ่องเจาะ",
            "จ่องเจาะเดาะด้อย", "จ่องชัก", "จ่องห้อย", "จ๋อง",
        ]
        for word in words:
            with self.subTest(word=word):
                result = self.engine.convert_thai_to_lanna(word)
                self.assertFalse(result["needs_review"])
                self.assertTrue(result["is_valid_lanna_unicode"])
                self.assertEqual(result["segments"][0]["source_pdf_page"], 107)

    def test_page_107_tone_distinctions_remain_separate(self):
        words = ["จอก", "จ๊อก", "จอง", "จ่อง", "จ๋อง"]
        scripts = [self.engine.convert_thai_to_lanna(word)["lanna_script"] for word in words]
        self.assertEqual(len(scripts), len(set(scripts)))

    def test_page_108_all_jo_headwords_are_reviewed(self):
        words = [
            "จ๋องป๊อง", "จ๋องม่าน", "จ๋องรุ่งควาว", "จ๋องลอ", "จอด", "จอดจั้ง", "จอดยั้ง", "จ๊อด",
            "จ๊อดหล๊อด", "จ่อน", "จ่อนขุ่ย", "จ้อน", "จ้อนจ้าน", "จอบ", "จ๊อบแจ๊บ", "จอม", "จอมดอย",
            "จอมหัว", "จอมแหล่", "จ่อม", "จ่อมก้าน", "จ่อมเจาะเดาะด้อย",
        ]
        for word in words:
            with self.subTest(word=word):
                result = self.engine.convert_thai_to_lanna(word)
                self.assertFalse(result["needs_review"])
                self.assertTrue(result["is_valid_lanna_unicode"])
                self.assertEqual(result["segments"][0]["source_pdf_page"], 108)

    def test_page_108_tone_forms_remain_distinct(self):
        words = ["จอด", "จ๊อด", "จ่อน", "จ้อน", "จอม", "จ่อม"]
        scripts = [self.engine.convert_thai_to_lanna(word)["lanna_script"] for word in words]
        self.assertEqual(len(scripts), len(set(scripts)))

    def test_page_109_all_jo_headwords_are_reviewed(self):
        words = [
            "จ่อมจิ้ง", "จ่อมบ่อม", "จ่อมเบ็ด", "จ่อมหล่อม", "จ่อม ๆ บ่อย ๆ", "จ้อม", "จ้อย", "จ้อยหว้อง",
            "จะกว้าย", "จะกอย", "จะจิ้ว", "จะดา", "จะได", "จะนี้", "จะบับ", "จะปุ", "จะลาง",
            "จะลางเดินทาง", "จะล่ำ", "จะเลาะ", "จะแหลม ๆ", "จะโลละโอ๊ะ",
        ]
        for word in words:
            with self.subTest(word=word):
                result = self.engine.convert_thai_to_lanna(word)
                self.assertFalse(result["needs_review"])
                self.assertTrue(result["is_valid_lanna_unicode"])
                self.assertEqual(result["segments"][0]["source_pdf_page"], 109)

    def test_page_109_repetition_uses_tai_tham_sign(self):
        for word in ["จ่อม ๆ บ่อย ๆ", "จะแหลม ๆ"]:
            with self.subTest(word=word):
                script = self.engine.convert_thai_to_lanna(word)["lanna_script"]
                self.assertIn("᩻", script)
                self.assertNotIn("ๆ", script)

    def test_page_110_all_jo_headwords_are_reviewed(self):
        words = [
            "จะหลวะจะกวะ", "จะหลิดจะหลิ้ว", "จะหลิดผิด", "จะหลุดผุด", "จะแหร็ดจะแหล้", "จะอั้น", "จะอี้",
            "จัก", "จักกวัตติ", "จักกวาพะ", "จักกอย", "จักกอยดัง", "จักกะ", "จักก่า", "จักก่าเสื้อ",
            "จักก่าเสื้อเกลี้ยง", "จักกิ้ม", "จักขาบ", "จักข้าว", "จักขุ", "จักขู", "จักเข้", "จักเข็บ",
        ]
        for word in words:
            with self.subTest(word=word):
                result = self.engine.convert_thai_to_lanna(word)
                self.assertFalse(result["needs_review"])
                self.assertTrue(result["is_valid_lanna_unicode"])
                self.assertEqual(result["segments"][0]["source_pdf_page"], 110)

    def test_page_110_near_spellings_remain_distinct(self):
        words = ["จักขาบ", "จักข้าว", "จักขุ", "จักขู", "จักเข้", "จักเข็บ"]
        scripts = [self.engine.convert_thai_to_lanna(word)["lanna_script"] for word in words]
        self.assertEqual(len(scripts), len(set(scripts)))

    def test_page_111_all_jo_headwords_are_reviewed(self):
        words = [
            "จักไคร้", "จักไคร้ต้น", "จักไคร้บ่าขูด", "จักคาดตื้อเดือน", "จักคาดตื้อวัน", "จักค่าน", "จักคู",
            "จักจั่น", "จักจ่า", "จักดา", "จักแตน", "จักหลัง", "จักร", "จังกอน", "จังกอนแดง", "จังงัง",
            "จังไร", "จังหัน", "จั้ง", "จันตาละ", "จัด", "จัดไล่", "จัดเอา", "จัน", "จั่น", "จันดิน", "จั่นหับ", "จั่นห้าว",
        ]
        for word in words:
            with self.subTest(word=word):
                result = self.engine.convert_thai_to_lanna(word)
                self.assertFalse(result["needs_review"])
                self.assertTrue(result["is_valid_lanna_unicode"])
                self.assertEqual(result["segments"][0]["source_pdf_page"], 111)

    def test_page_111_eclipse_definitions_are_not_swapped(self):
        moon = self.engine.convert_thai_to_lanna("จักคาดตื้อเดือน")["segments"][0]["definition"]
        sun = self.engine.convert_thai_to_lanna("จักคาดตื้อวัน")["segments"][0]["definition"]
        self.assertIn("จันทรุปราคา", moon)
        self.assertIn("สุริยุปราคา", sun)

    def test_page_112_all_jo_headwords_are_reviewed(self):
        words = [
            "จันทร์", "จันทฆาตกะ", "จันทน์", "จันทน์ขาว", "จันทน์ขี้ไก่", "จันทน์คา", "จันทน์จี",
            "จันทน์แดง", "จันทน์บ้าน", "จันทน์ป่า", "จับ", "จับตายาม", "จับมอก", "จับยับ", "จับลางวัน",
            "จับหลังได้", "จัมปา", "จัมปากะ", "จา", "จาขวัน", "จาคะ", "จาตุม", "จาที่แท้",
        ]
        for word in words:
            with self.subTest(word=word):
                result = self.engine.convert_thai_to_lanna(word)
                self.assertFalse(result["needs_review"])
                self.assertTrue(result["is_valid_lanna_unicode"])
                self.assertEqual(result["segments"][0]["source_pdf_page"], 112)

    def test_page_112_chan_and_chandan_are_distinct(self):
        moon = self.engine.convert_thai_to_lanna("จันทร์")
        wood = self.engine.convert_thai_to_lanna("จันทน์")
        self.assertNotEqual(moon["lanna_script"], wood["lanna_script"])
        self.assertIn("ดวงจันทร์", moon["segments"][0]["definition"])
        self.assertIn("ไม้", wood["segments"][0]["definition"])

    def test_page_113_all_jo_headwords_are_reviewed(self):
        words = [
            "จาเทิก", "จาเทิง", "จาเทียม", "จาพอ", "จารีต", "จาเลิก", "จาลวงสุด", "จาว่า", "จ่า", "จ่ากลอง",
            "จ่าคนโทส", "จ่าง", "จ่าช้าง", "จ่าน้ำ", "จ่าปตู", "จ่ายมภิบาล", "จ่าสวน", "จ่าหญ้าม้า",
            "จาก", "จาง", "จางเกลือ", "จางแฉ็ดแผ็ด", "จางปาก",
        ]
        for word in words:
            with self.subTest(word=word):
                result = self.engine.convert_thai_to_lanna(word)
                self.assertFalse(result["needs_review"])
                self.assertTrue(result["is_valid_lanna_unicode"])
                self.assertEqual(result["segments"][0]["source_pdf_page"], 113)

    def test_page_113_jaa_tone_distinction_is_preserved(self):
        plain = self.engine.convert_thai_to_lanna("จา")["lanna_script"]
        toned = self.engine.convert_thai_to_lanna("จ่า")["lanna_script"]
        self.assertNotEqual(plain, toned)
        self.assertEqual(toned, "ᨧ᩵ᩣ")

    def test_page_114_all_jo_headwords_are_reviewed(self):
        words = [
            "จางพริก", "จางพริกจางเกลือ", "จางเหมือนห้อไห้", "จ่าง", "จ่างซะ", "จ้าง", "จาด", "จาน",
            "จานจา", "จ่าน", "จาม", "จามเทวี", "จ่าม", "จาย", "จายขี้ปุ่ม", "จายเหมย", "จ่าย",
            "จ่ายอ่วย", "จ้าย ๆ", "จาร", "จารจา", "จาว",
        ]
        for word in words:
            with self.subTest(word=word):
                result = self.engine.convert_thai_to_lanna(word)
                self.assertFalse(result["needs_review"])
                self.assertTrue(result["is_valid_lanna_unicode"])

    def test_page_114_jaang_has_both_source_senses(self):
        result = self.engine.convert_thai_to_lanna("จ่าง")
        pages = {sense["source_page"] for sense in result["segments"][0]["senses"]}
        meanings = " ".join(sense["meaning"] for sense in result["segments"][0]["senses"])
        self.assertEqual(pages, {113, 114})
        self.assertIn("ผู้เลี้ยงวัว", meanings)
        self.assertIn("กระชาก", meanings)

    def test_page_114_repetition_uses_tai_tham_sign(self):
        script = self.engine.convert_thai_to_lanna("จ้าย ๆ")["lanna_script"]
        self.assertIn("᩻", script)
        self.assertNotIn("ๆ", script)

    def test_page_115_all_jo_headwords_are_reviewed(self):
        words = [
            "จาวจี", "จาวมอร", "จาวออกออ", "จ่าว", "จ้าว", "จำ", "จำจื่อ", "จำใต้คำปาก", "จำนิต", "จำปลาลาว", "จำเป็น",
            "จำพวก", "จำยาม", "จำเริญ", "จำหลัก", "จำเจือ", "จำระ", "จ้ำ", "จ้ำจ้น", "จ้ำจี๊ฮ่ว่า", "จ้ำตรา",
            "จิ", "จิกะหลิ่ง", "จิดอบ", "จิขอบเครือ",
        ]
        for word in words:
            with self.subTest(word=word):
                result = self.engine.convert_thai_to_lanna(word)
                self.assertFalse(result["needs_review"])
                self.assertTrue(result["is_valid_lanna_unicode"])
                self.assertEqual(result["segments"][0]["source_pdf_page"], 115)

    def test_page_115_jao_tone_forms_are_distinct(self):
        words = ["จาว", "จ่าว", "จ้าว"]
        scripts = [self.engine.convert_thai_to_lanna(word)["lanna_script"] for word in words]
        self.assertEqual(len(scripts), len(set(scripts)))

    def test_page_116_all_jo_headwords_are_reviewed(self):
        words = [
            "จิลิ้น", "จิก", "จิกคาง", "จิกคำ", "จิกดัง", "จิกปิ๊ก", "จิกพระเจ้า", "จิกโมฬี", "จิง", "จิงจ้อขน", "จิงจ้อขาว",
            "จึง", "จิ้งปิ้ง", "จิดหลุ", "จิ่น", "จิ่น ๆ", "จิบ", "จิบหาย", "จิ่ม", "จิ่มแสนา", "จิว", "จิ้วหวิ้ว",
        ]
        for word in words:
            with self.subTest(word=word):
                result = self.engine.convert_thai_to_lanna(word)
                self.assertFalse(result["needs_review"])
                self.assertTrue(result["is_valid_lanna_unicode"])
                self.assertEqual(result["segments"][0]["source_pdf_page"], 116)

    def test_page_116_jing_and_jueng_are_distinct(self):
        self.assertNotEqual(
            self.engine.convert_thai_to_lanna("จิง")["lanna_script"],
            self.engine.convert_thai_to_lanna("จึง")["lanna_script"],
        )

    def test_page_116_repetition_uses_tai_tham_sign(self):
        script = self.engine.convert_thai_to_lanna("จิ่น ๆ")["lanna_script"]
        self.assertIn("᩻", script)
        self.assertNotIn("ๆ", script)

    def test_page_117_all_jo_headwords_are_reviewed(self):
        words = [
            "จิ๋ว ๆ", "จิ", "จีคุก", "จีจ้อ", "จีจ้อหลวง", "จีจุม", "จีแจ็บ", "จีดอก", "จีมั่ง", "จีวร", "จีหลาม", "จีหุบ",
            "จี่", "จี้", "จี้กุ่ง", "จี้จอก", "จี้หลอบ", "จี้หวี้", "จี้หิด", "จี้หู", "จีด", "จีดผีด", "จีน", "จีบ", "จีม", "จีมจี๊มจิด", "จีก",
        ]
        for word in words:
            with self.subTest(word=word):
                result = self.engine.convert_thai_to_lanna(word)
                self.assertFalse(result["needs_review"])
                self.assertTrue(result["is_valid_lanna_unicode"])
                if word != "จิ":
                    self.assertEqual(result["segments"][0]["source_pdf_page"], 117)

    def test_page_117_ji_has_both_source_senses(self):
        result = self.engine.convert_thai_to_lanna("จิ")
        pages = {sense["source_page"] for sense in result["segments"][0]["senses"]}
        meanings = " ".join(sense["meaning"] for sense in result["segments"][0]["senses"])
        self.assertEqual(pages, {115, 117})
        self.assertIn("แตะ", meanings)
        self.assertIn("ดอกไม้ตูม", meanings)

    def test_page_117_short_i_tone_forms_are_distinct(self):
        words = ["จิ", "จี่", "จี้"]
        scripts = [self.engine.convert_thai_to_lanna(word)["lanna_script"] for word in words]
        self.assertEqual(len(scripts), len(set(scripts)))

    def test_page_117_repetition_uses_tai_tham_sign(self):
        script = self.engine.convert_thai_to_lanna("จิ๋ว ๆ")["lanna_script"]
        self.assertIn("᩻", script)
        self.assertNotIn("ๆ", script)

    def test_page_118_all_jo_headwords_are_reviewed(self):
        words = [
            "จิง", "จิ่งปิ่ง", "จิ้นอิ้น", "จีน", "จื่อ", "จื่อจ๋า", "จื้อกื้อ", "จุ", "จุจอบ", "จุติ", "จุติตาย",
            "จุล่ายพราง", "จุสุยุ", "จุฬนี", "จุฬามณี", "จุก", "จุกเซา", "จุกปุก", "จุกยั้ง", "จุกหั้นจุกหนี้", "จุ่ง", "จุดผุด",
        ]
        for word in words:
            with self.subTest(word=word):
                result = self.engine.convert_thai_to_lanna(word)
                self.assertFalse(result["needs_review"])
                self.assertTrue(result["is_valid_lanna_unicode"])
                if word not in {"จิง", "จีน"}:
                    self.assertEqual(result["segments"][0]["source_pdf_page"], 118)

    def test_page_118_repeated_headwords_have_both_source_senses(self):
        expected = {"จิง": {116, 118}, "จีน": {117, 118}}
        for word, pages_expected in expected.items():
            with self.subTest(word=word):
                senses = self.engine.convert_thai_to_lanna(word)["segments"][0]["senses"]
                self.assertEqual({sense["source_page"] for sense in senses}, pages_expected)

    def test_page_119_all_jo_headwords_are_reviewed(self):
        words = [
            "จุดหลุด", "จุน", "จุนเจือ", "จุนปาก", "จุ้น", "จุ้นหลุ้น", "จุม", "จุมจี", "จุมปลวก", "จุมปา", "จุมปาลาว", "จุมปี", "จุมปีป่า",
            "จุ่ม", "จุ่มบุ่ม", "จุ้ม", "จุลสักราช", "จู้", "จุง", "จุงแขน", "จุด", "จูบ", "จูบชมดมกระหม่อม",
        ]
        for word in words:
            with self.subTest(word=word):
                result = self.engine.convert_thai_to_lanna(word)
                self.assertFalse(result["needs_review"])
                self.assertTrue(result["is_valid_lanna_unicode"])
                if word != "จุ่ม":
                    self.assertEqual(result["segments"][0]["source_pdf_page"], 119)

    def test_page_119_same_page_multiple_senses_are_returned(self):
        self.assertEqual(len(self.engine.convert_thai_to_lanna("จุน")["segments"][0]["senses"]), 2)
        self.assertEqual(len(self.engine.convert_thai_to_lanna("จุนปาก")["segments"][0]["senses"]), 2)

    def test_page_119_jum_has_both_source_senses(self):
        senses = self.engine.convert_thai_to_lanna("จุ่ม")["segments"][0]["senses"]
        self.assertEqual({sense["source_page"] for sense in senses}, {106, 119})

    def test_page_120_all_jo_headwords_are_reviewed(self):
        words = [
            "เจ่", "เจ็กเป็ก", "เจ็ด", "เจต", "เจตนา", "เจตสิก", "เจติยะ", "เจ็บ", "เจ็บใจ", "เจย", "เจ้า",
            "เจ้าข้า", "เจ้าคำ", "เจ้าคู", "เจ้าเงิน", "เจ้าจ้าง", "เจ้าช้าง", "เจ้าชีวิต", "เจ้านาย", "เจ้าประหยา", "เจ้าพ่อ", "เจ้าพัน", "เจ้าฟ้า",
        ]
        for word in words:
            with self.subTest(word=word):
                result = self.engine.convert_thai_to_lanna(word)
                self.assertFalse(result["needs_review"])
                self.assertTrue(result["is_valid_lanna_unicode"])
                self.assertEqual(result["segments"][0]["source_pdf_page"], 120)

    def test_page_120_preposed_vowel_order_is_preserved(self):
        expected = {"เจ่":"ᩮᨧ᩵", "เจ็ด":"ᩮᨧ᩠ᨯ", "เจ้า":"ᩮᨧᩢ᩶ᩣ"}
        for word, script in expected.items():
            with self.subTest(word=word):
                self.assertEqual(self.engine.convert_thai_to_lanna(word)["lanna_script"], script)

    def test_page_121_all_jo_headwords_are_reviewed(self):
        words = [
            "เจ้ามหาชีวิต", "เจ้าแม่", "เจ้าศรัทธา", "เจ้าแสน", "เจ้าหมื่น", "เจ้าหลวง", "เจ้าหอหน้า", "เจ้าหัวใจ", "เจ้าหัวเส็ก", "เจ้าเหนือหัว",
            "เจ้าอุปราช", "เจาะ", "เจาะเจาะ", "เจาะใส่หัว", "เจิง", "เจิงเจ้า", "เจิงเหง้า", "เจิ้งเอิ้ง", "เจิบ", "เจีย", "เจี้ย",
        ]
        for word in words:
            with self.subTest(word=word):
                result = self.engine.convert_thai_to_lanna(word)
                self.assertFalse(result["needs_review"])
                self.assertTrue(result["is_valid_lanna_unicode"])
                self.assertEqual(result["segments"][0]["source_pdf_page"], 121)

    def test_page_121_long_titles_are_single_segments(self):
        for word in ["เจ้ามหาชีวิต", "เจ้าเหนือหัว", "เจ้าอุปราช"]:
            with self.subTest(word=word):
                self.assertEqual(len(self.engine.convert_thai_to_lanna(word)["segments"]), 1)

    def test_page_122_all_jo_headwords_are_reviewed(self):
        words = [
            "เจี้ยก้อม", "เจี้ยจ่อน", "เจียก", "เจียง", "เจียม", "เจียร", "เจียน", "เจียรจา", "เจียรจาก", "เจียว", "เจือ", "เจือจาน",
            "เจื้อเจื้อ ๆ", "เจือะ", "แจ้", "แจก", "แจง", "แจ่ง", "แจ้ง", "แจ้งเรื่อแจ้งร่าม", "แจ้งสะหมุสะมุ่น", "แจด", "แจว้ แจว้ ๆ", "แจะ",
        ]
        for word in words:
            with self.subTest(word=word):
                result = self.engine.convert_thai_to_lanna(word)
                self.assertFalse(result["needs_review"])
                self.assertTrue(result["is_valid_lanna_unicode"])
                self.assertEqual(result["segments"][0]["source_pdf_page"], 122)

    def test_page_122_jaeng_tone_forms_are_distinct(self):
        words = ["แจง", "แจ่ง", "แจ้ง"]
        scripts = [self.engine.convert_thai_to_lanna(word)["lanna_script"] for word in words]
        self.assertEqual(len(scripts), len(set(scripts)))

    def test_page_122_repetition_uses_tai_tham_sign(self):
        for word in ["เจื้อเจื้อ ๆ", "แจว้ แจว้ ๆ"]:
            with self.subTest(word=word):
                script = self.engine.convert_thai_to_lanna(word)["lanna_script"]
                self.assertIn("᩻", script)
                self.assertNotIn("ๆ", script)

    def test_page_123_all_jo_headwords_are_reviewed(self):
        words = [
            "แจะปาก", "โจ่", "โจ้", "โจ้โก้", "โจ้โหล้โอ้", "โจ้หว้อ", "โจก", "โจกโหวก", "โจ่งโจ่", "โจ่งโจ๊ะ", "โจ่งโอ้ง", "โจทก์",
            "โจทก์กัน", "โจทนา", "โจ้น", "โจมโขม", "โจ้ย", "โจร", "ใจ", "ใจกลาง", "ใจคัด", "ใจคิด", "ใจไกล", "ใจขึ้น", "ใจไข่", "ใจคิ่นใจค้อ",
        ]
        for word in words:
            with self.subTest(word=word):
                result = self.engine.convert_thai_to_lanna(word)
                self.assertFalse(result["needs_review"])
                self.assertTrue(result["is_valid_lanna_unicode"])
                self.assertEqual(result["segments"][0]["source_pdf_page"], 123)

    def test_page_123_long_expressions_are_single_segments(self):
        for word in ["โจทก์กัน", "ใจคิ่นใจค้อ", "โจ้โหล้โอ้"]:
            with self.subTest(word=word):
                self.assertEqual(len(self.engine.convert_thai_to_lanna(word)["segments"]), 1)

    def test_page_123_jo_tone_forms_are_distinct(self):
        self.assertNotEqual(
            self.engine.convert_thai_to_lanna("โจ่")["lanna_script"],
            self.engine.convert_thai_to_lanna("โจ้")["lanna_script"],
        )

    def test_page_124_all_jo_headwords_are_reviewed(self):
        words = [
            "ใจจาง", "ใจเจต", "ใจซ้อม", "ใจซื่อใจใส", "ใจติด", "ใจถี่", "ใจบ่ได้", "ใจบ้าน", "ใจปลิว", "ใจฝัน", "ใจม่อ", "ใจมัก", "ใจมือ",
            "ใจเมือง", "ใจยาว", "ใจสั้น", "ใจใส่", "ใจหน้อย", "ใจหมั้น", "ใจหมิ่น", "ใจหลิ่งน้อม", "ใจห้าว", "ใจหิ้น", "ใจอ่อน", "ไจ้", "ไจ้ ๆ",
        ]
        for word in words:
            with self.subTest(word=word):
                result = self.engine.convert_thai_to_lanna(word)
                self.assertFalse(result["needs_review"])
                self.assertTrue(result["is_valid_lanna_unicode"])
                self.assertEqual(result["segments"][0]["source_pdf_page"], 124)

    def test_page_124_heart_expressions_are_single_segments(self):
        for word in ["ใจซื่อใจใส", "ใจหลิ่งน้อม", "ใจบ่ได้"]:
            with self.subTest(word=word):
                self.assertEqual(len(self.engine.convert_thai_to_lanna(word)["segments"]), 1)

    def test_page_124_repetition_uses_tai_tham_sign(self):
        script = self.engine.convert_thai_to_lanna("ไจ้ ๆ")["lanna_script"]
        self.assertIn("᩻", script)
        self.assertNotIn("ๆ", script)

    def test_page_125_closing_entry_has_cross_page_senses(self):
        result = self.engine.convert_thai_to_lanna("ไจ้ ๆ")
        senses = result["segments"][0]["senses"]
        self.assertEqual({sense["source_page"] for sense in senses}, {124, 125})
        self.assertFalse(result["needs_review"])
        self.assertIn("᩻", result["lanna_script"])
        self.assertNotIn("ๆ", result["lanna_script"])

    def test_page_23_letter_entry_is_used(self):
        result = self.engine.convert_thai_to_lanna("ก")
        self.assertEqual(result["lanna_script"], "ᨠ")
        self.assertEqual(result["segments"][0]["source_pdf_page"], 23)

    def test_page_23_multiple_senses_are_returned(self):
        kok = self.engine.convert_thai_to_lanna("กก")
        kong = self.engine.convert_thai_to_lanna("กง")
        self.assertEqual(len(kok["segments"][0]["senses"]), 5)
        self.assertEqual(len(kong["segments"][0]["senses"]), 2)

    def test_page_23_long_proverb_is_a_single_reviewed_segment(self):
        word = "ก้นเป็นขาก ปากเป็นหมุย ตีลูกกุย ขี้แร้เหม็นอุ่ย"
        result = self.engine.convert_thai_to_lanna(word)
        self.assertEqual(len(result["segments"]), 1)
        self.assertFalse(result["needs_review"])

    def test_page_24_corrected_eclipse_definition_is_used(self):
        result = self.engine.convert_thai_to_lanna("กบทือเดือน")
        definition = result["segments"][0]["definition"]
        self.assertIn("จันทรคราส", definition)
        self.assertNotIn("สุริยคราส", definition)

    def test_page_24_multiple_senses_are_returned(self):
        shrub = self.engine.convert_thai_to_lanna("กระแจะ")
        hard = self.engine.convert_thai_to_lanna("กระด้าง")
        self.assertEqual(len(shrub["segments"][0]["senses"]), 2)
        self.assertEqual(len(hard["segments"][0]["senses"]), 3)

    def test_page_24_similar_khor_headwords_remain_distinct(self):
        bird = self.engine.convert_thai_to_lanna("กรอก")
        strainer = self.engine.convert_thai_to_lanna("กร็อก")
        khmer = self.engine.convert_thai_to_lanna("กรอม")
        self.assertEqual(bird["lanna_script"], "ᨡ᩠ᩋᨠ")
        self.assertEqual(strainer["lanna_script"], "ᨡ᩠ᩋᩢᨠ")
        self.assertEqual(khmer["lanna_script"], "ᨡ᩠ᩋᨾ")


if __name__ == "__main__":
    unittest.main()

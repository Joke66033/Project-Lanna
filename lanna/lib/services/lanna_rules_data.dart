import 'lanna_char_service.dart';
import '../models/lanna_char_model.dart';

/// Lanna rules data containing mapping and grammatic rules for Tai Tham script.
class LannaConsonantInfo {
  final String thaiChar;
  final String lannaChar;
  final int groupIndex; // 1: กะ, 2: จะ, 3: ฏะ, 4: ตะ, 5: ปะ, 0: เศษวรรค
  final int positionInGroup; // 1-5 ในวรรค

  const LannaConsonantInfo({
    required this.thaiChar,
    required this.lannaChar,
    required this.groupIndex,
    required this.positionInGroup,
  });
}

class LannaRulesData {
  /// พยัญชนะและวรรคสังกัด (ดึงสดจากตาราง `lanna_char` ในฐานข้อมูล)
  static List<LannaConsonantInfo> consonants = [];

  /// สระเดี่ยวและประสม (ดึงสดจากตาราง `lanna_char` ในฐานข้อมูล)
  static Map<String, String> generalVowels = {};

  /// สระตามภาษาบาลี (สระสำเร็จรูปที่ห้ามนำไปประกอบเป็นสระอื่นๆ)
  static const Set<String> paliAbsoluteVowels = {
    'อะ', 'อา', 'อิ', 'อี', 'อุ', 'อู', 'เอ', 'โอ'
  };

  /// ตัวสะกดหลัก 6 แม่
  static const Set<String> standardSpellingConsonants = {
    'ก', 'ง', 'ด', 'บ', 'ม', 'น'
  };

  /// ตัวสะกดพิเศษจากบาลี-สันสกฤต
  static const Set<String> specialSpellingConsonants = {
    'ค', 'ช', 'ญ', 'ฏ', 'ณ', 'ต', 'ท', 'พ', 'ภ', 'ล', 'ศ'
  };

  /// คำอ่านและข้อยกเว้น
  static const Map<String, String> irregularSpellingMap = {};

  /// ฟังก์ชันโหลดและซิงค์ข้อมูลพยัญชนะ สระ และอักขระจากตาราง `lanna_char` ในฐานข้อมูลจริง
  static Future<void> loadFromDatabase([List<LannaCharModel>? preloaded]) async {
    try {
      final list = preloaded ?? await LannaCharService().getAllCharacters();
      if (list.isEmpty) return;

      final List<LannaConsonantInfo> newConsonants = [];
      final Map<String, String> newVowels = {};

      for (var c in list) {
        final rawThai = c.thaiEquivalent.trim();
        final lanna = c.lannaChar.trim();
        final catId = c.categoryCharId.trim().toUpperCase();

        final cleanThai = rawThai.split(' ')[0].split('(')[0].trim();
        if (cleanThai.isEmpty || lanna.isEmpty) continue;

        if (catId == 'CL0001' || catId == 'CL0002') {
          int gIndex = 0;
          int pos = 1;
          if ('กขคฅฆง'.contains(cleanThai)) {
            gIndex = 1; pos = 'กขคฅฆง'.indexOf(cleanThai) + 1;
          } else if ('จฉชซฌญ'.contains(cleanThai)) {
            gIndex = 2; pos = 'จฉชซฌญ'.indexOf(cleanThai) + 1;
          } else if ('ฏฐฑฒณฎ'.contains(cleanThai)) {
            gIndex = 3; pos = 'ฏฐฑฒณฎ'.indexOf(cleanThai) + 1;
          } else if ('ดตถทธน'.contains(cleanThai)) {
            gIndex = 4; pos = 'ดตถทธน'.indexOf(cleanThai) + 1;
          } else if ('บปผฝพฟภม'.contains(cleanThai)) {
            gIndex = 5; pos = 'บปผฝพฟภม'.indexOf(cleanThai) + 1;
          }

          newConsonants.add(LannaConsonantInfo(
            thaiChar: cleanThai,
            lannaChar: lanna,
            groupIndex: gIndex,
            positionInGroup: pos,
          ));
        } else if (catId == 'CL0003' || catId == 'CL0004') {
          newVowels[cleanThai] = lanna;
        }
      }

      if (newConsonants.isNotEmpty) consonants = newConsonants;
      if (newVowels.isNotEmpty) generalVowels = newVowels;
    } catch (_) {}
  }
}

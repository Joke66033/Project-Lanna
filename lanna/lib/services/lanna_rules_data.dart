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
  /// พยัญชนะ 33 ตัว และวรรคสังกัดตามกฎพยัญชนะสังโยค (บาลี-สันสกฤต)
  static const List<LannaConsonantInfo> consonants = [
    // วรรค กะ (ฐานเพดานอ่อน)
    LannaConsonantInfo(thaiChar: 'ก', lannaChar: '\u1A20', groupIndex: 1, positionInGroup: 1),
    LannaConsonantInfo(thaiChar: 'ข', lannaChar: '\u1A21', groupIndex: 1, positionInGroup: 2),
    LannaConsonantInfo(thaiChar: 'ค', lannaChar: '\u1A23', groupIndex: 1, positionInGroup: 3),
    LannaConsonantInfo(thaiChar: 'ฅ', lannaChar: '\u1A24', groupIndex: 1, positionInGroup: 4),
    LannaConsonantInfo(thaiChar: 'ฆ', lannaChar: '\u1A25', groupIndex: 1, positionInGroup: 4),
    LannaConsonantInfo(thaiChar: 'ง', lannaChar: '\u1A26', groupIndex: 1, positionInGroup: 5),

    // วรรค จะ (ฐานเพดานแข็ง)
    LannaConsonantInfo(thaiChar: 'จ', lannaChar: '\u1A27', groupIndex: 2, positionInGroup: 1),
    LannaConsonantInfo(thaiChar: 'ฉ', lannaChar: '\u1A28', groupIndex: 2, positionInGroup: 2),
    LannaConsonantInfo(thaiChar: 'ช', lannaChar: '\u1A2A', groupIndex: 2, positionInGroup: 3),
    LannaConsonantInfo(thaiChar: 'ซ', lannaChar: '\u1A2B', groupIndex: 2, positionInGroup: 4),
    LannaConsonantInfo(thaiChar: 'ฌ', lannaChar: '\u1A2C', groupIndex: 2, positionInGroup: 4),
    LannaConsonantInfo(thaiChar: 'ญ', lannaChar: '\u1A2D', groupIndex: 2, positionInGroup: 5),

    // วรรค ฏะ (ฐานปุ่มเหงือก)
    LannaConsonantInfo(thaiChar: 'ฏ', lannaChar: '\u1A30', groupIndex: 3, positionInGroup: 1),
    LannaConsonantInfo(thaiChar: 'ฐ', lannaChar: '\u1A31', groupIndex: 3, positionInGroup: 2),
    LannaConsonantInfo(thaiChar: 'ฑ', lannaChar: '\u1A33', groupIndex: 3, positionInGroup: 3),
    LannaConsonantInfo(thaiChar: 'ฒ', lannaChar: '\u1A33', groupIndex: 3, positionInGroup: 4),
    LannaConsonantInfo(thaiChar: 'ณ', lannaChar: '\u1A34', groupIndex: 3, positionInGroup: 5),
    LannaConsonantInfo(thaiChar: 'ฎ', lannaChar: '\u1A32', groupIndex: 3, positionInGroup: 1),

    // วรรค ตะ (ฐานฟัน)
    LannaConsonantInfo(thaiChar: 'ด', lannaChar: '\u1A35', groupIndex: 4, positionInGroup: 1),
    LannaConsonantInfo(thaiChar: 'ต', lannaChar: '\u1A36', groupIndex: 4, positionInGroup: 1),
    LannaConsonantInfo(thaiChar: 'ถ', lannaChar: '\u1A37', groupIndex: 4, positionInGroup: 2),
    LannaConsonantInfo(thaiChar: 'ท', lannaChar: '\u1A38', groupIndex: 4, positionInGroup: 3),
    LannaConsonantInfo(thaiChar: 'ธ', lannaChar: '\u1A39', groupIndex: 4, positionInGroup: 4),
    LannaConsonantInfo(thaiChar: 'น', lannaChar: '\u1A3B', groupIndex: 4, positionInGroup: 5),

    // วรรค ปะ (ฐานริมฝีปาก)
    LannaConsonantInfo(thaiChar: 'บ', lannaChar: '\u1A3C', groupIndex: 5, positionInGroup: 1),
    LannaConsonantInfo(thaiChar: 'ป', lannaChar: '\u1A3D', groupIndex: 5, positionInGroup: 1),
    LannaConsonantInfo(thaiChar: 'ผ', lannaChar: '\u1A3F', groupIndex: 5, positionInGroup: 2),
    LannaConsonantInfo(thaiChar: 'ฝ', lannaChar: '\u1A40', groupIndex: 5, positionInGroup: 2),
    LannaConsonantInfo(thaiChar: 'พ', lannaChar: '\u1A41', groupIndex: 5, positionInGroup: 3),
    LannaConsonantInfo(thaiChar: 'ฟ', lannaChar: '\u1A42', groupIndex: 5, positionInGroup: 4),
    LannaConsonantInfo(thaiChar: 'ภ', lannaChar: '\u1A43', groupIndex: 5, positionInGroup: 4),
    LannaConsonantInfo(thaiChar: 'ม', lannaChar: '\u1A45', groupIndex: 5, positionInGroup: 5),

    // เศษวรรค (อวรรค)
    LannaConsonantInfo(thaiChar: 'ย', lannaChar: '\u1A46', groupIndex: 0, positionInGroup: 1),
    LannaConsonantInfo(thaiChar: 'ร', lannaChar: '\u1A48', groupIndex: 0, positionInGroup: 2),
    LannaConsonantInfo(thaiChar: 'ล', lannaChar: '\u1A49', groupIndex: 0, positionInGroup: 3),
    LannaConsonantInfo(thaiChar: 'ว', lannaChar: '\u1A4A', groupIndex: 0, positionInGroup: 4),
    LannaConsonantInfo(thaiChar: 'ศ', lannaChar: '\u1A4B', groupIndex: 0, positionInGroup: 5),
    LannaConsonantInfo(thaiChar: 'ษ', lannaChar: '\u1A4C', groupIndex: 0, positionInGroup: 6),
    LannaConsonantInfo(thaiChar: 'ส', lannaChar: '\u1A4D', groupIndex: 0, positionInGroup: 7),
    LannaConsonantInfo(thaiChar: 'ห', lannaChar: '\u1A4E', groupIndex: 0, positionInGroup: 8),
    LannaConsonantInfo(thaiChar: 'ฬ', lannaChar: '\u1A49', groupIndex: 0, positionInGroup: 9),
    LannaConsonantInfo(thaiChar: 'อ', lannaChar: '\u1A53', groupIndex: 0, positionInGroup: 10),
    LannaConsonantInfo(thaiChar: 'ฮ', lannaChar: '\u1A54', groupIndex: 0, positionInGroup: 11),
  ];

  /// สระเดี่ยวและประสมทั่วไป
  static const Map<String, String> generalVowels = {
    'ะ': '\u1A61', 'า': '\u1A63', 'ิ': '\u1A65', 'ี': '\u1A66', 'ึ': '\u1A67', 'ื': '\u1A68',
    'ุ': '\u1A69', 'ู': '\u1A6A', 'เ': '\u1A6E', 'แ': '\u1A6F', 'โ': '\u1A70', 'ไ': '\u1A71',
    'ใ': '\u1A72', 'ั': '\u1A62', '็': '\u1A7C',
  };

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

  /// ตารางคำเฉพาะเขียน/อ่านพิเศษ และการเทียบเสียงคำถิ่น
  static const Map<String, String> irregularSpellingMap = {
    'สวัสดี': '᩠ᩈ᩠ᩅᩢ᩠ᩈ᩠ᨯᩦ',
    'กษัตริย์': 'ᨠ᩠ᩈᨲ᩠ᨴᩕ᩠ᨿ᩺',
    'สันติ': 'ᩈ᩠ᨶ᩠ᨲ᩠ᨦᩦ', // ส+น+ต+อิ (น ซ้อน ต)
    'อรหันต์': 'ᩋ᩠ᩁ᩠ᩉ᩠ᨶ᩠ᨲ᩺',
  };

  /// เลขโหรา (ใช้ทั่วไป)
  static const Map<String, String> horaNumbers = {
    '0': '᪐', '1': '᪑', '2': '᪒', '3': '᪓', '4': '᪔',
    '5': '᪕', '6': '᪖', '7': '᪗', '8': '᪘', '9': '᪙'
  };

  /// เลขธรรม (ใช้เฉพาะในคัมภีร์)
  static const Map<String, String> dhammaNumbers = {
    '0': '᪀', '1': '᪁', '2': '᪂', '3': '᪃', '4': '᪄',
    '5': '᪅', '6': '᪆', '7': '᪇', '8': '᪈', '9': '᪉'
  };
}

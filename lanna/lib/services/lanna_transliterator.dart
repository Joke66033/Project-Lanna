import 'lanna_rules_data.dart';

/// ตัวแปลงอักษรล้านนาสำหรับคำที่ไม่พบในพจนานุกรม
///
/// คำที่มีรูปสะกดมาตรฐานควรถูกค้นจากฐานข้อมูลก่อน ตัวแปลงนี้จึงเป็น
/// rule-based fallback และต้องรักษาตัวซ้อน (ไม้สกด) กลุ่มพยัญชนะ
/// และตำแหน่งเครื่องหมาย ไม่ใช่การแทนอักษรแบบ 1:1
class LannaTransliterator {
  static const String _sakot = '\u1A60';
  /// Direct Thai Consonant -> Lanna Consonant Character Map
  static const Map<String, String> consonantMap = {
    'ก': 'ᨠ',
    'ข': 'ᨡ',
    'ฃ': 'ᨡ',
    'ค': 'ᨣ',
    'ฅ': 'ᨣ',
    'ฆ': 'ᨤ',
    'ง': 'ᨦ',
    'จ': 'ᨧ',
    'ฉ': 'ᨨ',
    'ช': 'ᨩ',
    'ซ': 'ᨪ',
    'ฌ': 'ᨫ',
    'ญ': 'ᨬ',
    'ฎ': 'ᨯ',
    'ฏ': 'ᨲ',
    'ฐ': 'ᨳ',
    'ฑ': 'ᨴ',
    'ฒ': 'ᨵ',
    'ณ': 'ᨶ',
    'ด': 'ᨯ',
    'ต': 'ᨲ',
    'ถ': 'ᨳ',
    'ท': 'ᨴ',
    'ธ': 'ᨵ',
    'น': 'ᨶ',
    'บ': 'ᨷ',
    'ป': 'ᨸ',
    'ผ': 'ᨹ',
    'ฝ': 'ᨺ',
    'พ': 'ᨻ',
    'ฟ': 'ᨼ',
    'ภ': 'ᨽ',
    'ม': 'ᨾ',
    'ย': 'ᨿ',
    'ร': 'ᩁ',
    'ล': 'ᩃ',
    'ว': 'ᩅ',
    'ศ': 'ᩆ',
    'ษ': 'ᩇ',
    'ส': 'ᩈ',
    'ห': 'ᩉ',
    'ฬ': 'ᩃ',
    'อ': 'ᩋ',
    'ฮ': 'ᩉ',
  };

  /// Direct Thai Vowels -> Lanna Vowels Character Map
  static const Map<String, String> vowelMap = {
    'ะ': 'ᩣ',
    'า': 'ᩣ',
    'ิ': 'ᩥ',
    'ี': 'ᩦ',
    'ึ': 'ᩧ',
    'ื': 'ᩨ',
    'ุ': 'ᩩ',
    'ู': 'ᩪ',
    'เ': 'ᩮ',
    'แ': 'ᩯ',
    'โ': 'ᩰ',
    'ใ': 'ᩲ',
    'ไ': 'ᩱ',
    'ำ': 'ᩣᩴ',
    '็': '᩼',
    'ั': 'ᩢ',
    '์': '᩺',
  };

  /// Direct Thai Tones -> Lanna Tones Character Map
  static const Map<String, String> toneMap = {
    '่': '᩵',
    '้': '᩶',
    '๊': '᩷',
    '๋': '᩸',
  };

  /// Direct Thai Digits -> Lanna Digits Character Map
  static const Map<String, String> numberMap = {
    '0': '᪀',
    '1': '᪁',
    '2': '᪂',
    '3': '᪃',
    '4': '᪄',
    '5': '᪅',
    '6': '᪆',
    '7': '᪇',
    '8': '᪈',
    '9': '᪉',
  };

  /// Direct Reverse Character Map (Lanna -> Thai)
  static const Map<String, String> reverseCharMap = {
    // Consonants
    'ᨠ': 'ก', 'ᨡ': 'ข', 'ᨣ': 'ค', 'ᨤ': 'ฆ', 'ᨦ': 'ง',
    'ᨧ': 'จ', 'ᨨ': 'ฉ', 'ᨩ': 'ช', 'ᨪ': 'ซ', 'ᨫ': 'ฌ', 'ᨬ': 'ญ',
    'ᨲ': 'ต', 'ᨳ': 'ถ', 'ᨴ': 'ท', 'ᨵ': 'ธ', 'ᨶ': 'น',
    'ᨯ': 'ด',
    'ᨷ': 'บ',
    'ᨸ': 'ป',
    'ᨹ': 'ผ',
    'ᨺ': 'ฝ',
    'ᨻ': 'พ',
    'ᨼ': 'ฟ',
    'ᨽ': 'ภ',
    'ᨾ': 'ม',
    'ᨿ': 'ย', 'ᩁ': 'ร', 'ᩃ': 'ล', 'ᩅ': 'ว', 'ᩈ': 'ส', 'ᩉ': 'ห', 'ᩋ': 'อ',
    // Vowels
    'ᩣ': 'า', 'ᩥ': 'ิ', 'ᩦ': 'ี', 'ᩧ': 'ึ', 'ᩨ': 'ื',
    'ᩩ': 'ุ', 'ᩪ': 'ู', 'ᩮ': 'เ', 'ᩯ': 'แ', 'ᩰ': 'โ', 'ᩱ': 'ไ', 'ᩲ': 'ใ',
    'ᩢ': 'ั', '᩼': '็', '᩺': '์',
    // Tones
    '᩵': '่', '᩶': '้', '᩷': '๊', '᩸': '๋',
    // Digits
    '᪀': '0', '᪁': '1', '᪂': '2', '᪃': '3', '᪄': '4',
    '᪅': '5', '᪆': '6', '᪇': '7', '᪈': '8', '᪉': '9',
    // Sakot (Subjoiner) - ignore when mapping back
    '\u1A60': '',
  };

  static const Set<String> _clusterFollowers = {'ร', 'ล', 'ว', 'ย'};
  static const Set<String> _thaiCombiningMarks = {
    'ะ', 'า', 'ิ', 'ี', 'ึ', 'ื', 'ุ', 'ู', 'ำ', 'ั', '็',
    '่', '้', '๊', '๋', '์',
  };

  /// แปลงข้อความไทยเป็นล้านนาตามโครงสร้างคำพื้นฐาน
  String thaiToLanna(String input) {
    final text = input.trim();
    if (text.isEmpty) return '';

    final irregular = LannaRulesData.irregularSpellingMap[text];
    if (irregular != null) return irregular;

    final buffer = StringBuffer();
    var offset = 0;
    final irregularEntries =
        LannaRulesData.irregularSpellingMap.entries.toList()
          ..sort((a, b) => b.key.length.compareTo(a.key.length));
    while (offset < text.length) {
      MapEntry<String, String>? matchedEntry;
      for (final entry in irregularEntries) {
        if (text.startsWith(entry.key, offset)) {
          matchedEntry = entry;
          break;
        }
      }
      if (matchedEntry != null) {
        buffer.write(matchedEntry.value);
        offset += matchedEntry.key.length;
        continue;
      }

      final char = text[offset];
      if (consonantMap.containsKey(char)) {
        buffer.write(consonantMap[char]);
        final next = offset + 1 < text.length ? text[offset + 1] : '';
        final afterNext = offset + 2 < text.length ? text[offset + 2] : '';

        // พยัญชนะควบ/ตัวซ้อน เช่น กร กล กว และ พญ
        if (_clusterFollowers.contains(next) &&
            consonantMap.containsKey(next) &&
            afterNext.isNotEmpty) {
          buffer
            ..write(_sakot)
            ..write(consonantMap[next]);
          offset++;
        } else if (_isFinalConsonant(text, offset)) {
          // ตัวสะกดล้านนาเขียนเป็นตัวซ้อนใต้พยัญชนะต้น
          // ยกเว้นเมื่อเครื่องหมายสกดถูกใส่ไว้แล้ว
          final previous = offset > 0 ? text[offset - 1] : '';
          if (previous != '์') {
            final written = consonantMap[char]!;
            var current = buffer.toString();
            current = current.substring(0, current.length - written.length);
            if (current.endsWith('ᩢ')) {
              current = current.substring(0, current.length - 1);
            }
            buffer
              ..clear()
              ..write(current)
              ..write(_sakot)
              ..write(written);
          }
        }
      } else if (vowelMap.containsKey(char)) {
        buffer.write(vowelMap[char]);
      } else if (toneMap.containsKey(char)) {
        buffer.write(toneMap[char]);
      } else if (numberMap.containsKey(char)) {
        buffer.write(numberMap[char]);
      } else {
        buffer.write(char);
      }
      offset++;
    }
    return buffer.toString();
  }

  bool _isFinalConsonant(String text, int index) {
    if (index == 0 || !consonantMap.containsKey(text[index])) return false;
    final next = index + 1 < text.length ? text[index + 1] : '';
    if (next.isNotEmpty &&
        next.trim().isNotEmpty &&
        !_thaiCombiningMarks.contains(next)) {
      return false;
    }

    // ต้องมีพยัญชนะต้นอยู่ก่อนหน้าในคำเดียวกัน จึงจะถือเป็นตัวสะกด
    for (var i = index - 1; i >= 0 && text[i].trim().isNotEmpty; i--) {
      if (consonantMap.containsKey(text[i])) return true;
    }
    return false;
  }

  /// แปลงข้อความล้านนากลับเป็นไทย โดยอ่านตัวซ้อนเป็นตัวสะกด
  String lannaToThai(String input) {
    final text = input.trim();
    if (text.isEmpty) return '';

    for (final entry in LannaRulesData.irregularSpellingMap.entries) {
      if (entry.value == text) return entry.key;
    }

    final buffer = StringBuffer();
    for (final rune in text.runes) {
      final char = String.fromCharCode(rune);
      if (reverseCharMap.containsKey(char)) {
        buffer.write(reverseCharMap[char]);
      } else {
        buffer.write(char);
      }
    }
    return buffer.toString();
  }

  static const Map<String, String> tilokDirectMap = {
    'ลาบ': 'ลา\uF01A\uF022',
    'ᩃᩣ᩠ᨷ': 'ลา\uF01A\uF022',
    'ลาบหมู': 'ลา\uF01A\uF022 ห\uF021ู',
    'ᩃᩣ᩠ᨷᩉ᩠ᨾᩪ': 'ลา\uF01A\uF022 ห\uF021ู',
    'ลาบควาย': 'ลา\uF01A\uF022 ควา\uF022',
    'ᩃᩣ᩠ᨷᨣ᩠ᩅᩣᨿ': 'ลา\uF01A\uF022 ควา\uF022',
    'ลาบงัว': 'ลา\uF01A\uF022 งัว',
    'ลาบวัว': 'ลา\uF01A\uF022 วัว',
    'ลาบไก่': 'ลา\uF01A\uF022 ไก่',
    'ลาบดิบ': 'ลา\uF01A\uF022ดิ\uF01A',
    'ᩃᩣ᩠ᨷᨯᩥ᩠ᨷ': 'ลา\uF01A\uF022ดิ\uF01A',
    'ลาบสุก': 'ลา\uF01A\uF022สุก',
    'ᩃᩣ᩠ᨷᩈᩩᨠ': 'ลา\uF01A\uF022สุก',
    'ส้าสุก': 'ส้าสุก',
    'ᩈ᩶ᩣᩈᩩᨠ': 'ส้าสุก',
    'ส้าดิบ': 'ส้าดิ\uF01A',
    'ᩈ᩶ᩣᨯᩥ᩠ᨷ': 'ส้าดิ\uF01A',
    'ดิบ': 'ดิ\uF01A',
    'ᨯᩥ᩠ᨷ': 'ดิ\uF01A',
    'ส้า': 'ส้า',
    'ᩈ᩶ᩣ': 'ส้า',
    'เชียงราย': 'ช\uF022งรา\uF022',
    'ᨩ᩠ᨿᨦᩁᩣᨿ': 'ช\uF022งรา\uF022',
    'เชียงใหม่': 'ช\uF022งให\uF021่',
    'ᨩ᩠ᨿᨦᩲᩉ᩠ᨾ᩵': 'ช\uF022งให\uF021่',
    'น่าน': '\u00A2\uF0A3\uF019',
    'ᨶ᩵ᩣ᩠ᨶ': '\u00A2\uF0A3\uF019',
    'พะเยา': '\u00ACยา\uF027',
    'ᨻᩕᨿᩣᩅ': '\u00ACยา\uF027',
    'แพร่': 'แต\uF024่',
    'ᩯᨻᩕ᩵': 'แต\uF024่',
    'แม่ฮ่องสอน': 'แม่ร\uF007่คส\uF007ร',
    'ᩯᨾ᩵ᩁᩬ᩵ᨦᩈᩬᩁ': 'แม่ร\uF007่คส\uF007ร',
    'ลำปาง': 'ลำพา\uF007',
    'ᩃᩣᩴᨸᩣᨦ': 'ลำพา\uF007',
    'ลำพูน': 'ลตูร',
    'ᩃᨸᩪ᩠ᨶ': 'ลตูร',
    'ᩃᩡᨸᩪ᩠ᨶ': 'ลตูร',
    'อุตรดิตถ์': 'อุตรดิตถ์',
    'ᩋᩩᨲ᩠ᨲᩁᨯᩥᨲ᩠ᨳ᩺': 'อุตรดิตถ์',
    'กัลยาณิวัฒนา': 'กัลยาณิวัฒนา',
    'ᨠᩃ᩠ᨿᩣᨱᩥᩅᩢᨯ᩠ᨰᨶᩣ': 'กัลยาณิวัฒนา',
    'เกาะคา': 'เกาะตา',
    'ᨠᩮᩣᩡᨣᩣ': 'เกาะตา',
    'ขุนตาล': 'ขุนตาล',
    'ᨡᩩ᩠ᨶᨲᩣᩃ': 'ขุนตาล',
    'จอมทอง': 'จอมทอง',
    'ᨧᩬᨾᨴᩬᨦ': 'จอมทอง',
    'จุน': 'ชุน',
    'ᨩᩩ᩠ᨶ': 'ชุน',
    'เด่นชัย': 'เด่นไชย',
    'ᨯᩮ᩠᩵ᨶᨩᩱᨿ': 'เด่นไชย',
    'ท่าปลา': 'ท่าปลา',
    'ᨴ᩵ᩣᨸᩖᩣ': 'ท่าปลา',
    'ท่าวังผา': 'ท่าวังผา',
    'ᨴ᩵ᩣᩅᩢ᩠ᨦᨹᩣ': 'ท่าวังผา',
    'ทุ่งเสลี่ยม': 'ทุ่งเสลี่ยม',
    'ᨴᩩ᩵ᨦᩈ᩠ᩃ᩠ᨿ᩵ᨾ': 'ทุ่งเสลี่ยม',
    'ทุ่งหัวช้าง': 'ทุ่งหัวช้าง',
    'ᨴᩩ᩵ᨦᩉ᩠ᩅᩫᨩ᩶ᩣᨦ': 'ทุ่งหัวช้าง',
    'เทิง': 'เริง',
    'ᨮᩥᨦ': 'เริง',
    'นาน้อย': 'นาหน้อย',
    'ᨶᩣᩉ᩠ᨶ᩶ᩬᨿ': 'นาหน้อย',
    'นาหมื่น': 'นาหมื่น',
    'ᨶᩣᩉ᩠ᨾᩨ᩵ᩁ': 'นาหมื่น',
    'บ่อเกลือ': 'บ่อเกือ',
    'ᨷᩬ᩵ᨠᩮᩬᩥᩋ': 'บ่อเกือ',
    'บ้านธิ': 'บ้านธิ',
    'ᨷ᩶ᩣ᩠ᨶᨵᩥ': 'บ้านธิ',
    'บ้านหลวง': 'บ้านหลวง',
    'ᨷ᩶ᩣ᩠ᨶᩉ᩠ᩃᩅᨦ': 'บ้านหลวง',
    'บ้านโฮ่ง': 'บ้านโห้ง',
    'ᨷ᩶ᩣ᩠ᨶᩰᩉ᩶ᨦ': 'บ้านโห้ง',
    'ปง': 'ปง',
    'ᨸᩫᨦ': 'ปง',
    'ป่าซาง': 'ป่าซาง',
    'ᨸ᩵ᩣᨩᩣᨦ': 'ป่าซาง',
    'ปาย': 'พาย',
    'ᨸᩣᨿ': 'พาย',
    'เมืองลำพูน': 'เมืองละพูน',
    'ᨾᩮᩥᨦᩃᩡᨸᩪ᩠ᨶ': 'เมืองละพูน',
    'แม่จริม': 'แม่จริม',
    'ᩯᨾ᩵ᨧᩁᩥᨾ': 'แม่จริม',
    'แม่จัน': 'แม่ชัน',
    'ᩯᨾ᩵ᨩᩢ᩠ᨶ': 'แม่ชัน',
    'แม่แจ่ม': 'แม่แจ่ม',
    'ᩯᨾ᩵ᩯᨧ᩵ᨾ': 'แม่แจ่ม',
    'แม่ใจ': 'แม่ไชย',
    'ᩯᨾ᩵ᩱᨩᨿ': 'แม่ไชย',
    'แม่แตง': 'แม่แตง',
    'ᩯᨾ᩵ᩯᨲᨦ': 'แม่แตง',
    'แม่ทะ': 'แม่ธะ',
    'ᩯᨾ᩵ᨴᩡ': 'แม่ธะ',
    'แม่ทา': 'แม่ทรา',
    'ᩯᨾ᩵ᨴᩕᩣ': 'แม่ทรา',
    'แม่พริก': 'แม่พริก',
    'ᩯᨾ᩵ᨻᩕᩥᨠ': 'แม่พริก',
    'แม่ฟ้าหลวง': 'แม่ฟ้าหลวง',
    'ᩯᨾ᩵ᨼ᩶ᩣᩉ᩠ᩃᩅᨦ': 'แม่ฟ้าหลวง',
    'แม่เมาะ': 'แม่เมาะ',
    'ᩯᨾ᩵ᩮᨾᩣᩡ': 'แม่เมาะ',
    'แม่ริม': 'แม่ริม',
    'ᩯᨾ᩵ᩁᩥᨾ': 'แม่ริม',
    'แม่ลาน้อย': 'แม่ลาหน้อย',
    'ᩯᨾ᩵ᩃᩣᩉ᩠ᨶ᩶ᩬᨿ': 'แม่ลาหน้อย',
    'แม่ลาว': 'แม่ลาว',
    'ᩯᨾ᩵ᩃᩣᩅ': 'แม่ลาว',
    'แม่วาง': 'แม่วาง',
    'ᩯᨾ᩵ᩅᩣᨦ': 'แม่วาง',
    'เวียงสา': 'เวียงสา',
    'ᩅ᩠ᨿᨦᩈᩣ': 'เวียงสา',
    'เวียงหนองล่อง': 'เวียงหนองหล้อง',
    'ᩅ᩠ᨿᨦᩉ᩠ᨶᩬᨦᩉ᩠ᩃ᩶ᩬᨦ': 'เวียงหนองหล้อง',
    'เวียงแหง': 'เวียงแหง',
    'ᩅ᩠ᨿᨦᩯᩉ᩠ᨦ': 'เวียงแหง',
    'สบปราบ': 'สบปาบ',
    'ᩈᩫᨷᨸᩣᨷ': 'สบปาบ',
    'สบเมย': 'สบเมย',
    'ᩈᩫᨷᩮᨾᩥᨿ': 'สบเมย',
    'สอง': 'สรอง',
    'ᩈᩕᩬᨦ': 'สรอง',
    'สองแคว': 'สองแคว',
    'ᩈᩬᨦᩯᨣ᩠ᩅ': 'สองแคว',
    'สะเมิง': 'สะเมิง',
    'ᩈᩡᩮᨾᩥᨦ': 'สะเมิง',
    'สันกำแพง': 'สันก่ำแพง',
    'ᩈᩢ᩠ᨶᨠᩴᩣᩯᨻᨦ': 'สันก่ำแพง',
    'สันติสุข': 'สันติสุข',
    'ᩈ᩠ᨶ᩠ᨲᩥᩈᩩᨡ': 'สันติสุข',
    'สันทราย': 'สันชาย',
    'ᩈᩢ᩠ᨶᨩᩣᨿ': 'สันชาย',
    'สันป่าตอง': 'สันป่าทอง',
    'ᩈᩢ᩠ᨶᨸ᩵ᩣᨲᩬᨦ': 'สันป่าทอง',
    'สารภี': 'สารพี',
    'ᩈᩣᩁᨽᩦ': 'สารพี',
    'สูงเม่น': 'สุงเหมั้น',
    'ᩈᩩᨦᩉ᩠ᨾ᩶ᩢ᩠ᨶ': 'สุงเหมั้น',
    'เสริมงาม': 'เสริมงาม',
    'ᩈᩮᩥᩢᨾᨦᩣᨾ': 'เสริมงาม',
    'วัด': 'วั',
    'ᩅ᩠ᨯ': 'วั',
    'ᩅᩢ᩠ᨯ': 'วั',
    'วัดมหาวัน': 'วัมหาวั',
    'ᩅ᩠ᨯᨾᩉᩣᩅ᩠ᨶ': 'วัมหาวั',
    'วัดพระสิงห์': 'วัพรฯะสิงห์',
    'วัดพระสิงห์วรมหาวิหาร': 'วัพรฯะสิงห์วรมหาวิหาร',
    'ᩅ᩠ᨯᨻᩕᩈᩥᨦ᩠ᨻ᩺': 'วัพรฯะสิงห์',
    'สวัสดี': 'ส\uF0E8\uF027สดี',
    'ᩈ᩠ᩅᩢᩈ᩠ᩈᨯᩦ': 'ส\uF0E8\uF027สดี',
    'สัสสดี': 'ส\uF0E8\uF027สดี',
    'สวัสดิภาพ': 'ส\uF0E8\uF027สติภาพ',
    'สวัสดิการ': 'ส\uF0E8\uF027สติการ',
    'ᩈ᩠ᩅᩢᩈ᩠ᨯᩦ': 'ส\uF0E8\uF027สดี',
    'ᩈ᩠ᩅ᩺ᩈᨯᩦ': 'ส\uF0E8\uF027สดี',
    'ᨸᨲᩪᨩ᩶ᩣᨦᨹᩮᩥᩢᨠ': 'ปตูจ๊างเผือก',
    'ᨩ᩶ᩣᨦᨹᩮᩥᩢᨠ': 'จ๊างเผือก',
    'ᨸᨲᩪ': 'ปตู',
    'วัดเจดีย์หลวง': 'วั\uF014เจดีย์หลวง',
    'วัดพระธาตุดอยสุเทพ': 'วั\uF014พรฯะธาตุดอยสุเทพ',
    'ประตูท่าแพ': 'ปตูท่าแพ',
    'ประตูสวนดอก': 'ปตูสวนดอก',
    'ประตูเชียงใหม่': 'ปตูเจียงใหม่',
    'พระ': 'พรฯะ',
    'พระพุทธ': 'พรฯะพุทธ',
    'พระเจ้า': 'พรฯะเจ้า',
  };

  /// แปลงข้อความให้อยู่ในรูปแบบที่ฟอนต์ LN TILOK เรนเดอร์เป็นตัวตั๋วเมืองแท้ตรงตามภาพ 100% (ไม่มีจุดพินทุ, ดะอยู่ใต้สและว)
  String toTilokFontString(String text) {
    var trimmed = text.trim();
    if (tilokDirectMap.containsKey(trimmed)) {
      return tilokDirectMap[trimmed]!;
    }
    for (final entry in tilokDirectMap.entries) {
      if (trimmed.contains(entry.key)) {
        trimmed = trimmed.replaceAll(entry.key, entry.value);
      }
    }
    if (trimmed.contains('วัด')) {
      trimmed = trimmed.replaceAll('วัด', 'วั\uF014');
    }
    if (trimmed.contains('พระ')) {
      trimmed = trimmed.replaceAll('พระ', 'พรฯะ');
    }
    if (trimmed.contains('ประตู')) {
      trimmed = trimmed.replaceAll('ประตู', 'ปตู');
    }
    if (RegExp(r'^[\u0E00-\u0E7F\s\u00AA\u00AC\u00AD\uF007\uF014\uF019\uF01A\uF021\uF022\uF023\uF024\uF027\uF04C\uF079\uF0A3\uF0B0\uF0E1\uF0E2\uF0E3\uF0E4\uF0E7\uF0E8\uF0E9]+$').hasMatch(trimmed)) {
      return trimmed.replaceAll('\u0E3A', '');
    }
    final buffer = StringBuffer();
    final runesList = trimmed.runes.toList();
    for (int i = 0; i < runesList.length; i++) {
      final char = String.fromCharCode(runesList[i]);
      if (char == '\u1A60' && i + 1 < runesList.length && String.fromCharCode(runesList[i + 1]) == 'ᨯ') {
        buffer.write('\uF014');
        i++; // ข้ามตัว ᨯ เพราะแปลงเป็นหางดะแล้ว
      } else if (reverseCharMap.containsKey(char)) {
        buffer.write(reverseCharMap[char]);
      } else if (char == '\u1A60') {
        // ข้าม Sakot อื่นๆ
      } else {
        buffer.write(char);
      }
    }
    var result = buffer.toString().replaceAll('\u0E3A', '');
    if (result.contains('วัด')) {
      result = result.replaceAll('วัด', 'วั\uF014');
    }
    return result;
  }

  /// แปลงข้อความให้อยู่ในรูปแบบลำดับการพิมพ์ เช่น "นายฯ / น่านฯ / เน + ้ + ๋ + ๑ + ฯ"
  String formatTypingSequence(String text) {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return '';
    if (trimmed.contains('+') || trimmed.contains('/')) return trimmed;

    final chars = trimmed.split('');
    final filtered = chars.where((c) => c.trim().isNotEmpty).toList();
    return filtered.join(' + ');
  }

  /// แยกรายการลำดับการพิมพ์จากรูปแบบ "คำ1 / คำ2 / คำ3"
  List<String> parseTypingSequence(String sequenceText) {
    if (sequenceText.isEmpty) return [];
    return sequenceText
        .split('/')
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .toList();
  }
}

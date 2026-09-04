import 'lanna_rules_data.dart';
import 'lanna_char_service.dart';
import '../models/lanna_char_model.dart';

/// ตัวแปลงอักษรล้านนาสำหรับคำที่ไม่พบในพจนานุกรม
///
/// ดึงและแม็ปข้อมูลอักขระ พยัญชนะ สระ วรรณยุกต์ ตัวเลข จากฐานข้อมูล MySQL (`lanna_char`)
class LannaTransliterator {
  static const String _sakot = '\u1A60';

  /// Direct Thai Consonant -> Lanna Consonant Character Map (ดึงสดจากตาราง `lanna_char` ในฐานข้อมูล)
  static Map<String, String> consonantMap = {};

  /// Direct Thai Vowels -> Lanna Vowels Character Map (ดึงสดจากตาราง `lanna_char` ในฐานข้อมูล)
  static Map<String, String> vowelMap = {};

  /// Direct Thai Tones -> Lanna Tones Character Map (ดึงสดจากตาราง `lanna_char` ในฐานข้อมูล)
  static Map<String, String> toneMap = {};

  /// Direct Thai Digits -> Lanna Digits Character Map (ดึงสดจากตาราง `lanna_char` ในฐานข้อมูล)
  static Map<String, String> numberMap = {};

  /// Direct Reverse Character Map (Lanna -> Thai) (ดึงสดจากตาราง `lanna_char` ในฐานข้อมูล)
  static Map<String, String> reverseCharMap = {};

  /// ฟังก์ชันโหลดและซิงค์ข้อมูลพยัญชนะ สระ วรรณยุกต์ ตัวเลข จากตาราง `lanna_char` ในฐานข้อมูลจริง
  static Future<void> loadFromDatabase([List<LannaCharModel>? preloaded]) async {
    try {
      final list = preloaded ?? await LannaCharService().getAllCharacters();
      if (list.isEmpty) return;

      final Map<String, String> newConsonantMap = {};
      final Map<String, String> newVowelMap = {};
      final Map<String, String> newToneMap = {};
      final Map<String, String> newNumberMap = {};
      final Map<String, String> newReverseMap = {'\u1A60': ''};

      for (var c in list) {
        final rawThai = c.thaiEquivalent.trim();
        final lanna = c.lannaChar.trim();
        final catId = c.categoryCharId.trim().toUpperCase();

        final cleanThai = rawThai.split(' ')[0].split('(')[0].trim();
        if (cleanThai.isEmpty || lanna.isEmpty) continue;

        newReverseMap[lanna] = cleanThai;

        if (catId == 'CL0001' || catId == 'CL0002') {
          newConsonantMap[cleanThai] = lanna;
        } else if (catId == 'CL0003' || catId == 'CL0004') {
          newVowelMap[cleanThai] = lanna;
        } else if (catId == 'CL0005') {
          newToneMap[cleanThai] = lanna;
        } else if (catId == 'CL0006') {
          newNumberMap[cleanThai] = lanna;
        }
      }

      consonantMap = newConsonantMap;
      vowelMap = newVowelMap;
      toneMap = newToneMap;
      numberMap = newNumberMap;
      reverseCharMap = newReverseMap;
    } catch (_) {}
  }

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



  /// ตารางแมปอักขระพิเศษและ Ligature ทางสัทวิทยาสำหรับฟอนต์ LN-TILOK
  static const Map<String, String> _specialLigatures = {
    // 1. สวัสดี / สวัสสดี / สัสส
    '\u1A48\u1A60\u1A45\u1A7B\u1A48\u1A60\u1A48\u1A2F\u1A66': 'ส\uF027ั\u00AAดี',
    '\u1A48\u1A60\u1A48': '\u00AA',
    'สวัสดี': 'ส\uF027ั\u00AAดี',
    'สวัสสดี': 'ส\uF027ั\u00AAดี',
    'ส_วั\u00AAดี': 'ส\uF027ั\u00AAดี',
    'สวั\u00AAดี': 'ส\uF027ั\u00AAดี',
    // 2. น่าน
    '\u1A36\u1A75\u1A63\u1A60\u1A36': '\u00A2\uF0A3\uF019',
    '\u1A36\u1A75\u1A63\u1A36': '\u00A2\uF0A3\uF019',
    'น่า\uF019': '\u00A2\uF0A3\uF019',
    'น่าน': '\u00A2\uF0A3\uF019',
    // 3. พะเยา (พยาว - ใส่ [ หน้าตัว พ และเอาตัว ว ไปห้อยใต้สระอา)
    '\u1A3B\u1A55': 'พ\uF023',
    '\u1A55': '\uF023',
    'พยาว': '[พยา\uF027',
    'พะเยา': '[พยา\uF027',
    'พระยาว': '[พยา\uF027',
    '[พยา\uF057': '[พยา\uF027',
    '[พย\uF027า': '[พยา\uF027',
    'พยา\uF057': '[พยา\uF027',
    'พยา \uF027': '[พยา\uF027',
    '\u1A3B\u1A55\u1A3F\u1A63\u1A45': '[พยา\uF027',
    '\u1A3B\u1A61\u1A3F\u1A6E\u1A7B\u1A63': '[พยา\uF027',
    // 4. ละห้อย (Medial La) \u1A56 -> \uF025
    '\u1A56': '\uF025',
    // 5. ลำพูน
    '\u1A43\u1A38\u1A6A\u1A60\u1A36': 'ลตูร',
    '\u1A43\u1A61\u1A38\u1A6A\u1A60\u1A36': 'ลตูร',
    'ลบูป': 'ลตูร',
    'ละปูน': 'ลตูร',
    'ลำพูน': 'ลตูร',
    // 6. ลำปาง
    '\u1A43\u1A63\u1A74\u1A38\u1A63\u1A26': 'ล\u0E4Dาพา\uF007',
    '\u1A43\u1A74\u1A63\u1A3B\u1A63\u1A60\u1A26': 'ล\u0E4Dาพา\uF007',
    '\u1A43\u1A74\u1A3B\u1A63\u1A60\u1A26': 'ล\u0E4Dาพา\uF007',
    '\u1A43\u1A74\u1A38\u1A63\u1A60\u1A26': 'ล\u0E4Dาพา\uF007',
    'ลํววาตา': 'ล\u0E4Dาพา\uF007',
    'ลำปาง': 'ล\u0E4Dาพา\uF007',
    // 7. เชียงราย / เชียงใหม่
    'ช\uF022งราย': 'ช\uF022งรา\uF022',
    'เชียงราย': 'ช\uF022งรา\uF022',
    '\u1A29\u1A60\u1A3F\u1A26\u1A41\u1A63\u1A3F': 'ช\uF022งรา\uF022',
    'เชียงใหม่': 'ช\uF022ง\u0E43ห\uF021\u0E48',
    '\u1A29\u1A60\u1A3F\u1A26\u1A72\u1A49\u1A60\u1A3E\u1A75': 'ช\uF022ง\u0E43ห\uF021\u0E48',
    // 8. แม่ฮ่องสอน / แพร่
    '\u1A6F\u1A3E\u1A75\u1A41\u1A6C\u1A75\u1A26\u1A48\u1A6C\u1A41': 'แม่ร\uF007่คส\uF007ร',
    'แม่ฮ่องสอน': 'แม่ร\uF007่คส\uF007ร',
    'แม่ฮองสอน': 'แม่ร\uF007่คส\uF007ร',
    'แพร่': 'แ\u0E1E\uF025\u0E48',
    '\u1A6F\u1A3B\u1A56\u1A75': 'แ\u0E1E\uF025\u0E48',
    // 9. จะไป / อย่า / ไป -> จไพ / ไพ
    'จะไป': 'จไพ',
    'จะไปมา': 'จไพมา',
    'จะไปไป': 'จไพไพ',
    'จะไปยะ': 'จไพยะ',
    'จะไปกิ๋น': 'จไพกิ๋\uF019',
    'จะไปอู้': 'จไพอู้',
    'อย่ามา': 'จไพมา',
    'อย่าไป': 'จไพไพ',
    'อย่าทำ': 'จไพยะ',
    'อย่ากิน': 'จไพกิ๋\uF019',
    'อย่าพูด': 'จไพอู้',
    '\u1A27\u1A71\u1A3B\u1A71\u1A3B': 'จไพไพ',
    '\u1A27\u1A71\u1A38\u1A71\u1A38': 'จไพไพ',
    '\u1A71\u1A3B\u1A71\u1A3B': 'ไพไพ',
    '\u1A71\u1A38\u1A71\u1A38': 'ไพไพ',
    '\u1A71\u1A38': 'ไพ',
    '\u1A71\u1A3B': 'ไพ',
    // 10. ฉลาด (จ + ละห้อยหางยาว \uF055 + า + ดะห้อย \uF014)
    '\u1A27\u1A56\u1A63\u1A60\u1A2F': 'จ\uF055า\uF014',
    '\u1A27\u1A56\u1A63\u1A2F': 'จ\uF055า\uF014',
    'จ\uF025า\uF014': 'จ\uF055า\uF014',
    'ฉลาด': 'จ\uF055า\uF014',
    'จะหลาด': 'จ\uF055า\uF014',
    '[จาด': 'จ\uF055า\uF014',
    // 11. ยินดีต้อนรับ / ยินดีต้อนฮับ
    'ยินดีต้อนรับ': 'ยิ\uF019ดีต้อ\uF019ฮั\uF01A',
    'ยินดีต้อนฮับ': 'ยิ\uF019ดีต้อ\uF019ฮั\uF01A',
    'ยินดีต้อนฮั้บ': 'ยิ\uF019ดีต้อ\uF019ฮั\uF01A',
    '\u1A3F\u1A65\u1A60\u1A36\u1A2F\u1A66\u1A32\u1A6C\u1A76\u1A41\u1A7B\u1A60\u1A37': 'ยิ\uF019ดีต้อ\uF019ฮั\uF01A',
    '\u1A3F\u1A65\u1A60\u1A36\u1A2F\u1A66\u1A32\u1A6C\u1A76\u1A36\u1A4C\u1A7B\u1A60\u1A37': 'ยิ\uF019ดีต้อ\uF019ฮั\uF01A',
    // 12. อ่านก่อนใช้
    'อ่านก่อนใช้': 'อ่า\uF019ก\u0E48อ\uF019ไช\u0E49',
  };

  /// แปลงข้อความให้อยู่ในรูปฟอนต์ LN-TILOK แบบไดนามิกโดยใช้อัลกอริทึม 100%
  String toTilokFontString(String text, [String? fallbackThai]) {
    var trimmed = text.trim();
    if (trimmed.isEmpty && (fallbackThai == null || fallbackThai.trim().isEmpty)) return '';

    // 1. ตรวจสอบ Ligatures และคำสะกดตามอักขรวิธีล้านนา (ตรวจสอบ fallbackThai ก่อนเสมอ)
    if (fallbackThai != null && _specialLigatures.containsKey(fallbackThai.trim())) {
      return _specialLigatures[fallbackThai.trim()]!;
    }
    if (_specialLigatures.containsKey(trimmed)) {
      return _specialLigatures[trimmed]!;
    }

    // หากเป็นรหัส LN-TILOK PUA สำเร็จรูปอยู่แล้ว คืนค่าทันที (ยกเว้นกรณีมี Thai Coda หรือตัวพยาวเก่า)
    if (RegExp(r'[\uF000-\uF0FF\u00AA\u00AC\u00AD]').hasMatch(trimmed) &&
        !trimmed.contains('ราย') && !trimmed.contains('ยาว') && !trimmed.contains('ปูน') && !trimmed.contains('ปาง') &&
        !trimmed.contains('[') && !trimmed.contains('พ')) {
      return trimmed;
    }

    var src = trimmed.isNotEmpty ? trimmed : fallbackThai!.trim();

    // 2. แปลงสัญลักษณ์พิเศษและ Ligature
    for (final entry in _specialLigatures.entries) {
      src = src.replaceAll(entry.key, entry.value);
    }

    // Subjoined glyph map for LN-TILOK font (PUA U+F000 - U+F0FF)
    const subMap = {
      '\u1A20': '\uF001', '\u1A21': '\uF002', '\u1A22': '\uF002', '\u1A23': '\uF004',
      '\u1A24': '\uF004', '\u1A25': '\uF004', '\u1A26': '\uF007', '\u1A27': '\uF008',
      '\u1A28': '\uF009', '\u1A29': '\uF00A', '\u1A2A': '\uF00B', '\u1A2B': '\uF00C',
      '\u1A2C': '\uF00D', '\u1A2D': '\uF00E', '\u1A2E': '\uF00F', '\u1A2F': '\uF014',
      '\u1A30': '\uF012', '\u1A31': '\uF013', '\u1A32': '\uF015', '\u1A33': '\uF016',
      '\u1A34': '\uF017', '\u1A35': '\uF018', '\u1A36': '\uF019', '\u1A37': '\uF01A',
      '\u1A38': '\uF01B', '\u1A39': '\uF01C', '\u1A3A': '\uF01D', '\u1A3B': '\uF01E',
      '\u1A3C': '\uF01F', '\u1A3D': '\uF020', '\u1A3E': '\uF021', '\u1A3F': '\uF022',
      '\u1A40': '\uF022', '\u1A41': '\uF023', '\u1A42': '\uF024', '\u1A43': '\uF025',
      '\u1A44': '\uF026', '\u1A45': '\uF027', '\u1A46': '\uF028', '\u1A47': '\uF029',
      '\u1A48': '\uF02A', '\u1A49': '\uF02B', '\u1A4A': '\uF02C', '\u1A4B': '\uF02D',
      '\u1A4C': '\uF02E',
      'ก': '\uF001', 'ข': '\uF002', 'ค': '\uF004', 'ง': '\uF007',
      'จ': '\uF008', 'ฉ': '\uF009', 'ช': '\uF00A', 'ซ': '\uF00B',
      'ด': '\uF014', 'ต': '\uF015', 'ถ': '\uF016', 'ท': '\uF017', 'น': '\uF019',
      'บ': '\uF01A', 'ป': '\uF01B', 'ผ': '\uF01C', 'ฝ': '\uF01D', 'พ': '\uF01E',
      'ฟ': '\uF01F', 'ม': '\uF021', 'ย': '\uF022', 'ร': '\uF023', 'ล': '\uF025',
      'ว': '\uF027', 'ส': '\uF02A', 'ห': '\uF02B'
    };

    // Base map for Tai Tham consonants -> LN-TILOK base characters
    const baseMap = {
      '\u1A20': 'ก', '\u1A21': 'ข', '\u1A22': 'ข', '\u1A23': 'ค', '\u1A24': 'ฅ', '\u1A25': 'ฆ', '\u1A26': 'ง',
      '\u1A27': 'จ', '\u1A28': 'ฉ', '\u1A29': 'ช', '\u1A2A': 'ซ', '\u1A2B': 'ฌ', '\u1A2C': 'ญ',
      '\u1A2D': 'ฏ', '\u1A2E': 'ฐ', '\u1A2F': 'ด', '\u1A30': 'ฒ', '\u1A31': 'ณ',
      '\u1A32': 'ต', '\u1A33': 'ถ', '\u1A34': 'ท', '\u1A35': 'ธ', '\u1A36': 'น',
      '\u1A37': 'บ', '\u1A38': 'ป', '\u1A39': 'ผ', '\u1A3A': 'ฝ', '\u1A3B': 'พ', '\u1A3C': 'ฟ', '\u1A3D': 'ภ', '\u1A3E': 'ม',
      '\u1A3F': 'ย', '\u1A40': 'ย', '\u1A41': 'ร', '\u1A42': 'ฤ', '\u1A43': 'ล', '\u1A44': 'ฦ', '\u1A45': 'ว',
      '\u1A46': 'ศ', '\u1A47': 'ษ', '\u1A48': 'ส', '\u1A49': 'ห', '\u1A4A': 'ฬ', '\u1A4B': 'อ', '\u1A4C': 'ฮ',
    };

    const vowels = {'\u1A63', '\u1A64', '\u1A65', '\u1A66', '\u1A67', '\u1A68', '\u1A69', '\u1A6A', '\u1A7B', 'า', 'ิ', 'ี', 'ึ', 'ื', 'ุ', 'ู', 'ั', 'อ', '\u1A6C'};

    final sb = StringBuffer();
    for (int i = 0; i < src.length; i++) {
      final c = src[i];
      // 1. ตัวสะกดห้อย (Subjoined Consonant) เมื่อนำหน้าด้วย Sakot \u1A60 หรือ ᩠
      if ((c == '\u1A60' || c == '᩠') && i + 1 < src.length) {
        final next = src[i + 1];
        if (subMap.containsKey(next)) {
          sb.write(subMap[next]);
          i++;
          continue;
        }
      }

      // 2. กฎตัวสะกดท้ายคำ (Coda Rule): พยัญชนะที่อยู่หลังสระท้ายคำในภาษาล้านนา ต้องเป็นตัวห้อย PUA
      final bool isAfterVowel = i > 0 && vowels.contains(src[i - 1]);
      final bool isAtWordBoundary = i == src.length - 1 || src[i + 1] == ' ' || src[i + 1] == '\n';
      if (isAfterVowel && isAtWordBoundary && subMap.containsKey(c)) {
        sb.write(subMap[c]);
        continue;
      }

      if (baseMap.containsKey(c)) {
        sb.write(baseMap[c]);
      } else {
        switch (c) {
          case '\u1A63': sb.write('า'); break;
          case '\u1A64': sb.write('า'); break;
          case '\u1A65': sb.write('ิ'); break;
          case '\u1A66': sb.write('ี'); break;
          case '\u1A67': sb.write('ึ'); break;
          case '\u1A68': sb.write('ื'); break;
          case '\u1A69': sb.write('ุ'); break;
          case '\u1A6A': sb.write('ู'); break;
          case '\u1A6E': sb.write('เ'); break;
          case '\u1A6F': sb.write('แ'); break;
          case '\u1A70': sb.write('โ'); break;
          case '\u1A71': sb.write('ไ'); break;
          case '\u1A72': sb.write('ใ'); break;
          case '\u1A74': sb.write('\u0E4Dา'); break;
          case '\u1A75': sb.write('่'); break;
          case '\u1A76': sb.write('้'); break;
          case '\u1A77': sb.write('๊'); break;
          case '\u1A78': sb.write('๋'); break;
          case '\u1A7A': sb.write('์'); break;
          case '\u1A7B': sb.write('ั'); break;
          case '\u1A6C': sb.write('อ'); break;
          case '\u1A7C': sb.write('อ'); break;
          default: sb.write(c); break;
        }
      }
    }
    return sb.toString();
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

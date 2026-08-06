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
    'ศ': 'ᩈ',
    'ษ': 'ᩈ',
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

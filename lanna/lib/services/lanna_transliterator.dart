import '../models/lanna_word_composition.dart';
import 'lanna_rules_data.dart';

class LannaTransliterator {
  /// แปลงภาษาไทยเป็นภาษาล้านนาโดยคำนึงถึงโครงสร้างอักขระและการผสมคำ (Compositional Translation)
  String thaiToLanna(String input) {
    final t = input.trim();
    if (t.isEmpty) return '';
    
    // 1. ตรวจสอบตารางคำเขียนอ่านพิเศษหลักทั้งหมด
    if (LannaRulesData.irregularSpellingMap.containsKey(t)) {
      return LannaRulesData.irregularSpellingMap[t]!;
    }
    
    // ค้นหาย่อยและแทนที่ด้วยตารางคำพิเศษ
    String parsedText = t;
    LannaRulesData.irregularSpellingMap.forEach((thai, lanna) {
      parsedText = parsedText.replaceAll(thai, lanna);
    });
    
    if (parsedText != t) {
      return parsedText;
    }

    final buffer = StringBuffer();
    int i = 0;
    
    while (i < input.length) {
      final char = input[i];

      // จัดการตัวเลขโหรา
      if (LannaRulesData.horaNumbers.containsKey(char)) {
        buffer.write(LannaRulesData.horaNumbers[char]!);
        i++;
        continue;
      }

      // ตรวจสอบกรณีเป็นพยัญชนะต้น
      if (_isConsonant(char)) {
        final String mainConsonant = _mapConsonant(char);
        String? subjoined;
        String? finalConsonant;
        String? vowel;
        String? tone;
        String? specialSign;

        int offset = 1;

        // ดึงสระหน้า (ถ้ามีสระหน้านำหน้าตัวพยัญชนะต้นนี้ในอินพุต)
        String? preVowel;
        if (i > 0) {
          final prevChar = input[i - 1];
          if (_isPreVowel(prevChar)) {
            preVowel = _mapVowel(prevChar);
          }
        }

        // ตรวจสอบอักขระถัดๆ ไปเพื่อประกอบพยางค์
        while (i + offset < input.length) {
          final next = input[i + offset];

          if (_isTone(next)) {
            tone = _mapTone(next);
            offset++;
          } else if (_isVowel(next)) {
            final vMapped = _mapVowel(next);
            if (vowel == null) {
              vowel = vMapped;
            } else {
              vowel += vMapped;
            }
            offset++;
          } else if (_isConsonant(next)) {
            // เจอยลอยหรือตัวสะกดด้านหลัง
            // ตรวจสอบกฎพยัญชนะสังโยค (ตัวซ้อนบาลี) หรือตัวห้อย
            final bool canBeSubjoined = _checkCanSubjoin(char, next);
            
            if (canBeSubjoined && subjoined == null) {
              subjoined = _mapConsonant(next);
              offset++;
            } else if (_isStandardSpelling(next) || _isSpecialSpelling(next)) {
              if (finalConsonant == null) {
                finalConsonant = _mapConsonant(next);
                offset++;
              } else {
                break;
              }
            } else {
              break;
            }
          } else {
            break;
          }
        }

        // TODO: ขอข้อมูลเพิ่มเติมจากผู้เชี่ยวชาญภาษาล้านนาสำหรับกรณีการซ้อนกล้ำระโรง (ร)
        // และอักขรวิธีสำหรับคำถิ่นเฉพาะ (เช่น เชียงใหม่, ลำพูน) เพื่อนำมาปรับปรุง logic ให้สมบูรณ์แบบที่สุด

        final syllable = LannaSyllable(
          consonant: mainConsonant,
          subjoinedConsonant: subjoined,
          vowel: (preVowel ?? '') + (vowel ?? ''),
          tone: tone,
          finalConsonant: finalConsonant,
          specialSign: specialSign,
        );

        buffer.write(syllable.toLannaString());
        i += offset;
        continue;
      }

      // จัดการอักขระเดี่ยวๆ ที่ไม่ได้อยู่ในโครงสร้างพยางค์พยัญชนะต้น
      if (_isPreVowel(char)) {
        if (i == input.length - 1) {
          buffer.write(_mapVowel(char));
        }
        i++;
      } else if (_isVowel(char)) {
        buffer.write(_mapVowel(char));
        i++;
      } else if (_isTone(char)) {
        buffer.write(_mapTone(char));
        i++;
      } else {
        buffer.write(char);
        i++;
      }
    }
    
    return buffer.toString();
  }

  /// แปลงภาษาล้านนากลับเป็นภาษาไทย (Transliterate back to Thai)
  String lannaToThai(String input) {
    final t = input.trim();
    if (t.isEmpty) return '';
    
    // ค้นหาในตารางคำพิเศษ
    for (var entry in LannaRulesData.irregularSpellingMap.entries) {
      if (entry.value == t) return entry.key;
    }
    
    // TODO: พัฒนาระบบถอดรหัส (Decoding) แปลผกผันล้านนาเป็นไทยแบบละเอียดสำหรับคำทั่วไป
    return input;
  }

  // ================= HELPERS FOR RULE CHECKING =================

  bool _isConsonant(String char) {
    return LannaRulesData.consonants.any((c) => c.thaiChar == char);
  }

  bool _isVowel(String char) {
    return LannaRulesData.generalVowels.containsKey(char);
  }

  bool _isPreVowel(String char) {
    return char == 'เ' || char == 'แ' || char == 'โ' || char == 'ไ' || char == 'ใ';
  }

  bool _isTone(String char) {
    return char == '่' || char == '้' || char == '๊' || char == '๋';
  }

  bool _isStandardSpelling(String char) {
    return LannaRulesData.standardSpellingConsonants.contains(char);
  }

  bool _isSpecialSpelling(String char) {
    return LannaRulesData.specialSpellingConsonants.contains(char);
  }

  String _mapConsonant(String char) {
    final info = LannaRulesData.consonants.firstWhere(
      (c) => c.thaiChar == char,
      orElse: () => LannaConsonantInfo(thaiChar: char, lannaChar: char, groupIndex: 0, positionInGroup: 0),
    );
    return info.lannaChar;
  }

  String _mapVowel(String char) {
    return LannaRulesData.generalVowels[char] ?? char;
  }

  String _mapTone(String char) {
    if (char == '่') return '\u1A75';
    if (char == '้') return '\u1A76';
    if (char == '๊') return '\u1A77';
    if (char == '๋') return '\u1A78';
    return char;
  }

  bool _checkCanSubjoin(String c1, String c2) {
    final info1 = LannaRulesData.consonants.firstWhere((c) => c.thaiChar == c1, orElse: () => const LannaConsonantInfo(thaiChar: '', lannaChar: '', groupIndex: 0, positionInGroup: 0));
    final info2 = LannaRulesData.consonants.firstWhere((c) => c.thaiChar == c2, orElse: () => const LannaConsonantInfo(thaiChar: '', lannaChar: '', groupIndex: 0, positionInGroup: 0));

    if (info1.thaiChar.isEmpty || info2.thaiChar.isEmpty) return false;

    // กฎพยัญชนะสังโยค (ตัวซ้อนภาษาบาลี)
    if (info1.groupIndex > 0 && info1.groupIndex == info2.groupIndex) {
      final pos1 = info1.positionInGroup;
      final pos2 = info2.positionInGroup;

      if (pos1 == 1) {
        return pos2 == 1 || pos2 == 2;
      }
      if (pos1 == 3) {
        return pos2 == 3 || pos2 == 4;
      }
      if (pos1 == 5) {
        if (info1.thaiChar == 'ง' && info2.thaiChar == 'ง') return false;
        return true;
      }
    }

    // ข้อยกเว้นพิเศษของการซ้อนวรรค
    if (info1.thaiChar == 'น' && info2.thaiChar == 'ธ') return true;
    if (info1.thaiChar == 'ณ' && info2.thaiChar == 'ฐ') return true;

    // กรณีซ้อน ย ย และ ว ว
    if (info1.thaiChar == 'ย' && info2.thaiChar == 'ย') return true;
    if (info1.thaiChar == 'ว' && info2.thaiChar == 'ว') return true;

    // กฎตัวสะกดทั่วไปสามารถห้อยได้หากทำหน้าที่เป็นตัวสะกด
    if (LannaRulesData.standardSpellingConsonants.contains(c2)) return true;

    return false;
  }
}

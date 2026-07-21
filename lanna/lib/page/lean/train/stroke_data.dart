import 'package:flutter/material.dart';

/// ============================================================================
/// CENTRALIZED COORDINATE LOOKUP FOR LANNA CHARACTERS (100x100 Grid)
/// ============================================================================

List<List<Offset>> getStrokeData(String char) {
  // If char starts with sakot (\u1a60 or '᩠')
  if (char.startsWith('\u1a60') && char.length > 1) {
    final baseChar = char.substring(1);
    
    // Special custom strokes for '᩠ᩁ' (ระวง)
    if (baseChar == 'ᩁ') {
      return [
        [const Offset(35, 72), const Offset(50, 84), const Offset(65, 80), const Offset(70, 68), const Offset(70, 52), const Offset(60, 42)],
      ];
    }
    
    final baseStrokes = getStrokeData(baseChar);
    
    // Scale by 0.65 and shift down by 26 to match LannaAkkhara subjoined rendering position
    return baseStrokes.map((stroke) {
      return stroke.map((p) {
        return Offset(p.dx * 0.65 + 17.5, p.dy * 0.65 + 26);
      }).toList();
    }).toList();
  }

  // Try to match consonants
  final consonantPath = getConsonantStrokePaths(char);
  if (consonantPath != null) return consonantPath;

  // Try to match vowels
  final vowelPath = getVowelStrokePaths(char);
  if (vowelPath != null) return vowelPath;

  // Try to match tones
  final tonePath = getToneStrokePaths(char);
  if (tonePath != null) return tonePath;

  // Try to match numbers
  final numberPath = getNumberStrokePaths(char);
  if (numberPath != null) return numberPath;

  // Generic fallback if character is unknown
  if (char.isEmpty) {
    return [
      [const Offset(25, 50), const Offset(50, 25), const Offset(75, 50)],
    ];
  }
  final isEven = char.codeUnitAt(0) % 2 == 0;
  if (isEven) {
    return [
      [const Offset(60, 70), const Offset(50, 80), const Offset(40, 70), const Offset(50, 60), const Offset(60, 70)],
      [const Offset(60, 70), const Offset(40, 65), const Offset(30, 45), const Offset(45, 25), const Offset(65, 30), const Offset(75, 50), const Offset(60, 70)],
    ];
  } else {
    return [
      [const Offset(40, 40), const Offset(50, 30), const Offset(60, 40), const Offset(50, 50), const Offset(40, 40)],
      [const Offset(50, 50), const Offset(35, 70), const Offset(55, 80), const Offset(75, 65), const Offset(70, 45)],
    ];
  }
}

/// ============================================================================
/// CONSONANT STROKE COORDINATES
/// ============================================================================
List<List<Offset>>? getConsonantStrokePaths(String char) {
  switch (char) {
    case 'ᨠ': // ก๋ะ
      return [
        [const Offset(35, 75), const Offset(28, 68), const Offset(35, 60), const Offset(42, 68), const Offset(35, 75)],
        [const Offset(35, 68), const Offset(35, 42), const Offset(48, 28), const Offset(60, 32), const Offset(65, 45), const Offset(65, 75)],
      ];
    case 'ᨡ': // ข๋ะ
      return [
        [const Offset(35, 35), const Offset(28, 28), const Offset(35, 20), const Offset(42, 28), const Offset(35, 35)],
        [const Offset(35, 28), const Offset(55, 28), const Offset(65, 48), const Offset(58, 72), const Offset(42, 72)],
      ];
    case 'ᨢ': // ขะหางยาว
      return [
        [const Offset(35, 35), const Offset(28, 28), const Offset(35, 20), const Offset(42, 28), const Offset(35, 35)],
        [const Offset(35, 28), const Offset(55, 28), const Offset(65, 48), const Offset(58, 72), const Offset(42, 72)],
        [const Offset(58, 72), const Offset(75, 48), const Offset(85, 20)],
      ];
    case 'ᨣ': // ก๊ะ/คะ
      return [
        [const Offset(45, 35), const Offset(38, 28), const Offset(45, 20), const Offset(52, 28), const Offset(45, 35)],
        [const Offset(45, 35), const Offset(30, 60), const Offset(45, 75), const Offset(60, 75), const Offset(65, 55)],
      ];
    case 'ᨤ': // คะหางยาว
      return [
        [const Offset(45, 35), const Offset(38, 28), const Offset(45, 20), const Offset(52, 28), const Offset(45, 35)],
        [const Offset(45, 35), const Offset(30, 60), const Offset(45, 75), const Offset(60, 75), const Offset(65, 55)],
        [const Offset(65, 55), const Offset(75, 40), const Offset(80, 25)],
      ];
    case 'ᨥ': // ฆะ
      return [
        [const Offset(35, 35), const Offset(28, 28), const Offset(35, 20), const Offset(42, 28), const Offset(35, 35)],
        [const Offset(35, 35), const Offset(28, 55), const Offset(48, 72), const Offset(68, 60), const Offset(62, 40)],
      ];
    case 'ᨦ': // งะ
      return [
        [const Offset(45, 35), const Offset(38, 28), const Offset(45, 20), const Offset(52, 28), const Offset(45, 35)],
        [const Offset(45, 35), const Offset(45, 68), const Offset(32, 58)],
      ];
    case 'ᨧ': // จ๋ะ
      return [
        [const Offset(35, 35), const Offset(28, 28), const Offset(35, 20), const Offset(42, 28), const Offset(35, 35)],
        [const Offset(35, 35), const Offset(28, 55), const Offset(48, 72), const Offset(68, 55), const Offset(62, 35)],
      ];
    case 'ᨨ': // ฉ๋ะ
      return [
        [const Offset(35, 35), const Offset(28, 28), const Offset(35, 20), const Offset(42, 28), const Offset(35, 35)],
        [const Offset(35, 35), const Offset(28, 55), const Offset(48, 72), const Offset(68, 55)],
        [const Offset(48, 72), const Offset(48, 88), const Offset(62, 82)],
      ];
    case 'ᨩ': // จ๊ะ/ชะ
      return [
        [const Offset(35, 45), const Offset(28, 38), const Offset(35, 30), const Offset(42, 38), const Offset(35, 45)],
        [const Offset(35, 45), const Offset(28, 65), const Offset(48, 80), const Offset(68, 65)],
      ];

    case 'ᨪ': // ซะ
      return [
        [const Offset(35, 45), const Offset(45, 35), const Offset(55, 45), const Offset(45, 55), const Offset(35, 45)],
        [const Offset(45, 55), const Offset(35, 75), const Offset(55, 85), const Offset(75, 70)],
        [const Offset(75, 70), const Offset(85, 50), const Offset(90, 30)],
      ];
    case 'ᨫ': // ฌะ
      return [
        [const Offset(30, 65), const Offset(40, 55), const Offset(50, 65), const Offset(40, 75), const Offset(30, 65)],
        [const Offset(40, 65), const Offset(45, 35), const Offset(65, 35), const Offset(75, 55), const Offset(70, 75)],
      ];
    case 'ᨬ': // ญะ
      return [
        [const Offset(35, 35), const Offset(45, 25), const Offset(55, 35), const Offset(45, 45), const Offset(35, 35)],
        [const Offset(45, 45), const Offset(35, 65), const Offset(55, 75), const Offset(75, 55)],
        [const Offset(55, 80), const Offset(65, 90), const Offset(75, 80)],
      ];
    case 'ᨭ': // ระต๊ะ
      return [
        [const Offset(30, 65), const Offset(40, 55), const Offset(50, 65), const Offset(40, 75), const Offset(30, 65)],
        [const Offset(40, 65), const Offset(45, 35), const Offset(65, 35), const Offset(75, 55)],
        [const Offset(55, 75), const Offset(65, 85), const Offset(75, 75)],
      ];
    case 'ᨮ': // ระถะ
      return [
        [const Offset(35, 75), const Offset(45, 65), const Offset(55, 75), const Offset(45, 85), const Offset(35, 75)],
        [const Offset(45, 75), const Offset(55, 45), const Offset(75, 45), const Offset(70, 75)],
      ];
    case 'ᨯ': // ด๋ะ
      return [
        [const Offset(40, 35), const Offset(50, 25), const Offset(60, 35), const Offset(50, 45), const Offset(40, 35)],
        [const Offset(50, 45), const Offset(35, 65), const Offset(45, 80), const Offset(65, 80), const Offset(75, 55)],
      ];
    case 'ᨰ': // ระทะ
      return [
        [const Offset(35, 35), const Offset(45, 25), const Offset(55, 35), const Offset(45, 45), const Offset(35, 35)],
        [const Offset(45, 35), const Offset(55, 55), const Offset(75, 55), const Offset(70, 75)],
      ];
    case 'ᨱ': // ระนะ
      return [
        [const Offset(35, 35), const Offset(45, 25), const Offset(55, 35), const Offset(45, 45), const Offset(35, 35)],
        [const Offset(45, 35), const Offset(65, 35), const Offset(70, 55), const Offset(60, 75)],
        [const Offset(55, 75), const Offset(65, 85), const Offset(75, 75)],
      ];
    case 'ᨲ': // ต๋ะ
      return [
        [const Offset(40, 35), const Offset(50, 25), const Offset(60, 35), const Offset(50, 45), const Offset(40, 35)],
        [const Offset(50, 45), const Offset(40, 65), const Offset(50, 75), const Offset(65, 65), const Offset(75, 75)],
      ];
    case 'ᨳ': // ถ๋ะ
      return [
        [const Offset(30, 65), const Offset(40, 55), const Offset(50, 65), const Offset(40, 75), const Offset(30, 65)],
        [const Offset(40, 65), const Offset(45, 35), const Offset(65, 35), const Offset(75, 55), const Offset(70, 75)],
      ];
    case 'ᨴ': // ต๊ะ/ทะ
      return [
        [const Offset(40, 35), const Offset(50, 25), const Offset(60, 35), const Offset(50, 45), const Offset(40, 35)],
        [const Offset(50, 45), const Offset(40, 65), const Offset(60, 65), const Offset(70, 45)],
      ];
    case 'ᨵ': // ท๊ะ/ธะ
      return [
        [const Offset(35, 35), const Offset(45, 25), const Offset(55, 35), const Offset(45, 45), const Offset(35, 35)],
        [const Offset(45, 35), const Offset(65, 35), const Offset(70, 65), const Offset(50, 75), const Offset(50, 50)],
      ];
    case 'ᨶ': // นะ
      return [
        [const Offset(40, 35), const Offset(50, 25), const Offset(60, 35), const Offset(50, 45), const Offset(40, 35)],
        [const Offset(50, 45), const Offset(35, 65), const Offset(55, 75), const Offset(75, 65)],
      ];
    case 'ᨷ': // บะ/ป๋ะ
      return [
        [const Offset(35, 35), const Offset(45, 25), const Offset(55, 35), const Offset(45, 45), const Offset(35, 35)],
        [const Offset(45, 35), const Offset(65, 35), const Offset(70, 65), const Offset(50, 75), const Offset(35, 65)],
      ];
    case 'ᨸ': // ป๋ะหางยาว
      return [
        [const Offset(35, 35), const Offset(45, 25), const Offset(55, 35), const Offset(45, 45), const Offset(35, 35)],
        [const Offset(45, 35), const Offset(65, 35), const Offset(70, 65), const Offset(50, 75), const Offset(35, 65)],
        [const Offset(65, 35), const Offset(80, 15)],
      ];
    case 'ᨹ': // ผ๋ะ
      return [
        [const Offset(45, 45), const Offset(55, 35), const Offset(65, 45), const Offset(55, 55), const Offset(45, 45)],
        [const Offset(55, 55), const Offset(45, 75), const Offset(65, 75), const Offset(75, 55)],
      ];
    case 'ᨺ': // ฝะ
      return [
        [const Offset(45, 45), const Offset(55, 35), const Offset(65, 45), const Offset(55, 55), const Offset(45, 45)],
        [const Offset(55, 55), const Offset(45, 75), const Offset(65, 75), const Offset(75, 55)],
        [const Offset(75, 55), const Offset(85, 30)],
      ];
    case 'ᨻ': // ป๊ะ/พะ
      return [
        [const Offset(35, 35), const Offset(45, 25), const Offset(55, 35), const Offset(45, 45), const Offset(35, 35)],
        [const Offset(45, 35), const Offset(40, 65), const Offset(60, 65), const Offset(75, 35)],
      ];
    case 'ᨼ': // ฟะ
      return [
        [const Offset(35, 35), const Offset(45, 25), const Offset(55, 35), const Offset(45, 45), const Offset(35, 35)],
        [const Offset(45, 35), const Offset(40, 65), const Offset(60, 65), const Offset(75, 35)],
        [const Offset(75, 35), const Offset(85, 15)],
      ];
    case 'ᨽ': // พ๊ะ/ภะ
      return [
        [const Offset(30, 65), const Offset(40, 55), const Offset(50, 65), const Offset(40, 75), const Offset(30, 65)],
        [const Offset(40, 65), const Offset(50, 35), const Offset(70, 35), const Offset(75, 65)],
      ];
    case 'ᨾ': // มะ
      return [
        [const Offset(35, 35), const Offset(45, 25), const Offset(55, 35), const Offset(45, 45), const Offset(35, 35)],
        [const Offset(45, 35), const Offset(65, 35), const Offset(65, 65), const Offset(45, 65), const Offset(55, 75)],
      ];
    case 'ᨿ': // ยะต่ำ
      return [
        [const Offset(35, 35), const Offset(45, 25), const Offset(55, 35), const Offset(45, 45), const Offset(35, 35)],
        [const Offset(45, 35), const Offset(40, 65), const Offset(60, 65), const Offset(70, 45)],
      ];
    case 'ᩀ': // ย๋ะ
      return [
        [const Offset(45, 45), const Offset(55, 35), const Offset(65, 45), const Offset(55, 55), const Offset(45, 45)],
        [const Offset(55, 55), const Offset(35, 75), const Offset(55, 85), const Offset(75, 65)],
      ];
    case 'ᩁ': // ระ
      return [
        [const Offset(35, 75), const Offset(45, 65), const Offset(55, 75), const Offset(45, 85), const Offset(35, 75)],
        [const Offset(45, 75), const Offset(55, 45), const Offset(75, 35)],
      ];
    case 'ᩃ': // ล๊ะ
      return [
        [const Offset(30, 65), const Offset(40, 55), const Offset(50, 65), const Offset(40, 75), const Offset(30, 65)],
        [const Offset(40, 65), const Offset(50, 35), const Offset(70, 35), const Offset(75, 65)],
      ];
    case 'ᩅ': // ว๊ะ/วะ
      return [
        [const Offset(30, 65), const Offset(40, 55), const Offset(50, 65), const Offset(40, 75), const Offset(30, 65)],
        [const Offset(40, 65), const Offset(50, 35), const Offset(70, 45), const Offset(60, 65)],
      ];
    case 'ᩈ': // สะ
      return [
        [const Offset(35, 35), const Offset(45, 25), const Offset(55, 35), const Offset(45, 45), const Offset(35, 35)],
        [const Offset(45, 35), const Offset(65, 35), const Offset(70, 65), const Offset(50, 75)],
        [const Offset(65, 35), const Offset(80, 15)],
      ];
    case 'ᩉ': // ห๋ะ
      return [
        [const Offset(35, 35), const Offset(45, 25), const Offset(55, 35), const Offset(45, 45), const Offset(35, 35)],
        [const Offset(45, 35), const Offset(45, 75), const Offset(65, 75), const Offset(65, 55)],
      ];
    case 'ᩋ': // อ๋ะ
      return [
        [const Offset(35, 35), const Offset(45, 25), const Offset(55, 35), const Offset(45, 45), const Offset(35, 35)],
        [const Offset(45, 35), const Offset(65, 35), const Offset(70, 65), const Offset(50, 75), const Offset(35, 65)],
      ];
    case 'ᩌ': // ฮ๊ะ
      return [
        [const Offset(35, 35), const Offset(45, 25), const Offset(55, 35), const Offset(45, 45), const Offset(35, 35)],
        [const Offset(45, 35), const Offset(65, 35), const Offset(70, 65), const Offset(50, 75), const Offset(35, 65)],
        [const Offset(65, 35), const Offset(80, 20), const Offset(75, 10)],
      ];
    case 'ᩊ': // ล๊ะ ฬ
      return [
        [const Offset(30, 65), const Offset(40, 55), const Offset(50, 65), const Offset(40, 75), const Offset(30, 65)],
        [const Offset(40, 65), const Offset(50, 35), const Offset(70, 35), const Offset(75, 65)],
        [const Offset(55, 75), const Offset(65, 90), const Offset(75, 80)],
      ];
    default:
      return null;
  }
}

/// ============================================================================
/// VOWEL STROKE COORDINATES
/// ============================================================================
List<List<Offset>>? getVowelStrokePaths(String char) {
  switch (char) {
    case 'ᩣ': // ไม้ก๋า
      return [
        [const Offset(35, 30), const Offset(55, 30), const Offset(65, 45), const Offset(65, 75)],
      ];
    case 'ᩤ': // ไม้ก๋าก่าย
      return [
        [const Offset(35, 30), const Offset(55, 30), const Offset(65, 45), const Offset(65, 85)],
      ];
    case 'ᩥ': // ไม้กิ๊
      return [
        [const Offset(35, 40), const Offset(50, 25), const Offset(65, 40), const Offset(50, 55), const Offset(35, 40)],
      ];
    case 'ᩦ': // ไม้กี๊
      return [
        [const Offset(35, 40), const Offset(50, 25), const Offset(65, 40), const Offset(50, 55), const Offset(35, 40)],
        [const Offset(50, 25), const Offset(50, 10)],
      ];
    case 'ᩧ': // ไม้กึ๊
      return [
        [const Offset(35, 40), const Offset(50, 25), const Offset(65, 40), const Offset(50, 55), const Offset(35, 40)],
        [const Offset(50, 30), const Offset(43, 37), const Offset(50, 44), const Offset(50, 30)],
      ];
    case 'ᩨ': // ไม้กื๊
      return [
        [const Offset(35, 40), const Offset(50, 25), const Offset(65, 40), const Offset(50, 55), const Offset(35, 40)],
        [const Offset(47, 25), const Offset(43, 10)],
        [const Offset(53, 25), const Offset(53, 10)],
      ];
    case 'ᩩ': // ไม้กุ๊
      return [
        [const Offset(40, 50), const Offset(45, 65), const Offset(55, 75), const Offset(65, 70)],
      ];
    case 'ᩪ': // ไม้กู๊
      return [
        [const Offset(40, 50), const Offset(45, 65), const Offset(55, 75), const Offset(65, 70)],
        [const Offset(55, 75), const Offset(55, 95)],
      ];
    case 'ᩫ': // ไม้โก๊ะ/ไม้กง
      return [
        [const Offset(40, 40), const Offset(50, 30), const Offset(60, 40), const Offset(50, 50), const Offset(40, 40)],
        [const Offset(50, 30), const Offset(65, 30), const Offset(75, 40)],
      ];
    case 'ᩬ': // ไม้กอ
      return [
        [const Offset(35, 60), const Offset(45, 50), const Offset(55, 60), const Offset(45, 70), const Offset(35, 60)],
        [const Offset(45, 70), const Offset(55, 75), const Offset(65, 70)],
      ];
    case 'ᩍ': // อะลอย
      return [
        [const Offset(30, 50), const Offset(40, 40), const Offset(50, 50), const Offset(40, 60), const Offset(30, 50)],
        [const Offset(40, 50), const Offset(60, 40), const Offset(70, 60), const Offset(60, 75), const Offset(45, 75)],
      ];
    case 'ᩎ': // อาลอย
      return [
        [const Offset(35, 30), const Offset(60, 30), const Offset(60, 75)],
        [const Offset(40, 50), const Offset(55, 50)],
      ];
    case 'ᩏ': // อิลอย
      return [
        [const Offset(30, 65), const Offset(40, 55), const Offset(50, 65), const Offset(40, 75), const Offset(30, 65)],
        [const Offset(40, 65), const Offset(50, 45), const Offset(65, 45), const Offset(75, 60)],
      ];
    case 'ᩐ': // อีลอย
      return [
        [const Offset(30, 45), const Offset(40, 35), const Offset(50, 45), const Offset(40, 55), const Offset(30, 45)],
        [const Offset(40, 45), const Offset(55, 45), const Offset(65, 70), const Offset(50, 80)],
      ];
    case 'ᩑ': // อุลอย
      return [
        [const Offset(30, 60), const Offset(40, 50), const Offset(50, 60), const Offset(40, 70), const Offset(30, 60)],
        [const Offset(40, 60), const Offset(60, 60), const Offset(70, 40)],
      ];
    case 'ᩒ': // อูลอย
      return [
        [const Offset(30, 70), const Offset(40, 60), const Offset(50, 70), const Offset(40, 80), const Offset(30, 70)],
        [const Offset(40, 70), const Offset(55, 70), const Offset(65, 50), const Offset(60, 30)],
      ];
    default:
      return null;
  }
}

/// ============================================================================
/// TONE STROKE COORDINATES
/// ============================================================================
List<List<Offset>>? getToneStrokePaths(String char) {
  switch (char) {
    case '\u1a75': // ไม้เอก
      return [
        [const Offset(50, 20), const Offset(50, 45)],
      ];
    case '\u1a76': // ไม้โท
      return [
        [const Offset(40, 45), const Offset(42, 35), const Offset(48, 25), const Offset(55, 25), const Offset(60, 32), const Offset(58, 42), const Offset(50, 45), const Offset(62, 40)],
      ];
    case '\u1a77': // ไม้ตรี
      return [
        [const Offset(35, 45), const Offset(45, 25), const Offset(55, 30), const Offset(50, 45), const Offset(60, 40)],
        [const Offset(48, 35), const Offset(58, 15), const Offset(68, 20), const Offset(63, 35), const Offset(73, 30)],
      ];
    case '\u1a78': // ไม้จัตวา
      return [
        [const Offset(50, 15), const Offset(50, 45)],
        [const Offset(35, 30), const Offset(65, 30)],
      ];
    case '\u1a62': // ไม้หันอากาศ
      return [
        [const Offset(35, 35), const Offset(45, 25), const Offset(55, 35), const Offset(65, 25)],
      ];
    case '\u1a7a': // เครื่องหมายเสียงสูง
      return [
        [const Offset(35, 45), const Offset(65, 15)],
      ];
    case '\u1a7f': // เครื่องหมายเสียงต่ำ
      return [
        [const Offset(40, 65), const Offset(50, 55), const Offset(60, 65), const Offset(50, 75), const Offset(40, 65)],
      ];
    case '\u1a7b': // ไม้พัด/ไม้ระเบิด
      return [
        [const Offset(30, 45), const Offset(35, 30), const Offset(42, 23), const Offset(50, 20), const Offset(58, 23), const Offset(65, 30), const Offset(70, 45)],
      ];
    case '\u1a7c': // ไม้ซัด
      return [
        [const Offset(30, 35), const Offset(50, 35), const Offset(60, 20), const Offset(70, 35)],
      ];
    case '\u1a74': // ไม้สัญญประกาศ
      return [
        [const Offset(30, 30), const Offset(70, 30)],
      ];
    case '\u1a53': // เครื่องหมายย่อคำ
      return [
        [const Offset(40, 55), const Offset(50, 45), const Offset(60, 55), const Offset(50, 65), const Offset(40, 55)],
        [const Offset(50, 65), const Offset(65, 75), const Offset(75, 60)],
      ];
    default:
      return null;
  }
}

/// ============================================================================
/// NUMBER STROKE COORDINATES
/// ============================================================================
List<List<Offset>>? getNumberStrokePaths(String char) {
  switch (char) {
    // === Dham Digits: ᪐ - ᪙ ===
    case '᪐':
      return [
        [const Offset(50, 25), const Offset(30, 25), const Offset(20, 50), const Offset(30, 75), const Offset(50, 75), const Offset(70, 75), const Offset(80, 50), const Offset(70, 25), const Offset(50, 25)],
      ];
    case '᪑':
      return [
        [const Offset(35, 75), const Offset(45, 65), const Offset(55, 75), const Offset(45, 85), const Offset(35, 75)],
        [const Offset(35, 75), const Offset(30, 45), const Offset(50, 30), const Offset(70, 45), const Offset(65, 75)],
      ];
    case '᪒':
      return [
        [const Offset(35, 35), const Offset(45, 25), const Offset(55, 35), const Offset(45, 45), const Offset(35, 35)],
        [const Offset(45, 45), const Offset(30, 65), const Offset(45, 80), const Offset(70, 80)],
      ];
    case '᪓':
      return [
        [const Offset(35, 35), const Offset(45, 25), const Offset(55, 35), const Offset(45, 45), const Offset(35, 35)],
        [const Offset(45, 45), const Offset(65, 45), const Offset(75, 60), const Offset(60, 75), const Offset(45, 75)],
      ];
    case '᪔':
      return [
        [const Offset(30, 70), const Offset(40, 60), const Offset(50, 70), const Offset(40, 80), const Offset(30, 70)],
        [const Offset(40, 70), const Offset(40, 40), const Offset(60, 30), const Offset(80, 50)],
      ];
    case '᪕':
      return [
        [const Offset(30, 70), const Offset(40, 60), const Offset(50, 70), const Offset(40, 80), const Offset(30, 70)],
        [const Offset(40, 70), const Offset(40, 40), const Offset(60, 30), const Offset(80, 50)],
        [const Offset(80, 50), const Offset(90, 35)],
      ];
    case '᪖':
      return [
        [const Offset(35, 35), const Offset(45, 25), const Offset(55, 35), const Offset(45, 45), const Offset(35, 35)],
        [const Offset(45, 45), const Offset(45, 75), const Offset(55, 85)],
      ];
    case '᪗':
      return [
        [const Offset(35, 35), const Offset(45, 25), const Offset(55, 35), const Offset(45, 45), const Offset(35, 35)],
        [const Offset(45, 45), const Offset(60, 45), const Offset(65, 75), const Offset(50, 85)],
      ];
    case '᪘':
      return [
        [const Offset(30, 70), const Offset(40, 60), const Offset(50, 70), const Offset(40, 80), const Offset(30, 70)],
        [const Offset(40, 70), const Offset(60, 50), const Offset(80, 60)],
      ];
    case '᪙':
      return [
        [const Offset(40, 50), const Offset(50, 40), const Offset(60, 50), const Offset(50, 60), const Offset(40, 50)],
        [const Offset(50, 60), const Offset(50, 80), const Offset(70, 70)],
      ];

    // === Hora Digits: ᪀ - ᪉ ===
    case '᪀':
      return [
        [const Offset(50, 25), const Offset(30, 25), const Offset(20, 50), const Offset(30, 75), const Offset(50, 75), const Offset(70, 75), const Offset(80, 50), const Offset(70, 25), const Offset(50, 25)],
      ];
    case '᪁':
      return [
        [const Offset(40, 70), const Offset(50, 45), const Offset(60, 30), const Offset(70, 45), const Offset(60, 70)],
      ];
    case '᪂':
      return [
        [const Offset(35, 35), const Offset(45, 25), const Offset(55, 35), const Offset(45, 45), const Offset(35, 35)],
        [const Offset(45, 45), const Offset(30, 65), const Offset(50, 75), const Offset(70, 65)],
      ];
    case '᪃':
      return [
        [const Offset(35, 35), const Offset(45, 25), const Offset(55, 35), const Offset(45, 45), const Offset(35, 35)],
        [const Offset(45, 45), const Offset(60, 45), const Offset(65, 75), const Offset(50, 85)],
      ];
    case '᪄':
      return [
        [const Offset(30, 65), const Offset(40, 55), const Offset(50, 65), const Offset(40, 75), const Offset(30, 65)],
        [const Offset(40, 65), const Offset(50, 35), const Offset(70, 45)],
      ];
    case '᪅':
      return [
        [const Offset(30, 65), const Offset(40, 55), const Offset(50, 65), const Offset(40, 75), const Offset(30, 65)],
        [const Offset(40, 65), const Offset(50, 35), const Offset(70, 45)],
        [const Offset(70, 45), const Offset(85, 30)],
      ];
    case '᪆':
      return [
        [const Offset(35, 35), const Offset(45, 25), const Offset(55, 35), const Offset(45, 45), const Offset(35, 35)],
        [const Offset(45, 45), const Offset(55, 75), const Offset(75, 75)],
      ];
    case '᪇':
      return [
        [const Offset(35, 35), const Offset(45, 25), const Offset(55, 35), const Offset(45, 45), const Offset(35, 35)],
        [const Offset(45, 45), const Offset(65, 45), const Offset(70, 75)],
      ];
    case '᪈':
      return [
        [const Offset(30, 65), const Offset(40, 55), const Offset(50, 65), const Offset(40, 75), const Offset(30, 65)],
        [const Offset(40, 65), const Offset(60, 75), const Offset(80, 55)],
      ];
    case '᪉':
      return [
        [const Offset(40, 50), const Offset(50, 40), const Offset(60, 50), const Offset(50, 60), const Offset(40, 50)],
        [const Offset(50, 60), const Offset(60, 75), const Offset(75, 55)],
      ];
    default:
      return null;
  }
}

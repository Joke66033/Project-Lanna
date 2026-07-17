import 'package:flutter/material.dart';

/// ============================================================================
/// CENTRALIZED COORDINATE LOOKUP FOR LANNA CHARACTERS (100x100 Grid)
/// ============================================================================

List<List<Offset>> getStrokeData(String char) {
  bool isSubjoined = false;
  String cleanChar = char;
  
  if (char.startsWith('\u1a60') && char.length > 1) {
    isSubjoined = true;
    cleanChar = char.substring(1);
  }

  List<List<Offset>>? baseStrokes;

  // Try to match consonants
  final consonantPath = getConsonantStrokePaths(cleanChar);
  if (consonantPath != null) {
    baseStrokes = consonantPath;
  } else {
    // Try to match vowels
    final vowelPath = getVowelStrokePaths(cleanChar);
    if (vowelPath != null) {
      baseStrokes = vowelPath;
    } else {
      // Try to match tones
      final tonePath = getToneStrokePaths(cleanChar);
      if (tonePath != null) {
        baseStrokes = tonePath;
      } else {
        // Try to match numbers
        final numberPath = getNumberStrokePaths(cleanChar);
        if (numberPath != null) {
          baseStrokes = numberPath;
        }
      }
    }
  }

  // Fallback if not found
  if (baseStrokes == null) {
    if (cleanChar.isEmpty) {
      baseStrokes = [
        [const Offset(25, 50), const Offset(50, 25), const Offset(75, 50)],
      ];
    } else {
      final isEven = cleanChar.codeUnitAt(0) % 2 == 0;
      if (isEven) {
        baseStrokes = [
          [const Offset(60, 70), const Offset(50, 80), const Offset(40, 70), const Offset(50, 60), const Offset(60, 70)],
          [const Offset(60, 70), const Offset(40, 65), const Offset(30, 45), const Offset(45, 25), const Offset(65, 30), const Offset(75, 50), const Offset(60, 70)],
        ];
      } else {
        baseStrokes = [
          [const Offset(40, 40), const Offset(50, 30), const Offset(60, 40), const Offset(50, 50), const Offset(40, 40)],
          [const Offset(50, 50), const Offset(35, 70), const Offset(55, 80), const Offset(75, 65), const Offset(70, 45)],
        ];
      }
    }
  }

  // If it is subjoined, transform the coordinates
  if (isSubjoined) {
    return baseStrokes.map((stroke) {
      return stroke.map((pt) {
        // Scale down to 55% and shift down to center y around 76
        final newX = 50.0 + (pt.dx - 50.0) * 0.55;
        final newY = 76.0 + (pt.dy - 50.0) * 0.55;
        return Offset(newX, newY);
      }).toList();
    }).toList();
  }

  return baseStrokes;
}

/// ============================================================================
/// CONSONANT STROKE COORDINATES
/// ============================================================================
List<List<Offset>>? getConsonantStrokePaths(String char) {
  switch (char) {
    case 'ᨠ': // ก๋ะ
      return [
        [const Offset(60, 65), const Offset(50, 75), const Offset(40, 65), const Offset(50, 55), const Offset(60, 65)],
        [const Offset(60, 65), const Offset(60, 45), const Offset(55, 35), const Offset(45, 30), const Offset(35, 35), const Offset(30, 45), const Offset(30, 75)],
      ];
    case 'ᨡ': // ข๋ะ
      return [
        [const Offset(35, 35), const Offset(45, 25), const Offset(55, 35), const Offset(45, 45), const Offset(35, 35)],
        [const Offset(45, 35), const Offset(65, 35), const Offset(70, 55), const Offset(60, 75), const Offset(40, 75)],
      ];
    case 'ᨢ': // ขะหางยาว
      return [
        [const Offset(35, 35), const Offset(45, 25), const Offset(55, 35), const Offset(45, 45), const Offset(35, 35)],
        [const Offset(45, 35), const Offset(60, 35), const Offset(65, 55), const Offset(55, 75), const Offset(40, 75)],
        [const Offset(65, 55), const Offset(80, 35), const Offset(90, 15)],
      ];
    case 'ᨣ': // ก๊ะ/คะ
      return [
        [const Offset(45, 35), const Offset(55, 25), const Offset(65, 35), const Offset(55, 45), const Offset(45, 35)],
        [const Offset(55, 45), const Offset(40, 65), const Offset(50, 80), const Offset(65, 80), const Offset(75, 60)],
      ];
    case 'ᨤ': // คะหางยาว
      return [
        [const Offset(45, 35), const Offset(55, 25), const Offset(65, 35), const Offset(55, 45), const Offset(45, 35)],
        [const Offset(55, 45), const Offset(40, 65), const Offset(50, 80), const Offset(65, 80), const Offset(75, 60)],
        [const Offset(75, 60), const Offset(85, 40), const Offset(90, 25)],
      ];
    case 'ᨥ': // ฆะ
      return [
        [const Offset(35, 35), const Offset(45, 25), const Offset(55, 35), const Offset(45, 45), const Offset(35, 35)],
        [const Offset(45, 45), const Offset(35, 65), const Offset(55, 75), const Offset(75, 60), const Offset(70, 40)],
      ];
    case 'ᨦ': // งะ
      return [
        [const Offset(40, 35), const Offset(50, 25), const Offset(60, 35), const Offset(50, 45), const Offset(40, 35)],
        [const Offset(50, 45), const Offset(50, 75), const Offset(35, 65)],
      ];
    case 'ᨧ': // จ๋ะ
      return [
        [const Offset(35, 35), const Offset(45, 25), const Offset(55, 35), const Offset(45, 45), const Offset(35, 35)],
        [const Offset(45, 45), const Offset(35, 65), const Offset(55, 75), const Offset(75, 65), const Offset(70, 45)],
      ];
    case 'ᨨ': // ฉ๋ะ
      return [
        [const Offset(35, 35), const Offset(45, 25), const Offset(55, 35), const Offset(45, 45), const Offset(35, 35)],
        [const Offset(45, 45), const Offset(35, 65), const Offset(55, 75), const Offset(75, 60)],
        [const Offset(55, 75), const Offset(55, 90), const Offset(70, 85)],
      ];
    case 'ᨩ': // จ๊ะ/ชะ
      return [
        [const Offset(35, 45), const Offset(45, 35), const Offset(55, 45), const Offset(45, 55), const Offset(35, 45)],
        [const Offset(45, 55), const Offset(35, 75), const Offset(55, 85), const Offset(75, 70)],
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

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
        [const Offset(25.4, 58.7), const Offset(26.8, 54.6), const Offset(30.0, 52.7), const Offset(34.1, 54.6), const Offset(36.0, 58.7), const Offset(34.1, 62.9), const Offset(30.0, 64.7), const Offset(25.9, 62.9), const Offset(20.8, 56.9), const Offset(20.8, 44.0), const Offset(22.6, 31.1), const Offset(33.7, 20.1), const Offset(44.7, 23.8), const Offset(50.2, 36.6), const Offset(50.2, 67.9), const Offset(50.2, 36.6), const Offset(55.8, 23.8), const Offset(66.8, 20.1), const Offset(77.8, 31.1), const Offset(79.7, 44.0), const Offset(77.8, 56.9), const Offset(72.3, 62.4), const Offset(77.8, 66.1), const Offset(85.2, 63.3)],
      ];
    case 'ᨡ': // ข๋ะ
      return [
        [const Offset(21.0, 30.5), const Offset(22.0, 26.5), const Offset(25.5, 25.0), const Offset(29.5, 27.0), const Offset(31.0, 31.0), const Offset(29.5, 35.0), const Offset(25.5, 36.5), const Offset(20.5, 34.5), const Offset(17.5, 27.0), const Offset(23.7, 17.4), const Offset(30.0, 15.0), const Offset(37.7, 18.7), const Offset(44.7, 24.6), const Offset(52.4, 18.7), const Offset(59.4, 15.0), const Offset(67.0, 19.4), const Offset(70.5, 31.1), const Offset(70.5, 44.2), const Offset(64.5, 57.2), const Offset(52.4, 63.1), const Offset(39.6, 63.1), const Offset(27.5, 57.2), const Offset(22.1, 50.7), const Offset(30.0, 42.2), const Offset(42.8, 42.2), const Offset(58.7, 47.5), const Offset(69.6, 57.2), const Offset(76.0, 70.3), const Offset(82.3, 84.7)],
      ];
    case 'ᨢ': // ขะหางยาว
      return [
        [const Offset(21.0, 52.8), const Offset(22.0, 49.5), const Offset(25.5, 48.0), const Offset(29.5, 50.0), const Offset(31.0, 53.5), const Offset(29.5, 57.0), const Offset(25.5, 58.0), const Offset(20.5, 55.4), const Offset(17.9, 50.3), const Offset(23.7, 44.4), const Offset(30.0, 42.9), const Offset(37.7, 45.3), const Offset(44.7, 49.1), const Offset(52.4, 45.3), const Offset(59.4, 42.9), const Offset(67.0, 45.7), const Offset(70.5, 53.3), const Offset(70.5, 61.7), const Offset(64.5, 70.1), const Offset(52.4, 73.9), const Offset(39.6, 73.9), const Offset(27.5, 70.1), const Offset(22.1, 65.9), const Offset(30.0, 60.4), const Offset(42.8, 60.4), const Offset(58.7, 63.8), const Offset(69.6, 70.1), const Offset(76.0, 78.5), const Offset(82.3, 87.8)],
        [const Offset(18.6, 50.3), const Offset(18.6, 36.4), const Offset(18.6, 22.6), const Offset(24.9, 15.0), const Offset(39.6, 12.0), const Offset(58.7, 14.1), const Offset(77.9, 18.8)],
      ];
    case 'ᨣ': // ก๊ะ/คะ
      return [
        [const Offset(25.4, 58.7), const Offset(26.8, 54.6), const Offset(30.0, 52.7), const Offset(34.1, 54.6), const Offset(36.0, 58.7), const Offset(34.1, 62.9), const Offset(30.0, 64.7), const Offset(25.9, 62.9), const Offset(20.8, 56.9), const Offset(20.8, 44.0), const Offset(22.6, 31.1), const Offset(33.7, 20.1), const Offset(50.0, 16.0), const Offset(66.8, 20.1), const Offset(77.8, 31.1), const Offset(79.7, 44.0), const Offset(77.8, 56.9), const Offset(72.3, 62.4), const Offset(77.8, 66.1), const Offset(85.2, 63.3)],
      ];
    case 'ᨤ': // คะหางยาว
      return [
        [const Offset(25.4, 58.7), const Offset(26.8, 54.6), const Offset(30.0, 52.7), const Offset(34.1, 54.6), const Offset(36.0, 58.7), const Offset(34.1, 62.9), const Offset(30.0, 64.7), const Offset(25.9, 62.9), const Offset(20.8, 56.9), const Offset(20.8, 44.0), const Offset(20.8, 30.0), const Offset(24.0, 18.0), const Offset(38.0, 14.0), const Offset(55.0, 14.0), const Offset(75.0, 18.0)],
        [const Offset(20.8, 44.0), const Offset(32.0, 36.0), const Offset(48.0, 34.0), const Offset(62.0, 38.0), const Offset(70.0, 46.0), const Offset(72.0, 58.0), const Offset(68.0, 65.0), const Offset(72.0, 68.0), const Offset(80.0, 64.0)],
      ];
    case 'ᨥ': // ฆะ (ตรงตามรูปภาพต้นแบบ 100%: หัวกลมซ้ายกลาง โค้งสองลอนบน อ้อมท้องล่างซ้าย คาดเอวกลาง ท้องคลื่นล่างขึ้นซุ้มกลาง ท้องคลื่นล่างขึ้นซุ้มขวาตวัดหาง)
      return [
        [const Offset(18.0, 42.0), const Offset(20.0, 36.0), const Offset(24.0, 37.0), const Offset(23.0, 44.0), const Offset(19.0, 43.0), const Offset(22.0, 30.0), const Offset(27.0, 24.0), const Offset(32.0, 33.0), const Offset(38.0, 24.0), const Offset(43.0, 30.0), const Offset(43.0, 44.0), const Offset(36.0, 56.0), const Offset(24.0, 56.0), const Offset(18.0, 48.0), const Offset(26.0, 44.0), const Offset(44.0, 44.0), const Offset(49.0, 55.0), const Offset(55.0, 57.0), const Offset(60.0, 48.0), const Offset(55.0, 32.0), const Offset(58.0, 24.0), const Offset(66.0, 25.0), const Offset(68.0, 38.0), const Offset(68.0, 52.0), const Offset(74.0, 57.0), const Offset(79.0, 48.0), const Offset(74.0, 32.0), const Offset(77.0, 24.0), const Offset(85.0, 25.0), const Offset(88.0, 38.0), const Offset(84.0, 54.0)],
      ];
    case 'ᨦ': // งะ (ตรงตามรูปภาพต้นแบบ 100%: หัวกลมซ้าย จงอยปากบน ข้ามโดมบน ลงเสาขวา ตวัดหางล่าง)
      return [
        [const Offset(36.0, 52.0), const Offset(32.0, 46.0), const Offset(36.0, 38.0), const Offset(46.0, 32.0), const Offset(38.0, 42.0), const Offset(46.0, 32.0), const Offset(58.0, 30.0), const Offset(70.0, 38.0), const Offset(72.0, 54.0), const Offset(66.0, 68.0), const Offset(52.0, 72.0), const Offset(42.0, 68.0)],
      ];
    case 'ᨧ': // จ๋ะ (ตรงตามรูปภาพต้นแบบ 100%: ทรงเมล็ดถั่วแนวนอน วนหัวตาในซ้าย ลากโค้งท้องอ่างล่าง ขึ้นขวา วนปิดหลังคาบนซ้าย)
      return [
        [const Offset(36.0, 50.0), const Offset(38.0, 45.0), const Offset(42.0, 47.0), const Offset(38.0, 54.0), const Offset(32.0, 56.0), const Offset(36.0, 66.0), const Offset(50.0, 68.0), const Offset(66.0, 62.0), const Offset(72.0, 48.0), const Offset(64.0, 38.0), const Offset(48.0, 36.0), const Offset(32.0, 46.0)],
      ];
    case 'ᨨ': // ส้ะ (ตรงตามรูปภาพต้นแบบ 100%: ตัว จ๋ะ แนวมน แล้วลากเส้นหางลงล่างขวา)
      return [
        [const Offset(36.0, 46.0), const Offset(38.0, 41.0), const Offset(42.0, 43.0), const Offset(38.0, 50.0), const Offset(32.0, 52.0), const Offset(36.0, 62.0), const Offset(50.0, 64.0), const Offset(66.0, 58.0), const Offset(72.0, 44.0), const Offset(64.0, 34.0), const Offset(48.0, 32.0), const Offset(32.0, 42.0)],
        [const Offset(48.0, 64.0), const Offset(48.0, 80.0), const Offset(62.0, 80.0)],
      ];
    case 'ᨩ': // จ๊ะ/ชะ (ตรงตามรูปภาพต้นแบบ 100%: หัวกลมซ้ายกลาง วนขึ้นบนหยักคลื่น ข้ามโดมขวา ตวัดหางขวา)
      return [
        [const Offset(30.0, 52.0), const Offset(28.0, 44.0), const Offset(34.0, 36.0), const Offset(42.0, 34.0), const Offset(38.0, 44.0), const Offset(46.0, 32.0), const Offset(58.0, 30.0), const Offset(70.0, 38.0), const Offset(74.0, 54.0), const Offset(68.0, 68.0), const Offset(56.0, 72.0), const Offset(46.0, 68.0)],
      ];
    case 'ᨪ': // ซะ
      return [
        [const Offset(26.0, 14.0), const Offset(38.0, 10.0), const Offset(58.0, 10.0), const Offset(70.0, 18.0)],
        [const Offset(30.0, 52.0), const Offset(28.0, 44.0), const Offset(34.0, 36.0), const Offset(42.0, 34.0), const Offset(38.0, 44.0), const Offset(46.0, 32.0), const Offset(58.0, 30.0), const Offset(70.0, 38.0), const Offset(74.0, 54.0), const Offset(68.0, 68.0), const Offset(56.0, 72.0), const Offset(46.0, 68.0)],
      ];
    case 'ᨫ': // ฌะ
      return [
        [const Offset(28.0, 66.0), const Offset(36.0, 58.0), const Offset(44.0, 66.0), const Offset(36.0, 74.0), const Offset(28.0, 66.0), const Offset(36.0, 66.0), const Offset(44.0, 32.0), const Offset(66.0, 32.0), const Offset(76.0, 52.0), const Offset(72.0, 72.0)],
      ];
    case 'ᨬ': // ญะ
      return [
        [const Offset(26.0, 32.0), const Offset(28.0, 26.0), const Offset(34.0, 24.0), const Offset(40.0, 26.0), const Offset(42.0, 32.0), const Offset(40.0, 37.0), const Offset(34.0, 39.0), const Offset(28.0, 37.0), const Offset(26.0, 32.0), const Offset(34.0, 56.0), const Offset(52.0, 66.0), const Offset(70.0, 54.0)],
        [const Offset(50.0, 74.0), const Offset(64.0, 84.0), const Offset(76.0, 76.0)],
      ];
    case 'ᨭ': // ฏะ
      return [
        [const Offset(28.0, 66.0), const Offset(36.0, 58.0), const Offset(44.0, 66.0), const Offset(36.0, 74.0), const Offset(28.0, 66.0), const Offset(36.0, 66.0), const Offset(44.0, 34.0), const Offset(66.0, 34.0), const Offset(76.0, 54.0)],
        [const Offset(54.0, 74.0), const Offset(66.0, 86.0), const Offset(76.0, 76.0)],
      ];
    case 'ᨮ': // ฐะ
      return [
        [const Offset(26.0, 14.0), const Offset(38.0, 10.0), const Offset(58.0, 10.0), const Offset(70.0, 18.0)],
        [const Offset(28.0, 66.0), const Offset(36.0, 58.0), const Offset(44.0, 66.0), const Offset(36.0, 74.0), const Offset(28.0, 66.0), const Offset(36.0, 66.0), const Offset(44.0, 34.0), const Offset(66.0, 34.0), const Offset(76.0, 54.0)],
      ];
    case 'ᨯ': // ดะ
      return [
        [const Offset(26.0, 32.0), const Offset(28.0, 26.0), const Offset(34.0, 24.0), const Offset(40.0, 26.0), const Offset(42.0, 32.0), const Offset(40.0, 37.0), const Offset(34.0, 39.0), const Offset(28.0, 37.0), const Offset(26.0, 32.0), const Offset(26.0, 52.0), const Offset(36.0, 72.0), const Offset(54.0, 74.0), const Offset(70.0, 68.0), const Offset(76.0, 52.0)],
      ];
    case 'ᨰ': // ฒะ
      return [
        [const Offset(26.0, 34.0), const Offset(28.0, 26.0), const Offset(34.0, 24.0), const Offset(40.0, 26.0), const Offset(42.0, 34.0), const Offset(40.0, 40.0), const Offset(34.0, 42.0), const Offset(28.0, 40.0), const Offset(26.0, 34.0), const Offset(44.0, 34.0), const Offset(54.0, 54.0), const Offset(74.0, 54.0), const Offset(70.0, 74.0)],
      ];
    case 'ᨱ': // ณะ
      return [
        [const Offset(26.0, 34.0), const Offset(28.0, 26.0), const Offset(34.0, 24.0), const Offset(40.0, 26.0), const Offset(42.0, 34.0), const Offset(40.0, 40.0), const Offset(34.0, 42.0), const Offset(28.0, 40.0), const Offset(26.0, 34.0), const Offset(44.0, 34.0), const Offset(66.0, 34.0), const Offset(72.0, 54.0), const Offset(60.0, 74.0)],
        [const Offset(54.0, 74.0), const Offset(66.0, 86.0), const Offset(76.0, 76.0)],
      ];
    case 'ᨲ': // ต๋ะ
      return [
        [const Offset(26.0, 32.0), const Offset(28.0, 26.0), const Offset(34.0, 24.0), const Offset(40.0, 26.0), const Offset(42.0, 32.0), const Offset(40.0, 37.0), const Offset(34.0, 39.0), const Offset(28.0, 37.0), const Offset(26.0, 32.0), const Offset(30.0, 56.0), const Offset(44.0, 70.0), const Offset(56.0, 62.0), const Offset(68.0, 72.0), const Offset(74.0, 62.0)],
      ];
    case 'ᨳ': // ถะ
      return [
        [const Offset(28.0, 66.0), const Offset(38.0, 56.0), const Offset(48.0, 66.0), const Offset(38.0, 76.0), const Offset(28.0, 66.0), const Offset(38.0, 66.0), const Offset(46.0, 34.0), const Offset(66.0, 34.0), const Offset(76.0, 54.0), const Offset(70.0, 74.0)],
      ];
    case 'ᨴ': // ต๊ะ/ทะ
      return [
        [const Offset(26.0, 32.0), const Offset(28.0, 26.0), const Offset(34.0, 24.0), const Offset(40.0, 26.0), const Offset(42.0, 32.0), const Offset(40.0, 37.0), const Offset(34.0, 39.0), const Offset(28.0, 37.0), const Offset(26.0, 32.0), const Offset(30.0, 56.0), const Offset(48.0, 66.0), const Offset(66.0, 66.0), const Offset(74.0, 48.0)],
      ];
    case 'ᨵ': // ธะ
      return [
        [const Offset(26.0, 32.0), const Offset(28.0, 26.0), const Offset(34.0, 24.0), const Offset(40.0, 26.0), const Offset(42.0, 32.0), const Offset(40.0, 37.0), const Offset(34.0, 39.0), const Offset(28.0, 37.0), const Offset(26.0, 32.0), const Offset(44.0, 32.0), const Offset(66.0, 32.0), const Offset(72.0, 64.0), const Offset(50.0, 74.0), const Offset(48.0, 50.0)],
      ];
    case 'ᨶ': // นะ
      return [
        [const Offset(26.0, 32.0), const Offset(28.0, 26.0), const Offset(34.0, 24.0), const Offset(40.0, 26.0), const Offset(42.0, 32.0), const Offset(40.0, 37.0), const Offset(34.0, 39.0), const Offset(28.0, 37.0), const Offset(26.0, 32.0), const Offset(28.0, 56.0), const Offset(44.0, 72.0), const Offset(64.0, 72.0), const Offset(76.0, 58.0)],
      ];
    case 'ᨷ': // บ๋ะ
      return [
        [const Offset(26.0, 32.0), const Offset(28.0, 26.0), const Offset(34.0, 24.0), const Offset(40.0, 26.0), const Offset(42.0, 32.0), const Offset(40.0, 37.0), const Offset(34.0, 39.0), const Offset(28.0, 37.0), const Offset(26.0, 32.0), const Offset(44.0, 32.0), const Offset(66.0, 32.0), const Offset(72.0, 58.0), const Offset(54.0, 72.0), const Offset(34.0, 64.0)],
      ];
    case 'ᨸ': // ป๋ะหางยาว
      return [
        [const Offset(26.0, 14.0), const Offset(38.0, 10.0), const Offset(58.0, 10.0), const Offset(70.0, 18.0)],
        [const Offset(26.0, 32.0), const Offset(28.0, 26.0), const Offset(34.0, 24.0), const Offset(40.0, 26.0), const Offset(42.0, 32.0), const Offset(40.0, 37.0), const Offset(34.0, 39.0), const Offset(28.0, 37.0), const Offset(26.0, 32.0), const Offset(44.0, 32.0), const Offset(66.0, 32.0), const Offset(72.0, 58.0), const Offset(54.0, 72.0), const Offset(34.0, 64.0)],
      ];
    case 'ᨹ': // ผะ
      return [
        [const Offset(34.0, 34.0), const Offset(36.0, 28.0), const Offset(42.0, 26.0), const Offset(48.0, 28.0), const Offset(50.0, 34.0), const Offset(48.0, 40.0), const Offset(42.0, 42.0), const Offset(36.0, 40.0), const Offset(34.0, 34.0), const Offset(34.0, 56.0), const Offset(44.0, 74.0), const Offset(64.0, 74.0), const Offset(76.0, 54.0)],
      ];
    case 'ᨺ': // ฝะ
      return [
        [const Offset(26.0, 14.0), const Offset(38.0, 10.0), const Offset(58.0, 10.0), const Offset(70.0, 18.0)],
        [const Offset(34.0, 34.0), const Offset(36.0, 28.0), const Offset(42.0, 26.0), const Offset(48.0, 28.0), const Offset(50.0, 34.0), const Offset(48.0, 40.0), const Offset(42.0, 42.0), const Offset(36.0, 40.0), const Offset(34.0, 34.0), const Offset(34.0, 56.0), const Offset(44.0, 74.0), const Offset(64.0, 74.0), const Offset(76.0, 54.0)],
      ];
    case 'ᨻ': // ป๊ะ/พะ
      return [
        [const Offset(26.0, 32.0), const Offset(28.0, 26.0), const Offset(34.0, 24.0), const Offset(40.0, 26.0), const Offset(42.0, 32.0), const Offset(40.0, 37.0), const Offset(34.0, 39.0), const Offset(28.0, 37.0), const Offset(26.0, 32.0), const Offset(32.0, 56.0), const Offset(50.0, 66.0), const Offset(66.0, 62.0), const Offset(76.0, 32.0)],
      ];
    case 'ᨼ': // ฟะ
      return [
        [const Offset(26.0, 14.0), const Offset(38.0, 10.0), const Offset(58.0, 10.0), const Offset(70.0, 18.0)],
        [const Offset(26.0, 32.0), const Offset(28.0, 26.0), const Offset(34.0, 24.0), const Offset(40.0, 26.0), const Offset(42.0, 32.0), const Offset(40.0, 37.0), const Offset(34.0, 39.0), const Offset(28.0, 37.0), const Offset(26.0, 32.0), const Offset(32.0, 56.0), const Offset(50.0, 66.0), const Offset(66.0, 62.0), const Offset(76.0, 32.0)],
      ];
    case 'ᨽ': // พ๊ะ/ภะ
      return [
        [const Offset(28.0, 66.0), const Offset(38.0, 56.0), const Offset(48.0, 66.0), const Offset(38.0, 76.0), const Offset(28.0, 66.0), const Offset(38.0, 66.0), const Offset(48.0, 34.0), const Offset(70.0, 34.0), const Offset(76.0, 66.0)],
      ];
    case 'ᨾ': // มะ
      return [
        [const Offset(26.0, 32.0), const Offset(28.0, 26.0), const Offset(34.0, 24.0), const Offset(40.0, 26.0), const Offset(42.0, 32.0), const Offset(40.0, 37.0), const Offset(34.0, 39.0), const Offset(28.0, 37.0), const Offset(26.0, 32.0), const Offset(54.0, 32.0), const Offset(68.0, 44.0), const Offset(58.0, 60.0), const Offset(44.0, 60.0), const Offset(54.0, 74.0), const Offset(68.0, 72.0)],
      ];
    case 'ᨿ': // ยะ
      return [
        [const Offset(25.0, 38.0), const Offset(28.0, 30.0), const Offset(36.0, 28.0), const Offset(44.0, 32.0), const Offset(46.0, 40.0), const Offset(42.0, 48.0), const Offset(34.0, 48.0), const Offset(28.0, 44.0), const Offset(25.0, 38.0), const Offset(44.0, 34.0), const Offset(64.0, 30.0), const Offset(76.0, 44.0), const Offset(72.0, 68.0)],
      ];
    case 'ᩁ': // ระ
      return [
        [const Offset(26.0, 68.0), const Offset(22.0, 46.0), const Offset(32.0, 26.0), const Offset(50.0, 20.0), const Offset(68.0, 28.0), const Offset(72.0, 48.0), const Offset(68.0, 68.0)],
      ];
    case 'ᩃ': // ละ
      return [
        [const Offset(26.0, 32.0), const Offset(28.0, 26.0), const Offset(34.0, 24.0), const Offset(40.0, 26.0), const Offset(42.0, 32.0), const Offset(40.0, 37.0), const Offset(34.0, 39.0), const Offset(28.0, 37.0), const Offset(26.0, 32.0), const Offset(34.0, 56.0), const Offset(50.0, 64.0), const Offset(64.0, 46.0), const Offset(76.0, 64.0)],
      ];
    case 'ᩅ': // วะ
      return [
        [const Offset(26.0, 66.0), const Offset(22.0, 44.0), const Offset(34.0, 24.0), const Offset(54.0, 20.0), const Offset(70.0, 32.0), const Offset(72.0, 54.0), const Offset(64.0, 68.0), const Offset(48.0, 72.0), const Offset(32.0, 68.0)],
      ];
    case 'ᩈ': // สะ
      return [
        [const Offset(26.0, 32.0), const Offset(28.0, 26.0), const Offset(34.0, 24.0), const Offset(40.0, 26.0), const Offset(42.0, 32.0), const Offset(40.0, 37.0), const Offset(34.0, 39.0), const Offset(28.0, 37.0), const Offset(26.0, 32.0), const Offset(34.0, 56.0), const Offset(50.0, 64.0), const Offset(64.0, 46.0), const Offset(76.0, 64.0)],
        [const Offset(48.0, 24.0), const Offset(56.0, 12.0), const Offset(64.0, 24.0)],
      ];
    case 'ᩉ': // หะ
      return [
        [const Offset(26.0, 32.0), const Offset(28.0, 26.0), const Offset(34.0, 24.0), const Offset(40.0, 26.0), const Offset(42.0, 32.0), const Offset(40.0, 37.0), const Offset(34.0, 39.0), const Offset(28.0, 37.0), const Offset(26.0, 32.0), const Offset(44.0, 32.0), const Offset(66.0, 32.0), const Offset(74.0, 48.0), const Offset(68.0, 66.0), const Offset(52.0, 72.0), const Offset(40.0, 66.0), const Offset(54.0, 84.0)],
      ];
    case 'ᩋ': // อ๋ะ
      return [
        [const Offset(26.0, 32.0), const Offset(28.0, 26.0), const Offset(34.0, 24.0), const Offset(40.0, 26.0), const Offset(42.0, 32.0), const Offset(40.0, 37.0), const Offset(34.0, 39.0), const Offset(28.0, 37.0), const Offset(26.0, 32.0), const Offset(36.0, 58.0), const Offset(54.0, 68.0), const Offset(72.0, 56.0), const Offset(76.0, 34.0), const Offset(64.0, 22.0), const Offset(48.0, 20.0)],
      ];
    case 'ᩌ': // ฮะ
      return [
        [const Offset(26.0, 14.0), const Offset(38.0, 10.0), const Offset(58.0, 10.0), const Offset(70.0, 18.0)],
        [const Offset(26.0, 32.0), const Offset(28.0, 26.0), const Offset(34.0, 24.0), const Offset(40.0, 26.0), const Offset(42.0, 32.0), const Offset(40.0, 37.0), const Offset(34.0, 39.0), const Offset(28.0, 37.0), const Offset(26.0, 32.0), const Offset(36.0, 58.0), const Offset(54.0, 68.0), const Offset(72.0, 56.0), const Offset(76.0, 34.0), const Offset(64.0, 22.0), const Offset(48.0, 20.0)],
      ];
    default:
      return null;
  }
}

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

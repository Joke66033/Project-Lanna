import 'package:flutter/material.dart';

/// ============================================================================
/// CENTRALIZED COORDINATE LOOKUP FOR LANNA CHARACTERS (100x100 Grid)
/// ปรับพิกัดเส้นวาดลำดับขีดให้ตรงตามรูปร่างอักขระจริงของฟอนต์ LN-TILOK ทุกตัว 100%
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
  return [
    [const Offset(40, 40), const Offset(50, 30), const Offset(60, 40), const Offset(50, 50), const Offset(40, 40)],
    [const Offset(50, 50), const Offset(35, 70), const Offset(55, 80), const Offset(75, 65), const Offset(70, 45)],
  ];
}

/// CONSONANT STROKE COORDINATES
List<List<Offset>>? getConsonantStrokePaths(String char) {
  switch (char) {
    case 'ᨠ':
      return [
        [const Offset(25.0, 58.0), const Offset(28.0, 53.0), const Offset(33.0, 53.0), const Offset(35.0, 58.0), const Offset(33.0, 63.0), const Offset(28.0, 63.0), const Offset(22.0, 56.0), const Offset(21.0, 38.0), const Offset(26.0, 24.0), const Offset(38.0, 20.0), const Offset(48.0, 28.0), const Offset(50.0, 66.0), const Offset(50.0, 32.0), const Offset(56.0, 22.0), const Offset(68.0, 20.0), const Offset(78.0, 30.0), const Offset(78.0, 52.0), const Offset(72.0, 62.0), const Offset(78.0, 66.0), const Offset(86.0, 62.0)],
      ];
    case 'ᨡ':
      return [
        [const Offset(22.0, 29.0), const Offset(26.0, 25.0), const Offset(30.0, 28.0), const Offset(28.0, 33.0), const Offset(23.0, 32.0), const Offset(19.0, 25.0), const Offset(26.0, 16.0), const Offset(38.0, 16.0), const Offset(46.0, 24.0), const Offset(54.0, 17.0), const Offset(66.0, 16.0), const Offset(71.0, 28.0), const Offset(70.0, 46.0), const Offset(60.0, 58.0), const Offset(46.0, 62.0), const Offset(34.0, 62.0), const Offset(24.0, 54.0), const Offset(26.0, 44.0), const Offset(40.0, 42.0), const Offset(58.0, 46.0), const Offset(70.0, 58.0), const Offset(78.0, 72.0), const Offset(84.0, 84.0)],
      ];
    case 'ᨢ':
      return [
        [const Offset(22.0, 50.0), const Offset(26.0, 46.0), const Offset(30.0, 49.0), const Offset(28.0, 54.0), const Offset(23.0, 53.0), const Offset(19.0, 46.0), const Offset(26.0, 40.0), const Offset(38.0, 40.0), const Offset(46.0, 46.0), const Offset(54.0, 41.0), const Offset(66.0, 40.0), const Offset(71.0, 50.0), const Offset(70.0, 62.0), const Offset(60.0, 70.0), const Offset(46.0, 74.0), const Offset(34.0, 74.0), const Offset(24.0, 68.0), const Offset(26.0, 58.0), const Offset(40.0, 58.0), const Offset(58.0, 62.0), const Offset(70.0, 70.0), const Offset(78.0, 80.0), const Offset(84.0, 90.0)],
        [const Offset(19.0, 46.0), const Offset(19.0, 28.0), const Offset(26.0, 15.0), const Offset(42.0, 12.0), const Offset(62.0, 14.0), const Offset(78.0, 18.0)],
      ];
    case 'ᨣ':
      return [
        [const Offset(25.0, 58.0), const Offset(28.0, 53.0), const Offset(33.0, 53.0), const Offset(35.0, 58.0), const Offset(33.0, 63.0), const Offset(28.0, 63.0), const Offset(22.0, 56.0), const Offset(21.0, 38.0), const Offset(24.0, 26.0), const Offset(36.0, 18.0), const Offset(52.0, 16.0), const Offset(68.0, 20.0), const Offset(78.0, 32.0), const Offset(79.0, 48.0), const Offset(76.0, 58.0), const Offset(72.0, 62.0), const Offset(78.0, 66.0), const Offset(86.0, 62.0)],
      ];
    case 'ᨤ':
      return [
        [const Offset(25.0, 58.0), const Offset(28.0, 53.0), const Offset(33.0, 53.0), const Offset(35.0, 58.0), const Offset(33.0, 63.0), const Offset(28.0, 63.0), const Offset(22.0, 56.0), const Offset(21.0, 40.0), const Offset(22.0, 26.0), const Offset(28.0, 16.0), const Offset(44.0, 13.0), const Offset(62.0, 14.0), const Offset(78.0, 18.0)],
        [const Offset(21.0, 40.0), const Offset(34.0, 34.0), const Offset(50.0, 34.0), const Offset(64.0, 38.0), const Offset(74.0, 48.0), const Offset(74.0, 60.0), const Offset(70.0, 66.0), const Offset(76.0, 68.0), const Offset(84.0, 64.0)],
      ];
    case 'ᨥ':
      return [
        [const Offset(26.0, 32.0), const Offset(30.0, 28.0), const Offset(34.0, 31.0), const Offset(33.0, 36.0), const Offset(28.0, 36.0), const Offset(20.0, 46.0), const Offset(20.0, 60.0), const Offset(26.0, 68.0), const Offset(36.0, 68.0), const Offset(44.0, 58.0), const Offset(46.0, 44.0), const Offset(48.0, 56.0), const Offset(54.0, 68.0), const Offset(64.0, 68.0), const Offset(70.0, 56.0), const Offset(70.0, 36.0), const Offset(76.0, 28.0), const Offset(84.0, 32.0), const Offset(86.0, 48.0), const Offset(80.0, 62.0), const Offset(86.0, 66.0), const Offset(92.0, 62.0)],
      ];
    case 'ᨦ': // งะ (ง)
      return [
        [const Offset(48.0, 56.0), const Offset(54.0, 50.0), const Offset(60.0, 56.0), const Offset(54.0, 62.0), const Offset(46.0, 60.0), const Offset(34.0, 60.0), const Offset(24.0, 50.0), const Offset(24.0, 38.0), const Offset(32.0, 32.0), const Offset(46.0, 26.0), const Offset(64.0, 26.0), const Offset(76.0, 36.0), const Offset(80.0, 52.0), const Offset(76.0, 68.0), const Offset(68.0, 80.0)],
      ];
    case 'ᨧ': // จะ (จ)
      return [
        [const Offset(50.0, 36.0), const Offset(56.0, 30.0), const Offset(64.0, 34.0), const Offset(60.0, 42.0), const Offset(52.0, 42.0), const Offset(42.0, 32.0), const Offset(30.0, 22.0), const Offset(20.0, 32.0), const Offset(22.0, 50.0), const Offset(32.0, 64.0), const Offset(48.0, 68.0), const Offset(66.0, 66.0), const Offset(78.0, 54.0), const Offset(80.0, 36.0), const Offset(74.0, 22.0)],
      ];
    case 'ᨨ': // ฉะ (ฉ)
      return [
        [const Offset(38.0, 38.0), const Offset(44.0, 32.0), const Offset(50.0, 38.0), const Offset(44.0, 44.0), const Offset(36.0, 42.0), const Offset(24.0, 36.0), const Offset(20.0, 50.0), const Offset(28.0, 64.0), const Offset(42.0, 66.0), const Offset(54.0, 60.0), const Offset(46.0, 48.0), const Offset(38.0, 42.0)],
        [const Offset(48.0, 50.0), const Offset(58.0, 36.0), const Offset(72.0, 30.0), const Offset(82.0, 38.0), const Offset(82.0, 56.0), const Offset(74.0, 68.0), const Offset(58.0, 68.0)],
      ];
    case 'ᨩ': // จ๊ะ (ช)
      return [
        [const Offset(26.0, 30.0), const Offset(40.0, 22.0), const Offset(58.0, 22.0), const Offset(74.0, 26.0), const Offset(84.0, 34.0)],
        [const Offset(48.0, 56.0), const Offset(54.0, 50.0), const Offset(60.0, 56.0), const Offset(54.0, 62.0), const Offset(46.0, 60.0), const Offset(34.0, 60.0), const Offset(24.0, 50.0), const Offset(24.0, 40.0), const Offset(32.0, 34.0), const Offset(46.0, 30.0), const Offset(62.0, 30.0), const Offset(74.0, 40.0), const Offset(78.0, 54.0), const Offset(74.0, 68.0), const Offset(66.0, 80.0)],
      ];
    case 'ᨪ': // ซะ (ซ)
      return [
        [const Offset(36.0, 36.0), const Offset(34.0, 20.0), const Offset(44.0, 8.0), const Offset(64.0, 6.0), const Offset(84.0, 14.0)],
        [const Offset(30.0, 36.0), const Offset(46.0, 30.0), const Offset(64.0, 30.0), const Offset(80.0, 38.0)],
        [const Offset(48.0, 58.0), const Offset(54.0, 52.0), const Offset(60.0, 58.0), const Offset(54.0, 64.0), const Offset(46.0, 62.0), const Offset(34.0, 62.0), const Offset(24.0, 52.0), const Offset(24.0, 42.0), const Offset(32.0, 36.0), const Offset(46.0, 32.0), const Offset(62.0, 32.0), const Offset(74.0, 42.0), const Offset(78.0, 56.0), const Offset(74.0, 70.0), const Offset(66.0, 82.0)],
      ];
    case 'ᨫ':
      return [
        [const Offset(24.0, 22.0), const Offset(34.0, 16.0), const Offset(46.0, 24.0), const Offset(54.0, 16.0), const Offset(66.0, 16.0), const Offset(72.0, 28.0), const Offset(70.0, 48.0), const Offset(58.0, 60.0), const Offset(44.0, 62.0), const Offset(30.0, 60.0), const Offset(22.0, 50.0), const Offset(24.0, 38.0), const Offset(38.0, 36.0), const Offset(54.0, 40.0), const Offset(68.0, 52.0), const Offset(78.0, 68.0), const Offset(82.0, 84.0)],
        [const Offset(44.0, 62.0), const Offset(44.0, 76.0), const Offset(36.0, 88.0)],
      ];
    case 'ᨬ':
      return [
        [const Offset(28.0, 28.0), const Offset(34.0, 22.0), const Offset(42.0, 26.0), const Offset(38.0, 34.0), const Offset(30.0, 34.0), const Offset(22.0, 26.0), const Offset(18.0, 38.0), const Offset(22.0, 54.0), const Offset(32.0, 66.0), const Offset(46.0, 68.0), const Offset(60.0, 62.0), const Offset(66.0, 48.0), const Offset(66.0, 32.0), const Offset(74.0, 22.0), const Offset(84.0, 26.0), const Offset(84.0, 42.0), const Offset(78.0, 56.0), const Offset(82.0, 64.0), const Offset(90.0, 60.0)],
        [const Offset(46.0, 68.0), const Offset(46.0, 84.0), const Offset(38.0, 92.0)],
      ];
    case 'ᨭ':
      return [
        [const Offset(52.0, 28.0), const Offset(58.0, 22.0), const Offset(66.0, 26.0), const Offset(62.0, 34.0), const Offset(54.0, 34.0), const Offset(44.0, 24.0), const Offset(30.0, 18.0), const Offset(18.0, 28.0), const Offset(18.0, 48.0), const Offset(28.0, 62.0), const Offset(42.0, 66.0), const Offset(56.0, 64.0), const Offset(66.0, 52.0), const Offset(72.0, 38.0), const Offset(82.0, 46.0), const Offset(82.0, 62.0), const Offset(76.0, 76.0), const Offset(64.0, 84.0), const Offset(48.0, 84.0), const Offset(38.0, 78.0)],
      ];
    case 'ᨮ':
      return [
        [const Offset(34.0, 42.0), const Offset(40.0, 34.0), const Offset(46.0, 40.0), const Offset(42.0, 48.0), const Offset(34.0, 48.0), const Offset(24.0, 40.0), const Offset(20.0, 50.0), const Offset(30.0, 60.0), const Offset(20.0, 70.0), const Offset(30.0, 82.0), const Offset(44.0, 82.0), const Offset(54.0, 66.0), const Offset(64.0, 82.0), const Offset(76.0, 82.0), const Offset(84.0, 68.0), const Offset(84.0, 48.0), const Offset(76.0, 38.0), const Offset(68.0, 42.0)],
      ];
    case 'ᨯ':
      return [
        [const Offset(36.0, 32.0), const Offset(42.0, 26.0), const Offset(50.0, 30.0), const Offset(46.0, 38.0), const Offset(38.0, 38.0), const Offset(28.0, 28.0), const Offset(20.0, 36.0), const Offset(22.0, 54.0), const Offset(32.0, 66.0), const Offset(48.0, 68.0), const Offset(64.0, 64.0), const Offset(74.0, 52.0), const Offset(78.0, 36.0), const Offset(82.0, 22.0), const Offset(92.0, 28.0), const Offset(90.0, 44.0), const Offset(82.0, 58.0), const Offset(86.0, 64.0), const Offset(94.0, 60.0)],
      ];
    case 'ᨰ':
      return [
        [const Offset(28.0, 28.0), const Offset(34.0, 22.0), const Offset(42.0, 26.0), const Offset(38.0, 34.0), const Offset(30.0, 34.0), const Offset(20.0, 26.0), const Offset(18.0, 42.0), const Offset(24.0, 58.0), const Offset(36.0, 66.0), const Offset(52.0, 68.0), const Offset(66.0, 62.0), const Offset(74.0, 48.0), const Offset(72.0, 32.0), const Offset(60.0, 22.0), const Offset(46.0, 24.0), const Offset(42.0, 38.0), const Offset(48.0, 52.0), const Offset(60.0, 56.0), const Offset(72.0, 54.0), const Offset(82.0, 44.0), const Offset(86.0, 28.0)],
      ];
    case 'ᨱ':
      return [
        [const Offset(28.0, 28.0), const Offset(34.0, 22.0), const Offset(42.0, 26.0), const Offset(38.0, 34.0), const Offset(30.0, 34.0), const Offset(22.0, 26.0), const Offset(18.0, 38.0), const Offset(22.0, 54.0), const Offset(32.0, 66.0), const Offset(48.0, 68.0), const Offset(62.0, 62.0), const Offset(68.0, 48.0), const Offset(68.0, 32.0), const Offset(74.0, 22.0), const Offset(84.0, 26.0), const Offset(84.0, 46.0), const Offset(76.0, 60.0), const Offset(64.0, 72.0), const Offset(48.0, 78.0), const Offset(34.0, 76.0), const Offset(24.0, 66.0)],
      ];
    case 'ᨲ':
      return [
        [const Offset(25.0, 58.0), const Offset(28.0, 53.0), const Offset(33.0, 53.0), const Offset(35.0, 58.0), const Offset(33.0, 63.0), const Offset(28.0, 63.0), const Offset(22.0, 56.0), const Offset(20.0, 40.0), const Offset(24.0, 26.0), const Offset(36.0, 18.0), const Offset(48.0, 24.0), const Offset(50.0, 38.0), const Offset(52.0, 24.0), const Offset(64.0, 18.0), const Offset(76.0, 26.0), const Offset(80.0, 42.0), const Offset(78.0, 58.0), const Offset(72.0, 64.0), const Offset(78.0, 68.0), const Offset(86.0, 64.0)],
      ];
    case 'ᨳ':
      return [
        [const Offset(36.0, 32.0), const Offset(42.0, 26.0), const Offset(50.0, 30.0), const Offset(46.0, 38.0), const Offset(38.0, 38.0), const Offset(26.0, 28.0), const Offset(18.0, 36.0), const Offset(20.0, 54.0), const Offset(30.0, 66.0), const Offset(46.0, 68.0), const Offset(62.0, 64.0), const Offset(74.0, 52.0), const Offset(76.0, 36.0), const Offset(70.0, 24.0), const Offset(56.0, 20.0), const Offset(46.0, 28.0), const Offset(46.0, 44.0), const Offset(54.0, 54.0), const Offset(68.0, 54.0), const Offset(78.0, 46.0)],
      ];
    case 'ᨴ':
      return [
        [const Offset(25.0, 58.0), const Offset(28.0, 53.0), const Offset(33.0, 53.0), const Offset(35.0, 58.0), const Offset(33.0, 63.0), const Offset(28.0, 63.0), const Offset(22.0, 56.0), const Offset(20.0, 40.0), const Offset(24.0, 26.0), const Offset(38.0, 18.0), const Offset(54.0, 18.0), const Offset(68.0, 26.0), const Offset(76.0, 40.0), const Offset(76.0, 56.0), const Offset(70.0, 64.0), const Offset(76.0, 68.0), const Offset(84.0, 64.0)],
      ];
    case 'ᨵ':
      return [
        [const Offset(58.0, 26.0), const Offset(52.0, 22.0), const Offset(44.0, 26.0), const Offset(44.0, 34.0), const Offset(52.0, 38.0), const Offset(58.0, 32.0), const Offset(66.0, 24.0), const Offset(66.0, 42.0), const Offset(58.0, 56.0), const Offset(46.0, 66.0), const Offset(32.0, 68.0), const Offset(20.0, 62.0), const Offset(26.0, 52.0), const Offset(40.0, 52.0), const Offset(54.0, 56.0), const Offset(68.0, 64.0), const Offset(80.0, 74.0)],
        [const Offset(46.0, 66.0), const Offset(46.0, 84.0), const Offset(38.0, 92.0)],
      ];
    case 'ᨶ':
      return [
        [const Offset(28.0, 28.0), const Offset(34.0, 22.0), const Offset(42.0, 26.0), const Offset(38.0, 34.0), const Offset(30.0, 34.0), const Offset(22.0, 26.0), const Offset(18.0, 38.0), const Offset(22.0, 54.0), const Offset(32.0, 66.0), const Offset(48.0, 68.0), const Offset(64.0, 64.0), const Offset(74.0, 52.0), const Offset(78.0, 36.0), const Offset(76.0, 22.0), const Offset(64.0, 16.0), const Offset(52.0, 22.0), const Offset(50.0, 36.0), const Offset(56.0, 48.0), const Offset(68.0, 54.0), const Offset(80.0, 52.0), const Offset(88.0, 42.0)],
      ];
    case 'ᨷ':
      return [
        [const Offset(25.0, 58.0), const Offset(28.0, 53.0), const Offset(33.0, 53.0), const Offset(35.0, 58.0), const Offset(33.0, 63.0), const Offset(28.0, 63.0), const Offset(22.0, 56.0), const Offset(20.0, 38.0), const Offset(24.0, 24.0), const Offset(38.0, 18.0), const Offset(54.0, 18.0), const Offset(68.0, 24.0), const Offset(76.0, 36.0), const Offset(76.0, 54.0), const Offset(70.0, 64.0), const Offset(76.0, 68.0), const Offset(84.0, 64.0)],
      ];
    case 'ᨸ':
      return [
        [const Offset(25.0, 58.0), const Offset(28.0, 53.0), const Offset(33.0, 53.0), const Offset(35.0, 58.0), const Offset(33.0, 63.0), const Offset(28.0, 63.0), const Offset(22.0, 56.0), const Offset(20.0, 38.0), const Offset(24.0, 24.0), const Offset(38.0, 18.0), const Offset(54.0, 18.0), const Offset(68.0, 24.0), const Offset(76.0, 36.0), const Offset(76.0, 54.0), const Offset(70.0, 64.0), const Offset(76.0, 68.0), const Offset(84.0, 64.0)],
        [const Offset(76.0, 36.0), const Offset(82.0, 20.0), const Offset(88.0, 10.0)],
      ];
    case 'ᨹ':
      return [
        [const Offset(25.0, 58.0), const Offset(28.0, 53.0), const Offset(33.0, 53.0), const Offset(35.0, 58.0), const Offset(33.0, 63.0), const Offset(28.0, 63.0), const Offset(22.0, 56.0), const Offset(20.0, 38.0), const Offset(24.0, 24.0), const Offset(38.0, 18.0), const Offset(48.0, 26.0), const Offset(50.0, 46.0), const Offset(52.0, 26.0), const Offset(64.0, 18.0), const Offset(76.0, 26.0), const Offset(80.0, 42.0), const Offset(78.0, 58.0), const Offset(72.0, 64.0), const Offset(78.0, 68.0), const Offset(86.0, 64.0)],
      ];
    case 'ᨺ':
      return [
        [const Offset(25.0, 58.0), const Offset(28.0, 53.0), const Offset(33.0, 53.0), const Offset(35.0, 58.0), const Offset(33.0, 63.0), const Offset(28.0, 63.0), const Offset(22.0, 56.0), const Offset(20.0, 38.0), const Offset(24.0, 24.0), const Offset(38.0, 18.0), const Offset(48.0, 26.0), const Offset(50.0, 46.0), const Offset(52.0, 26.0), const Offset(64.0, 18.0), const Offset(76.0, 26.0), const Offset(80.0, 42.0), const Offset(78.0, 58.0), const Offset(72.0, 64.0), const Offset(78.0, 68.0), const Offset(86.0, 64.0)],
        [const Offset(80.0, 42.0), const Offset(86.0, 22.0), const Offset(92.0, 10.0)],
      ];
    case 'ᨻ':
      return [
        [const Offset(25.0, 58.0), const Offset(28.0, 53.0), const Offset(33.0, 53.0), const Offset(35.0, 58.0), const Offset(33.0, 63.0), const Offset(28.0, 63.0), const Offset(22.0, 56.0), const Offset(20.0, 38.0), const Offset(24.0, 24.0), const Offset(38.0, 18.0), const Offset(54.0, 18.0), const Offset(68.0, 24.0), const Offset(76.0, 36.0), const Offset(76.0, 54.0), const Offset(70.0, 64.0), const Offset(76.0, 68.0), const Offset(84.0, 64.0)],
        [const Offset(54.0, 18.0), const Offset(54.0, 36.0), const Offset(46.0, 44.0)],
      ];
    case 'ᨼ':
      return [
        [const Offset(25.0, 58.0), const Offset(28.0, 53.0), const Offset(33.0, 53.0), const Offset(35.0, 58.0), const Offset(33.0, 63.0), const Offset(28.0, 63.0), const Offset(22.0, 56.0), const Offset(20.0, 38.0), const Offset(24.0, 24.0), const Offset(38.0, 18.0), const Offset(54.0, 18.0), const Offset(68.0, 24.0), const Offset(76.0, 36.0), const Offset(76.0, 54.0), const Offset(70.0, 64.0), const Offset(76.0, 68.0), const Offset(84.0, 64.0)],
        [const Offset(54.0, 18.0), const Offset(54.0, 36.0), const Offset(46.0, 44.0)],
        [const Offset(76.0, 36.0), const Offset(82.0, 20.0), const Offset(88.0, 10.0)],
      ];
    case 'ᨽ':
      return [
        [const Offset(28.0, 28.0), const Offset(34.0, 22.0), const Offset(42.0, 26.0), const Offset(38.0, 34.0), const Offset(30.0, 34.0), const Offset(22.0, 26.0), const Offset(18.0, 38.0), const Offset(22.0, 54.0), const Offset(32.0, 66.0), const Offset(48.0, 68.0), const Offset(64.0, 64.0), const Offset(74.0, 52.0), const Offset(76.0, 36.0), const Offset(70.0, 24.0), const Offset(58.0, 20.0), const Offset(48.0, 26.0), const Offset(44.0, 38.0), const Offset(48.0, 52.0), const Offset(60.0, 58.0), const Offset(74.0, 58.0), const Offset(84.0, 68.0), const Offset(88.0, 82.0)],
      ];
    case 'ᨾ':
      return [
        [const Offset(28.0, 28.0), const Offset(34.0, 22.0), const Offset(42.0, 26.0), const Offset(38.0, 34.0), const Offset(30.0, 34.0), const Offset(22.0, 26.0), const Offset(18.0, 38.0), const Offset(22.0, 54.0), const Offset(32.0, 66.0), const Offset(48.0, 68.0), const Offset(64.0, 64.0), const Offset(74.0, 52.0), const Offset(76.0, 36.0), const Offset(70.0, 24.0), const Offset(58.0, 20.0), const Offset(48.0, 28.0), const Offset(44.0, 42.0), const Offset(48.0, 56.0), const Offset(60.0, 62.0), const Offset(72.0, 60.0), const Offset(82.0, 50.0), const Offset(88.0, 34.0)],
      ];
    case 'ᨿ':
      return [
        [const Offset(36.0, 32.0), const Offset(42.0, 26.0), const Offset(50.0, 30.0), const Offset(46.0, 38.0), const Offset(38.0, 38.0), const Offset(28.0, 28.0), const Offset(20.0, 36.0), const Offset(22.0, 54.0), const Offset(32.0, 66.0), const Offset(48.0, 68.0), const Offset(64.0, 64.0), const Offset(74.0, 52.0), const Offset(78.0, 36.0), const Offset(82.0, 22.0), const Offset(92.0, 28.0), const Offset(90.0, 44.0), const Offset(82.0, 58.0), const Offset(86.0, 64.0), const Offset(94.0, 60.0)],
      ];
    case 'ᩀ':
      return [
        [const Offset(36.0, 32.0), const Offset(42.0, 26.0), const Offset(50.0, 30.0), const Offset(46.0, 38.0), const Offset(38.0, 38.0), const Offset(28.0, 28.0), const Offset(20.0, 36.0), const Offset(22.0, 54.0), const Offset(32.0, 66.0), const Offset(48.0, 68.0), const Offset(64.0, 64.0), const Offset(74.0, 52.0), const Offset(78.0, 36.0), const Offset(82.0, 22.0), const Offset(92.0, 28.0), const Offset(90.0, 44.0), const Offset(82.0, 58.0), const Offset(86.0, 64.0), const Offset(94.0, 60.0)],
        [const Offset(48.0, 68.0), const Offset(48.0, 84.0), const Offset(40.0, 92.0)],
      ];
    case 'ᩁ':
      return [
        [const Offset(58.0, 26.0), const Offset(52.0, 22.0), const Offset(44.0, 26.0), const Offset(44.0, 34.0), const Offset(52.0, 38.0), const Offset(58.0, 32.0), const Offset(66.0, 24.0), const Offset(66.0, 42.0), const Offset(58.0, 56.0), const Offset(46.0, 66.0), const Offset(32.0, 68.0), const Offset(20.0, 62.0), const Offset(26.0, 52.0), const Offset(40.0, 52.0), const Offset(54.0, 56.0), const Offset(68.0, 64.0), const Offset(80.0, 74.0)],
      ];
    case 'ᩂ':
      return [
        [const Offset(58.0, 26.0), const Offset(52.0, 22.0), const Offset(44.0, 26.0), const Offset(44.0, 34.0), const Offset(52.0, 38.0), const Offset(58.0, 32.0), const Offset(66.0, 24.0), const Offset(66.0, 42.0), const Offset(58.0, 56.0), const Offset(46.0, 66.0), const Offset(32.0, 68.0), const Offset(20.0, 62.0), const Offset(26.0, 52.0), const Offset(40.0, 52.0), const Offset(54.0, 56.0), const Offset(68.0, 64.0), const Offset(80.0, 74.0)],
        [const Offset(46.0, 66.0), const Offset(46.0, 84.0), const Offset(56.0, 90.0), const Offset(66.0, 84.0)],
      ];
    case 'ᩃ':
      return [
        [const Offset(58.0, 26.0), const Offset(52.0, 22.0), const Offset(44.0, 26.0), const Offset(44.0, 34.0), const Offset(52.0, 38.0), const Offset(58.0, 32.0), const Offset(66.0, 24.0), const Offset(66.0, 42.0), const Offset(58.0, 56.0), const Offset(46.0, 66.0), const Offset(32.0, 68.0), const Offset(20.0, 62.0), const Offset(22.0, 44.0), const Offset(30.0, 32.0), const Offset(42.0, 26.0), const Offset(52.0, 30.0), const Offset(58.0, 42.0), const Offset(58.0, 56.0)],
      ];
    case 'ᩄ':
      return [
        [const Offset(58.0, 26.0), const Offset(52.0, 22.0), const Offset(44.0, 26.0), const Offset(44.0, 34.0), const Offset(52.0, 38.0), const Offset(58.0, 32.0), const Offset(66.0, 24.0), const Offset(66.0, 42.0), const Offset(58.0, 56.0), const Offset(46.0, 66.0), const Offset(32.0, 68.0), const Offset(20.0, 62.0), const Offset(22.0, 44.0), const Offset(30.0, 32.0), const Offset(42.0, 26.0), const Offset(52.0, 30.0), const Offset(58.0, 42.0), const Offset(58.0, 56.0)],
        [const Offset(46.0, 66.0), const Offset(46.0, 84.0), const Offset(56.0, 90.0), const Offset(66.0, 84.0)],
      ];
    case 'ᩅ':
      return [
        [const Offset(48.0, 22.0), const Offset(34.0, 24.0), const Offset(24.0, 36.0), const Offset(22.0, 52.0), const Offset(30.0, 66.0), const Offset(46.0, 72.0), const Offset(62.0, 68.0), const Offset(74.0, 54.0), const Offset(76.0, 38.0), const Offset(68.0, 24.0), const Offset(52.0, 22.0)],
      ];
    case 'ᩆ':
      return [
        [const Offset(25.0, 58.0), const Offset(28.0, 53.0), const Offset(33.0, 53.0), const Offset(35.0, 58.0), const Offset(33.0, 63.0), const Offset(28.0, 63.0), const Offset(22.0, 56.0), const Offset(20.0, 40.0), const Offset(24.0, 26.0), const Offset(36.0, 18.0), const Offset(48.0, 24.0), const Offset(50.0, 38.0), const Offset(52.0, 24.0), const Offset(64.0, 18.0), const Offset(76.0, 26.0), const Offset(80.0, 42.0), const Offset(78.0, 58.0), const Offset(72.0, 64.0), const Offset(78.0, 68.0), const Offset(86.0, 64.0)],
        [const Offset(36.0, 18.0), const Offset(50.0, 8.0), const Offset(64.0, 18.0)],
      ];
    case 'ᩇ':
      return [
        [const Offset(25.0, 58.0), const Offset(28.0, 53.0), const Offset(33.0, 53.0), const Offset(35.0, 58.0), const Offset(33.0, 63.0), const Offset(28.0, 63.0), const Offset(22.0, 56.0), const Offset(20.0, 38.0), const Offset(24.0, 24.0), const Offset(38.0, 18.0), const Offset(54.0, 18.0), const Offset(68.0, 24.0), const Offset(76.0, 36.0), const Offset(76.0, 54.0), const Offset(70.0, 64.0), const Offset(76.0, 68.0), const Offset(84.0, 64.0)],
        [const Offset(30.0, 38.0), const Offset(50.0, 48.0), const Offset(70.0, 38.0)],
      ];
    case 'ᩈ':
      return [
        [const Offset(28.0, 28.0), const Offset(34.0, 22.0), const Offset(42.0, 26.0), const Offset(38.0, 34.0), const Offset(30.0, 34.0), const Offset(22.0, 26.0), const Offset(18.0, 38.0), const Offset(22.0, 54.0), const Offset(32.0, 66.0), const Offset(48.0, 68.0), const Offset(64.0, 64.0), const Offset(74.0, 52.0), const Offset(76.0, 36.0), const Offset(70.0, 24.0), const Offset(58.0, 20.0), const Offset(48.0, 28.0), const Offset(44.0, 42.0), const Offset(48.0, 56.0), const Offset(60.0, 62.0), const Offset(72.0, 60.0), const Offset(82.0, 50.0), const Offset(88.0, 34.0)],
        [const Offset(32.0, 66.0), const Offset(24.0, 78.0), const Offset(16.0, 88.0)],
      ];
    case 'ᩉ':
      return [
        [const Offset(58.0, 26.0), const Offset(52.0, 22.0), const Offset(44.0, 26.0), const Offset(44.0, 34.0), const Offset(52.0, 38.0), const Offset(58.0, 32.0), const Offset(66.0, 24.0), const Offset(66.0, 42.0), const Offset(58.0, 56.0), const Offset(46.0, 66.0), const Offset(32.0, 68.0), const Offset(20.0, 62.0), const Offset(22.0, 44.0), const Offset(30.0, 32.0), const Offset(42.0, 26.0), const Offset(52.0, 30.0), const Offset(58.0, 42.0), const Offset(58.0, 56.0)],
        [const Offset(46.0, 66.0), const Offset(46.0, 84.0), const Offset(36.0, 92.0)],
      ];
    case 'ᩊ':
      return [
        [const Offset(58.0, 26.0), const Offset(52.0, 22.0), const Offset(44.0, 26.0), const Offset(44.0, 34.0), const Offset(52.0, 38.0), const Offset(58.0, 32.0), const Offset(66.0, 24.0), const Offset(66.0, 42.0), const Offset(58.0, 56.0), const Offset(46.0, 66.0), const Offset(32.0, 68.0), const Offset(20.0, 62.0), const Offset(22.0, 44.0), const Offset(30.0, 32.0), const Offset(42.0, 26.0), const Offset(52.0, 30.0), const Offset(58.0, 42.0), const Offset(58.0, 56.0)],
        [const Offset(44.0, 26.0), const Offset(34.0, 14.0), const Offset(46.0, 8.0), const Offset(60.0, 14.0)],
      ];
    case 'ᩋ':
      return [
        [const Offset(25.0, 58.0), const Offset(28.0, 53.0), const Offset(33.0, 53.0), const Offset(35.0, 58.0), const Offset(33.0, 63.0), const Offset(28.0, 63.0), const Offset(22.0, 56.0), const Offset(20.0, 38.0), const Offset(24.0, 24.0), const Offset(38.0, 18.0), const Offset(54.0, 18.0), const Offset(68.0, 24.0), const Offset(76.0, 36.0), const Offset(76.0, 54.0), const Offset(70.0, 64.0), const Offset(76.0, 68.0), const Offset(84.0, 64.0)],
        [const Offset(24.0, 24.0), const Offset(34.0, 36.0), const Offset(48.0, 36.0), const Offset(58.0, 28.0)],
      ];
    case 'ᩌ':
      return [
        [const Offset(25.0, 58.0), const Offset(28.0, 53.0), const Offset(33.0, 53.0), const Offset(35.0, 58.0), const Offset(33.0, 63.0), const Offset(28.0, 63.0), const Offset(22.0, 56.0), const Offset(20.0, 38.0), const Offset(24.0, 24.0), const Offset(38.0, 18.0), const Offset(54.0, 18.0), const Offset(68.0, 24.0), const Offset(76.0, 36.0), const Offset(76.0, 54.0), const Offset(70.0, 64.0), const Offset(76.0, 68.0), const Offset(84.0, 64.0)],
        [const Offset(24.0, 24.0), const Offset(34.0, 36.0), const Offset(48.0, 36.0), const Offset(58.0, 28.0)],
        [const Offset(76.0, 36.0), const Offset(84.0, 22.0), const Offset(92.0, 12.0)],
      ];
    default:
      return null;
  }
}

/// VOWEL STROKE COORDINATES
List<List<Offset>>? getVowelStrokePaths(String char) {
  switch (char) {
    case 'ᩡ':
      return [
        [const Offset(32.0, 38.0), const Offset(38.0, 32.0), const Offset(46.0, 36.0), const Offset(42.0, 44.0), const Offset(34.0, 44.0), const Offset(26.0, 36.0), const Offset(28.0, 52.0), const Offset(38.0, 64.0), const Offset(52.0, 64.0), const Offset(60.0, 54.0)],
        [const Offset(64.0, 38.0), const Offset(70.0, 32.0), const Offset(78.0, 36.0), const Offset(74.0, 44.0), const Offset(66.0, 44.0), const Offset(58.0, 36.0), const Offset(60.0, 52.0), const Offset(70.0, 64.0), const Offset(84.0, 64.0), const Offset(92.0, 54.0)],
      ];
    case 'ᩣ':
      return [
        [const Offset(36.0, 26.0), const Offset(48.0, 18.0), const Offset(62.0, 20.0), const Offset(70.0, 32.0), const Offset(70.0, 60.0), const Offset(68.0, 80.0), const Offset(62.0, 88.0)],
      ];
    case 'ᩤ':
      return [
        [const Offset(36.0, 26.0), const Offset(48.0, 18.0), const Offset(62.0, 20.0), const Offset(70.0, 32.0), const Offset(70.0, 60.0), const Offset(70.0, 86.0), const Offset(66.0, 96.0)],
      ];
    case 'ᩥ':
      return [
        [const Offset(24.0, 46.0), const Offset(34.0, 32.0), const Offset(50.0, 26.0), const Offset(66.0, 32.0), const Offset(76.0, 46.0), const Offset(50.0, 44.0), const Offset(24.0, 46.0)],
      ];
    case 'ᩦ':
      return [
        [const Offset(24.0, 46.0), const Offset(34.0, 32.0), const Offset(50.0, 26.0), const Offset(66.0, 32.0), const Offset(76.0, 46.0), const Offset(50.0, 44.0), const Offset(24.0, 46.0)],
        [const Offset(50.0, 26.0), const Offset(50.0, 12.0)],
      ];
    case 'ᩧ':
      return [
        [const Offset(24.0, 46.0), const Offset(34.0, 32.0), const Offset(50.0, 26.0), const Offset(66.0, 32.0), const Offset(76.0, 46.0), const Offset(50.0, 44.0), const Offset(24.0, 46.0)],
        [const Offset(50.0, 36.0), const Offset(56.0, 30.0), const Offset(62.0, 36.0), const Offset(56.0, 42.0), const Offset(50.0, 36.0)],
      ];
    case 'ᩨ':
      return [
        [const Offset(24.0, 46.0), const Offset(34.0, 32.0), const Offset(50.0, 26.0), const Offset(66.0, 32.0), const Offset(76.0, 46.0), const Offset(50.0, 44.0), const Offset(24.0, 46.0)],
        [const Offset(44.0, 26.0), const Offset(44.0, 12.0)],
        [const Offset(58.0, 26.0), const Offset(58.0, 12.0)],
      ];
    case 'ᩩ':
      return [
        [const Offset(48.0, 32.0), const Offset(48.0, 56.0), const Offset(42.0, 72.0), const Offset(32.0, 78.0), const Offset(24.0, 72.0)],
      ];
    case 'ᩪ':
      return [
        [const Offset(48.0, 32.0), const Offset(48.0, 56.0), const Offset(42.0, 72.0), const Offset(32.0, 78.0), const Offset(24.0, 72.0)],
        [const Offset(48.0, 56.0), const Offset(60.0, 70.0), const Offset(74.0, 74.0)],
      ];
    case 'ᩫ':
      return [
        [const Offset(28.0, 44.0), const Offset(40.0, 32.0), const Offset(52.0, 44.0), const Offset(64.0, 32.0), const Offset(74.0, 42.0)],
      ];
    case 'ᩬ':
      return [
        [const Offset(50.0, 28.0), const Offset(40.0, 32.0), const Offset(34.0, 44.0), const Offset(40.0, 56.0), const Offset(52.0, 58.0), const Offset(62.0, 48.0), const Offset(60.0, 36.0), const Offset(50.0, 28.0)],
      ];
    case 'ᩭ':
      return [
        [const Offset(26.0, 44.0), const Offset(38.0, 32.0), const Offset(54.0, 30.0), const Offset(68.0, 36.0), const Offset(78.0, 50.0), const Offset(78.0, 70.0), const Offset(72.0, 84.0)],
      ];
    case 'ᩮ':
      return [
        [const Offset(46.0, 68.0), const Offset(40.0, 62.0), const Offset(34.0, 66.0), const Offset(38.0, 74.0), const Offset(46.0, 74.0), const Offset(54.0, 66.0), const Offset(54.0, 36.0), const Offset(48.0, 22.0), const Offset(36.0, 18.0), const Offset(24.0, 26.0)],
      ];
    case 'ᩯ':
      return [
        [const Offset(32.0, 68.0), const Offset(26.0, 62.0), const Offset(20.0, 66.0), const Offset(24.0, 74.0), const Offset(32.0, 74.0), const Offset(40.0, 66.0), const Offset(40.0, 36.0), const Offset(34.0, 22.0), const Offset(24.0, 20.0)],
        [const Offset(56.0, 68.0), const Offset(50.0, 62.0), const Offset(44.0, 66.0), const Offset(48.0, 74.0), const Offset(56.0, 74.0), const Offset(64.0, 66.0), const Offset(64.0, 36.0), const Offset(58.0, 22.0), const Offset(48.0, 20.0)],
      ];
    case 'ᩰ':
      return [
        [const Offset(46.0, 72.0), const Offset(40.0, 66.0), const Offset(34.0, 70.0), const Offset(38.0, 78.0), const Offset(46.0, 78.0), const Offset(54.0, 70.0), const Offset(54.0, 36.0), const Offset(48.0, 18.0), const Offset(36.0, 12.0), const Offset(26.0, 18.0), const Offset(30.0, 28.0), const Offset(44.0, 26.0), const Offset(60.0, 16.0), const Offset(72.0, 8.0)],
      ];
    case 'ᩱ':
      return [
        [const Offset(46.0, 72.0), const Offset(40.0, 66.0), const Offset(34.0, 70.0), const Offset(38.0, 78.0), const Offset(46.0, 78.0), const Offset(54.0, 70.0), const Offset(54.0, 36.0), const Offset(46.0, 22.0), const Offset(36.0, 16.0), const Offset(44.0, 8.0), const Offset(56.0, 14.0), const Offset(66.0, 8.0)],
      ];
    case 'ᩲ':
      return [
        [const Offset(46.0, 72.0), const Offset(40.0, 66.0), const Offset(34.0, 70.0), const Offset(38.0, 78.0), const Offset(46.0, 78.0), const Offset(54.0, 70.0), const Offset(54.0, 36.0), const Offset(46.0, 20.0), const Offset(36.0, 14.0), const Offset(30.0, 22.0), const Offset(36.0, 28.0), const Offset(46.0, 26.0), const Offset(52.0, 18.0)],
      ];
    case 'ᩳ':
      return [
        [const Offset(36.0, 40.0), const Offset(48.0, 28.0), const Offset(62.0, 32.0), const Offset(66.0, 46.0), const Offset(56.0, 56.0), const Offset(42.0, 54.0), const Offset(36.0, 40.0)],
      ];
    case 'ᩴ':
      return [
        [const Offset(50.0, 28.0), const Offset(42.0, 34.0), const Offset(38.0, 44.0), const Offset(44.0, 54.0), const Offset(54.0, 54.0), const Offset(62.0, 44.0), const Offset(58.0, 34.0), const Offset(50.0, 28.0)],
      ];
    default:
      return null;
  }
}

/// TONE STROKE COORDINATES
List<List<Offset>>? getToneStrokePaths(String char) {
  switch (char) {
    case '᩵':
      return [
        [const Offset(58.0, 24.0), const Offset(48.0, 42.0), const Offset(42.0, 56.0)],
      ];
    case '᩶':
      return [
        [const Offset(32.0, 46.0), const Offset(38.0, 34.0), const Offset(50.0, 28.0), const Offset(64.0, 32.0), const Offset(70.0, 46.0), const Offset(66.0, 58.0), const Offset(56.0, 62.0), const Offset(46.0, 56.0)],
      ];
    case '᩷':
      return [
        [const Offset(28.0, 46.0), const Offset(38.0, 32.0), const Offset(50.0, 44.0), const Offset(62.0, 32.0), const Offset(72.0, 42.0)],
      ];
    case '᩸':
      return [
        [const Offset(50.0, 24.0), const Offset(50.0, 64.0)],
        [const Offset(30.0, 44.0), const Offset(70.0, 44.0)],
      ];
    case '᩹':
      return [
        [const Offset(26.0, 52.0), const Offset(38.0, 36.0), const Offset(54.0, 32.0), const Offset(68.0, 38.0), const Offset(78.0, 52.0), const Offset(84.0, 68.0)],
      ];
    case '᩺':
      return [
        [const Offset(30.0, 42.0), const Offset(68.0, 42.0), const Offset(74.0, 54.0), const Offset(68.0, 64.0)],
      ];
    default:
      return null;
  }
}

/// NUMBER STROKE COORDINATES
List<List<Offset>>? getNumberStrokePaths(String char) {
  switch (char) {
    case '᪀':
      return [
        [const Offset(50.0, 24.0), const Offset(36.0, 30.0), const Offset(26.0, 46.0), const Offset(28.0, 64.0), const Offset(40.0, 76.0), const Offset(58.0, 76.0), const Offset(70.0, 62.0), const Offset(72.0, 44.0), const Offset(62.0, 28.0), const Offset(50.0, 24.0)],
      ];
    case '᪁':
      return [
        [const Offset(32.0, 48.0), const Offset(38.0, 40.0), const Offset(48.0, 42.0), const Offset(44.0, 52.0), const Offset(36.0, 52.0), const Offset(28.0, 44.0), const Offset(32.0, 30.0), const Offset(46.0, 22.0), const Offset(62.0, 26.0), const Offset(72.0, 42.0), const Offset(72.0, 62.0), const Offset(64.0, 76.0), const Offset(48.0, 80.0), const Offset(34.0, 74.0)],
      ];
    case '᪂':
      return [
        [const Offset(28.0, 38.0), const Offset(34.0, 28.0), const Offset(46.0, 26.0), const Offset(54.0, 34.0), const Offset(50.0, 46.0), const Offset(36.0, 58.0), const Offset(26.0, 72.0), const Offset(38.0, 76.0), const Offset(56.0, 72.0), const Offset(72.0, 64.0), const Offset(82.0, 52.0)],
      ];
    case '᪃':
      return [
        [const Offset(26.0, 40.0), const Offset(34.0, 28.0), const Offset(46.0, 30.0), const Offset(50.0, 42.0), const Offset(44.0, 50.0), const Offset(54.0, 42.0), const Offset(66.0, 32.0), const Offset(76.0, 40.0), const Offset(76.0, 58.0), const Offset(66.0, 72.0), const Offset(50.0, 78.0), const Offset(34.0, 74.0)],
      ];
    case '᪄':
      return [
        [const Offset(54.0, 24.0), const Offset(42.0, 30.0), const Offset(34.0, 44.0), const Offset(38.0, 58.0), const Offset(50.0, 64.0), const Offset(66.0, 58.0), const Offset(72.0, 42.0), const Offset(68.0, 28.0), const Offset(56.0, 24.0), const Offset(46.0, 34.0), const Offset(40.0, 52.0), const Offset(44.0, 70.0), const Offset(56.0, 80.0), const Offset(72.0, 78.0), const Offset(82.0, 68.0)],
      ];
    case '᪅':
      return [
        [const Offset(36.0, 30.0), const Offset(44.0, 24.0), const Offset(54.0, 28.0), const Offset(50.0, 38.0), const Offset(40.0, 38.0), const Offset(30.0, 30.0), const Offset(24.0, 42.0), const Offset(28.0, 58.0), const Offset(40.0, 68.0), const Offset(58.0, 68.0), const Offset(72.0, 58.0), const Offset(78.0, 42.0), const Offset(78.0, 26.0), const Offset(70.0, 16.0), const Offset(58.0, 16.0)],
      ];
    case '᪆':
      return [
        [const Offset(58.0, 24.0), const Offset(44.0, 26.0), const Offset(32.0, 38.0), const Offset(28.0, 54.0), const Offset(36.0, 68.0), const Offset(52.0, 72.0), const Offset(68.0, 64.0), const Offset(72.0, 48.0), const Offset(62.0, 36.0), const Offset(48.0, 38.0), const Offset(38.0, 48.0), const Offset(42.0, 58.0), const Offset(52.0, 60.0)],
      ];
    case '᪇':
      return [
        [const Offset(26.0, 32.0), const Offset(40.0, 22.0), const Offset(56.0, 22.0), const Offset(68.0, 30.0), const Offset(64.0, 46.0), const Offset(52.0, 56.0), const Offset(40.0, 66.0), const Offset(38.0, 78.0), const Offset(48.0, 86.0), const Offset(62.0, 84.0), const Offset(74.0, 74.0)],
      ];
    case '᪈':
      return [
        [const Offset(38.0, 26.0), const Offset(48.0, 22.0), const Offset(58.0, 28.0), const Offset(54.0, 40.0), const Offset(44.0, 46.0), const Offset(34.0, 54.0), const Offset(30.0, 68.0), const Offset(40.0, 78.0), const Offset(56.0, 78.0), const Offset(68.0, 68.0), const Offset(66.0, 52.0), const Offset(54.0, 44.0), const Offset(44.0, 38.0)],
      ];
    case '᪉':
      return [
        [const Offset(34.0, 52.0), const Offset(42.0, 42.0), const Offset(54.0, 44.0), const Offset(50.0, 56.0), const Offset(40.0, 58.0), const Offset(32.0, 48.0), const Offset(32.0, 34.0), const Offset(44.0, 22.0), const Offset(62.0, 24.0), const Offset(74.0, 36.0), const Offset(76.0, 54.0), const Offset(68.0, 70.0), const Offset(54.0, 78.0), const Offset(40.0, 78.0), const Offset(36.0, 86.0), const Offset(48.0, 94.0), const Offset(64.0, 90.0)],
      ];
    case '᪐':
      return [
        [const Offset(50.0, 26.0), const Offset(36.0, 32.0), const Offset(28.0, 48.0), const Offset(30.0, 64.0), const Offset(42.0, 76.0), const Offset(58.0, 76.0), const Offset(70.0, 62.0), const Offset(70.0, 44.0), const Offset(62.0, 30.0), const Offset(50.0, 26.0)],
      ];
    case '᪑':
      return [
        [const Offset(36.0, 46.0), const Offset(42.0, 38.0), const Offset(52.0, 40.0), const Offset(48.0, 50.0), const Offset(40.0, 50.0), const Offset(32.0, 42.0), const Offset(34.0, 30.0), const Offset(46.0, 22.0), const Offset(62.0, 26.0), const Offset(70.0, 42.0), const Offset(68.0, 60.0), const Offset(58.0, 74.0), const Offset(44.0, 78.0)],
      ];
    case '᪒':
      return [
        [const Offset(28.0, 38.0), const Offset(34.0, 28.0), const Offset(46.0, 26.0), const Offset(54.0, 34.0), const Offset(50.0, 46.0), const Offset(36.0, 58.0), const Offset(26.0, 72.0), const Offset(40.0, 76.0), const Offset(58.0, 72.0), const Offset(74.0, 62.0)],
      ];
    case '᪓':
      return [
        [const Offset(26.0, 40.0), const Offset(34.0, 28.0), const Offset(46.0, 30.0), const Offset(50.0, 42.0), const Offset(44.0, 50.0), const Offset(54.0, 42.0), const Offset(66.0, 32.0), const Offset(76.0, 40.0), const Offset(74.0, 58.0), const Offset(62.0, 72.0), const Offset(46.0, 78.0)],
      ];
    case '᪔':
      return [
        [const Offset(54.0, 26.0), const Offset(42.0, 32.0), const Offset(34.0, 46.0), const Offset(38.0, 60.0), const Offset(50.0, 66.0), const Offset(66.0, 60.0), const Offset(72.0, 44.0), const Offset(68.0, 30.0), const Offset(56.0, 26.0), const Offset(44.0, 36.0), const Offset(40.0, 54.0), const Offset(46.0, 72.0), const Offset(60.0, 80.0), const Offset(76.0, 76.0)],
      ];
    case '᪕':
      return [
        [const Offset(36.0, 30.0), const Offset(44.0, 24.0), const Offset(54.0, 28.0), const Offset(50.0, 38.0), const Offset(40.0, 38.0), const Offset(30.0, 30.0), const Offset(24.0, 44.0), const Offset(28.0, 60.0), const Offset(42.0, 70.0), const Offset(60.0, 70.0), const Offset(74.0, 58.0), const Offset(78.0, 40.0), const Offset(74.0, 22.0)],
      ];
    case '᪖':
      return [
        [const Offset(58.0, 24.0), const Offset(44.0, 26.0), const Offset(32.0, 38.0), const Offset(28.0, 54.0), const Offset(36.0, 68.0), const Offset(52.0, 72.0), const Offset(68.0, 64.0), const Offset(72.0, 48.0), const Offset(62.0, 36.0), const Offset(48.0, 38.0), const Offset(38.0, 48.0), const Offset(42.0, 58.0), const Offset(52.0, 60.0)],
      ];
    case '᪗':
      return [
        [const Offset(26.0, 32.0), const Offset(40.0, 22.0), const Offset(56.0, 22.0), const Offset(68.0, 30.0), const Offset(64.0, 46.0), const Offset(52.0, 56.0), const Offset(40.0, 66.0), const Offset(38.0, 78.0), const Offset(48.0, 86.0), const Offset(62.0, 84.0), const Offset(74.0, 74.0)],
      ];
    case '᪘':
      return [
        [const Offset(38.0, 26.0), const Offset(48.0, 22.0), const Offset(58.0, 28.0), const Offset(54.0, 40.0), const Offset(44.0, 46.0), const Offset(34.0, 54.0), const Offset(30.0, 68.0), const Offset(40.0, 78.0), const Offset(56.0, 78.0), const Offset(68.0, 68.0), const Offset(66.0, 52.0), const Offset(54.0, 44.0), const Offset(44.0, 38.0)],
      ];
    case '᪙':
      return [
        [const Offset(34.0, 52.0), const Offset(42.0, 42.0), const Offset(54.0, 44.0), const Offset(50.0, 56.0), const Offset(40.0, 58.0), const Offset(32.0, 48.0), const Offset(32.0, 34.0), const Offset(44.0, 22.0), const Offset(62.0, 24.0), const Offset(74.0, 36.0), const Offset(76.0, 54.0), const Offset(68.0, 70.0), const Offset(54.0, 78.0), const Offset(40.0, 78.0)],
      ];
    default:
      return null;
  }
}

import 'package:flutter/material.dart';
/// CENTRALIZED AUTHENTIC LN-TILOK STROKE COORDINATES (100x100 Grid)
List<List<Offset>> getStrokeData(String char) {
  if (char.startsWith('\u1a60') && char.length > 1) {
    final baseChar = char.substring(1);
    final baseStrokes = getStrokeData(baseChar);
    return baseStrokes.map((stroke) {
      return stroke.map((p) => Offset(p.dx * 0.65 + 17.5, p.dy * 0.65 + 26)).toList();
    }).toList();
  }
  final c = getConsonantStrokePaths(char);
  if (c != null) return c;
  final v = getVowelStrokePaths(char);
  if (v != null) return v;
  final t = getToneStrokePaths(char);
  if (t != null) return t;
  final n = getNumberStrokePaths(char);
  if (n != null) return n;
  return [[const Offset(25, 50), const Offset(50, 25), const Offset(75, 50)]];
}

List<List<Offset>>? getConsonantStrokePaths(String char) {
  switch (char) {
    case 'ᨠ': // กะ (ก)
      return [
        [const Offset(48.3, 82.5), const Offset(50.0, 73.5), const Offset(50.0, 64.4), const Offset(50.0, 55.4), const Offset(50.0, 46.3), const Offset(49.4, 37.2), const Offset(46.0, 28.2), const Offset(39.7, 20.8), const Offset(33.4, 19.1), const Offset(27.0, 22.4), const Offset(22.5, 27.4), const Offset(19.6, 34.8), const Offset(17.9, 42.2), const Offset(16.7, 51.2), const Offset(17.3, 59.5), const Offset(19.0, 68.5), const Offset(21.9, 74.3), const Offset(26.5, 78.4), const Offset(28.2, 71.0), const Offset(33.9, 69.4), const Offset(36.8, 76.8), const Offset(32.2, 80.9), const Offset(28.8, 77.6)],
      ];
    case 'ᨡ': // ขะ (ข)
      return [
        [const Offset(85.0, 85.0), const Offset(84.4, 78.4), const Offset(83.2, 71.8), const Offset(80.8, 65.2), const Offset(76.7, 58.6), const Offset(70.2, 52.0), const Offset(71.4, 45.4), const Offset(73.7, 38.8), const Offset(74.3, 32.2), const Offset(73.1, 25.7), const Offset(67.8, 19.1), const Offset(60.1, 17.5), const Offset(54.2, 20.1), const Offset(50.0, 23.6), const Offset(42.3, 23.1), const Offset(34.6, 18.0), const Offset(26.9, 17.5), const Offset(19.7, 22.1), const Offset(18.0, 28.7), const Offset(23.3, 30.7), const Offset(30.4, 27.7), const Offset(35.2, 31.2), const Offset(28.6, 34.8), const Offset(22.7, 31.7), const Offset(26.3, 28.7)],
      ];
    case 'ᨢ': // ขะ หางยาว (ฃ)
      return [
        [const Offset(85.0, 19.7), const Offset(72.3, 17.2), const Offset(59.6, 15.9), const Offset(47.0, 15.6), const Offset(34.3, 17.5), const Offset(23.3, 22.3), const Offset(17.8, 28.2), const Offset(16.7, 35.5), const Offset(19.4, 42.4), const Offset(29.9, 42.7), const Offset(40.4, 45.6), const Offset(51.4, 45.3), const Offset(64.1, 43.4), const Offset(71.2, 48.7), const Offset(71.8, 56.0), const Offset(67.9, 62.9), const Offset(56.9, 60.7), const Offset(44.2, 59.1), const Offset(31.5, 58.8), const Offset(22.2, 62.9), const Offset(29.9, 67.3), const Offset(42.6, 67.3), const Offset(55.2, 66.1), const Offset(64.1, 63.9)],
      ];
    case 'ᨣ': // ก๊ะ (ค)
      return [
        [const Offset(85.0, 63.0), const Offset(82.0, 74.4), const Offset(77.8, 80.9), const Offset(67.1, 80.9), const Offset(72.4, 73.6), const Offset(80.2, 62.2), const Offset(80.8, 50.0), const Offset(77.2, 37.8), const Offset(68.8, 26.4), const Offset(59.9, 20.7), const Offset(50.9, 18.3), const Offset(41.9, 19.1), const Offset(32.9, 24.0), const Offset(26.4, 29.7), const Offset(22.2, 36.2), const Offset(18.6, 45.9), const Offset(17.4, 57.3), const Offset(19.8, 68.7), const Offset(24.0, 76.0), const Offset(30.0, 72.0), const Offset(38.3, 75.2), const Offset(33.5, 81.7), const Offset(31.8, 81.7)],
      ];
    case 'ᨤ': // ก๊ะ หางยาว (ฅ)
      return [
        [const Offset(85.0, 18.3), const Offset(74.5, 16.6), const Offset(64.1, 15.8), const Offset(53.6, 16.2), const Offset(43.1, 17.4), const Offset(32.6, 20.3), const Offset(25.5, 24.0), const Offset(20.0, 29.7), const Offset(17.8, 36.6), const Offset(17.2, 44.3), const Offset(19.4, 52.0), const Offset(23.8, 59.0), const Offset(34.3, 54.1), const Offset(44.8, 51.6), const Offset(55.2, 52.0), const Offset(63.5, 54.5), const Offset(70.1, 58.1), const Offset(76.2, 64.2), const Offset(77.3, 71.6), const Offset(71.8, 78.1), const Offset(64.1, 82.2), const Offset(74.0, 83.0), const Offset(81.1, 75.6), const Offset(81.1, 74.0)],
      ];
    case 'ᨥ': // ก๊ะ ระฆัง (ฆ)
      return [
        [const Offset(41.2, 58.4), const Offset(39.4, 67.3), const Offset(35.3, 75.3), const Offset(30.7, 80.2), const Offset(25.1, 81.8), const Offset(19.6, 77.8), const Offset(16.8, 68.1), const Offset(18.2, 58.4), const Offset(23.3, 51.2), const Offset(28.8, 49.6), const Offset(34.3, 49.6), const Offset(39.9, 46.4), const Offset(42.2, 36.7), const Offset(40.8, 27.1), const Offset(36.6, 19.8), const Offset(32.0, 25.5), const Offset(27.4, 27.9), const Offset(22.4, 19.8), const Offset(18.2, 23.0), const Offset(16.4, 31.9), const Offset(18.7, 37.5), const Offset(22.4, 41.6), const Offset(17.8, 42.4), const Offset(17.8, 38.3)],
      ];
    case 'ᨦ': // งะ (ง)
      return [
        [const Offset(22.8, 24.5), const Offset(27.6, 24.5), const Offset(32.4, 21.9), const Offset(37.1, 20.0), const Offset(41.9, 18.8), const Offset(46.7, 18.2), const Offset(51.5, 17.5), const Offset(56.3, 18.2), const Offset(60.5, 18.8), const Offset(65.3, 20.7), const Offset(69.4, 22.6), const Offset(73.0, 25.7), const Offset(77.2, 30.8), const Offset(80.2, 35.8), const Offset(82.0, 40.9), const Offset(82.6, 45.3), const Offset(83.2, 49.7), const Offset(82.6, 54.7), const Offset(82.6, 59.8), const Offset(80.8, 64.8), const Offset(80.2, 69.2), const Offset(78.4, 73.6), const Offset(76.6, 77.4), const Offset(74.2, 81.8), const Offset(72.4, 85.0)],
      ];
    case 'ᨧ': // จะ (จ)
      return [
        [const Offset(15.0, 43.3), const Offset(20.2, 35.0), const Offset(27.4, 26.7), const Offset(34.6, 21.7), const Offset(41.8, 19.2), const Offset(49.0, 18.3), const Offset(56.2, 18.3), const Offset(63.4, 20.8), const Offset(70.0, 24.2), const Offset(73.9, 28.3), const Offset(77.8, 33.3), const Offset(81.1, 41.7), const Offset(82.4, 50.8), const Offset(81.1, 60.0), const Offset(78.5, 66.7), const Offset(71.3, 74.2), const Offset(64.1, 79.2), const Offset(56.9, 80.8), const Offset(49.7, 81.7), const Offset(42.5, 80.8), const Offset(35.3, 79.2), const Offset(28.1, 75.0), const Offset(22.9, 66.7), const Offset(18.9, 64.2)],
      ];
    case 'ᨨ': // ฉะ (ฉ)
      return [
        [const Offset(29.1, 25.3), const Offset(29.7, 33.3), const Offset(23.6, 35.7), const Offset(19.3, 29.3), const Offset(21.8, 21.4), const Offset(27.9, 18.2), const Offset(34.0, 19.0), const Offset(38.9, 23.0), const Offset(41.4, 30.9), const Offset(42.0, 38.9), const Offset(42.0, 46.8), const Offset(42.0, 54.8), const Offset(42.0, 62.7), const Offset(35.9, 61.1), const Offset(29.7, 59.5), const Offset(23.6, 61.1), const Offset(19.3, 65.9), const Offset(18.1, 73.1), const Offset(21.1, 80.2), const Offset(26.7, 82.6), const Offset(32.8, 81.0), const Offset(38.9, 74.7), const Offset(41.4, 66.7), const Offset(42.0, 63.5)],
      ];
    case 'ᨩ': // จ๊ะ (ช)
      return [
        [const Offset(21.8, 24.4), const Offset(24.7, 23.8), const Offset(27.5, 23.1), const Offset(30.4, 21.7), const Offset(33.2, 21.1), const Offset(36.1, 19.7), const Offset(38.9, 19.0), const Offset(41.7, 18.4), const Offset(44.6, 17.7), const Offset(47.4, 17.0), const Offset(50.3, 17.0), const Offset(53.1, 17.0), const Offset(56.0, 17.0), const Offset(58.8, 17.0), const Offset(61.7, 17.0), const Offset(64.5, 17.7), const Offset(66.8, 18.4), const Offset(69.6, 19.7), const Offset(71.9, 21.1), const Offset(74.2, 21.7), const Offset(76.5, 23.1), const Offset(78.2, 25.1), const Offset(80.4, 27.1), const Offset(82.2, 29.8), const Offset(83.9, 33.2), const Offset(85.0, 35.2)],
        [const Offset(73.6, 85.0), const Offset(74.8, 81.0), const Offset(75.3, 76.9), const Offset(76.5, 72.9), const Offset(76.5, 68.8), const Offset(76.5, 64.8), const Offset(76.5, 60.8), const Offset(75.3, 56.7), const Offset(74.2, 52.7), const Offset(72.5, 48.7), const Offset(70.2, 44.6), const Offset(66.8, 40.6), const Offset(63.4, 38.6), const Offset(60.0, 37.2), const Offset(56.5, 36.5), const Offset(53.1, 35.9), const Offset(49.7, 35.9), const Offset(46.3, 37.2), const Offset(44.0, 39.2), const Offset(42.9, 43.3), const Offset(44.0, 46.0), const Offset(47.4, 46.0), const Offset(50.9, 43.9), const Offset(52.0, 39.9), const Offset(52.6, 36.5)],
      ];
    case 'ᨪ': // ซะ (ซ)
      return [
        [const Offset(22.3, 52.2), const Offset(22.9, 49.3), const Offset(21.8, 46.4), const Offset(20.6, 43.4), const Offset(19.5, 40.5), const Offset(19.5, 37.6), const Offset(19.5, 34.7), const Offset(20.1, 31.8), const Offset(21.2, 28.9), const Offset(23.5, 25.9), const Offset(26.3, 23.0), const Offset(30.8, 20.1), const Offset(35.3, 18.6), const Offset(39.8, 17.2), const Offset(44.4, 16.5), const Offset(48.9, 16.1), const Offset(53.4, 16.1), const Offset(57.9, 16.1), const Offset(62.4, 16.5), const Offset(66.4, 16.8), const Offset(70.9, 17.6), const Offset(74.8, 18.3), const Offset(79.4, 19.4), const Offset(83.9, 20.5), const Offset(85.0, 20.8)],
        [const Offset(73.1, 85.0), const Offset(74.3, 82.8), const Offset(75.4, 80.6), const Offset(76.0, 78.4), const Offset(76.0, 76.2), const Offset(76.5, 74.1), const Offset(76.0, 71.9), const Offset(75.4, 69.7), const Offset(74.3, 67.5), const Offset(72.6, 65.3), const Offset(69.8, 63.1), const Offset(66.4, 60.9), const Offset(63.0, 59.8), const Offset(59.6, 59.1), const Offset(56.2, 58.8), const Offset(52.8, 58.4), const Offset(49.4, 58.4), const Offset(46.0, 59.1), const Offset(43.2, 60.6), const Offset(43.2, 62.8), const Offset(46.0, 64.2), const Offset(49.4, 63.5), const Offset(51.7, 61.3), const Offset(52.3, 59.1), const Offset(52.3, 58.8)],
      ];
    case 'ᨫ': // จ๊ะ ช้าง (ฌ)
      return [
        [const Offset(20.9, 22.9), const Offset(23.0, 22.9), const Offset(25.2, 22.3), const Offset(27.3, 21.2), const Offset(29.4, 20.6), const Offset(31.6, 19.5), const Offset(33.7, 19.0), const Offset(35.8, 18.4), const Offset(38.0, 17.8), const Offset(40.1, 17.3), const Offset(42.3, 17.3), const Offset(44.4, 17.3), const Offset(46.5, 17.3), const Offset(48.7, 17.3), const Offset(50.8, 17.3), const Offset(52.9, 17.3), const Offset(55.1, 17.8), const Offset(57.2, 17.8), const Offset(58.8, 18.4), const Offset(61.0, 19.5), const Offset(63.1, 20.6), const Offset(65.2, 21.8), const Offset(66.3, 22.9), const Offset(68.4, 24.6), const Offset(70.0, 26.9), const Offset(71.1, 28.5), const Offset(72.2, 30.2), const Offset(72.2, 30.8)],
        [const Offset(64.2, 72.6), const Offset(64.7, 69.2), const Offset(65.2, 65.8), const Offset(65.8, 62.4), const Offset(65.8, 59.0), const Offset(65.8, 55.6), const Offset(65.8, 52.3), const Offset(64.7, 48.9), const Offset(63.6, 45.5), const Offset(62.0, 42.1), const Offset(59.4, 38.7), const Offset(56.1, 35.9), const Offset(52.9, 34.2), const Offset(49.7, 33.6), const Offset(46.5, 33.1), const Offset(43.3, 33.6), const Offset(40.1, 34.8), const Offset(38.0, 36.5), const Offset(38.0, 39.3), const Offset(40.1, 42.1), const Offset(43.3, 41.0), const Offset(45.5, 38.1), const Offset(46.0, 34.8), const Offset(46.0, 33.6)],
        [const Offset(71.1, 17.8), const Offset(72.2, 17.8), const Offset(73.2, 17.3), const Offset(74.3, 16.7), const Offset(75.4, 16.7), const Offset(76.5, 16.7), const Offset(77.5, 17.3), const Offset(78.6, 17.3), const Offset(79.7, 17.8), const Offset(80.2, 18.4), const Offset(81.3, 19.5), const Offset(81.8, 20.1), const Offset(82.3, 21.2), const Offset(82.9, 21.8), const Offset(82.9, 22.9), const Offset(83.4, 24.0), const Offset(83.9, 25.2), const Offset(83.9, 26.3), const Offset(84.5, 27.4), const Offset(84.5, 28.5), const Offset(85.0, 29.7), const Offset(85.0, 30.8), const Offset(85.0, 31.4)],
      ];
    case 'ᨬ': // ยะ หญิง (ญ)
      return [
        [const Offset(20.2, 39.0), const Offset(19.8, 44.1), const Offset(23.6, 47.0), const Offset(28.3, 49.6), const Offset(33.6, 50.0), const Offset(39.3, 48.3), const Offset(44.5, 43.7), const Offset(46.4, 38.6), const Offset(46.4, 33.6), const Offset(46.4, 28.5), const Offset(46.4, 23.4), const Offset(43.6, 18.4), const Offset(37.9, 19.6), const Offset(35.0, 22.2), const Offset(29.3, 20.9), const Offset(24.0, 17.5), const Offset(19.8, 19.6), const Offset(17.4, 23.0), const Offset(17.4, 28.1), const Offset(21.7, 30.6), const Offset(25.5, 27.2), const Offset(27.9, 31.4), const Offset(22.1, 31.4), const Offset(21.7, 31.4)],
      ];
    case 'ᨭ': // ฏะ (ฏ)
      return [
        [const Offset(15.6, 57.0), const Offset(20.1, 50.2), const Offset(26.4, 44.4), const Offset(34.3, 42.5), const Offset(42.3, 41.6), const Offset(50.3, 41.1), const Offset(58.3, 39.6), const Offset(66.2, 37.2), const Offset(70.2, 30.9), const Offset(69.6, 24.2), const Offset(63.9, 17.9), const Offset(56.0, 17.9), const Offset(49.7, 20.8), const Offset(42.9, 23.2), const Offset(34.9, 19.8), const Offset(27.0, 16.9), const Offset(20.1, 19.3), const Offset(17.8, 26.1), const Offset(21.3, 30.9), const Offset(25.8, 25.6), const Offset(32.1, 27.1), const Offset(29.8, 32.9), const Offset(23.0, 30.9), const Offset(22.4, 31.9)],
      ];
    case 'ᨮ': // ฐะ (ฐ)
      return [
        [const Offset(27.6, 54.1), const Offset(24.5, 52.4), const Offset(20.7, 47.6), const Offset(18.2, 42.7), const Offset(17.5, 37.8), const Offset(16.9, 32.9), const Offset(18.2, 28.0), const Offset(20.7, 23.1), const Offset(24.5, 19.9), const Offset(28.2, 19.1), const Offset(32.0, 19.1), const Offset(35.8, 19.9), const Offset(39.0, 22.3), const Offset(40.9, 24.8), const Offset(39.0, 28.8), const Offset(35.2, 28.0), const Offset(32.7, 29.7), const Offset(30.8, 32.9), const Offset(30.8, 37.0), const Offset(33.9, 40.2), const Offset(37.7, 40.2), const Offset(40.9, 36.2), const Offset(42.1, 31.3), const Offset(39.6, 29.7), const Offset(41.5, 28.8)],
      ];
    case 'ᨯ': // ดะ (ด)
      return [
        [const Offset(15.6, 57.0), const Offset(20.1, 50.2), const Offset(26.4, 44.4), const Offset(34.3, 42.5), const Offset(42.3, 41.6), const Offset(50.3, 41.1), const Offset(58.3, 39.6), const Offset(66.2, 37.2), const Offset(70.2, 30.9), const Offset(69.6, 24.2), const Offset(63.9, 17.9), const Offset(56.0, 17.9), const Offset(49.7, 20.8), const Offset(42.9, 23.2), const Offset(34.9, 19.8), const Offset(27.0, 16.9), const Offset(20.1, 19.3), const Offset(17.8, 26.1), const Offset(21.3, 30.9), const Offset(25.8, 25.6), const Offset(32.1, 27.1), const Offset(29.8, 32.9), const Offset(23.0, 30.9), const Offset(22.4, 31.9)],
      ];
    case 'ᨰ': // ต๊ะ (ฑ)
      return [
        [const Offset(85.0, 43.8), const Offset(80.3, 26.5), const Offset(70.0, 18.3), const Offset(73.1, 29.0), const Offset(78.8, 41.4), const Offset(79.8, 58.6), const Offset(75.1, 73.5), const Offset(64.3, 80.9), const Offset(54.4, 67.7), const Offset(46.6, 71.8), const Offset(39.4, 79.2), const Offset(28.5, 81.7), const Offset(18.1, 73.5), const Offset(21.2, 56.2), const Offset(32.1, 49.6), const Offset(43.0, 49.6), const Offset(52.9, 40.5), const Offset(50.8, 23.2), const Offset(40.4, 24.1), const Offset(30.0, 25.7), const Offset(20.2, 21.6), const Offset(17.1, 37.2), const Offset(25.4, 41.4), const Offset(18.1, 38.9)],
      ];
    case 'ᨱ': // ณะ (ณ)
      return [
        [const Offset(85.0, 58.1), const Offset(80.5, 72.8), const Offset(70.0, 82.6), const Offset(76.5, 67.1), const Offset(82.0, 49.2), const Offset(79.5, 31.3), const Offset(69.5, 19.1), const Offset(59.5, 24.0), const Offset(54.5, 39.4), const Offset(58.5, 55.7), const Offset(59.0, 72.8), const Offset(50.0, 81.7), const Offset(41.5, 68.7), const Offset(44.5, 50.8), const Offset(45.5, 32.9), const Offset(36.5, 19.9), const Offset(25.5, 20.7), const Offset(19.0, 32.1), const Offset(16.5, 49.2), const Offset(18.5, 66.3), const Offset(23.5, 76.0), const Offset(32.5, 73.6), const Offset(25.0, 79.3), const Offset(25.5, 80.1)],
      ];
    case 'ᨲ': // ตะ (ต)
      return [
        [const Offset(85.0, 58.1), const Offset(82.4, 71.2), const Offset(75.1, 83.4), const Offset(70.9, 76.9), const Offset(78.7, 63.0), const Offset(81.9, 49.2), const Offset(80.8, 35.3), const Offset(74.0, 21.5), const Offset(65.1, 19.1), const Offset(56.8, 26.4), const Offset(49.5, 32.9), const Offset(41.6, 20.7), const Offset(32.8, 18.3), const Offset(23.9, 25.6), const Offset(19.2, 35.3), const Offset(17.1, 46.7), const Offset(18.1, 60.6), const Offset(23.9, 73.6), const Offset(30.7, 79.3), const Offset(39.6, 78.5), const Offset(48.4, 67.1), const Offset(52.1, 53.3), const Offset(51.6, 39.4), const Offset(52.6, 33.7)],
      ];
    case 'ᨳ': // ถะ (ถ)
      return [
        [const Offset(23.4, 26.4), const Offset(26.5, 27.2), const Offset(29.5, 25.6), const Offset(32.5, 24.0), const Offset(35.5, 22.3), const Offset(38.5, 21.5), const Offset(41.6, 19.9), const Offset(44.6, 19.1), const Offset(47.6, 19.1), const Offset(50.6, 18.3), const Offset(53.6, 17.4), const Offset(56.6, 17.4), const Offset(59.7, 17.4), const Offset(62.7, 18.3), const Offset(65.7, 19.1), const Offset(68.1, 19.9), const Offset(71.1, 21.5), const Offset(74.1, 23.1), const Offset(76.6, 25.6), const Offset(79.0, 28.0), const Offset(80.8, 31.3), const Offset(82.6, 33.7), const Offset(84.4, 36.2), const Offset(85.0, 37.8)],
      ];
    case 'ᨴ': // ต๊ะ ทหาร (ท)
      return [
        [const Offset(65.0, 57.0), const Offset(67.7, 55.4), const Offset(71.0, 52.9), const Offset(73.0, 48.8), const Offset(73.0, 44.6), const Offset(70.3, 40.5), const Offset(67.0, 38.1), const Offset(63.7, 35.6), const Offset(60.3, 33.1), const Offset(57.0, 31.5), const Offset(53.7, 30.6), const Offset(50.3, 30.6), const Offset(47.0, 31.5), const Offset(43.7, 32.3), const Offset(40.3, 33.9), const Offset(37.0, 36.4), const Offset(33.7, 40.5), const Offset(33.0, 43.8), const Offset(35.0, 45.5), const Offset(38.3, 43.8), const Offset(41.7, 43.8), const Offset(43.7, 47.1), const Offset(43.0, 50.4), const Offset(39.7, 51.2), const Offset(36.3, 51.2), const Offset(33.7, 47.9), const Offset(33.7, 46.3)],
      ];
    case 'ᨵ': // ต๊ะ ธง (ธ)
      return [
        [const Offset(16.9, 34.4), const Offset(24.6, 26.8), const Offset(33.0, 21.7), const Offset(41.3, 19.2), const Offset(49.7, 18.4), const Offset(58.0, 19.2), const Offset(66.4, 23.4), const Offset(73.4, 28.5), const Offset(77.9, 33.6), const Offset(81.1, 42.0), const Offset(81.8, 53.0), const Offset(79.2, 63.1), const Offset(74.7, 71.5), const Offset(69.6, 78.3), const Offset(61.2, 74.9), const Offset(52.9, 65.6), const Offset(44.5, 63.9), const Offset(36.8, 69.8), const Offset(31.7, 76.6), const Offset(24.0, 68.1), const Offset(19.5, 57.2), const Offset(17.6, 46.2), const Offset(21.4, 36.9), const Offset(22.1, 36.9)],
      ];
    case 'ᨶ': // นะ (น)
      return [
        [const Offset(53.1, 40.8), const Offset(49.1, 37.6), const Offset(46.3, 34.3), const Offset(45.7, 31.0), const Offset(49.1, 31.0), const Offset(51.4, 33.8), const Offset(54.8, 36.1), const Offset(58.8, 36.6), const Offset(62.8, 36.1), const Offset(66.2, 33.3), const Offset(67.4, 30.0), const Offset(67.4, 26.7), const Offset(65.1, 23.5), const Offset(61.7, 20.2), const Offset(57.7, 18.3), const Offset(53.7, 17.3), const Offset(49.7, 16.9), const Offset(45.7, 16.4), const Offset(41.7, 16.4), const Offset(37.8, 16.9), const Offset(33.8, 17.8), const Offset(29.8, 19.2), const Offset(27.0, 20.6), const Offset(31.5, 18.8)],
      ];
    case 'ᨷ': // บะ (บ)
      return [
        [const Offset(85.0, 39.4), const Offset(84.4, 34.5), const Offset(83.2, 29.7), const Offset(81.3, 24.8), const Offset(78.2, 19.9), const Offset(74.6, 17.4), const Offset(70.9, 16.6), const Offset(67.2, 17.4), const Offset(64.7, 21.5), const Offset(64.7, 26.4), const Offset(68.4, 27.2), const Offset(72.1, 29.7), const Offset(75.2, 32.9), const Offset(77.6, 37.0), const Offset(78.9, 41.0), const Offset(80.1, 45.9), const Offset(80.1, 50.8), const Offset(79.5, 55.7), const Offset(78.9, 59.8), const Offset(76.4, 64.7), const Offset(74.6, 68.7), const Offset(72.1, 72.0), const Offset(67.8, 75.2), const Offset(69.6, 74.4)],
      ];
    case 'ᨸ': // ปะ (ป)
      return [
        [const Offset(85.0, 15.4), const Offset(76.3, 16.2), const Offset(67.6, 20.8), const Offset(63.5, 26.2), const Offset(63.0, 33.2), const Offset(64.1, 39.9), const Offset(65.6, 46.9), const Offset(67.6, 53.9), const Offset(69.2, 60.6), const Offset(69.2, 67.6), const Offset(67.1, 73.8), const Offset(62.5, 78.4), const Offset(55.9, 81.3), const Offset(47.2, 83.3), const Offset(38.5, 82.9), const Offset(29.8, 81.7), const Offset(21.1, 76.7), const Offset(17.0, 69.7), const Offset(19.1, 62.6), const Offset(27.3, 58.5), const Offset(28.3, 51.9), const Offset(20.6, 53.5), const Offset(27.8, 55.6), const Offset(29.8, 55.6)],
      ];
    case 'ᨹ': // ผะ (ผ)
      return [
        [const Offset(28.8, 54.5), const Offset(25.2, 54.5), const Offset(22.2, 49.6), const Offset(19.2, 44.6), const Offset(17.4, 39.7), const Offset(16.8, 34.8), const Offset(17.4, 29.8), const Offset(19.2, 24.9), const Offset(22.8, 20.8), const Offset(26.4, 18.3), const Offset(30.0, 18.3), const Offset(33.5, 18.3), const Offset(37.1, 20.8), const Offset(39.5, 24.1), const Offset(40.1, 28.2), const Offset(36.5, 27.4), const Offset(32.9, 27.4), const Offset(30.6, 29.8), const Offset(30.0, 34.8), const Offset(31.2, 38.9), const Offset(34.1, 40.5), const Offset(37.7, 38.9), const Offset(40.1, 34.8), const Offset(40.7, 29.8), const Offset(37.7, 29.0)],
      ];
    case 'ᨺ': // ฝะ (ฝ)
      return [
        [const Offset(31.1, 70.8), const Offset(28.2, 70.8), const Offset(26.5, 69.2), const Offset(23.6, 67.1), const Offset(21.9, 65.0), const Offset(21.3, 62.9), const Offset(21.3, 60.8), const Offset(21.9, 58.8), const Offset(23.6, 56.7), const Offset(26.5, 55.0), const Offset(29.3, 54.6), const Offset(32.2, 54.2), const Offset(35.1, 54.2), const Offset(37.4, 55.0), const Offset(39.7, 56.2), const Offset(41.4, 58.3), const Offset(39.1, 59.2), const Offset(36.2, 58.3), const Offset(33.4, 59.2), const Offset(32.2, 60.8), const Offset(32.2, 62.9), const Offset(35.1, 64.2), const Offset(38.0, 64.2), const Offset(40.8, 62.9), const Offset(41.4, 60.8), const Offset(41.4, 59.2)],
      ];
    case 'ᨻ': // ป๊ะ (พ)
      return [
        [const Offset(62.1, 80.9), const Offset(69.9, 75.9), const Offset(77.2, 66.9), const Offset(81.4, 56.2), const Offset(81.4, 45.5), const Offset(79.0, 34.8), const Offset(72.9, 24.1), const Offset(65.1, 17.5), const Offset(57.2, 19.1), const Offset(50.0, 24.9), const Offset(42.2, 19.9), const Offset(34.3, 17.5), const Offset(27.1, 24.1), const Offset(22.2, 30.6), const Offset(18.6, 38.9), const Offset(16.8, 48.8), const Offset(17.4, 59.5), const Offset(20.4, 66.9), const Offset(25.3, 75.1), const Offset(30.1, 74.3), const Offset(33.7, 67.7), const Offset(38.5, 74.3), const Offset(34.3, 80.1), const Offset(30.1, 79.2)],
      ];
    case 'ᨼ': // ฟะ (ฟ)
      return [
        [const Offset(83.4, 22.4), const Offset(73.1, 19.5), const Offset(62.8, 17.5), const Offset(52.4, 16.6), const Offset(42.1, 16.6), const Offset(31.8, 18.7), const Offset(23.7, 23.2), const Offset(18.3, 30.2), const Offset(16.6, 37.6), const Offset(17.2, 45.5), const Offset(18.8, 53.3), const Offset(26.4, 54.5), const Offset(36.7, 51.2), const Offset(45.4, 54.9), const Offset(55.7, 51.6), const Offset(66.0, 53.3), const Offset(73.1, 59.9), const Offset(75.8, 66.9), const Offset(74.1, 73.9), const Offset(67.1, 79.6), const Offset(58.4, 82.9), const Offset(69.8, 82.9), const Offset(76.9, 75.5), const Offset(79.0, 71.0)],
      ];
    case 'ᨽ': // ป๊ะ สำเภา (ภ)
      return [
        [const Offset(44.5, 62.2), const Offset(42.9, 69.5), const Offset(38.0, 76.9), const Offset(33.0, 80.9), const Offset(27.0, 81.7), const Offset(21.0, 79.3), const Offset(17.2, 71.2), const Offset(21.0, 68.7), const Offset(27.0, 69.5), const Offset(33.0, 67.1), const Offset(39.1, 61.4), const Offset(42.3, 52.4), const Offset(42.9, 43.5), const Offset(42.3, 34.5), const Offset(39.6, 25.6), const Offset(33.6, 19.9), const Offset(27.6, 19.9), const Offset(22.1, 24.0), const Offset(18.3, 28.0), const Offset(17.7, 35.3), const Offset(21.0, 40.2), const Offset(27.0, 35.3), const Offset(26.5, 26.4), const Offset(24.8, 23.1)],
      ];
    case 'ᨾ': // มะ (ม)
      return [
        [const Offset(23.2, 28.6), const Offset(18.2, 24.5), const Offset(23.2, 19.1), const Offset(30.1, 23.2), const Offset(28.9, 30.6), const Offset(22.6, 36.1), const Offset(17.5, 43.5), const Offset(16.9, 51.0), const Offset(20.0, 57.8), const Offset(23.8, 63.3), const Offset(29.5, 67.3), const Offset(37.1, 70.0), const Offset(44.6, 72.1), const Offset(52.2, 72.1), const Offset(59.8, 70.7), const Offset(67.3, 67.3), const Offset(74.9, 61.2), const Offset(76.2, 53.7), const Offset(68.6, 50.3), const Offset(61.0, 49.0), const Offset(53.5, 49.7), const Offset(46.5, 53.1), const Offset(50.3, 57.8), const Offset(55.4, 52.4), const Offset(55.4, 49.7)],
      ];
    case 'ᨿ': // ยะ (ย)
      return [
        [const Offset(23.0, 34.5), const Offset(18.2, 28.8), const Offset(20.3, 20.7), const Offset(26.2, 19.9), const Offset(29.4, 28.0), const Offset(26.8, 37.0), const Offset(24.1, 41.0), const Offset(19.3, 49.2), const Offset(17.7, 57.3), const Offset(20.3, 66.3), const Offset(24.1, 73.6), const Offset(28.9, 79.3), const Offset(34.2, 80.9), const Offset(40.1, 77.7), const Offset(46.0, 71.2), const Offset(49.7, 63.0), const Offset(49.7, 54.1), const Offset(50.3, 45.1), const Offset(49.2, 36.2), const Offset(44.4, 28.0), const Offset(46.5, 20.7), const Offset(51.9, 23.1), const Offset(54.5, 30.5), const Offset(55.6, 37.8)],
      ];
    case 'ᩀ': // ร้า (ยย)
      return [
        [const Offset(23.0, 34.5), const Offset(18.2, 28.8), const Offset(20.3, 20.7), const Offset(26.2, 19.9), const Offset(29.4, 28.0), const Offset(26.8, 37.0), const Offset(24.1, 41.0), const Offset(19.3, 49.2), const Offset(17.7, 57.3), const Offset(20.3, 66.3), const Offset(24.1, 73.6), const Offset(28.9, 79.3), const Offset(34.2, 80.9), const Offset(40.1, 77.7), const Offset(46.0, 71.2), const Offset(49.7, 63.0), const Offset(49.7, 54.1), const Offset(50.3, 45.1), const Offset(49.2, 36.2), const Offset(44.4, 28.0), const Offset(46.5, 20.7), const Offset(51.9, 23.1), const Offset(54.5, 30.5), const Offset(55.6, 37.8)],
      ];
    case 'ᩁ': // ระ (ร)
      return [
        [const Offset(60.2, 15.0), const Offset(61.9, 15.8), const Offset(63.0, 16.6), const Offset(64.1, 17.3), const Offset(65.8, 18.9), const Offset(66.9, 19.7), const Offset(68.6, 22.0), const Offset(69.8, 23.6), const Offset(70.3, 25.1), const Offset(71.5, 25.9), const Offset(72.0, 27.4), const Offset(72.6, 29.0), const Offset(73.7, 30.6), const Offset(74.3, 32.1), const Offset(75.4, 33.7), const Offset(76.0, 36.0), const Offset(77.1, 38.3), const Offset(77.7, 40.7), const Offset(78.8, 43.0), const Offset(79.4, 44.6), const Offset(79.9, 46.1), const Offset(80.5, 48.4), const Offset(81.0, 50.8), const Offset(82.2, 53.1), const Offset(82.7, 55.4), const Offset(83.3, 57.0), const Offset(83.9, 59.3), const Offset(84.4, 61.7), const Offset(85.0, 63.2)],
        [const Offset(24.6, 38.3), const Offset(26.9, 35.2), const Offset(29.7, 32.1), const Offset(30.8, 27.4), const Offset(34.2, 22.8), const Offset(37.6, 20.4), const Offset(41.0, 19.7), const Offset(44.4, 18.1), const Offset(47.7, 18.1), const Offset(51.1, 18.9), const Offset(54.0, 20.4), const Offset(57.3, 22.8), const Offset(59.6, 25.9), const Offset(61.9, 29.0), const Offset(63.5, 31.3), const Offset(66.4, 36.0), const Offset(68.1, 39.1), const Offset(69.8, 43.0), const Offset(72.0, 46.9), const Offset(73.1, 50.8), const Offset(75.4, 55.4), const Offset(76.5, 58.6), const Offset(78.2, 63.2), const Offset(78.8, 64.0)],
      ];
    case 'ᩂ': // ฤ (ฤ)
      return [
        [const Offset(61.1, 85.0), const Offset(61.1, 82.9), const Offset(61.1, 80.8), const Offset(61.7, 78.7), const Offset(61.1, 76.6), const Offset(61.1, 74.5), const Offset(60.5, 72.4), const Offset(59.9, 70.3), const Offset(58.8, 68.2), const Offset(58.2, 66.1), const Offset(57.0, 64.0), const Offset(54.7, 61.9), const Offset(52.3, 59.9), const Offset(49.4, 58.6), const Offset(46.5, 58.2), const Offset(43.6, 57.3), const Offset(40.7, 57.8), const Offset(38.3, 59.0), const Offset(37.2, 61.1), const Offset(38.3, 62.4), const Offset(41.2, 62.4), const Offset(44.2, 60.7), const Offset(44.8, 58.6), const Offset(45.3, 57.3)],
      ];
    case 'ᩃ': // ละ (ล)
      return [
        [const Offset(66.0, 28.4), const Offset(67.0, 28.4), const Offset(68.0, 27.6), const Offset(68.0, 26.0), const Offset(68.0, 24.4), const Offset(68.5, 22.9), const Offset(69.0, 21.3), const Offset(70.1, 20.5), const Offset(71.1, 18.9), const Offset(72.1, 18.1), const Offset(73.2, 17.4), const Offset(74.2, 17.4), const Offset(75.2, 18.1), const Offset(76.2, 18.1), const Offset(77.3, 18.1), const Offset(78.3, 19.7), const Offset(79.3, 20.5), const Offset(79.9, 21.3), const Offset(80.4, 22.1), const Offset(80.4, 23.7), const Offset(80.9, 24.4), const Offset(81.4, 26.0), const Offset(81.9, 26.8), const Offset(82.4, 28.4), const Offset(82.9, 29.9), const Offset(82.9, 31.5), const Offset(83.5, 33.1), const Offset(84.0, 34.7), const Offset(84.0, 36.2), const Offset(84.5, 37.8), const Offset(84.5, 39.4), const Offset(85.0, 41.0), const Offset(85.0, 42.5)],
      ];
    case 'ᩄ': // ฦ (ฦ)
      return [
        [const Offset(76.0, 63.4), const Offset(68.9, 59.5), const Offset(61.2, 57.8), const Offset(53.5, 57.8), const Offset(45.8, 58.6), const Offset(38.1, 60.8), const Offset(33.0, 63.0), const Offset(29.1, 65.6), const Offset(25.9, 70.3), const Offset(25.9, 75.5), const Offset(29.8, 80.2), const Offset(37.5, 83.3), const Offset(45.2, 83.7), const Offset(52.9, 82.8), const Offset(60.6, 80.7), const Offset(68.3, 77.7), const Offset(74.1, 72.9), const Offset(66.4, 69.9), const Offset(58.7, 69.0), const Offset(51.0, 69.9), const Offset(46.5, 72.9), const Offset(51.6, 74.2), const Offset(52.9, 69.4)],
      ];
    case 'ᩅ': // วะ (ว)
      return [
        [const Offset(45.7, 18.2), const Offset(53.7, 18.2), const Offset(61.7, 19.8), const Offset(68.3, 23.9), const Offset(73.0, 28.7), const Offset(77.7, 35.1), const Offset(81.0, 43.2), const Offset(81.0, 52.8), const Offset(79.0, 62.5), const Offset(75.0, 69.7), const Offset(68.3, 76.1), const Offset(60.3, 80.2), const Offset(52.3, 81.0), const Offset(44.3, 81.8), const Offset(36.3, 78.6), const Offset(28.3, 72.9), const Offset(21.0, 63.3), const Offset(18.3, 53.6), const Offset(18.3, 44.0), const Offset(22.3, 34.3), const Offset(29.7, 25.5), const Offset(37.7, 20.6), const Offset(45.0, 19.0)],
      ];
    case 'ᩆ': // ศะ (ศ)
      return [
        [const Offset(54.8, 51.3), const Offset(60.5, 47.4), const Offset(66.2, 43.5), const Offset(65.1, 37.0), const Offset(59.4, 34.4), const Offset(53.7, 32.5), const Offset(48.0, 31.9), const Offset(42.3, 32.5), const Offset(36.6, 33.8), const Offset(30.9, 37.0), const Offset(26.4, 40.3), const Offset(24.1, 43.5), const Offset(21.8, 46.8), const Offset(19.0, 51.9), const Offset(17.3, 57.8), const Offset(17.3, 64.3), const Offset(19.0, 70.7), const Offset(21.3, 75.3), const Offset(24.1, 78.5), const Offset(28.1, 75.9), const Offset(33.2, 74.0), const Offset(37.8, 78.5), const Offset(34.3, 82.4), const Offset(28.7, 81.1), const Offset(30.9, 82.4)],
      ];
    case 'ᩇ': // ษะ (ษ)
      return [
        [const Offset(24.3, 34.2), const Offset(24.8, 30.8), const Offset(26.6, 27.4), const Offset(28.3, 23.9), const Offset(29.5, 20.5), const Offset(32.4, 18.4), const Offset(35.2, 17.7), const Offset(38.1, 18.4), const Offset(41.0, 20.5), const Offset(43.3, 23.2), const Offset(44.5, 26.0), const Offset(45.1, 28.7), const Offset(45.7, 31.5), const Offset(45.7, 34.9), const Offset(45.7, 38.3), const Offset(44.5, 41.1), const Offset(43.3, 38.3), const Offset(42.2, 34.9), const Offset(41.0, 31.5), const Offset(38.7, 28.0), const Offset(35.8, 26.0), const Offset(32.9, 26.0), const Offset(30.0, 26.0), const Offset(27.1, 27.4), const Offset(26.0, 29.4)],
      ];
    case 'ᩈ': // สะ (ส)
      return [
        [const Offset(24.3, 37.8), const Offset(24.8, 33.7), const Offset(26.6, 29.7), const Offset(28.3, 25.6), const Offset(29.5, 21.5), const Offset(32.4, 19.1), const Offset(35.2, 18.3), const Offset(38.1, 19.1), const Offset(41.0, 21.5), const Offset(43.3, 24.8), const Offset(44.5, 28.0), const Offset(45.1, 31.3), const Offset(45.7, 34.5), const Offset(45.7, 38.6), const Offset(45.7, 42.7), const Offset(44.5, 45.9), const Offset(43.3, 42.7), const Offset(42.2, 38.6), const Offset(41.0, 34.5), const Offset(38.7, 30.5), const Offset(35.8, 28.0), const Offset(32.9, 28.0), const Offset(30.0, 28.0), const Offset(27.1, 29.7), const Offset(26.0, 32.1)],
      ];
    case 'ᩉ': // หะ (ห)
      return [
        [const Offset(84.4, 56.8), const Offset(83.8, 62.5), const Offset(82.1, 68.1), const Offset(80.3, 72.9), const Offset(79.1, 76.1), const Offset(77.4, 79.4), const Offset(73.8, 81.8), const Offset(69.7, 81.0), const Offset(67.4, 75.3), const Offset(69.7, 71.3), const Offset(73.8, 67.3), const Offset(77.4, 62.5), const Offset(79.7, 56.8), const Offset(80.9, 51.2), const Offset(80.9, 45.6), const Offset(80.3, 39.9), const Offset(77.9, 34.3), const Offset(75.6, 28.7), const Offset(71.5, 23.0), const Offset(67.4, 19.8), const Offset(63.2, 19.0), const Offset(59.1, 18.2), const Offset(55.0, 19.8), const Offset(55.6, 19.8)],
      ];
    case 'ᩊ': // ฬะ (ฬ)
      return [
        [const Offset(23.1, 21.8), const Offset(27.4, 21.8), const Offset(31.7, 20.1), const Offset(36.1, 18.8), const Offset(40.4, 18.0), const Offset(44.7, 17.1), const Offset(49.1, 17.1), const Offset(53.4, 17.1), const Offset(57.7, 17.6), const Offset(61.5, 18.0), const Offset(65.8, 19.3), const Offset(68.9, 21.0), const Offset(72.0, 22.3), const Offset(73.8, 24.0), const Offset(75.7, 25.7), const Offset(77.6, 27.4), const Offset(78.8, 29.9), const Offset(80.0, 32.5), const Offset(80.7, 35.5), const Offset(80.7, 38.5), const Offset(80.0, 41.5), const Offset(78.8, 44.5), const Offset(77.6, 47.4), const Offset(76.3, 50.0), const Offset(73.8, 52.6), const Offset(72.6, 54.3)],
      ];
    case 'ᩋ': // อะ (อ)
      return [
        [const Offset(29.6, 44.6), const Offset(26.5, 44.6), const Offset(23.3, 43.3), const Offset(20.1, 39.9), const Offset(18.2, 36.5), const Offset(17.5, 33.2), const Offset(17.5, 29.8), const Offset(18.2, 26.4), const Offset(20.1, 23.1), const Offset(23.3, 20.4), const Offset(26.5, 18.4), const Offset(29.6, 17.7), const Offset(32.8, 17.7), const Offset(35.4, 19.0), const Offset(37.9, 20.4), const Offset(40.5, 22.4), const Offset(41.7, 25.1), const Offset(41.7, 28.5), const Offset(41.7, 31.8), const Offset(39.2, 34.5), const Offset(36.0, 35.9), const Offset(32.8, 35.2), const Offset(30.3, 31.8), const Offset(30.9, 28.5), const Offset(34.1, 26.4), const Offset(37.3, 26.4), const Offset(37.9, 26.4)],
        [const Offset(54.5, 27.1), const Offset(60.2, 29.1), const Offset(57.6, 35.9), const Offset(50.6, 34.5), const Offset(49.4, 27.1), const Offset(54.5, 20.4), const Offset(61.5, 17.7), const Offset(68.5, 18.4), const Offset(73.5, 21.1), const Offset(76.7, 25.8), const Offset(79.3, 33.2), const Offset(79.9, 40.6), const Offset(79.9, 48.0), const Offset(78.6, 55.4), const Offset(72.9, 54.7), const Offset(65.9, 52.7), const Offset(58.9, 52.7), const Offset(53.8, 56.7), const Offset(53.2, 64.1), const Offset(58.3, 68.8), const Offset(65.3, 69.5), const Offset(72.3, 66.8), const Offset(78.0, 60.1), const Offset(78.0, 56.7)],
      ];
    case 'ᩌ': // ฮะ (ฮ)
      return [
        [const Offset(85.0, 36.3), const Offset(83.2, 44.0), const Offset(77.4, 48.7), const Offset(67.9, 48.7), const Offset(73.8, 42.7), const Offset(80.9, 35.5), const Offset(79.7, 27.8), const Offset(72.6, 20.1), const Offset(62.1, 17.1), const Offset(54.4, 18.0), const Offset(46.8, 23.1), const Offset(47.9, 30.4), const Offset(52.1, 36.8), const Offset(49.7, 44.0), const Offset(40.3, 49.6), const Offset(29.7, 49.6), const Offset(19.1, 44.9), const Offset(17.4, 37.2), const Offset(25.0, 29.5), const Offset(30.9, 21.8), const Offset(23.8, 17.1), const Offset(19.1, 23.1), const Offset(27.4, 21.4), const Offset(29.1, 21.0)],
      ];
    default:
      return null;
  }
}

List<List<Offset>>? getVowelStrokePaths(String char) {
  switch (char) {
    case 'ᩡ': // อะ
      return [
        [const Offset(85.0, 43.2), const Offset(83.7, 39.5), const Offset(79.6, 35.9), const Offset(76.9, 32.3), const Offset(74.2, 28.6), const Offset(68.8, 25.0), const Offset(63.5, 22.3), const Offset(58.1, 20.5), const Offset(52.7, 18.6), const Offset(47.3, 17.7), const Offset(41.9, 17.7), const Offset(36.5, 17.7), const Offset(31.2, 19.5), const Offset(28.5, 22.3), const Offset(23.1, 24.1), const Offset(19.0, 26.8), const Offset(17.7, 30.5), const Offset(17.7, 34.1), const Offset(19.0, 36.8), const Offset(23.1, 37.7), const Offset(28.5, 36.8), const Offset(31.2, 33.2), const Offset(31.2, 29.5), const Offset(29.8, 25.9), const Offset(28.5, 24.1)],
        [const Offset(85.0, 85.0), const Offset(82.3, 81.4), const Offset(79.6, 77.7), const Offset(76.9, 74.1), const Offset(72.9, 70.5), const Offset(67.5, 66.8), const Offset(62.1, 63.2), const Offset(56.7, 62.3), const Offset(51.3, 60.5), const Offset(46.0, 60.5), const Offset(40.6, 60.5), const Offset(35.2, 60.5), const Offset(29.8, 62.3), const Offset(27.1, 65.0), const Offset(21.7, 66.8), const Offset(19.0, 70.5), const Offset(17.7, 74.1), const Offset(17.7, 77.7), const Offset(20.4, 80.5), const Offset(25.8, 80.5), const Offset(29.8, 76.8), const Offset(31.2, 73.2), const Offset(31.2, 69.5), const Offset(27.1, 65.9)],
      ];
    case 'ᩣ': // อา
      return [
        [const Offset(85.0, 59.0), const Offset(81.5, 67.7), const Offset(76.1, 74.8), const Offset(69.9, 79.5), const Offset(61.1, 82.6), const Offset(50.4, 83.4), const Offset(42.5, 77.1), const Offset(53.1, 75.6), const Offset(63.7, 70.8), const Offset(72.6, 62.2), const Offset(77.0, 52.8), const Offset(78.8, 43.3), const Offset(76.1, 33.9), const Offset(67.3, 24.4), const Offset(56.6, 18.9), const Offset(46.0, 17.4), const Offset(35.4, 18.9), const Offset(24.7, 23.7), const Offset(18.5, 29.9), const Offset(22.1, 35.4), const Offset(28.3, 39.4), const Offset(25.6, 44.9), const Offset(17.7, 37.0), const Offset(19.4, 40.2)],
      ];
    case 'ᩤ': // อา (กางก่อม)
      return [
        [const Offset(85.0, 71.3), const Offset(82.3, 77.3), const Offset(77.0, 82.0), const Offset(68.6, 83.7), const Offset(69.1, 79.9), const Offset(76.5, 74.8), const Offset(78.1, 67.9), const Offset(77.6, 61.1), const Offset(77.6, 54.3), const Offset(78.1, 47.4), const Offset(78.1, 40.6), const Offset(78.6, 33.8), const Offset(72.8, 27.0), const Offset(64.8, 20.1), const Offset(56.4, 17.1), const Offset(47.9, 16.3), const Offset(39.4, 16.3), const Offset(30.9, 18.8), const Offset(22.4, 22.7), const Offset(17.1, 28.2), const Offset(17.7, 34.2), const Offset(25.1, 34.2), const Offset(18.7, 35.9), const Offset(20.3, 32.9)],
      ];
    case 'ᩥ': // อิ
      return [
        [const Offset(36.5, 70.5), const Offset(38.3, 59.7), const Offset(46.4, 58.4), const Offset(50.0, 64.5), const Offset(49.1, 75.3), const Offset(42.8, 80.2), const Offset(34.7, 80.2), const Offset(26.7, 76.6), const Offset(19.5, 65.7), const Offset(17.7, 54.8), const Offset(18.6, 44.0), const Offset(23.1, 33.1), const Offset(31.2, 24.7), const Offset(39.2, 19.8), const Offset(47.3, 18.6), const Offset(55.4, 18.6), const Offset(63.5, 19.8), const Offset(70.6, 24.7), const Offset(76.0, 30.7), const Offset(81.4, 41.6), const Offset(82.3, 52.4), const Offset(81.4, 63.3), const Offset(77.8, 72.9), const Offset(71.5, 80.2), const Offset(67.1, 85.0)],
      ];
    case 'ᩦ': // อี
      return [
        [const Offset(31.7, 70.5), const Offset(33.3, 60.9), const Offset(39.2, 59.7), const Offset(43.3, 68.1), const Offset(41.7, 76.6), const Offset(35.0, 80.2), const Offset(28.3, 80.2), const Offset(21.7, 72.9), const Offset(18.3, 63.3), const Offset(17.5, 53.6), const Offset(18.3, 44.0), const Offset(20.8, 34.3), const Offset(26.7, 24.7), const Offset(33.3, 21.0), const Offset(40.0, 18.6), const Offset(46.7, 18.6), const Offset(53.3, 21.0), const Offset(59.2, 24.7), const Offset(64.2, 31.9), const Offset(66.7, 41.6), const Offset(68.3, 51.2), const Offset(67.5, 60.9), const Offset(65.0, 70.5), const Offset(61.7, 77.8), const Offset(56.7, 83.8)],
        [const Offset(76.7, 21.0), const Offset(77.5, 23.4), const Offset(78.3, 24.7), const Offset(79.2, 25.9), const Offset(79.2, 28.3), const Offset(80.0, 30.7), const Offset(80.8, 33.1), const Offset(80.8, 35.5), const Offset(81.7, 37.9), const Offset(81.7, 40.3), const Offset(82.5, 42.8), const Offset(82.5, 45.2), const Offset(82.5, 47.6), const Offset(82.5, 50.0), const Offset(81.7, 52.4), const Offset(81.7, 54.8), const Offset(81.7, 57.2), const Offset(81.7, 59.7), const Offset(80.8, 62.1), const Offset(80.0, 64.5), const Offset(79.2, 66.9), const Offset(79.2, 68.1), const Offset(79.2, 69.3), const Offset(77.5, 71.7), const Offset(76.7, 74.1), const Offset(76.7, 75.3), const Offset(75.0, 77.8), const Offset(73.3, 79.0), const Offset(73.3, 80.2), const Offset(71.7, 81.4), const Offset(71.7, 82.6), const Offset(70.0, 83.8), const Offset(69.2, 85.0)],
      ];
    case 'ᩧ': // อึ
      return [
        [const Offset(32.9, 70.5), const Offset(37.2, 59.7), const Offset(44.0, 63.3), const Offset(44.0, 75.3), const Offset(38.0, 80.2), const Offset(28.7, 79.0), const Offset(20.1, 68.1), const Offset(17.6, 54.8), const Offset(19.3, 41.6), const Offset(26.1, 28.3), const Offset(35.5, 22.2), const Offset(44.9, 18.6), const Offset(54.3, 18.6), const Offset(62.8, 21.0), const Offset(71.3, 27.1), const Offset(76.5, 34.3), const Offset(80.7, 42.8), const Offset(81.6, 54.8), const Offset(78.2, 63.3), const Offset(68.8, 56.0), const Offset(61.1, 63.3), const Offset(62.0, 76.6), const Offset(69.6, 81.4), const Offset(79.0, 74.1), const Offset(74.8, 59.7)],
      ];
    case 'ᩨ': // อือ
      return [
        [const Offset(26.2, 55.5), const Offset(34.8, 51.8), const Offset(39.4, 65.4), const Offset(36.8, 77.6), const Offset(28.2, 81.3), const Offset(19.6, 71.5), const Offset(17.0, 55.5), const Offset(18.3, 39.6), const Offset(25.6, 26.1), const Offset(34.2, 19.9), const Offset(42.7, 18.7), const Offset(51.3, 19.9), const Offset(59.2, 24.8), const Offset(65.8, 39.6), const Offset(59.9, 45.7), const Offset(52.6, 53.1), const Offset(50.7, 67.8), const Offset(55.3, 78.9), const Offset(63.9, 77.6), const Offset(68.5, 62.9), const Offset(68.5, 46.9), const Offset(74.4, 46.9), const Offset(83.0, 56.8), const Offset(85.0, 60.4)],
      ];
    case 'ᩩ': // อุ
      return [
        [const Offset(19.6, 16.9), const Offset(18.4, 26.7), const Offset(17.3, 38.3), const Offset(17.3, 50.0), const Offset(17.3, 61.7), const Offset(19.0, 71.4), const Offset(22.4, 73.3), const Offset(25.8, 75.3), const Offset(29.2, 77.2), const Offset(32.1, 79.2), const Offset(35.5, 79.2), const Offset(38.9, 79.2), const Offset(42.3, 81.1), const Offset(45.7, 81.1), const Offset(49.1, 79.2), const Offset(52.6, 79.2), const Offset(56.0, 77.2), const Offset(59.4, 77.2), const Offset(62.8, 77.2), const Offset(66.2, 75.3), const Offset(69.6, 73.3), const Offset(73.0, 73.3), const Offset(76.5, 71.4), const Offset(79.9, 71.4), const Offset(83.3, 71.4), const Offset(85.0, 71.4)],
      ];
    case 'ᩪ': // อู
      return [
        [const Offset(18.0, 20.4), const Offset(18.0, 22.2), const Offset(18.0, 24.0), const Offset(17.5, 25.8), const Offset(17.5, 27.6), const Offset(17.0, 29.4), const Offset(17.5, 29.4), const Offset(17.0, 31.2), const Offset(17.0, 32.9), const Offset(16.5, 34.7), const Offset(16.5, 36.5), const Offset(16.5, 38.3), const Offset(16.5, 40.1), const Offset(16.5, 41.9), const Offset(16.5, 43.7), const Offset(16.5, 45.5), const Offset(16.5, 47.3), const Offset(16.5, 49.1), const Offset(16.5, 50.9), const Offset(16.5, 52.7), const Offset(16.5, 54.5), const Offset(16.5, 56.3), const Offset(16.5, 58.1), const Offset(16.5, 59.9), const Offset(16.5, 61.7), const Offset(16.5, 63.5), const Offset(16.5, 65.3), const Offset(16.5, 67.1)],
        [const Offset(26.3, 20.4), const Offset(25.4, 31.2), const Offset(25.4, 41.9), const Offset(25.4, 52.7), const Offset(25.4, 63.5), const Offset(27.3, 70.6), const Offset(30.3, 72.4), const Offset(33.2, 76.0), const Offset(36.2, 76.0), const Offset(39.2, 77.8), const Offset(42.1, 77.8), const Offset(45.1, 79.6), const Offset(48.0, 79.6), const Offset(51.0, 79.6), const Offset(53.9, 77.8), const Offset(56.9, 77.8), const Offset(59.9, 76.0), const Offset(62.8, 76.0), const Offset(65.8, 74.2), const Offset(68.7, 74.2), const Offset(71.7, 74.2), const Offset(74.6, 72.4), const Offset(77.6, 70.6), const Offset(80.6, 70.6), const Offset(83.5, 70.6), const Offset(85.0, 70.6)],
      ];
    case 'ᩫ': // โอ๊ะ/อัวะ
      return [
        [const Offset(19.6, 16.9), const Offset(18.4, 26.7), const Offset(17.3, 38.3), const Offset(17.3, 50.0), const Offset(17.3, 61.7), const Offset(19.0, 71.4), const Offset(22.4, 73.3), const Offset(25.8, 75.3), const Offset(29.2, 77.2), const Offset(32.1, 79.2), const Offset(35.5, 79.2), const Offset(38.9, 79.2), const Offset(42.3, 81.1), const Offset(45.7, 81.1), const Offset(49.1, 79.2), const Offset(52.6, 79.2), const Offset(56.0, 77.2), const Offset(59.4, 77.2), const Offset(62.8, 77.2), const Offset(66.2, 75.3), const Offset(69.6, 73.3), const Offset(73.0, 73.3), const Offset(76.5, 71.4), const Offset(79.9, 71.4), const Offset(83.3, 71.4), const Offset(85.0, 71.4)],
      ];
    case 'ᩬ': // ออ
      return [
        [const Offset(18.0, 20.4), const Offset(18.0, 22.2), const Offset(18.0, 24.0), const Offset(17.5, 25.8), const Offset(17.5, 27.6), const Offset(17.0, 29.4), const Offset(17.5, 29.4), const Offset(17.0, 31.2), const Offset(17.0, 32.9), const Offset(16.5, 34.7), const Offset(16.5, 36.5), const Offset(16.5, 38.3), const Offset(16.5, 40.1), const Offset(16.5, 41.9), const Offset(16.5, 43.7), const Offset(16.5, 45.5), const Offset(16.5, 47.3), const Offset(16.5, 49.1), const Offset(16.5, 50.9), const Offset(16.5, 52.7), const Offset(16.5, 54.5), const Offset(16.5, 56.3), const Offset(16.5, 58.1), const Offset(16.5, 59.9), const Offset(16.5, 61.7), const Offset(16.5, 63.5), const Offset(16.5, 65.3), const Offset(16.5, 67.1)],
        [const Offset(26.3, 20.4), const Offset(25.4, 31.2), const Offset(25.4, 41.9), const Offset(25.4, 52.7), const Offset(25.4, 63.5), const Offset(27.3, 70.6), const Offset(30.3, 72.4), const Offset(33.2, 76.0), const Offset(36.2, 76.0), const Offset(39.2, 77.8), const Offset(42.1, 77.8), const Offset(45.1, 79.6), const Offset(48.0, 79.6), const Offset(51.0, 79.6), const Offset(53.9, 77.8), const Offset(56.9, 77.8), const Offset(59.9, 76.0), const Offset(62.8, 76.0), const Offset(65.8, 74.2), const Offset(68.7, 74.2), const Offset(71.7, 74.2), const Offset(74.6, 72.4), const Offset(77.6, 70.6), const Offset(80.6, 70.6), const Offset(83.5, 70.6), const Offset(85.0, 70.6)],
      ];
    case 'ᩭ': // ออย
      return [
        [const Offset(16.9, 15.8), const Offset(30.6, 15.8), const Offset(44.2, 15.8), const Offset(57.8, 15.8), const Offset(71.4, 15.8), const Offset(83.1, 17.3), const Offset(83.1, 27.9), const Offset(83.1, 38.6), const Offset(83.1, 49.2), const Offset(83.1, 59.9), const Offset(83.1, 70.5), const Offset(83.1, 81.2), const Offset(71.4, 83.5), const Offset(57.8, 83.5), const Offset(44.2, 83.5), const Offset(30.6, 83.5), const Offset(16.9, 83.5), const Offset(16.0, 72.8), const Offset(16.0, 62.2), const Offset(16.0, 51.5), const Offset(16.0, 40.9), const Offset(16.0, 30.2), const Offset(16.0, 19.6), const Offset(16.9, 16.5)],
      ];
    case 'ᩮ': // เอ
      return [
        [const Offset(85.0, 44.8), const Offset(81.8, 37.5), const Offset(76.5, 30.3), const Offset(69.1, 23.0), const Offset(59.5, 18.2), const Offset(50.0, 18.2), const Offset(40.5, 19.8), const Offset(35.2, 23.9), const Offset(27.7, 29.5), const Offset(23.5, 35.9), const Offset(20.3, 42.4), const Offset(19.2, 49.6), const Offset(20.3, 56.8), const Offset(23.5, 63.3), const Offset(28.8, 68.9), const Offset(33.0, 72.9), const Offset(38.3, 77.0), const Offset(47.9, 78.6), const Offset(51.1, 72.9), const Offset(59.5, 69.7), const Offset(65.9, 72.9), const Offset(68.0, 78.6), const Offset(60.6, 81.0), const Offset(51.1, 79.4), const Offset(50.0, 79.4)],
      ];
    case 'ᩯ': // แอ
      return [
        [const Offset(85.0, 42.7), const Offset(82.9, 36.2), const Offset(80.2, 29.7), const Offset(76.5, 23.1), const Offset(72.2, 19.1), const Offset(67.9, 18.3), const Offset(63.6, 19.9), const Offset(59.4, 25.6), const Offset(56.7, 32.1), const Offset(55.1, 37.8), const Offset(54.0, 43.5), const Offset(53.5, 50.0), const Offset(54.0, 56.5), const Offset(55.1, 63.0), const Offset(56.7, 68.7), const Offset(59.9, 74.4), const Offset(62.6, 78.5), const Offset(65.8, 76.9), const Offset(65.2, 70.3), const Offset(69.0, 69.5), const Offset(71.6, 73.6), const Offset(72.2, 79.3), const Offset(67.9, 80.9), const Offset(65.8, 79.3)],
        [const Offset(46.5, 35.3), const Offset(44.4, 29.7), const Offset(41.2, 24.0), const Offset(37.4, 19.9), const Offset(33.7, 18.3), const Offset(30.0, 18.3), const Offset(26.2, 20.7), const Offset(23.5, 24.8), const Offset(20.3, 30.5), const Offset(18.7, 36.2), const Offset(17.7, 41.9), const Offset(17.1, 47.6), const Offset(17.1, 53.3), const Offset(17.7, 59.0), const Offset(18.7, 64.7), const Offset(20.3, 69.5), const Offset(23.5, 75.2), const Offset(26.8, 78.5), const Offset(28.4, 73.6), const Offset(29.4, 68.7), const Offset(32.6, 70.3), const Offset(34.8, 73.6), const Offset(35.3, 78.5), const Offset(32.6, 81.7), const Offset(28.9, 79.3), const Offset(28.4, 76.9)],
      ];
    case 'ᩰ': // โอ
      return [
        [const Offset(28.9, 79.2), const Offset(35.4, 78.8), const Offset(32.4, 83.2), const Offset(25.4, 80.5), const Offset(22.9, 74.3), const Offset(22.4, 68.1), const Offset(23.9, 61.8), const Offset(29.4, 56.0), const Offset(35.9, 52.5), const Offset(31.9, 47.1), const Offset(24.9, 45.3), const Offset(18.5, 42.2), const Offset(17.0, 36.0), const Offset(18.5, 29.7), const Offset(23.4, 23.5), const Offset(30.4, 19.5), const Offset(37.3, 17.7), const Offset(44.3, 16.3), const Offset(51.2, 16.8), const Offset(58.2, 17.2), const Offset(65.1, 18.1), const Offset(72.1, 19.0), const Offset(78.5, 20.4), const Offset(85.0, 21.7)],
      ];
    case 'ᩱ': // ใอ
      return [
        [const Offset(15.6, 28.3), const Offset(23.9, 25.2), const Offset(32.2, 22.5), const Offset(40.5, 19.4), const Offset(48.8, 17.7), const Offset(57.1, 16.8), const Offset(64.8, 17.7), const Offset(72.5, 20.8), const Offset(77.3, 24.3), const Offset(80.3, 28.7), const Offset(81.4, 34.5), const Offset(79.7, 40.7), const Offset(71.4, 42.9), const Offset(64.2, 45.6), const Offset(59.5, 48.2), const Offset(53.0, 52.7), const Offset(48.2, 58.4), const Offset(45.8, 64.6), const Offset(45.8, 70.8), const Offset(47.6, 77.0), const Offset(51.2, 81.0), const Offset(58.9, 83.2), const Offset(65.4, 80.6), const Offset(58.9, 77.9), const Offset(58.9, 78.4)],
      ];
    case 'ᩲ': // ไอ
      return [
        [const Offset(29.2, 23.0), const Offset(24.4, 24.4), const Offset(18.9, 23.5), const Offset(18.9, 20.4), const Offset(24.4, 18.6), const Offset(29.9, 17.7), const Offset(35.4, 17.2), const Offset(41.0, 16.8), const Offset(46.5, 16.3), const Offset(52.0, 16.3), const Offset(57.5, 16.8), const Offset(63.0, 17.2), const Offset(68.5, 17.7), const Offset(73.2, 18.1), const Offset(77.9, 20.4), const Offset(81.1, 22.1), const Offset(81.9, 25.3), const Offset(79.5, 28.4), const Offset(74.8, 30.2), const Offset(69.3, 30.2), const Offset(63.8, 30.6), const Offset(58.3, 31.5), const Offset(52.8, 32.4), const Offset(54.3, 32.4)],
      ];
    case 'ᩳ': // อือ (สระบน)
      return [
        [const Offset(47.9, 19.7), const Offset(54.1, 22.0), const Offset(60.3, 22.0), const Offset(66.5, 24.3), const Offset(70.6, 29.0), const Offset(76.8, 36.0), const Offset(76.8, 43.0), const Offset(76.8, 50.0), const Offset(76.8, 57.0), const Offset(74.7, 64.0), const Offset(70.6, 71.0), const Offset(64.4, 73.3), const Offset(58.2, 75.7), const Offset(52.1, 78.0), const Offset(45.9, 75.7), const Offset(39.7, 75.7), const Offset(33.5, 73.3), const Offset(27.4, 66.3), const Offset(23.2, 59.3), const Offset(21.2, 52.3), const Offset(21.2, 45.3), const Offset(23.2, 38.3), const Offset(27.4, 31.3), const Offset(33.5, 24.3), const Offset(39.7, 22.0), const Offset(45.9, 22.0)],
      ];
    case 'ᩴ': // อัง (นิคหิต)
      return [
        [const Offset(15.5, 83.4), const Offset(17.7, 80.1), const Offset(20.5, 76.9), const Offset(23.2, 74.4), const Offset(25.9, 72.8), const Offset(28.6, 70.3), const Offset(31.4, 67.9), const Offset(34.1, 65.5), const Offset(36.8, 63.0), const Offset(39.5, 60.6), const Offset(42.3, 57.3), const Offset(45.0, 54.9), const Offset(47.7, 52.4), const Offset(50.5, 50.0), const Offset(53.2, 47.6), const Offset(55.9, 45.1), const Offset(58.6, 42.7), const Offset(61.4, 40.2), const Offset(64.1, 37.0), const Offset(66.8, 33.7), const Offset(69.5, 31.3), const Offset(72.3, 28.8), const Offset(75.0, 25.6), const Offset(77.7, 23.1), const Offset(80.5, 19.9), const Offset(82.7, 17.4)],
      ];
    default:
      return null;
  }
}

List<List<Offset>>? getToneStrokePaths(String char) {
  switch (char) {
    case '᩵': // เอก (หย่อม)
      return [
        [const Offset(35.6, 43.7), const Offset(31.5, 40.1), const Offset(27.4, 36.5), const Offset(27.4, 32.9), const Offset(27.4, 29.4), const Offset(31.5, 27.6), const Offset(39.7, 25.8), const Offset(47.9, 25.8), const Offset(56.2, 25.8), const Offset(60.3, 27.6), const Offset(64.4, 31.2), const Offset(64.4, 34.7), const Offset(64.4, 38.3), const Offset(64.4, 41.9), const Offset(64.4, 45.5), const Offset(60.3, 49.1), const Offset(60.3, 52.7), const Offset(60.3, 56.3), const Offset(56.2, 59.9), const Offset(56.2, 63.5), const Offset(52.1, 67.1), const Offset(47.9, 70.6), const Offset(47.9, 72.4), const Offset(47.9, 76.0), const Offset(43.8, 79.6), const Offset(39.7, 83.2)],
      ];
    case '᩶': // โท (ซัด)
      return [
        [const Offset(16.8, 67.1), const Offset(15.9, 72.0), const Offset(15.9, 77.7), const Offset(18.6, 78.5), const Offset(21.8, 76.0), const Offset(24.9, 73.6), const Offset(28.1, 71.2), const Offset(31.3, 67.9), const Offset(34.4, 65.5), const Offset(37.6, 62.2), const Offset(40.7, 59.0), const Offset(43.9, 56.5), const Offset(47.1, 53.3), const Offset(50.2, 50.8), const Offset(53.4, 47.6), const Offset(56.5, 44.3), const Offset(59.7, 41.0), const Offset(62.9, 37.8), const Offset(66.0, 34.5), const Offset(69.2, 31.3), const Offset(72.4, 28.8), const Offset(75.5, 24.8), const Offset(78.7, 21.5), const Offset(81.8, 18.3), const Offset(82.7, 17.4)],
      ];
    case '᩷': // ตรี
      return [
        [const Offset(47.9, 19.8), const Offset(54.1, 22.2), const Offset(60.3, 22.2), const Offset(66.5, 24.7), const Offset(72.6, 29.5), const Offset(76.8, 36.7), const Offset(76.8, 44.0), const Offset(76.8, 51.2), const Offset(76.8, 58.4), const Offset(74.7, 65.7), const Offset(68.5, 70.5), const Offset(62.4, 75.3), const Offset(56.2, 75.3), const Offset(50.0, 77.8), const Offset(43.8, 75.3), const Offset(37.6, 75.3), const Offset(31.5, 70.5), const Offset(25.3, 65.7), const Offset(21.2, 58.4), const Offset(19.1, 51.2), const Offset(21.2, 44.0), const Offset(23.2, 36.7), const Offset(27.4, 29.5), const Offset(33.5, 24.7), const Offset(39.7, 22.2), const Offset(45.9, 22.2)],
      ];
    case '᩸': // จัตวา
      return [
        [const Offset(15.8, 82.9), const Offset(20.6, 74.4), const Offset(25.5, 74.4), const Offset(30.3, 72.3), const Offset(35.1, 68.0), const Offset(39.9, 63.8), const Offset(40.7, 51.1), const Offset(39.9, 38.3), const Offset(40.7, 25.6), const Offset(45.6, 21.4), const Offset(49.6, 29.8), const Offset(48.8, 42.6), const Offset(45.6, 55.3), const Offset(42.4, 59.5), const Offset(46.4, 68.0), const Offset(51.2, 72.3), const Offset(56.0, 76.5), const Offset(60.9, 78.6), const Offset(65.7, 76.5), const Offset(70.5, 74.4), const Offset(75.3, 70.2), const Offset(80.2, 63.8), const Offset(85.0, 55.3), const Offset(81.0, 63.8)],
      ];
    case '᩹': // กาชาด
      return [
        [const Offset(26.1, 33.9), const Offset(29.7, 32.0), const Offset(31.6, 28.2), const Offset(33.4, 24.5), const Offset(37.1, 20.7), const Offset(40.8, 18.8), const Offset(44.5, 16.9), const Offset(48.2, 16.9), const Offset(51.8, 18.8), const Offset(55.5, 18.8), const Offset(59.2, 20.7), const Offset(61.1, 22.6), const Offset(64.7, 22.6), const Offset(66.6, 24.5), const Offset(68.4, 26.4), const Offset(70.3, 28.2), const Offset(72.1, 32.0), const Offset(73.9, 33.9), const Offset(75.8, 37.7), const Offset(77.6, 39.6), const Offset(79.5, 43.4), const Offset(81.3, 47.2), const Offset(83.2, 50.9), const Offset(83.2, 54.7), const Offset(85.0, 58.5), const Offset(85.0, 60.4)],
      ];
    case '᩺': // การันต์ (ทัณฑฆาต)
      return [
        [const Offset(26.1, 33.9), const Offset(29.7, 32.0), const Offset(31.6, 28.2), const Offset(33.4, 24.5), const Offset(37.1, 20.7), const Offset(40.8, 18.8), const Offset(44.5, 16.9), const Offset(48.2, 16.9), const Offset(51.8, 18.8), const Offset(55.5, 18.8), const Offset(59.2, 20.7), const Offset(61.1, 22.6), const Offset(64.7, 22.6), const Offset(66.6, 24.5), const Offset(68.4, 26.4), const Offset(70.3, 28.2), const Offset(72.1, 32.0), const Offset(73.9, 33.9), const Offset(75.8, 37.7), const Offset(77.6, 39.6), const Offset(79.5, 43.4), const Offset(81.3, 47.2), const Offset(83.2, 50.9), const Offset(83.2, 54.7), const Offset(85.0, 58.5), const Offset(85.0, 60.4)],
      ];
    default:
      return null;
  }
}

List<List<Offset>>? getNumberStrokePaths(String char) {
  switch (char) {
    case '᪀': // เลข 0 โหรา
      return [
        [const Offset(42.8, 19.1), const Offset(50.4, 19.1), const Offset(57.9, 19.9), const Offset(64.7, 23.2), const Offset(70.7, 27.4), const Offset(76.0, 32.3), const Offset(79.7, 38.9), const Offset(82.0, 45.5), const Offset(82.0, 53.7), const Offset(81.2, 61.1), const Offset(76.7, 69.4), const Offset(69.2, 75.9), const Offset(61.7, 80.1), const Offset(54.1, 80.9), const Offset(46.6, 80.9), const Offset(39.1, 78.4), const Offset(31.6, 74.3), const Offset(24.0, 66.9), const Offset(19.5, 58.6), const Offset(18.0, 50.4), const Offset(18.8, 42.2), const Offset(21.8, 33.9), const Offset(28.5, 25.7), const Offset(36.1, 21.6), const Offset(39.8, 20.8)],
      ];
    case '᪁': // เลข 1 โหรา
      return [
        [const Offset(85.0, 20.7), const Offset(77.9, 17.9), const Offset(70.9, 16.7), const Offset(63.8, 16.1), const Offset(56.7, 17.3), const Offset(50.4, 21.3), const Offset(47.5, 24.8), const Offset(44.7, 29.3), const Offset(44.0, 35.1), const Offset(47.5, 39.1), const Offset(54.6, 39.1), const Offset(61.7, 41.4), const Offset(68.0, 44.8), const Offset(73.7, 50.6), const Offset(77.2, 56.3), const Offset(78.6, 62.0), const Offset(77.9, 67.8), const Offset(75.8, 73.0), const Offset(70.9, 77.0), const Offset(64.5, 79.3), const Offset(64.5, 83.3), const Offset(70.9, 83.9), const Offset(77.2, 79.8), const Offset(82.2, 74.1), const Offset(82.9, 70.7)],
      ];
    case '᪂': // เลข 2 โหรา
      return [
        [const Offset(83.2, 24.0), const Offset(74.5, 19.3), const Offset(64.9, 17.4), const Offset(55.2, 16.4), const Offset(45.6, 16.9), const Offset(36.0, 18.8), const Offset(29.0, 21.6), const Offset(22.9, 24.9), const Offset(18.5, 30.1), const Offset(17.6, 35.3), const Offset(17.6, 40.5), const Offset(17.6, 45.7), const Offset(17.6, 50.9), const Offset(17.6, 56.1), const Offset(17.6, 61.4), const Offset(17.6, 66.6), const Offset(17.6, 71.8), const Offset(19.4, 77.0), const Offset(25.5, 76.5), const Offset(34.2, 74.6), const Offset(38.6, 78.9), const Offset(34.2, 83.1), const Offset(24.6, 81.7), const Offset(24.6, 77.9)],
      ];
    case '᪃': // เลข 3 โหรา
      return [
        [const Offset(19.4, 54.7), const Offset(20.2, 53.2), const Offset(20.9, 51.7), const Offset(23.1, 50.2), const Offset(23.1, 48.8), const Offset(23.8, 47.3), const Offset(25.3, 45.8), const Offset(27.5, 44.8), const Offset(29.7, 44.3), const Offset(31.9, 44.3), const Offset(34.2, 44.3), const Offset(35.6, 44.8), const Offset(37.8, 45.8), const Offset(38.6, 46.8), const Offset(40.1, 47.8), const Offset(40.8, 48.8), const Offset(42.3, 49.8), const Offset(43.0, 51.2), const Offset(43.7, 52.2), const Offset(44.5, 53.7), const Offset(45.2, 54.7), const Offset(45.2, 56.2), const Offset(45.9, 57.7), const Offset(46.7, 59.2), const Offset(46.7, 60.7), const Offset(46.7, 62.2)],
      ];
    case '᪄': // เลข 4 โหรา
      return [
        [const Offset(42.8, 30.9), const Offset(44.4, 30.9), const Offset(46.1, 30.9), const Offset(47.8, 30.5), const Offset(49.4, 30.0), const Offset(51.1, 28.7), const Offset(52.8, 27.9), const Offset(53.9, 26.6), const Offset(55.0, 25.3), const Offset(55.6, 24.0), const Offset(56.1, 22.7), const Offset(56.1, 21.4), const Offset(55.6, 20.2), const Offset(55.0, 18.9), const Offset(53.3, 17.6), const Offset(51.7, 16.7), const Offset(50.0, 16.3), const Offset(48.3, 16.3), const Offset(46.7, 16.3), const Offset(45.0, 17.1), const Offset(44.4, 18.4), const Offset(44.4, 19.7), const Offset(45.6, 21.0), const Offset(47.2, 21.4), const Offset(48.9, 21.4), const Offset(50.6, 21.9), const Offset(51.7, 21.9)],
      ];
    case '᪅': // เลข 5 โหรา
      return [
        [const Offset(18.3, 31.8), const Offset(20.0, 31.5), const Offset(21.7, 30.8), const Offset(23.3, 30.5), const Offset(25.0, 30.2), const Offset(26.7, 29.8), const Offset(28.3, 29.2), const Offset(30.0, 28.5), const Offset(31.1, 27.6), const Offset(30.0, 26.6), const Offset(28.3, 26.0), const Offset(27.8, 25.0), const Offset(28.9, 24.0), const Offset(30.0, 23.4), const Offset(31.7, 23.4), const Offset(33.3, 23.4), const Offset(34.4, 23.7), const Offset(35.0, 24.7), const Offset(34.4, 25.6), const Offset(34.4, 26.6), const Offset(33.3, 27.3), const Offset(31.7, 27.3), const Offset(30.0, 28.9)],
        [const Offset(42.8, 44.4), const Offset(44.4, 44.0), const Offset(46.1, 44.0), const Offset(47.8, 44.0), const Offset(49.4, 43.7), const Offset(50.6, 43.1), const Offset(52.2, 42.1), const Offset(53.9, 41.1), const Offset(55.0, 40.2), const Offset(55.6, 39.2), const Offset(56.1, 38.2), const Offset(56.1, 37.3), const Offset(55.6, 36.3), const Offset(55.0, 35.3), const Offset(53.9, 34.4), const Offset(52.2, 33.7), const Offset(50.6, 33.4), const Offset(48.9, 33.1), const Offset(47.2, 33.4), const Offset(45.6, 33.4), const Offset(45.0, 34.0), const Offset(44.4, 35.0), const Offset(44.4, 36.0), const Offset(45.6, 36.6), const Offset(46.7, 36.9), const Offset(48.3, 37.3), const Offset(50.0, 37.3), const Offset(51.7, 37.3)],
      ];
    case '᪆': // เลข 6 โหรา
      return [
        [const Offset(48.5, 28.5), const Offset(50.7, 26.0), const Offset(52.9, 23.5), const Offset(53.6, 21.0), const Offset(56.6, 19.0), const Offset(60.2, 17.5), const Offset(63.9, 17.0), const Offset(67.5, 17.5), const Offset(71.1, 18.5), const Offset(73.3, 19.5), const Offset(75.5, 21.0), const Offset(77.7, 23.5), const Offset(79.9, 26.0), const Offset(80.6, 28.5), const Offset(82.1, 31.0), const Offset(82.8, 33.0), const Offset(83.5, 35.5), const Offset(83.5, 38.0), const Offset(84.3, 40.5), const Offset(84.3, 43.0), const Offset(84.3, 45.5), const Offset(84.3, 48.0), const Offset(84.3, 50.5), const Offset(84.3, 53.0), const Offset(84.3, 55.5), const Offset(84.3, 56.5)],
      ];
    case '᪇': // เลข 7 โหรา
      return [
        [const Offset(32.3, 54.5), const Offset(28.0, 54.5), const Offset(24.4, 51.2), const Offset(20.8, 46.3), const Offset(19.3, 41.4), const Offset(17.9, 36.4), const Offset(18.6, 31.5), const Offset(19.3, 26.5), const Offset(22.9, 22.4), const Offset(27.3, 19.1), const Offset(31.6, 19.1), const Offset(35.9, 19.9), const Offset(38.8, 22.4), const Offset(41.7, 25.7), const Offset(41.0, 29.8), const Offset(36.6, 28.2), const Offset(32.3, 29.8), const Offset(31.6, 33.1), const Offset(31.6, 38.1), const Offset(34.5, 40.5), const Offset(38.8, 40.5), const Offset(41.7, 35.6), const Offset(42.4, 30.6), const Offset(42.4, 29.8)],
      ];
    case '᪈': // เลข 8 โหรา
      return [
        [const Offset(40.1, 25.7), const Offset(43.9, 22.4), const Offset(48.5, 18.2), const Offset(55.3, 16.4), const Offset(62.2, 15.9), const Offset(68.3, 17.3), const Offset(73.6, 19.6), const Offset(78.2, 23.3), const Offset(80.4, 26.6), const Offset(82.0, 30.8), const Offset(82.7, 34.9), const Offset(82.7, 39.1), const Offset(82.7, 43.3), const Offset(82.7, 47.5), const Offset(82.7, 51.6), const Offset(82.7, 55.8), const Offset(82.7, 60.0), const Offset(82.7, 64.1), const Offset(82.7, 68.3), const Offset(82.0, 72.5), const Offset(80.4, 76.7), const Offset(78.2, 79.9), const Offset(72.8, 83.1), const Offset(66.0, 84.5), const Offset(59.1, 84.5), const Offset(57.6, 84.5)],
      ];
    case '᪉': // เลข 9 โหรา
      return [
        [const Offset(27.8, 85.0), const Offset(40.5, 84.5), const Offset(53.3, 82.1), const Offset(66.1, 76.8), const Offset(77.3, 65.7), const Offset(81.9, 53.6), const Offset(83.0, 41.6), const Offset(82.4, 29.5), const Offset(75.3, 17.9), const Offset(65.1, 21.8), const Offset(73.8, 30.4), const Offset(73.8, 42.5), const Offset(66.6, 52.2), const Offset(53.8, 53.1), const Offset(47.2, 43.0), const Offset(51.3, 30.9), const Offset(43.6, 19.3), const Offset(30.8, 17.9), const Offset(20.1, 26.6), const Offset(17.6, 37.2), const Offset(21.6, 48.8), const Offset(31.4, 47.3), const Offset(27.8, 53.6), const Offset(26.2, 49.8)],
      ];
    case '᪐': // เลข 0 เมือง
      return [
        [const Offset(42.8, 19.1), const Offset(50.4, 19.1), const Offset(57.9, 19.9), const Offset(64.7, 23.2), const Offset(70.7, 27.4), const Offset(76.0, 32.3), const Offset(79.7, 38.9), const Offset(82.0, 45.5), const Offset(82.0, 53.7), const Offset(81.2, 61.1), const Offset(76.7, 69.4), const Offset(69.2, 75.9), const Offset(61.7, 80.1), const Offset(54.1, 80.9), const Offset(46.6, 80.9), const Offset(39.1, 78.4), const Offset(31.6, 74.3), const Offset(24.0, 66.9), const Offset(19.5, 58.6), const Offset(18.0, 50.4), const Offset(18.8, 42.2), const Offset(21.8, 33.9), const Offset(28.5, 25.7), const Offset(36.1, 21.6), const Offset(39.8, 20.8)],
      ];
    case '᪑': // เลข 1 เมือง
      return [
        [const Offset(85.0, 20.7), const Offset(77.9, 17.9), const Offset(70.9, 16.7), const Offset(63.8, 16.1), const Offset(56.7, 17.3), const Offset(50.4, 21.3), const Offset(47.5, 24.8), const Offset(44.7, 29.3), const Offset(44.0, 35.1), const Offset(47.5, 39.1), const Offset(54.6, 39.1), const Offset(61.7, 41.4), const Offset(68.0, 44.8), const Offset(73.7, 50.6), const Offset(77.2, 56.3), const Offset(78.6, 62.0), const Offset(77.9, 67.8), const Offset(75.8, 73.0), const Offset(70.9, 77.0), const Offset(64.5, 79.3), const Offset(64.5, 83.3), const Offset(70.9, 83.9), const Offset(77.2, 79.8), const Offset(82.2, 74.1), const Offset(82.9, 70.7)],
      ];
    case '᪒': // เลข 2 เมือง
      return [
        [const Offset(83.2, 24.0), const Offset(74.5, 19.3), const Offset(64.9, 17.4), const Offset(55.2, 16.4), const Offset(45.6, 16.9), const Offset(36.0, 18.8), const Offset(29.0, 21.6), const Offset(22.9, 24.9), const Offset(18.5, 30.1), const Offset(17.6, 35.3), const Offset(17.6, 40.5), const Offset(17.6, 45.7), const Offset(17.6, 50.9), const Offset(17.6, 56.1), const Offset(17.6, 61.4), const Offset(17.6, 66.6), const Offset(17.6, 71.8), const Offset(19.4, 77.0), const Offset(25.5, 76.5), const Offset(34.2, 74.6), const Offset(38.6, 78.9), const Offset(34.2, 83.1), const Offset(24.6, 81.7), const Offset(24.6, 77.9)],
      ];
    case '᪓': // เลข 3 เมือง
      return [
        [const Offset(19.4, 54.7), const Offset(20.2, 53.2), const Offset(20.9, 51.7), const Offset(23.1, 50.2), const Offset(23.1, 48.8), const Offset(23.8, 47.3), const Offset(25.3, 45.8), const Offset(27.5, 44.8), const Offset(29.7, 44.3), const Offset(31.9, 44.3), const Offset(34.2, 44.3), const Offset(35.6, 44.8), const Offset(37.8, 45.8), const Offset(38.6, 46.8), const Offset(40.1, 47.8), const Offset(40.8, 48.8), const Offset(42.3, 49.8), const Offset(43.0, 51.2), const Offset(43.7, 52.2), const Offset(44.5, 53.7), const Offset(45.2, 54.7), const Offset(45.2, 56.2), const Offset(45.9, 57.7), const Offset(46.7, 59.2), const Offset(46.7, 60.7), const Offset(46.7, 62.2)],
      ];
    case '᪔': // เลข 4 เมือง
      return [
        [const Offset(42.8, 30.9), const Offset(44.4, 30.9), const Offset(46.1, 30.9), const Offset(47.8, 30.5), const Offset(49.4, 30.0), const Offset(51.1, 28.7), const Offset(52.8, 27.9), const Offset(53.9, 26.6), const Offset(55.0, 25.3), const Offset(55.6, 24.0), const Offset(56.1, 22.7), const Offset(56.1, 21.4), const Offset(55.6, 20.2), const Offset(55.0, 18.9), const Offset(53.3, 17.6), const Offset(51.7, 16.7), const Offset(50.0, 16.3), const Offset(48.3, 16.3), const Offset(46.7, 16.3), const Offset(45.0, 17.1), const Offset(44.4, 18.4), const Offset(44.4, 19.7), const Offset(45.6, 21.0), const Offset(47.2, 21.4), const Offset(48.9, 21.4), const Offset(50.6, 21.9), const Offset(51.7, 21.9)],
      ];
    case '᪕': // เลข 5 เมือง
      return [
        [const Offset(18.3, 31.8), const Offset(20.0, 31.5), const Offset(21.7, 30.8), const Offset(23.3, 30.5), const Offset(25.0, 30.2), const Offset(26.7, 29.8), const Offset(28.3, 29.2), const Offset(30.0, 28.5), const Offset(31.1, 27.6), const Offset(30.0, 26.6), const Offset(28.3, 26.0), const Offset(27.8, 25.0), const Offset(28.9, 24.0), const Offset(30.0, 23.4), const Offset(31.7, 23.4), const Offset(33.3, 23.4), const Offset(34.4, 23.7), const Offset(35.0, 24.7), const Offset(34.4, 25.6), const Offset(34.4, 26.6), const Offset(33.3, 27.3), const Offset(31.7, 27.3), const Offset(30.0, 28.9)],
        [const Offset(42.8, 44.4), const Offset(44.4, 44.0), const Offset(46.1, 44.0), const Offset(47.8, 44.0), const Offset(49.4, 43.7), const Offset(50.6, 43.1), const Offset(52.2, 42.1), const Offset(53.9, 41.1), const Offset(55.0, 40.2), const Offset(55.6, 39.2), const Offset(56.1, 38.2), const Offset(56.1, 37.3), const Offset(55.6, 36.3), const Offset(55.0, 35.3), const Offset(53.9, 34.4), const Offset(52.2, 33.7), const Offset(50.6, 33.4), const Offset(48.9, 33.1), const Offset(47.2, 33.4), const Offset(45.6, 33.4), const Offset(45.0, 34.0), const Offset(44.4, 35.0), const Offset(44.4, 36.0), const Offset(45.6, 36.6), const Offset(46.7, 36.9), const Offset(48.3, 37.3), const Offset(50.0, 37.3), const Offset(51.7, 37.3)],
      ];
    case '᪖': // เลข 6 เมือง
      return [
        [const Offset(48.5, 28.5), const Offset(50.7, 26.0), const Offset(52.9, 23.5), const Offset(53.6, 21.0), const Offset(56.6, 19.0), const Offset(60.2, 17.5), const Offset(63.9, 17.0), const Offset(67.5, 17.5), const Offset(71.1, 18.5), const Offset(73.3, 19.5), const Offset(75.5, 21.0), const Offset(77.7, 23.5), const Offset(79.9, 26.0), const Offset(80.6, 28.5), const Offset(82.1, 31.0), const Offset(82.8, 33.0), const Offset(83.5, 35.5), const Offset(83.5, 38.0), const Offset(84.3, 40.5), const Offset(84.3, 43.0), const Offset(84.3, 45.5), const Offset(84.3, 48.0), const Offset(84.3, 50.5), const Offset(84.3, 53.0), const Offset(84.3, 55.5), const Offset(84.3, 56.5)],
      ];
    case '᪗': // เลข 7 เมือง
      return [
        [const Offset(32.3, 54.5), const Offset(28.0, 54.5), const Offset(24.4, 51.2), const Offset(20.8, 46.3), const Offset(19.3, 41.4), const Offset(17.9, 36.4), const Offset(18.6, 31.5), const Offset(19.3, 26.5), const Offset(22.9, 22.4), const Offset(27.3, 19.1), const Offset(31.6, 19.1), const Offset(35.9, 19.9), const Offset(38.8, 22.4), const Offset(41.7, 25.7), const Offset(41.0, 29.8), const Offset(36.6, 28.2), const Offset(32.3, 29.8), const Offset(31.6, 33.1), const Offset(31.6, 38.1), const Offset(34.5, 40.5), const Offset(38.8, 40.5), const Offset(41.7, 35.6), const Offset(42.4, 30.6), const Offset(42.4, 29.8)],
      ];
    case '᪘': // เลข 8 เมือง
      return [
        [const Offset(40.1, 25.7), const Offset(43.9, 22.4), const Offset(48.5, 18.2), const Offset(55.3, 16.4), const Offset(62.2, 15.9), const Offset(68.3, 17.3), const Offset(73.6, 19.6), const Offset(78.2, 23.3), const Offset(80.4, 26.6), const Offset(82.0, 30.8), const Offset(82.7, 34.9), const Offset(82.7, 39.1), const Offset(82.7, 43.3), const Offset(82.7, 47.5), const Offset(82.7, 51.6), const Offset(82.7, 55.8), const Offset(82.7, 60.0), const Offset(82.7, 64.1), const Offset(82.7, 68.3), const Offset(82.0, 72.5), const Offset(80.4, 76.7), const Offset(78.2, 79.9), const Offset(72.8, 83.1), const Offset(66.0, 84.5), const Offset(59.1, 84.5), const Offset(57.6, 84.5)],
      ];
    case '᪙': // เลข 9 เมือง
      return [
        [const Offset(27.8, 85.0), const Offset(40.5, 84.5), const Offset(53.3, 82.1), const Offset(66.1, 76.8), const Offset(77.3, 65.7), const Offset(81.9, 53.6), const Offset(83.0, 41.6), const Offset(82.4, 29.5), const Offset(75.3, 17.9), const Offset(65.1, 21.8), const Offset(73.8, 30.4), const Offset(73.8, 42.5), const Offset(66.6, 52.2), const Offset(53.8, 53.1), const Offset(47.2, 43.0), const Offset(51.3, 30.9), const Offset(43.6, 19.3), const Offset(30.8, 17.9), const Offset(20.1, 26.6), const Offset(17.6, 37.2), const Offset(21.6, 48.8), const Offset(31.4, 47.3), const Offset(27.8, 53.6), const Offset(26.2, 49.8)],
      ];
    default:
      return null;
  }
}


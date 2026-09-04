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
  switch (char) {
    case 'ᨠ':
      return [
        [const Offset(32.0, 58.0), const Offset(28.0, 66.0), const Offset(22.0, 62.0), const Offset(20.0, 48.0), const Offset(24.0, 30.0), const Offset(36.0, 22.0), const Offset(48.0, 26.0), const Offset(50.0, 68.0), const Offset(52.0, 32.0), const Offset(60.0, 22.0), const Offset(72.0, 22.0), const Offset(80.0, 36.0), const Offset(78.0, 62.0), const Offset(84.0, 66.0), const Offset(88.0, 56.0)],
      ];
    case 'ᨡ':
      return [
        [const Offset(24.0, 28.0), const Offset(28.0, 22.0), const Offset(36.0, 22.0), const Offset(38.0, 30.0), const Offset(32.0, 34.0), const Offset(24.0, 30.0), const Offset(22.0, 22.0), const Offset(32.0, 16.0), const Offset(46.0, 16.0), const Offset(52.0, 24.0), const Offset(58.0, 18.0), const Offset(68.0, 18.0), const Offset(76.0, 28.0), const Offset(74.0, 52.0), const Offset(64.0, 64.0), const Offset(48.0, 68.0), const Offset(32.0, 66.0), const Offset(22.0, 54.0), const Offset(28.0, 42.0), const Offset(44.0, 42.0), const Offset(62.0, 48.0), const Offset(76.0, 62.0), const Offset(82.0, 78.0)],
      ];
    case 'ᨢ':
      return [
        [const Offset(24.0, 46.0), const Offset(28.0, 40.0), const Offset(36.0, 40.0), const Offset(38.0, 48.0), const Offset(32.0, 52.0), const Offset(24.0, 48.0), const Offset(22.0, 40.0), const Offset(32.0, 34.0), const Offset(46.0, 34.0), const Offset(52.0, 42.0), const Offset(58.0, 36.0), const Offset(68.0, 36.0), const Offset(76.0, 46.0), const Offset(74.0, 70.0), const Offset(64.0, 80.0), const Offset(48.0, 84.0), const Offset(32.0, 82.0), const Offset(22.0, 70.0), const Offset(28.0, 60.0), const Offset(44.0, 60.0), const Offset(62.0, 66.0), const Offset(76.0, 78.0), const Offset(82.0, 92.0)],
        [const Offset(22.0, 40.0), const Offset(22.0, 24.0), const Offset(30.0, 14.0), const Offset(48.0, 12.0), const Offset(68.0, 14.0), const Offset(82.0, 18.0)],
      ];
    case 'ᨣ':
      return [
        [const Offset(32.0, 58.0), const Offset(28.0, 66.0), const Offset(22.0, 62.0), const Offset(20.0, 48.0), const Offset(24.0, 30.0), const Offset(36.0, 20.0), const Offset(52.0, 16.0), const Offset(68.0, 18.0), const Offset(78.0, 30.0), const Offset(78.0, 56.0), const Offset(74.0, 68.0), const Offset(82.0, 70.0), const Offset(88.0, 60.0)],
      ];
    case 'ᨤ':
      return [
        [const Offset(32.0, 58.0), const Offset(28.0, 66.0), const Offset(22.0, 62.0), const Offset(20.0, 48.0), const Offset(24.0, 30.0), const Offset(36.0, 20.0), const Offset(52.0, 16.0), const Offset(68.0, 18.0), const Offset(78.0, 30.0), const Offset(78.0, 56.0), const Offset(74.0, 68.0), const Offset(82.0, 70.0), const Offset(88.0, 60.0)],
        [const Offset(20.0, 30.0), const Offset(20.0, 18.0), const Offset(32.0, 10.0), const Offset(54.0, 8.0), const Offset(74.0, 10.0), const Offset(88.0, 16.0)],
      ];
    case 'ᨥ':
      return [
        [const Offset(26.0, 32.0), const Offset(32.0, 26.0), const Offset(36.0, 32.0), const Offset(32.0, 38.0), const Offset(26.0, 36.0), const Offset(20.0, 46.0), const Offset(22.0, 64.0), const Offset(32.0, 70.0), const Offset(42.0, 66.0), const Offset(46.0, 50.0), const Offset(48.0, 66.0), const Offset(58.0, 70.0), const Offset(68.0, 64.0), const Offset(72.0, 46.0), const Offset(76.0, 28.0), const Offset(84.0, 32.0), const Offset(86.0, 52.0), const Offset(80.0, 68.0), const Offset(88.0, 70.0), const Offset(92.0, 60.0)],
      ];
    case 'ᨦ':
      return [
        [const Offset(38.0, 32.0), const Offset(46.0, 26.0), const Offset(52.0, 32.0), const Offset(48.0, 40.0), const Offset(40.0, 38.0), const Offset(32.0, 44.0), const Offset(30.0, 60.0), const Offset(38.0, 72.0), const Offset(52.0, 76.0), const Offset(68.0, 72.0), const Offset(78.0, 60.0), const Offset(82.0, 44.0)],
      ];
    case 'ᨧ':
      return [
        [const Offset(46.0, 44.0), const Offset(40.0, 38.0), const Offset(44.0, 48.0), const Offset(52.0, 46.0), const Offset(46.0, 38.0), const Offset(38.0, 32.0), const Offset(28.0, 40.0), const Offset(26.0, 56.0), const Offset(36.0, 70.0), const Offset(52.0, 74.0), const Offset(68.0, 68.0), const Offset(76.0, 52.0), const Offset(74.0, 34.0), const Offset(62.0, 24.0), const Offset(46.0, 24.0), const Offset(32.0, 32.0)],
      ];
    case 'ᨨ':
      return [
        [const Offset(46.0, 40.0), const Offset(40.0, 34.0), const Offset(44.0, 44.0), const Offset(52.0, 42.0), const Offset(44.0, 34.0), const Offset(34.0, 28.0), const Offset(24.0, 36.0), const Offset(22.0, 54.0), const Offset(32.0, 68.0), const Offset(46.0, 70.0), const Offset(60.0, 64.0), const Offset(66.0, 48.0), const Offset(66.0, 34.0), const Offset(74.0, 24.0), const Offset(82.0, 30.0), const Offset(82.0, 48.0), const Offset(76.0, 62.0), const Offset(82.0, 66.0), const Offset(88.0, 58.0)],
        [const Offset(46.0, 50.0), const Offset(46.0, 70.0), const Offset(46.0, 88.0), const Offset(40.0, 94.0)],
      ];
    case 'ᨩ':
      return [
        [const Offset(24.0, 26.0), const Offset(36.0, 20.0), const Offset(52.0, 20.0), const Offset(66.0, 26.0), const Offset(78.0, 22.0), const Offset(86.0, 26.0)],
        [const Offset(36.0, 42.0), const Offset(42.0, 36.0), const Offset(46.0, 42.0), const Offset(42.0, 48.0), const Offset(36.0, 46.0), const Offset(28.0, 48.0), const Offset(24.0, 60.0), const Offset(34.0, 72.0), const Offset(50.0, 74.0), const Offset(66.0, 68.0), const Offset(76.0, 54.0), const Offset(78.0, 40.0)],
      ];
    case 'ᨪ':
      return [
        [const Offset(22.0, 24.0), const Offset(38.0, 14.0), const Offset(58.0, 14.0), const Offset(76.0, 20.0), const Offset(86.0, 30.0)],
        [const Offset(34.0, 44.0), const Offset(40.0, 38.0), const Offset(44.0, 44.0), const Offset(40.0, 50.0), const Offset(34.0, 48.0), const Offset(26.0, 50.0), const Offset(22.0, 62.0), const Offset(32.0, 74.0), const Offset(48.0, 76.0), const Offset(64.0, 70.0), const Offset(74.0, 56.0), const Offset(76.0, 42.0)],
      ];
    case 'ᨫ':
      return [
        [const Offset(24.0, 28.0), const Offset(34.0, 20.0), const Offset(46.0, 26.0), const Offset(54.0, 20.0), const Offset(66.0, 20.0), const Offset(74.0, 30.0), const Offset(70.0, 50.0), const Offset(58.0, 62.0), const Offset(44.0, 64.0), const Offset(30.0, 62.0), const Offset(22.0, 50.0), const Offset(26.0, 38.0), const Offset(40.0, 38.0), const Offset(56.0, 44.0), const Offset(70.0, 56.0), const Offset(80.0, 72.0), const Offset(84.0, 88.0)],
        [const Offset(44.0, 64.0), const Offset(44.0, 78.0), const Offset(36.0, 90.0)],
      ];
    case 'ᨬ':
      return [
        [const Offset(30.0, 34.0), const Offset(36.0, 28.0), const Offset(44.0, 32.0), const Offset(40.0, 40.0), const Offset(32.0, 40.0), const Offset(24.0, 32.0), const Offset(20.0, 44.0), const Offset(24.0, 60.0), const Offset(34.0, 70.0), const Offset(48.0, 70.0), const Offset(60.0, 64.0), const Offset(66.0, 50.0), const Offset(66.0, 34.0), const Offset(74.0, 24.0), const Offset(84.0, 28.0), const Offset(84.0, 44.0), const Offset(78.0, 58.0), const Offset(84.0, 66.0), const Offset(90.0, 60.0)],
        [const Offset(48.0, 70.0), const Offset(48.0, 86.0), const Offset(40.0, 94.0)],
      ];
    case 'ᨭ':
      return [
        [const Offset(28.0, 54.0), const Offset(34.0, 48.0), const Offset(40.0, 52.0), const Offset(36.0, 60.0), const Offset(28.0, 60.0), const Offset(22.0, 50.0), const Offset(20.0, 36.0), const Offset(26.0, 24.0), const Offset(38.0, 20.0), const Offset(50.0, 26.0), const Offset(52.0, 64.0), const Offset(54.0, 30.0), const Offset(62.0, 22.0), const Offset(72.0, 22.0), const Offset(82.0, 32.0), const Offset(82.0, 54.0), const Offset(74.0, 64.0), const Offset(80.0, 70.0), const Offset(88.0, 64.0)],
        [const Offset(48.0, 64.0), const Offset(48.0, 80.0), const Offset(40.0, 88.0)],
      ];
    case 'ᨮ':
      return [
        [const Offset(30.0, 54.0), const Offset(36.0, 48.0), const Offset(42.0, 52.0), const Offset(38.0, 60.0), const Offset(30.0, 60.0), const Offset(22.0, 50.0), const Offset(20.0, 34.0), const Offset(26.0, 22.0), const Offset(38.0, 18.0), const Offset(50.0, 26.0), const Offset(52.0, 66.0), const Offset(54.0, 30.0), const Offset(62.0, 22.0), const Offset(74.0, 22.0), const Offset(84.0, 32.0), const Offset(84.0, 54.0), const Offset(76.0, 66.0), const Offset(82.0, 70.0), const Offset(88.0, 64.0)],
      ];
    case 'ᨯ':
      return [
        [const Offset(48.0, 44.0), const Offset(42.0, 38.0), const Offset(46.0, 48.0), const Offset(54.0, 46.0), const Offset(48.0, 38.0), const Offset(38.0, 32.0), const Offset(28.0, 40.0), const Offset(26.0, 58.0), const Offset(36.0, 72.0), const Offset(54.0, 74.0), const Offset(70.0, 68.0), const Offset(78.0, 50.0), const Offset(76.0, 32.0), const Offset(64.0, 22.0), const Offset(48.0, 22.0), const Offset(34.0, 30.0)],
      ];
    case 'ᨰ':
      return [
        [const Offset(24.0, 28.0), const Offset(36.0, 20.0), const Offset(50.0, 26.0), const Offset(58.0, 20.0), const Offset(70.0, 20.0), const Offset(78.0, 30.0), const Offset(76.0, 52.0), const Offset(64.0, 64.0), const Offset(48.0, 66.0), const Offset(32.0, 64.0), const Offset(22.0, 52.0), const Offset(28.0, 40.0), const Offset(44.0, 40.0), const Offset(62.0, 46.0), const Offset(76.0, 60.0), const Offset(82.0, 76.0)],
        [const Offset(48.0, 66.0), const Offset(48.0, 82.0), const Offset(40.0, 90.0)],
      ];
    case 'ᨱ':
      return [
        [const Offset(30.0, 34.0), const Offset(36.0, 28.0), const Offset(44.0, 32.0), const Offset(40.0, 40.0), const Offset(32.0, 40.0), const Offset(24.0, 32.0), const Offset(20.0, 44.0), const Offset(24.0, 62.0), const Offset(34.0, 72.0), const Offset(48.0, 72.0), const Offset(62.0, 66.0), const Offset(68.0, 50.0), const Offset(68.0, 34.0), const Offset(76.0, 24.0), const Offset(84.0, 28.0), const Offset(84.0, 46.0), const Offset(78.0, 60.0), const Offset(84.0, 68.0), const Offset(90.0, 62.0)],
      ];
    case 'ᨲ':
      return [
        [const Offset(28.0, 56.0), const Offset(34.0, 50.0), const Offset(40.0, 54.0), const Offset(36.0, 62.0), const Offset(28.0, 62.0), const Offset(22.0, 52.0), const Offset(20.0, 36.0), const Offset(26.0, 24.0), const Offset(38.0, 20.0), const Offset(50.0, 26.0), const Offset(52.0, 66.0), const Offset(54.0, 30.0), const Offset(62.0, 22.0), const Offset(74.0, 22.0), const Offset(84.0, 32.0), const Offset(84.0, 54.0), const Offset(76.0, 64.0), const Offset(82.0, 68.0), const Offset(88.0, 60.0)],
      ];
    case 'ᨳ':
      return [
        [const Offset(44.0, 48.0), const Offset(38.0, 42.0), const Offset(42.0, 52.0), const Offset(50.0, 50.0), const Offset(44.0, 42.0), const Offset(34.0, 36.0), const Offset(24.0, 44.0), const Offset(22.0, 60.0), const Offset(32.0, 74.0), const Offset(50.0, 76.0), const Offset(66.0, 70.0), const Offset(74.0, 54.0), const Offset(72.0, 36.0), const Offset(60.0, 26.0), const Offset(44.0, 26.0), const Offset(30.0, 34.0)],
      ];
    case 'ᨴ':
      return [
        [const Offset(26.0, 28.0), const Offset(36.0, 20.0), const Offset(52.0, 18.0), const Offset(68.0, 22.0), const Offset(78.0, 34.0), const Offset(76.0, 56.0), const Offset(66.0, 68.0), const Offset(50.0, 72.0), const Offset(34.0, 70.0), const Offset(24.0, 58.0), const Offset(28.0, 44.0), const Offset(44.0, 44.0), const Offset(62.0, 50.0), const Offset(76.0, 64.0), const Offset(82.0, 80.0)],
      ];
    case 'ᨵ':
      return [
        [const Offset(24.0, 48.0), const Offset(30.0, 42.0), const Offset(38.0, 46.0), const Offset(34.0, 54.0), const Offset(26.0, 52.0), const Offset(20.0, 44.0), const Offset(24.0, 28.0), const Offset(38.0, 20.0), const Offset(56.0, 18.0), const Offset(72.0, 24.0), const Offset(80.0, 38.0), const Offset(78.0, 62.0), const Offset(68.0, 72.0), const Offset(50.0, 74.0), const Offset(32.0, 72.0), const Offset(22.0, 60.0), const Offset(30.0, 46.0), const Offset(46.0, 46.0), const Offset(64.0, 52.0), const Offset(78.0, 66.0), const Offset(84.0, 82.0)],
      ];
    case 'ᨶ':
      return [
        [const Offset(30.0, 58.0), const Offset(36.0, 52.0), const Offset(42.0, 56.0), const Offset(38.0, 64.0), const Offset(30.0, 64.0), const Offset(22.0, 54.0), const Offset(20.0, 38.0), const Offset(26.0, 24.0), const Offset(38.0, 20.0), const Offset(52.0, 20.0), const Offset(66.0, 24.0), const Offset(76.0, 36.0), const Offset(78.0, 54.0), const Offset(74.0, 68.0), const Offset(82.0, 70.0), const Offset(88.0, 60.0)],
      ];
    case 'ᨷ':
      return [
        [const Offset(28.0, 34.0), const Offset(34.0, 28.0), const Offset(42.0, 32.0), const Offset(38.0, 40.0), const Offset(30.0, 40.0), const Offset(22.0, 32.0), const Offset(20.0, 46.0), const Offset(24.0, 64.0), const Offset(36.0, 74.0), const Offset(52.0, 74.0), const Offset(68.0, 68.0), const Offset(76.0, 52.0), const Offset(76.0, 32.0), const Offset(84.0, 24.0), const Offset(92.0, 32.0), const Offset(90.0, 50.0), const Offset(84.0, 64.0), const Offset(90.0, 68.0), const Offset(96.0, 60.0)],
      ];
    case 'ᨸ':
      return [
        [const Offset(28.0, 34.0), const Offset(34.0, 28.0), const Offset(42.0, 32.0), const Offset(38.0, 40.0), const Offset(30.0, 40.0), const Offset(22.0, 32.0), const Offset(20.0, 46.0), const Offset(24.0, 64.0), const Offset(36.0, 74.0), const Offset(52.0, 74.0), const Offset(68.0, 68.0), const Offset(76.0, 52.0), const Offset(76.0, 32.0), const Offset(84.0, 24.0), const Offset(92.0, 32.0), const Offset(90.0, 50.0), const Offset(84.0, 64.0), const Offset(90.0, 68.0), const Offset(96.0, 60.0)],
        [const Offset(84.0, 24.0), const Offset(84.0, 10.0), const Offset(92.0, 4.0)],
      ];
    case 'ᨹ':
      return [
        [const Offset(26.0, 32.0), const Offset(32.0, 26.0), const Offset(40.0, 30.0), const Offset(36.0, 38.0), const Offset(28.0, 38.0), const Offset(20.0, 30.0), const Offset(20.0, 46.0), const Offset(24.0, 64.0), const Offset(36.0, 74.0), const Offset(52.0, 74.0), const Offset(66.0, 68.0), const Offset(74.0, 52.0), const Offset(74.0, 34.0), const Offset(82.0, 26.0), const Offset(90.0, 32.0), const Offset(88.0, 50.0), const Offset(82.0, 64.0), const Offset(88.0, 68.0), const Offset(94.0, 60.0)],
        [const Offset(46.0, 52.0), const Offset(54.0, 44.0), const Offset(62.0, 52.0)],
      ];
    case 'ᨺ':
      return [
        [const Offset(26.0, 32.0), const Offset(32.0, 26.0), const Offset(40.0, 30.0), const Offset(36.0, 38.0), const Offset(28.0, 38.0), const Offset(20.0, 30.0), const Offset(20.0, 46.0), const Offset(24.0, 64.0), const Offset(36.0, 74.0), const Offset(52.0, 74.0), const Offset(66.0, 68.0), const Offset(74.0, 52.0), const Offset(74.0, 34.0), const Offset(82.0, 26.0), const Offset(90.0, 32.0), const Offset(88.0, 50.0), const Offset(82.0, 64.0), const Offset(88.0, 68.0), const Offset(94.0, 60.0)],
        [const Offset(46.0, 52.0), const Offset(54.0, 44.0), const Offset(62.0, 52.0)],
        [const Offset(82.0, 26.0), const Offset(82.0, 10.0), const Offset(90.0, 4.0)],
      ];
    case 'ᨻ':
      return [
        [const Offset(28.0, 56.0), const Offset(34.0, 50.0), const Offset(40.0, 54.0), const Offset(36.0, 62.0), const Offset(28.0, 62.0), const Offset(22.0, 52.0), const Offset(20.0, 36.0), const Offset(26.0, 24.0), const Offset(38.0, 20.0), const Offset(50.0, 26.0), const Offset(52.0, 66.0), const Offset(54.0, 30.0), const Offset(62.0, 22.0), const Offset(74.0, 22.0), const Offset(84.0, 32.0), const Offset(84.0, 54.0), const Offset(76.0, 64.0), const Offset(82.0, 68.0), const Offset(88.0, 60.0)],
      ];
    case 'ᨼ':
      return [
        [const Offset(28.0, 56.0), const Offset(34.0, 50.0), const Offset(40.0, 54.0), const Offset(36.0, 62.0), const Offset(28.0, 62.0), const Offset(22.0, 52.0), const Offset(20.0, 36.0), const Offset(26.0, 24.0), const Offset(38.0, 20.0), const Offset(50.0, 26.0), const Offset(52.0, 66.0), const Offset(54.0, 30.0), const Offset(62.0, 22.0), const Offset(74.0, 22.0), const Offset(84.0, 32.0), const Offset(84.0, 54.0), const Offset(76.0, 64.0), const Offset(82.0, 68.0), const Offset(88.0, 60.0)],
        [const Offset(84.0, 32.0), const Offset(84.0, 14.0), const Offset(92.0, 8.0)],
      ];
    case 'ᨽ':
      return [
        [const Offset(26.0, 30.0), const Offset(36.0, 22.0), const Offset(52.0, 20.0), const Offset(68.0, 24.0), const Offset(78.0, 36.0), const Offset(76.0, 58.0), const Offset(66.0, 70.0), const Offset(50.0, 74.0), const Offset(34.0, 72.0), const Offset(24.0, 60.0), const Offset(28.0, 46.0), const Offset(44.0, 46.0), const Offset(62.0, 52.0), const Offset(76.0, 66.0), const Offset(82.0, 82.0)],
      ];
    case 'ᨾ':
      return [
        [const Offset(30.0, 32.0), const Offset(36.0, 26.0), const Offset(44.0, 30.0), const Offset(40.0, 38.0), const Offset(32.0, 38.0), const Offset(24.0, 30.0), const Offset(20.0, 44.0), const Offset(22.0, 62.0), const Offset(32.0, 72.0), const Offset(48.0, 74.0), const Offset(64.0, 70.0), const Offset(74.0, 56.0), const Offset(76.0, 40.0), const Offset(82.0, 28.0), const Offset(90.0, 34.0), const Offset(88.0, 52.0), const Offset(82.0, 66.0), const Offset(88.0, 70.0), const Offset(94.0, 62.0)],
      ];
    case 'ᨿ':
      return [
        [const Offset(26.0, 34.0), const Offset(34.0, 26.0), const Offset(44.0, 30.0), const Offset(40.0, 40.0), const Offset(30.0, 40.0), const Offset(22.0, 32.0), const Offset(20.0, 48.0), const Offset(26.0, 64.0), const Offset(38.0, 74.0), const Offset(54.0, 74.0), const Offset(68.0, 68.0), const Offset(76.0, 52.0), const Offset(74.0, 34.0), const Offset(62.0, 24.0), const Offset(46.0, 24.0), const Offset(34.0, 32.0)],
      ];
    case 'ᩀ':
      return [
        [const Offset(24.0, 32.0), const Offset(32.0, 24.0), const Offset(42.0, 28.0), const Offset(38.0, 38.0), const Offset(28.0, 38.0), const Offset(20.0, 30.0), const Offset(20.0, 46.0), const Offset(24.0, 64.0), const Offset(36.0, 74.0), const Offset(50.0, 74.0), const Offset(62.0, 68.0), const Offset(68.0, 52.0), const Offset(68.0, 34.0), const Offset(76.0, 24.0), const Offset(86.0, 28.0), const Offset(86.0, 46.0), const Offset(80.0, 60.0), const Offset(86.0, 68.0), const Offset(92.0, 60.0)],
      ];
    case 'ᩁ':
      return [
        [const Offset(24.0, 58.0), const Offset(30.0, 52.0), const Offset(36.0, 56.0), const Offset(32.0, 64.0), const Offset(24.0, 64.0), const Offset(18.0, 54.0), const Offset(18.0, 38.0), const Offset(24.0, 24.0), const Offset(36.0, 20.0), const Offset(52.0, 20.0), const Offset(66.0, 26.0), const Offset(76.0, 38.0), const Offset(78.0, 56.0), const Offset(74.0, 70.0), const Offset(82.0, 72.0), const Offset(88.0, 62.0)],
      ];
    case 'ᩂ':
      return [
        [const Offset(24.0, 58.0), const Offset(30.0, 52.0), const Offset(36.0, 56.0), const Offset(32.0, 64.0), const Offset(24.0, 64.0), const Offset(18.0, 54.0), const Offset(18.0, 38.0), const Offset(24.0, 24.0), const Offset(36.0, 20.0), const Offset(52.0, 20.0), const Offset(66.0, 26.0), const Offset(76.0, 38.0), const Offset(78.0, 56.0), const Offset(74.0, 70.0), const Offset(82.0, 72.0), const Offset(88.0, 62.0)],
        [const Offset(74.0, 70.0), const Offset(74.0, 86.0), const Offset(66.0, 94.0)],
      ];
    case 'ᩃ':
      return [
        [const Offset(28.0, 34.0), const Offset(34.0, 28.0), const Offset(42.0, 32.0), const Offset(38.0, 40.0), const Offset(30.0, 40.0), const Offset(22.0, 32.0), const Offset(20.0, 46.0), const Offset(24.0, 64.0), const Offset(36.0, 74.0), const Offset(52.0, 74.0), const Offset(68.0, 68.0), const Offset(76.0, 52.0), const Offset(76.0, 32.0), const Offset(84.0, 24.0), const Offset(92.0, 32.0), const Offset(90.0, 50.0), const Offset(84.0, 64.0), const Offset(90.0, 68.0), const Offset(96.0, 60.0)],
      ];
    case 'ᩄ':
      return [
        [const Offset(28.0, 34.0), const Offset(34.0, 28.0), const Offset(42.0, 32.0), const Offset(38.0, 40.0), const Offset(30.0, 40.0), const Offset(22.0, 32.0), const Offset(20.0, 46.0), const Offset(24.0, 64.0), const Offset(36.0, 74.0), const Offset(52.0, 74.0), const Offset(68.0, 68.0), const Offset(76.0, 52.0), const Offset(76.0, 32.0), const Offset(84.0, 24.0), const Offset(92.0, 32.0), const Offset(90.0, 50.0), const Offset(84.0, 64.0), const Offset(90.0, 68.0), const Offset(96.0, 60.0)],
        [const Offset(84.0, 64.0), const Offset(84.0, 82.0), const Offset(76.0, 92.0)],
      ];
    case 'ᩅ':
      return [
        [const Offset(36.0, 44.0), const Offset(42.0, 38.0), const Offset(46.0, 44.0), const Offset(42.0, 50.0), const Offset(36.0, 48.0), const Offset(28.0, 48.0), const Offset(24.0, 60.0), const Offset(34.0, 72.0), const Offset(50.0, 74.0), const Offset(66.0, 68.0), const Offset(76.0, 54.0), const Offset(78.0, 40.0), const Offset(74.0, 26.0), const Offset(62.0, 18.0), const Offset(48.0, 18.0), const Offset(34.0, 26.0)],
      ];
    case 'ᩆ':
      return [
        [const Offset(32.0, 58.0), const Offset(28.0, 66.0), const Offset(22.0, 62.0), const Offset(20.0, 48.0), const Offset(24.0, 30.0), const Offset(36.0, 22.0), const Offset(48.0, 26.0), const Offset(50.0, 68.0), const Offset(52.0, 32.0), const Offset(60.0, 22.0), const Offset(72.0, 22.0), const Offset(80.0, 36.0), const Offset(78.0, 62.0), const Offset(84.0, 66.0), const Offset(88.0, 56.0)],
        [const Offset(36.0, 22.0), const Offset(48.0, 12.0), const Offset(64.0, 12.0)],
      ];
    case 'ᩇ':
      return [
        [const Offset(28.0, 34.0), const Offset(34.0, 28.0), const Offset(42.0, 32.0), const Offset(38.0, 40.0), const Offset(30.0, 40.0), const Offset(22.0, 32.0), const Offset(20.0, 46.0), const Offset(24.0, 64.0), const Offset(36.0, 74.0), const Offset(52.0, 74.0), const Offset(68.0, 68.0), const Offset(76.0, 52.0), const Offset(76.0, 32.0), const Offset(84.0, 24.0), const Offset(92.0, 32.0), const Offset(90.0, 50.0), const Offset(84.0, 64.0), const Offset(90.0, 68.0), const Offset(96.0, 60.0)],
        [const Offset(44.0, 52.0), const Offset(58.0, 42.0), const Offset(72.0, 54.0)],
      ];
    case 'ᩈ':
      return [
        [const Offset(24.0, 26.0), const Offset(36.0, 18.0), const Offset(52.0, 18.0), const Offset(66.0, 24.0), const Offset(76.0, 36.0), const Offset(74.0, 58.0), const Offset(64.0, 70.0), const Offset(48.0, 72.0), const Offset(32.0, 70.0), const Offset(22.0, 58.0), const Offset(26.0, 44.0), const Offset(42.0, 44.0), const Offset(60.0, 50.0), const Offset(74.0, 64.0), const Offset(80.0, 80.0)],
      ];
    case 'ᩉ':
      return [
        [const Offset(26.0, 34.0), const Offset(32.0, 28.0), const Offset(40.0, 32.0), const Offset(36.0, 40.0), const Offset(28.0, 40.0), const Offset(20.0, 32.0), const Offset(20.0, 48.0), const Offset(26.0, 66.0), const Offset(38.0, 74.0), const Offset(54.0, 74.0), const Offset(68.0, 68.0), const Offset(76.0, 54.0), const Offset(76.0, 36.0), const Offset(84.0, 28.0), const Offset(92.0, 34.0), const Offset(90.0, 52.0), const Offset(84.0, 66.0), const Offset(90.0, 70.0), const Offset(96.0, 62.0)],
        [const Offset(76.0, 36.0), const Offset(62.0, 46.0), const Offset(54.0, 60.0)],
      ];
    case 'ᩊ':
      return [
        [const Offset(28.0, 34.0), const Offset(34.0, 28.0), const Offset(42.0, 32.0), const Offset(38.0, 40.0), const Offset(30.0, 40.0), const Offset(22.0, 32.0), const Offset(20.0, 46.0), const Offset(24.0, 64.0), const Offset(36.0, 74.0), const Offset(52.0, 74.0), const Offset(68.0, 68.0), const Offset(76.0, 52.0), const Offset(76.0, 32.0), const Offset(84.0, 24.0), const Offset(92.0, 32.0), const Offset(90.0, 50.0), const Offset(84.0, 64.0), const Offset(90.0, 68.0), const Offset(96.0, 60.0)],
        [const Offset(68.0, 68.0), const Offset(74.0, 82.0), const Offset(84.0, 86.0)],
      ];
    case 'ᩋ':
      return [
        [const Offset(36.0, 44.0), const Offset(42.0, 38.0), const Offset(46.0, 44.0), const Offset(42.0, 50.0), const Offset(36.0, 48.0), const Offset(28.0, 48.0), const Offset(24.0, 60.0), const Offset(34.0, 72.0), const Offset(50.0, 74.0), const Offset(66.0, 68.0), const Offset(76.0, 54.0), const Offset(78.0, 40.0), const Offset(74.0, 26.0), const Offset(62.0, 18.0), const Offset(48.0, 18.0), const Offset(34.0, 26.0)],
      ];
    case 'ᩌ':
      return [
        [const Offset(36.0, 44.0), const Offset(42.0, 38.0), const Offset(46.0, 44.0), const Offset(42.0, 50.0), const Offset(36.0, 48.0), const Offset(28.0, 48.0), const Offset(24.0, 60.0), const Offset(34.0, 72.0), const Offset(50.0, 74.0), const Offset(66.0, 68.0), const Offset(76.0, 54.0), const Offset(78.0, 40.0), const Offset(74.0, 26.0), const Offset(62.0, 18.0), const Offset(48.0, 18.0), const Offset(34.0, 26.0)],
        [const Offset(74.0, 26.0), const Offset(82.0, 18.0), const Offset(90.0, 24.0), const Offset(88.0, 34.0)],
      ];
    case 'ᩡ':
      return [
        [const Offset(38.0, 34.0), const Offset(46.0, 28.0), const Offset(52.0, 34.0), const Offset(48.0, 42.0), const Offset(40.0, 40.0), const Offset(32.0, 48.0), const Offset(34.0, 64.0), const Offset(44.0, 72.0), const Offset(58.0, 68.0), const Offset(64.0, 52.0)],
        [const Offset(66.0, 34.0), const Offset(74.0, 28.0), const Offset(80.0, 34.0), const Offset(76.0, 42.0), const Offset(68.0, 40.0), const Offset(60.0, 48.0), const Offset(62.0, 64.0), const Offset(72.0, 72.0), const Offset(84.0, 68.0), const Offset(90.0, 52.0)],
      ];
    case 'ᩣ':
      return [
        [const Offset(36.0, 22.0), const Offset(50.0, 16.0), const Offset(66.0, 20.0), const Offset(76.0, 34.0), const Offset(76.0, 62.0), const Offset(72.0, 82.0)],
      ];
    case 'ᩤ':
      return [
        [const Offset(34.0, 22.0), const Offset(48.0, 16.0), const Offset(64.0, 20.0), const Offset(74.0, 34.0), const Offset(74.0, 62.0), const Offset(70.0, 84.0)],
      ];
    case 'ᩥ':
      return [
        [const Offset(30.0, 54.0), const Offset(46.0, 38.0), const Offset(64.0, 38.0), const Offset(78.0, 52.0), const Offset(64.0, 66.0), const Offset(46.0, 66.0), const Offset(30.0, 54.0)],
      ];
    case 'ᩦ':
      return [
        [const Offset(30.0, 54.0), const Offset(46.0, 38.0), const Offset(64.0, 38.0), const Offset(78.0, 52.0), const Offset(64.0, 66.0), const Offset(46.0, 66.0), const Offset(30.0, 54.0)],
        [const Offset(58.0, 38.0), const Offset(64.0, 24.0), const Offset(74.0, 18.0)],
      ];
    case 'ᩧ':
      return [
        [const Offset(30.0, 54.0), const Offset(46.0, 38.0), const Offset(64.0, 38.0), const Offset(78.0, 52.0), const Offset(64.0, 66.0), const Offset(46.0, 66.0), const Offset(30.0, 54.0)],
        [const Offset(54.0, 52.0), const Offset(60.0, 46.0), const Offset(66.0, 52.0), const Offset(60.0, 58.0), const Offset(54.0, 52.0)],
      ];
    case 'ᩨ':
      return [
        [const Offset(30.0, 54.0), const Offset(46.0, 38.0), const Offset(64.0, 38.0), const Offset(78.0, 52.0), const Offset(64.0, 66.0), const Offset(46.0, 66.0), const Offset(30.0, 54.0)],
        [const Offset(52.0, 38.0), const Offset(52.0, 22.0)],
        [const Offset(66.0, 38.0), const Offset(66.0, 22.0)],
      ];
    case 'ᩩ':
      return [
        [const Offset(44.0, 32.0), const Offset(50.0, 26.0), const Offset(58.0, 30.0), const Offset(54.0, 38.0), const Offset(46.0, 38.0), const Offset(38.0, 46.0), const Offset(40.0, 62.0), const Offset(50.0, 72.0), const Offset(62.0, 68.0)],
      ];
    case 'ᩪ':
      return [
        [const Offset(38.0, 32.0), const Offset(44.0, 26.0), const Offset(52.0, 30.0), const Offset(48.0, 38.0), const Offset(40.0, 38.0), const Offset(32.0, 46.0), const Offset(34.0, 62.0), const Offset(44.0, 72.0), const Offset(58.0, 72.0), const Offset(72.0, 64.0), const Offset(80.0, 50.0)],
      ];
    case 'ᩫ':
      return [
        [const Offset(34.0, 50.0), const Offset(48.0, 36.0), const Offset(64.0, 36.0), const Offset(76.0, 48.0), const Offset(64.0, 62.0), const Offset(48.0, 62.0), const Offset(34.0, 50.0)],
      ];
    case 'ᩬ':
      return [
        [const Offset(34.0, 46.0), const Offset(42.0, 38.0), const Offset(48.0, 44.0), const Offset(44.0, 52.0), const Offset(36.0, 50.0), const Offset(28.0, 52.0), const Offset(26.0, 64.0), const Offset(36.0, 76.0), const Offset(52.0, 78.0), const Offset(68.0, 72.0), const Offset(76.0, 58.0)],
      ];
    case 'ᩭ':
      return [
        [const Offset(34.0, 46.0), const Offset(42.0, 38.0), const Offset(48.0, 44.0), const Offset(44.0, 52.0), const Offset(36.0, 50.0), const Offset(28.0, 52.0), const Offset(26.0, 64.0), const Offset(36.0, 76.0), const Offset(52.0, 78.0), const Offset(68.0, 72.0), const Offset(76.0, 58.0)],
        [const Offset(68.0, 72.0), const Offset(76.0, 84.0), const Offset(86.0, 88.0)],
      ];
    case 'ᩮ':
      return [
        [const Offset(44.0, 58.0), const Offset(50.0, 52.0), const Offset(56.0, 56.0), const Offset(52.0, 64.0), const Offset(44.0, 64.0), const Offset(36.0, 54.0), const Offset(36.0, 36.0), const Offset(42.0, 22.0), const Offset(54.0, 18.0), const Offset(68.0, 22.0), const Offset(76.0, 34.0), const Offset(74.0, 54.0), const Offset(66.0, 68.0), const Offset(54.0, 78.0), const Offset(40.0, 84.0)],
      ];
    case 'ᩯ':
      return [
        [const Offset(34.0, 58.0), const Offset(40.0, 52.0), const Offset(46.0, 56.0), const Offset(42.0, 64.0), const Offset(34.0, 64.0), const Offset(26.0, 54.0), const Offset(26.0, 36.0), const Offset(32.0, 22.0), const Offset(44.0, 18.0), const Offset(56.0, 22.0), const Offset(62.0, 34.0)],
        [const Offset(54.0, 58.0), const Offset(60.0, 52.0), const Offset(66.0, 56.0), const Offset(62.0, 64.0), const Offset(54.0, 64.0), const Offset(46.0, 54.0), const Offset(46.0, 36.0), const Offset(52.0, 22.0), const Offset(64.0, 18.0), const Offset(76.0, 22.0), const Offset(84.0, 34.0)],
      ];
    case 'ᩰ':
      return [
        [const Offset(46.0, 64.0), const Offset(52.0, 58.0), const Offset(58.0, 62.0), const Offset(54.0, 70.0), const Offset(46.0, 70.0), const Offset(38.0, 60.0), const Offset(38.0, 40.0), const Offset(46.0, 24.0), const Offset(60.0, 16.0), const Offset(74.0, 22.0), const Offset(80.0, 38.0), const Offset(76.0, 56.0), const Offset(62.0, 72.0), const Offset(50.0, 82.0), const Offset(36.0, 88.0)],
      ];
    case 'ᩱ':
      return [
        [const Offset(44.0, 64.0), const Offset(50.0, 58.0), const Offset(56.0, 62.0), const Offset(52.0, 70.0), const Offset(44.0, 70.0), const Offset(36.0, 60.0), const Offset(36.0, 40.0), const Offset(44.0, 24.0), const Offset(58.0, 16.0), const Offset(72.0, 22.0), const Offset(80.0, 36.0), const Offset(76.0, 52.0), const Offset(64.0, 64.0), const Offset(56.0, 48.0), const Offset(62.0, 36.0)],
      ];
    case 'ᩲ':
      return [
        [const Offset(44.0, 64.0), const Offset(50.0, 58.0), const Offset(56.0, 62.0), const Offset(52.0, 70.0), const Offset(44.0, 70.0), const Offset(36.0, 60.0), const Offset(36.0, 40.0), const Offset(44.0, 24.0), const Offset(58.0, 16.0), const Offset(72.0, 22.0), const Offset(80.0, 36.0), const Offset(76.0, 52.0), const Offset(66.0, 66.0), const Offset(74.0, 74.0), const Offset(84.0, 74.0)],
      ];
    case 'ᩳ':
      return [
        [const Offset(32.0, 54.0), const Offset(48.0, 38.0), const Offset(64.0, 38.0), const Offset(78.0, 52.0), const Offset(64.0, 66.0), const Offset(48.0, 66.0), const Offset(32.0, 54.0)],
        [const Offset(46.0, 38.0), const Offset(46.0, 24.0)],
        [const Offset(62.0, 38.0), const Offset(62.0, 24.0)],
      ];
    case 'ᩴ':
      return [
        [const Offset(42.0, 48.0), const Offset(48.0, 42.0), const Offset(56.0, 46.0), const Offset(52.0, 54.0), const Offset(44.0, 54.0), const Offset(42.0, 48.0)],
      ];
    case '᩵':
      return [
        [const Offset(44.0, 38.0), const Offset(50.0, 32.0), const Offset(58.0, 36.0), const Offset(54.0, 44.0), const Offset(46.0, 44.0), const Offset(44.0, 38.0)],
        [const Offset(50.0, 44.0), const Offset(50.0, 68.0)],
      ];
    case '᩶':
      return [
        [const Offset(34.0, 52.0), const Offset(44.0, 38.0), const Offset(58.0, 34.0), const Offset(72.0, 42.0), const Offset(76.0, 58.0), const Offset(66.0, 68.0), const Offset(50.0, 68.0), const Offset(38.0, 58.0)],
      ];
    case '᩷':
      return [
        [const Offset(38.0, 42.0), const Offset(46.0, 34.0), const Offset(58.0, 34.0), const Offset(68.0, 44.0), const Offset(64.0, 58.0), const Offset(52.0, 66.0), const Offset(40.0, 62.0)],
      ];
    case '᩸':
      return [
        [const Offset(36.0, 50.0), const Offset(64.0, 50.0)],
        [const Offset(50.0, 36.0), const Offset(50.0, 64.0)],
      ];
    case '᩹':
      return [
        [const Offset(36.0, 36.0), const Offset(64.0, 64.0)],
        [const Offset(64.0, 36.0), const Offset(36.0, 64.0)],
      ];
    case '᩺':
      return [
        [const Offset(36.0, 56.0), const Offset(46.0, 42.0), const Offset(60.0, 42.0), const Offset(70.0, 54.0), const Offset(62.0, 68.0), const Offset(48.0, 68.0), const Offset(38.0, 58.0)],
        [const Offset(58.0, 42.0), const Offset(66.0, 30.0), const Offset(76.0, 24.0)],
      ];
    case '᪀':
      return [
        [const Offset(34.0, 50.0), const Offset(48.0, 34.0), const Offset(64.0, 34.0), const Offset(78.0, 48.0), const Offset(78.0, 66.0), const Offset(64.0, 80.0), const Offset(48.0, 80.0), const Offset(34.0, 66.0), const Offset(34.0, 50.0)],
      ];
    case '᪁':
      return [
        [const Offset(38.0, 44.0), const Offset(44.0, 38.0), const Offset(50.0, 44.0), const Offset(46.0, 50.0), const Offset(38.0, 48.0), const Offset(32.0, 52.0), const Offset(30.0, 66.0), const Offset(40.0, 78.0), const Offset(56.0, 78.0), const Offset(70.0, 68.0), const Offset(76.0, 52.0), const Offset(74.0, 36.0), const Offset(62.0, 26.0), const Offset(48.0, 26.0), const Offset(36.0, 34.0)],
      ];
    case '᪂':
      return [
        [const Offset(26.0, 34.0), const Offset(36.0, 24.0), const Offset(50.0, 26.0), const Offset(62.0, 36.0), const Offset(58.0, 52.0), const Offset(44.0, 66.0), const Offset(32.0, 74.0), const Offset(50.0, 76.0), const Offset(68.0, 76.0), const Offset(80.0, 72.0)],
      ];
    case '᪃':
      return [
        [const Offset(28.0, 38.0), const Offset(36.0, 28.0), const Offset(48.0, 30.0), const Offset(44.0, 46.0), const Offset(56.0, 46.0), const Offset(68.0, 54.0), const Offset(68.0, 68.0), const Offset(56.0, 78.0), const Offset(40.0, 78.0), const Offset(28.0, 68.0)],
      ];
    case '᪄':
      return [
        [const Offset(58.0, 24.0), const Offset(42.0, 48.0), const Offset(68.0, 48.0)],
        [const Offset(56.0, 36.0), const Offset(56.0, 76.0)],
      ];
    case '᪅':
      return [
        [const Offset(62.0, 28.0), const Offset(42.0, 28.0), const Offset(38.0, 48.0), const Offset(48.0, 42.0), const Offset(62.0, 44.0), const Offset(70.0, 56.0), const Offset(66.0, 72.0), const Offset(52.0, 78.0), const Offset(36.0, 74.0)],
      ];
    case '᪆':
      return [
        [const Offset(64.0, 30.0), const Offset(50.0, 24.0), const Offset(36.0, 38.0), const Offset(32.0, 58.0), const Offset(42.0, 74.0), const Offset(58.0, 76.0), const Offset(72.0, 66.0), const Offset(72.0, 52.0), const Offset(60.0, 42.0), const Offset(44.0, 46.0)],
      ];
    case '᪇':
      return [
        [const Offset(30.0, 26.0), const Offset(68.0, 26.0), const Offset(54.0, 48.0), const Offset(48.0, 74.0)],
      ];
    case '᪈':
      return [
        [const Offset(48.0, 44.0), const Offset(42.0, 38.0), const Offset(46.0, 48.0), const Offset(54.0, 46.0), const Offset(48.0, 38.0), const Offset(38.0, 32.0), const Offset(28.0, 40.0), const Offset(26.0, 58.0), const Offset(36.0, 72.0), const Offset(54.0, 74.0), const Offset(70.0, 68.0), const Offset(78.0, 50.0), const Offset(76.0, 32.0), const Offset(64.0, 22.0), const Offset(48.0, 22.0), const Offset(34.0, 30.0)],
      ];
    case '᪉':
      return [
        [const Offset(54.0, 64.0), const Offset(40.0, 56.0), const Offset(40.0, 42.0), const Offset(52.0, 32.0), const Offset(66.0, 34.0), const Offset(74.0, 48.0), const Offset(70.0, 68.0), const Offset(56.0, 80.0), const Offset(40.0, 80.0), const Offset(28.0, 70.0)],
      ];
    case '᪐':
      return [
        [const Offset(34.0, 50.0), const Offset(48.0, 34.0), const Offset(64.0, 34.0), const Offset(78.0, 48.0), const Offset(78.0, 66.0), const Offset(64.0, 80.0), const Offset(48.0, 80.0), const Offset(34.0, 66.0), const Offset(34.0, 50.0)],
      ];
    case '᪑':
      return [
        [const Offset(38.0, 44.0), const Offset(44.0, 38.0), const Offset(50.0, 44.0), const Offset(46.0, 50.0), const Offset(38.0, 48.0), const Offset(32.0, 52.0), const Offset(30.0, 66.0), const Offset(40.0, 78.0), const Offset(56.0, 78.0), const Offset(70.0, 68.0), const Offset(76.0, 52.0), const Offset(74.0, 36.0), const Offset(62.0, 26.0), const Offset(48.0, 26.0), const Offset(36.0, 34.0)],
      ];
    case '᪒':
      return [
        [const Offset(26.0, 34.0), const Offset(36.0, 24.0), const Offset(50.0, 26.0), const Offset(62.0, 36.0), const Offset(58.0, 52.0), const Offset(44.0, 66.0), const Offset(32.0, 74.0), const Offset(50.0, 76.0), const Offset(68.0, 76.0), const Offset(80.0, 72.0)],
      ];
    case '᪓':
      return [
        [const Offset(28.0, 38.0), const Offset(36.0, 28.0), const Offset(48.0, 30.0), const Offset(44.0, 46.0), const Offset(56.0, 46.0), const Offset(68.0, 54.0), const Offset(68.0, 68.0), const Offset(56.0, 78.0), const Offset(40.0, 78.0), const Offset(28.0, 68.0)],
      ];
    case '᪔':
      return [
        [const Offset(58.0, 24.0), const Offset(42.0, 48.0), const Offset(68.0, 48.0)],
        [const Offset(56.0, 36.0), const Offset(56.0, 76.0)],
      ];
    case '᪕':
      return [
        [const Offset(62.0, 28.0), const Offset(42.0, 28.0), const Offset(38.0, 48.0), const Offset(48.0, 42.0), const Offset(62.0, 44.0), const Offset(70.0, 56.0), const Offset(66.0, 72.0), const Offset(52.0, 78.0), const Offset(36.0, 74.0)],
      ];
    case '᪖':
      return [
        [const Offset(64.0, 30.0), const Offset(50.0, 24.0), const Offset(36.0, 38.0), const Offset(32.0, 58.0), const Offset(42.0, 74.0), const Offset(58.0, 76.0), const Offset(72.0, 66.0), const Offset(72.0, 52.0), const Offset(60.0, 42.0), const Offset(44.0, 46.0)],
      ];
    case '᪗':
      return [
        [const Offset(30.0, 26.0), const Offset(68.0, 26.0), const Offset(54.0, 48.0), const Offset(48.0, 74.0)],
      ];
    case '᪘':
      return [
        [const Offset(48.0, 44.0), const Offset(42.0, 38.0), const Offset(46.0, 48.0), const Offset(54.0, 46.0), const Offset(48.0, 38.0), const Offset(38.0, 32.0), const Offset(28.0, 40.0), const Offset(26.0, 58.0), const Offset(36.0, 72.0), const Offset(54.0, 74.0), const Offset(70.0, 68.0), const Offset(78.0, 50.0), const Offset(76.0, 32.0), const Offset(64.0, 22.0), const Offset(48.0, 22.0), const Offset(34.0, 30.0)],
      ];
    case '᪙':
      return [
        [const Offset(54.0, 64.0), const Offset(40.0, 56.0), const Offset(40.0, 42.0), const Offset(52.0, 32.0), const Offset(66.0, 34.0), const Offset(74.0, 48.0), const Offset(70.0, 68.0), const Offset(56.0, 80.0), const Offset(40.0, 80.0), const Offset(28.0, 70.0)],
      ];
    default:
      return [
        [const Offset(30.0, 50.0), const Offset(50.0, 30.0), const Offset(70.0, 50.0), const Offset(50.0, 70.0), const Offset(30.0, 50.0)],
      ];
  }
}

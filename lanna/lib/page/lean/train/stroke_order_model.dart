import 'package:flutter/material.dart';

import 'package:lanna/services/character_stroke_service.dart';

enum StrokeReviewStatus { expertVerified, needsExpertReview }

@immutable
class StrokeDefinition {
  final int order;
  final List<Offset> points;
  final Color color;

  const StrokeDefinition({
    required this.order,
    required this.points,
    required this.color,
  });

  Offset get start => points.first;
  Offset get end => points.last;
}

@immutable
class CharacterStrokeOrder {
  final String character;
  final List<StrokeDefinition> strokes;
  final StrokeReviewStatus reviewStatus;
  final String sourceNote;

  const CharacterStrokeOrder({
    required this.character,
    required this.strokes,
    required this.reviewStatus,
    required this.sourceNote,
  });

  int get strokeCount => strokes.length;
  bool get requiresExpertReview =>
      reviewStatus == StrokeReviewStatus.needsExpertReview;
}

const List<Color> strokeOrderColors = [
  Color(0xFF2457D6), // 1 blue
  Color(0xFFD32F2F), // 2 red
  Color(0xFF2E9B45), // 3 green
  Color(0xFF252525), // 4 black
  Color(0xFF7B3FB5), // 5 purple
  Color(0xFF00838F), // 6 teal
  Color(0xFFF57C00), // 7 orange
];

/// Central adapter used by every stroke-order screen.
///
/// Existing coordinates were digitized inside this project and have not yet
/// been confirmed against an authoritative Lanna handwriting reference.
/// Therefore they are deliberately marked as requiring expert review.
CharacterStrokeOrder? getCharacterStrokeOrder(String rawCharacter) {
  final character = rawCharacter.trim().replaceAll(
    RegExp(r'[\u200B-\u200F\uFEFF]'),
    '',
  );
  final paths = getStrokeData(character);
  final nonEmpty = paths.where((path) => path.isNotEmpty).toList();
  if (nonEmpty.isEmpty) return null;

  return CharacterStrokeOrder(
    character: character,
    strokes: [
      for (var index = 0; index < nonEmpty.length; index++)
        StrokeDefinition(
          order: index + 1,
          points: List.unmodifiable(nonEmpty[index]),
          color: strokeOrderColors[index % strokeOrderColors.length],
        ),
    ],
    reviewStatus: StrokeReviewStatus.needsExpertReview,
    sourceNote: 'ต้องตรวจสอบกับผู้เชี่ยวชาญ/ตำราอักษรล้านนา',
  );
}

Path buildStrokePath(List<Offset> points, Offset Function(Offset) transform) {
  final path = Path();
  if (points.isEmpty) return path;
  final transformed = points.map(transform).toList();
  path.moveTo(transformed.first.dx, transformed.first.dy);
  if (transformed.length == 1) return path;
  if (transformed.length == 2) {
    path.lineTo(transformed.last.dx, transformed.last.dy);
    return path;
  }
  for (var index = 0; index < transformed.length - 1; index++) {
    final p0 = transformed[(index - 1).clamp(0, transformed.length - 1)];
    final p1 = transformed[index];
    final p2 = transformed[index + 1];
    final p3 = transformed[(index + 2).clamp(0, transformed.length - 1)];
    // Keep short stroke tails close to their control points so they do not
    // overshoot and curl upward at the end.
    path.cubicTo(
      p1.dx + (p2.dx - p0.dx) / 9,
      p1.dy + (p2.dy - p0.dy) / 9,
      p2.dx - (p3.dx - p1.dx) / 9,
      p2.dy - (p3.dy - p1.dy) / 9,
      p2.dx,
      p2.dy,
    );
  }
  return path;
}

void drawDashedStroke(
  Canvas canvas,
  Path path,
  Paint paint, {
  double dashLength = 8,
  double gapLength = 6,
}) {
  for (final metric in path.computeMetrics()) {
    var distance = 0.0;
    while (distance < metric.length) {
      final end = (distance + dashLength).clamp(0.0, metric.length);
      canvas.drawPath(metric.extractPath(distance, end), paint);
      distance += dashLength + gapLength;
    }
  }
}

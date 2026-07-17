import 'dart:math';
import 'package:flutter/material.dart';
import 'stroke_data.dart';

class WritingAIService {
  static double analyze({
    required List<Offset> strokes, // Normalized user points (0 to 100)
    required String targetChar,
  }) {
    if (strokes.isEmpty) return 0;

    // 1. ดึงลายเส้นตัวอักษรแม่แบบ
    final templateStrokes = getStrokeData(targetChar);
    if (templateStrokes.isEmpty) return 50.0; // ค่าเริ่มต้นหากไม่มีข้อมูล

    // ทำการ Interpolate เพื่อสร้างจุดความหนาแน่นสูงบนเส้นแม่แบบ
    final templatePoints = _interpolatePath(templateStrokes, spacing: 1.5);
    if (templatePoints.isEmpty) return 50.0;

    // แยกเส้นวาดของผู้ใช้และทำการ Interpolate
    final userStrokes = _splitStrokes(strokes);
    final userPoints = _interpolatePath(userStrokes, spacing: 1.5);
    if (userPoints.isEmpty) return 0;

    // 2. คำนวณความสอดคล้อง (Coverage)
    // สำหรับทุกจุดในแม่แบบ ต้องมีจุดผู้ใช้อยู่ใกล้ๆ
    int coveredCount = 0;
    const double threshold = 16.0; // ระยะห่างที่อนุญาตบน 100x100 grid

    for (final tp in templatePoints) {
      double minDist = double.infinity;
      for (final up in userPoints) {
        final dist = (tp - up).distance;
        if (dist < minDist) {
          minDist = dist;
        }
      }
      if (minDist <= threshold) {
        coveredCount++;
      }
    }
    final coverage = coveredCount / templatePoints.length;

    // 3. คำนวณความแม่นยำ (Accuracy)
    // จุดวาดของผู้ใช้ต้องไม่ลากออกนอกเส้นเฉไฉไปทางอื่น
    int accurateCount = 0;
    for (final up in userPoints) {
      double minDist = double.infinity;
      for (final tp in templatePoints) {
        final dist = (up - tp).distance;
        if (dist < minDist) {
          minDist = dist;
        }
      }
      if (minDist <= threshold) {
        accurateCount++;
      }
    }
    final accuracy = accurateCount / userPoints.length;

    // 4. คำนวณคะแนนรวม
    // ให้สัดส่วนของ Coverage 65% และ Accuracy 35%
    double finalScore = (coverage * 0.65 + accuracy * 0.35) * 100;

    // เติม randomness เล็กน้อยเพื่อความเป็นธรรมชาติ
    finalScore += Random().nextDouble() * 2;

    return finalScore.clamp(0, 100);
  }

  /// แยกเส้นเป็น Stroke ย่อยๆ
  static List<List<Offset>> _splitStrokes(List<Offset> points) {
    final List<List<Offset>> strokes = [];
    List<Offset> current = [];
    for (final p in points) {
      if (p == Offset.infinite) {
        if (current.isNotEmpty) {
          strokes.add(current);
          current = [];
        }
      } else {
        current.add(p);
      }
    }
    if (current.isNotEmpty) {
      strokes.add(current);
    }
    return strokes;
  }

  /// เติมจุดระหว่างเส้นโค้ง/เส้นตรง เพื่อการคำนวณระยะห่างจุดต่อจุดที่สมบูรณ์ขึ้น
  static List<Offset> _interpolatePath(List<List<Offset>> strokes, {required double spacing}) {
    final List<Offset> points = [];
    for (final stroke in strokes) {
      if (stroke.isEmpty) continue;
      points.add(stroke[0]);
      for (int i = 0; i < stroke.length - 1; i++) {
        final p1 = stroke[i];
        final p2 = stroke[i + 1];
        final dist = (p2 - p1).distance;
        if (dist < spacing) continue;

        final steps = (dist / spacing).floor();
        for (int s = 1; s <= steps; s++) {
          final t = s / steps;
          points.add(Offset(
            p1.dx + (p2.dx - p1.dx) * t,
            p1.dy + (p2.dy - p1.dy) * t,
          ));
        }
      }
    }
    return points;
  }
}

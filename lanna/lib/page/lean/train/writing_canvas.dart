import 'package:flutter/material.dart';
import 'writing_ai_service.dart';
import 'stroke_data.dart';

class WritingCanvas extends StatefulWidget {
  final ValueChanged<List<Offset>> onChanged;
  final String guideChar;
  final String character;
  final String fontFamily;

  const WritingCanvas({
    super.key,
    required this.onChanged,
    required this.guideChar,
    required this.character,
    this.fontFamily = 'LannaFont',
  });

  @override
  WritingCanvasState createState() => WritingCanvasState();
}

class WritingCanvasState extends State<WritingCanvas> {
  final List<Offset> _points = [];
  double _accuracy = 0.0;

  /// 🧹 ล้างกระดาน
  void clear() {
    setState(() {
      _points.clear();
      _accuracy = 0.0;
    });
    widget.onChanged(_points);
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return Stack(
          children: [
            // Drawing canvas (paints both font guide and drawing strokes)
            Positioned.fill(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onPanStart: (details) {
                  final box = context.findRenderObject() as RenderBox;
                  final point = box.globalToLocal(details.globalPosition);
                  final width = box.size.width > 0 ? box.size.width : 1.0;
                  final height = box.size.height > 0 ? box.size.height : 1.0;
                  
                  final normalizedPoint = Offset(
                    (point.dx * 100 / width).clamp(0.0, 100.0),
                    (point.dy * 100 / height).clamp(0.0, 100.0),
                  );

                  setState(() => _points.add(normalizedPoint));
                  widget.onChanged(_points);
                },
                onPanUpdate: (details) {
                  final box = context.findRenderObject() as RenderBox;
                  final point = box.globalToLocal(details.globalPosition);
                  final width = box.size.width > 0 ? box.size.width : 1.0;
                  final height = box.size.height > 0 ? box.size.height : 1.0;

                  final normalizedPoint = Offset(
                    (point.dx * 100 / width).clamp(0.0, 100.0),
                    (point.dy * 100 / height).clamp(0.0, 100.0),
                  );

                  setState(() => _points.add(normalizedPoint));
                  widget.onChanged(_points);
                },
                onPanEnd: (_) {
                  _points.add(Offset.infinite);

                  final score = WritingAIService.analyze(
                    strokes: _points,
                    targetChar: widget.guideChar,
                  );

                  setState(() => _accuracy = score);
                },
                child: CustomPaint(
                  painter: _WritingPainter(
                    points: _points,
                    guideChar: widget.guideChar,
                  ),
                ),
              ),
            ),

            // ================== ปุ่มล้าง ==================
            Positioned(
              top: 16,
              right: 16,
              child: GestureDetector(
                onTap: clear,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0xFFEADBC8)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.04),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.refresh, color: Color(0xFF2C1A04), size: 16),
                      SizedBox(width: 4),
                      Text(
                        'ล้าง',
                        style: TextStyle(
                          color: Color(0xFF2C1A04),
                          fontSize: 8,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // ================== ความถูกต้อง ==================
            Positioned(
              bottom: 16,
              left: 0,
              right: 0,
              child: IgnorePointer(
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: _accuracy >= 80
                          ? const Color(0xFFE8F8F5)
                          : _accuracy >= 50
                              ? const Color(0xFFFEF9E7)
                              : const Color(0xFFFDEDEC),
                      borderRadius: BorderRadius.circular(100),
                      border: Border.all(
                        color: _accuracy >= 80
                            ? const Color(0xFFA3E4D7)
                            : _accuracy >= 50
                                ? const Color(0xFFF9E79F)
                                : const Color(0xFFFADBD8),
                        width: 1.0,
                      ),
                    ),
                    child: Text(
                      'ความถูกต้อง ${_accuracy.toStringAsFixed(1)}%',
                      style: TextStyle(
                        fontSize: 8,
                        fontWeight: FontWeight.bold,
                        color: _accuracy >= 80
                            ? const Color(0xFF117A65)
                            : _accuracy >= 50
                                ? const Color(0xFFB7950B)
                                : const Color(0xFF922B21),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _WritingPainter extends CustomPainter {
  final List<Offset> points;
  final String guideChar;

  _WritingPainter({required this.points, required this.guideChar});

  @override
  void paint(Canvas canvas, Size size) {
    // 0. Draw dotted grid background
    final paintDot = Paint()..color = const Color(0xFFDCC8B8).withValues(alpha: 0.4);
    const double spacing = 16.0;
    for (double x = spacing; x < size.width; x += spacing) {
      for (double y = spacing; y < size.height; y += spacing) {
        canvas.drawCircle(Offset(x, y), 1.0, paintDot);
      }
    }

    // Helper ในการสเกลพิกัด 100x100 -> ขนาด Canvas จริง
    Offset scale(Offset o) {
      return Offset(o.dx * size.width / 100, o.dy * size.height / 100);
    }

    // Helper: Catmull-Rom spline
    Path catmullRomPath(List<Offset> pts, Offset Function(Offset) scaler) {
      final path = Path();
      if (pts.isEmpty) return path;
      final scaled = pts.map(scaler).toList();
      path.moveTo(scaled[0].dx, scaled[0].dy);
      if (scaled.length == 1) return path;
      if (scaled.length == 2) { path.lineTo(scaled[1].dx, scaled[1].dy); return path; }
      for (int i = 0; i < scaled.length - 1; i++) {
        final p0 = scaled[(i - 1).clamp(0, scaled.length - 1)];
        final p1 = scaled[i];
        final p2 = scaled[i + 1];
        final p3 = scaled[(i + 2).clamp(0, scaled.length - 1)];
        final cp1x = p1.dx + (p2.dx - p0.dx) / 6;
        final cp1y = p1.dy + (p2.dy - p0.dy) / 6;
        final cp2x = p2.dx - (p3.dx - p1.dx) / 6;
        final cp2y = p2.dy - (p3.dy - p1.dy) / 6;
        path.cubicTo(cp1x, cp1y, cp2x, cp2y, p2.dx, p2.dy);
      }
      return path;
    }

    // 2. ดึงลายเส้นตัวอักษรจริงสำหรับลำดับการเขียน (Ghost Character Template)
    final templateStrokes = getStrokeData(guideChar);

    // 1. วาดเส้นไกด์พื้นหลังสี #F5D5C0 (ตามพิกัดจริง)
    final paintGuide = Paint()
      ..color = const Color(0xFFF5D5C0)
      ..strokeWidth = 14
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    for (int i = 0; i < templateStrokes.length; i++) {
      final pts = templateStrokes[i];
      if (pts.isEmpty) continue;
      canvas.drawPath(catmullRomPath(pts, scale), paintGuide);
    }

    // 3. วาดจุดแสดงลำดับเส้น 1, 2, 3... พร้อมทิศทาง
    final paintCircleBg = Paint()..color = const Color(0xFFEADBC8);
    final paintCircleBorder = Paint()
      ..color = const Color(0xFF7A5C3A).withValues(alpha: 0.5)
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;

    for (int i = 0; i < templateStrokes.length; i++) {
      if (templateStrokes[i].isEmpty) continue;
      final startPt = scale(templateStrokes[i][0]);
      canvas.drawCircle(startPt, 10, paintCircleBg);
      canvas.drawCircle(startPt, 10, paintCircleBorder);

      final numPainter = TextPainter(
        text: TextSpan(
          text: '${i + 1}',
          style: const TextStyle(
            fontSize: 8,
            fontWeight: FontWeight.bold,
            color: Color(0xFF7A5C3A),
            fontFamily: 'sans-serif',
          ),
        ),
        textDirection: TextDirection.ltr,
      );
      numPainter.layout();
      numPainter.paint(
        canvas,
        Offset(startPt.dx - numPainter.width / 2, startPt.dy - numPainter.height / 2),
      );

      // Draw end point dot to show direction (from start Pt to end Pt)
      if (templateStrokes[i].length > 1) {
        final endPt = scale(templateStrokes[i].last);
        final paintEndDot = Paint()..color = const Color(0xFFD2691E);
        canvas.drawCircle(endPt, 4, paintEndDot);
      }
    }

    // 4. วาดเส้นที่ผู้ใช้ลากเขียน
    final paintUser = Paint()
      ..color = const Color(0xFF924E19)
      ..strokeWidth = 10
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    for (int i = 0; i < points.length - 1; i++) {
      if (points[i] != Offset.infinite && points[i + 1] != Offset.infinite) {
        canvas.drawLine(scale(points[i]), scale(points[i + 1]), paintUser);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _WritingPainter oldDelegate) => true;
}
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'glyph_layout.dart';
import 'writing_ai_service.dart';
import 'stroke_order_model.dart';

class WritingCanvas extends StatefulWidget {
  final ValueChanged<List<Offset>> onChanged;
  final String guideChar;
  final String character;
  final String fontFamily;
  final bool showStrokeOrder;
  final double maxGlyphExtent;
  final double targetGlyphInkArea;
  /// ถ้า true จะวาดข้อความ [tracingText] เป็นแบบนำตามสีน้ำตาลอ่อนบนกระดาน
  final bool showTracingGuide;
  /// ข้อความล้านนาที่จะแสดงเป็น Tracing Guide (ใช้เมื่อ showTracingGuide = true)
  final String tracingText;

  const WritingCanvas({
    super.key,
    required this.onChanged,
    required this.guideChar,
    required this.character,
    this.fontFamily = 'PayapLanna',
    this.showStrokeOrder = true,
    this.maxGlyphExtent = 150,
    this.targetGlyphInkArea = 3500,
    this.showTracingGuide = false,
    this.tracingText = '',
  });

  @override
  WritingCanvasState createState() => WritingCanvasState();
}

class WritingCanvasState extends State<WritingCanvas> {
  final List<Offset> _points = [];
  double _accuracy = 0.0;
  int _analysisVersion = 0;

  /// 🧹 ล้างกระดาน
  void clear() {
    _analysisVersion++;
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
            // Drawing canvas paints the pale glyph, stroke-order overlay and
            // user ink in one coordinate system so every marker stays aligned.
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
                onPanEnd: (_) async {
                  final renderBox = context.findRenderObject() as RenderBox;
                  final analysisVersion = ++_analysisVersion;
                  setState(() => _points.add(Offset.infinite));
                  widget.onChanged(_points);

                  final score = await WritingAIService.analyze(
                    strokes: List.unmodifiable(_points),
                    targetChar: widget.guideChar,
                    fontFamily: widget.fontFamily,
                    canvasSize: renderBox.size,
                    maxGlyphExtent: widget.maxGlyphExtent,
                    targetGlyphInkArea: widget.targetGlyphInkArea,
                  );

                  if (mounted && analysisVersion == _analysisVersion) {
                    setState(() => _accuracy = score);
                  }
                },
                child: CustomPaint(
                  painter: _WritingPainter(
                    points: _points,
                    guideChar: widget.guideChar,
                    fontFamily: widget.fontFamily,
                    showStrokeOrder: widget.showStrokeOrder,
                    maxGlyphExtent: widget.maxGlyphExtent,
                    completedStrokeCount: _points
                        .where((point) => point == Offset.infinite)
                        .length,
                    showTracingGuide: widget.showTracingGuide,
                    tracingText: widget.tracingText,
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
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 6,
                  ),
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
  final String fontFamily;
  final bool showStrokeOrder;
  final double maxGlyphExtent;
  final int completedStrokeCount;
  final bool showTracingGuide;
  final String tracingText;

  _WritingPainter({
    required this.points,
    required this.guideChar,
    required this.fontFamily,
    required this.showStrokeOrder,
    required this.maxGlyphExtent,
    required this.completedStrokeCount,
    this.showTracingGuide = false,
    this.tracingText = '',
  });

  @override
  void paint(Canvas canvas, Size size) {
    // 0. Draw dotted grid background
    final paintDot = Paint()
      ..color = const Color(0xFFDCC8B8).withValues(alpha: 0.4);
    const double spacing = 16.0;
    for (double x = spacing; x < size.width; x += spacing) {
      for (double y = spacing; y < size.height; y += spacing) {
        canvas.drawCircle(Offset(x, y), 1.0, paintDot);
      }
    }

    // 0.5 วาด Tracing Guide — แสดงคำล้านนาสีน้ำตาลอ่อนเพื่อให้ผู้ใช้วาดตาม
    if (showTracingGuide && tracingText.isNotEmpty) {
      _drawTracingGuide(canvas, size);
    }

    // User input remains normalized against the entire writing canvas.
    Offset scale(Offset o) {
      return Offset(o.dx * size.width / 100, o.dy * size.height / 100);
    }

    // Draw the real glyph and its stroke metadata through the exact same
    // layout. This guarantees that 1, 2, 3 and the arrows sit on the pale ink.
    final guidePadding = math.max(
      0.0,
      (size.shortestSide - maxGlyphExtent) / 2,
    );
    final glyphLayout = layoutWritingGlyph(
      character: guideChar,
      fontFamily: fontFamily,
      size: size,
      padding: guidePadding,
    );
    final orderData = getCharacterStrokeOrder(guideChar);

    if (showStrokeOrder && orderData != null) {
      // Build the worksheet outline from the authored teaching paths. This
      // keeps the outline, dotted centreline and arrows on the exact same
      // geometry and does not depend on platform font rendering.
      for (final stroke in orderData.strokes) {
        final strokePath = buildStrokePath(
          stroke.points,
          glyphLayout.positionFromNormalized,
        );
        canvas.drawPath(
          strokePath,
          Paint()
            ..color = const Color(0xFF7A5C3A).withValues(alpha: 0.38)
            ..strokeWidth = 15
            ..strokeCap = StrokeCap.round
            ..strokeJoin = StrokeJoin.round
            ..style = PaintingStyle.stroke,
        );
        canvas.drawPath(
          strokePath,
          Paint()
            ..color = const Color(0xFFFFFBF6).withValues(alpha: 0.96)
            ..strokeWidth = 10
            ..strokeCap = StrokeCap.round
            ..strokeJoin = StrokeJoin.round
            ..style = PaintingStyle.stroke,
        );
      }

      // Paint every teaching stroke as a coloured dotted centreline on top of
      // the pale glyph. All categories use this painter, so consonants,
      // vowels, tones, numbers and compound forms share the same guide style.
      for (final stroke in orderData.strokes) {
        final strokePath = buildStrokePath(
          stroke.points,
          glyphLayout.positionFromNormalized,
        );
        final isCurrent = stroke.order == completedStrokeCount + 1;
        drawDashedStroke(
          canvas,
          strokePath,
          Paint()
            ..color = stroke.color.withValues(alpha: isCurrent ? 0.95 : 0.62)
            ..strokeWidth = isCurrent ? 3.2 : 2.5
            ..strokeCap = StrokeCap.round
            ..strokeJoin = StrokeJoin.round
            ..style = PaintingStyle.stroke,
          dashLength: isCurrent ? 7 : 5,
          gapLength: isCurrent ? 4 : 5,
        );
      }

      for (final stroke in orderData.strokes) {
        final startPt = glyphLayout.positionFromNormalized(stroke.start);
        final isCurrent = stroke.order == completedStrokeCount + 1;
        final markerFill = Paint()
          ..color = stroke.color.withValues(alpha: isCurrent ? 1 : 0.16);
        final markerBorder = Paint()
          ..color = stroke.color.withValues(alpha: isCurrent ? 1 : 0.72)
          ..strokeWidth = 1.2
          ..style = PaintingStyle.stroke;
        canvas.drawCircle(startPt, 9, markerFill);
        canvas.drawCircle(startPt, 9, markerBorder);

        final numPainter = TextPainter(
          text: TextSpan(
            text: '${stroke.order}',
            style: TextStyle(
              fontSize: 8,
              fontWeight: FontWeight.bold,
              color: isCurrent ? Colors.white : stroke.color,
              fontFamily: 'sans-serif',
            ),
          ),
          textDirection: TextDirection.ltr,
        );
        numPainter.layout();
        numPainter.paint(
          canvas,
          Offset(
            startPt.dx - numPainter.width / 2,
            startPt.dy - numPainter.height / 2,
          ),
        );

        // Show the initial writing direction without covering the full glyph.
        // Pick a point far enough from the numbered start to make the arrow
        // readable even when the source path contains dense control points.
        if (stroke.points.length > 1) {
          var directionPoint = stroke.points[1];
          for (final candidate in stroke.points.skip(1)) {
            directionPoint = candidate;
            if ((candidate - stroke.start).distance >= 12) break;
          }
          final arrowEnd = glyphLayout.positionFromNormalized(directionPoint);
          _drawDirectionArrow(
            canvas,
            startPt,
            arrowEnd,
            color: stroke.color,
            isCurrent: isCurrent,
          );
        }
      }
    }

    // 3. วาดเส้นที่ผู้ใช้ลากเขียน
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

  /// วาดตัวอักษรล้านนาเป็น Tracing Guide สีน้ำตาลอ่อนตรงกลางกระดาน
  void _drawTracingGuide(Canvas canvas, Size size) {
    // คำนวณขนาดฟอนต์ให้พอดีกับกระดาน
    final double fontSize = (size.shortestSide * 0.55).clamp(40.0, 160.0);
    final painter = TextPainter(
      text: TextSpan(
        text: tracingText,
        style: TextStyle(
          fontFamily: fontFamily,
          fontSize: fontSize,
          color: const Color(0xFFA0724A).withValues(alpha: 0.18),
          fontWeight: FontWeight.bold,
          letterSpacing: 2.0,
        ),
      ),
      textDirection: TextDirection.ltr,
      textAlign: TextAlign.center,
    );

    painter.layout(maxWidth: size.width * 0.88);

    // วางตัวอักษรกึ่งกลางกระดาน (เยื้องขึ้นเล็กน้อยเพราะตัวอักษรล้านนามีส่วนล่าง)
    final dx = (size.width - painter.width) / 2;
    final dy = (size.height - painter.height) / 2 - size.height * 0.02;
    painter.paint(canvas, Offset(dx, dy));
  }

  @override
  bool shouldRepaint(covariant _WritingPainter oldDelegate) => true;

  void _drawDirectionArrow(
    Canvas canvas,
    Offset start,
    Offset rawEnd, {
    required Color color,
    required bool isCurrent,
  }) {
    final vector = rawEnd - start;
    if (vector.distance < 3) return;
    final unit = vector / vector.distance;
    final lineStart = start + unit * 11;
    final lineEnd = start + unit * math.min(vector.distance, 27);
    final arrowColor = color.withValues(alpha: isCurrent ? 1 : 0.72);
    final paint = Paint()
      ..color = arrowColor
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    canvas.drawLine(lineStart, lineEnd, paint);

    const headLength = 6.0;
    const headAngle = math.pi / 6;
    final angle = math.atan2(unit.dy, unit.dx);
    final left =
        lineEnd -
        Offset(
          math.cos(angle - headAngle) * headLength,
          math.sin(angle - headAngle) * headLength,
        );
    final right =
        lineEnd -
        Offset(
          math.cos(angle + headAngle) * headLength,
          math.sin(angle + headAngle) * headLength,
        );
    final arrowHead = Path()
      ..moveTo(left.dx, left.dy)
      ..lineTo(lineEnd.dx, lineEnd.dy)
      ..lineTo(right.dx, right.dy);
    canvas.drawPath(arrowHead, paint);
  }
}

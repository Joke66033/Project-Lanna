import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'glyph_layout.dart';
import 'writing_ai_service.dart';
import 'stroke_order_model.dart';
import 'package:lanna/services/character_stroke_service.dart';

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
    this.fontFamily = 'LNTilok',
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
  final CharacterStrokeService _strokeService = CharacterStrokeService();

  @override
  void initState() {
    super.initState();
    _fetchStroke();
  }

  @override
  void didUpdateWidget(covariant WritingCanvas oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.guideChar != widget.guideChar) {
      _fetchStroke();
    }
  }

  Future<void> _fetchStroke() async {
    if (widget.guideChar.trim().isEmpty) return;
    final model = await _strokeService.getStrokeByChar(widget.guideChar);
    if (mounted && model != null) {
      setState(() {});
    }
  }

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

    final orderData = getCharacterStrokeOrder(guideChar);

    if (showStrokeOrder && orderData != null && orderData.strokes.isNotEmpty) {
      final characterRunes = guideChar.runes.toList();
      final isFloatingVowelOrMark =
          characterRunes.length == 1 &&
          characterRunes.first >= 0x1A65 &&
          characterRunes.first <= 0x1A7C;

      // 1. คำนวณ Bounding Box ของเส้นลำดับขีดทั้งหมด เพื่อจัดกึ่งกลางและปรับขนาดให้พอดีสวยงามเสมอ
      double minX = 100.0, minY = 100.0, maxX = 0.0, maxY = 0.0;
      bool hasPoints = false;
      for (final stroke in orderData.strokes) {
        for (final pt in stroke.points) {
          hasPoints = true;
          if (pt.dx < minX) minX = pt.dx;
          if (pt.dy < minY) minY = pt.dy;
          if (pt.dx > maxX) maxX = pt.dx;
          if (pt.dy > maxY) maxY = pt.dy;
        }
      }

      final double charWidth = hasPoints ? math.max(20.0, maxX - minX) : 60.0;
      final double charHeight = hasPoints ? math.max(20.0, maxY - minY) : 60.0;
      final double charCenterX = hasPoints ? (minX + maxX) / 2.0 : 50.0;
      final double charCenterY = hasPoints ? (minY + maxY) / 2.0 : 50.0;

      final double targetSize = size.shortestSide * (isFloatingVowelOrMark ? 0.38 : 0.54);
      final double scaleFactor = targetSize / math.max(charWidth, charHeight);

      Offset strokeTransform(Offset point) {
        final double scaledX = (point.dx - charCenterX) * scaleFactor;
        final double scaledY = (point.dy - charCenterY) * scaleFactor;
        return Offset(
          size.width / 2.0 + scaledX,
          size.height / 2.0 + scaledY,
        );
      }

      // 2. วาดเส้นร่างแม่แบบวิธีเขียน (Stroke Guide Line) เหมือนรูปที่ 2
      final guidePaint = Paint()
        ..color = const Color(0xFFD9D2CB).withValues(alpha: 0.85)
        ..strokeWidth = 6.0
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..style = PaintingStyle.stroke;

      final innerGuidePaint = Paint()
        ..color = const Color(0xFF924E19).withValues(alpha: 0.35)
        ..strokeWidth = 2.5
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..style = PaintingStyle.stroke;

      for (final stroke in orderData.strokes) {
        if (stroke.points.isEmpty) continue;
        final strokePath = buildStrokePath(stroke.points, strokeTransform);
        canvas.drawPath(strokePath, guidePaint);
        drawDashedStroke(
          canvas,
          strokePath,
          innerGuidePaint,
          dashLength: 6,
          gapLength: 4,
        );
      }

      // 3. วาดจุดเริ่มต้นของเส้นพร้อมตัวเลขลำดับ (1, 2, 3) สีส้มสดใส เหมือนรูปที่ 2
      for (int i = 0; i < orderData.strokes.length; i++) {
        final stroke = orderData.strokes[i];
        if (stroke.points.isEmpty) continue;
        final startPt = strokeTransform(stroke.points.first);
        final isFirst = i == 0;
        final isCompleted = i < completedStrokeCount;

        // วงกลมพื้นหลังจุดเริ่มต้น (สีส้มสดใส #FF9800 สำหรับเส้นที่ 1 เหมือนรูปที่ 2)
        canvas.drawCircle(
          startPt,
          10.5,
          Paint()
            ..color = isFirst
                ? const Color(0xFFFF9800)
                : (isCompleted
                    ? const Color(0xFF4CAF50)
                    : const Color(0xFF8D6E63))
            ..style = PaintingStyle.fill,
        );

        // ขอบขาวเพื่อความคมชัด
        canvas.drawCircle(
          startPt,
          10.5,
          Paint()
            ..color = Colors.white
            ..strokeWidth = 1.8
            ..style = PaintingStyle.stroke,
        );

        // ตัวเลขลำดับขีด 1, 2, 3...
        final tp = TextPainter(
          text: TextSpan(
            text: '${i + 1}',
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: Colors.white,
              fontFamily: 'sans-serif',
            ),
          ),
          textDirection: TextDirection.ltr,
        );
        tp.layout();
        tp.paint(
          canvas,
          Offset(startPt.dx - tp.width / 2, startPt.dy - tp.height / 2),
        );
      }
    } else {
      // Fallback ถ้าไม่มีข้อมูลเส้น ให้แสดงตัวอักษรจางๆ กึ่งกลาง
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
      glyphLayout.paint(
        canvas,
        const Color(0xFF8D6E63).withValues(alpha: 0.16),
      );
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
}

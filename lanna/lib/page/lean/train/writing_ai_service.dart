import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import 'glyph_layout.dart';

class WritingAIService {
  static Future<double> analyze({
    required List<Offset> strokes,
    required String targetChar,
    required String fontFamily,
    required Size canvasSize,
    double maxGlyphExtent = 150,
    double targetGlyphInkArea = 3500,
  }) async {
    if (strokes.every((point) => point == Offset.infinite)) return 0;
    if (canvasSize.isEmpty) return 0;

    final width = math.max(1, canvasSize.width.ceil());
    final height = math.max(1, canvasSize.height.ceil());
    final target = await _renderTargetMask(
      character: targetChar,
      fontFamily: fontFamily,
      size: Size(width.toDouble(), height.toDouble()),
      maxGlyphExtent: maxGlyphExtent,
      targetGlyphInkArea: targetGlyphInkArea,
    );
    final user = await _renderUserMask(
      strokes: strokes,
      size: Size(width.toDouble(), height.toDouble()),
    );

    var targetArea = 0;
    var userArea = 0;
    var coveredTarget = 0;
    var accurateUser = 0;
    const tolerance = 7;

    for (var y = 0; y < height; y++) {
      for (var x = 0; x < width; x++) {
        final index = y * width + x;
        final isTarget = target[index] > 20;
        final isUser = user[index] > 20;
        if (isTarget) {
          targetArea++;
          if (_hasInkNear(user, width, height, x, y, tolerance)) {
            coveredTarget++;
          }
        }
        if (isUser) {
          userArea++;
          if (_hasInkNear(target, width, height, x, y, tolerance)) {
            accurateUser++;
          }
        }
      }
    }

    if (targetArea == 0 || userArea == 0) return 0;
    final coverage = coveredTarget / targetArea;
    final precision = accurateUser / userArea;
    return ((coverage * 0.60 + precision * 0.40) * 100).clamp(0, 100);
  }

  static Future<Uint8List> _renderTargetMask({
    required String character,
    required String fontFamily,
    required Size size,
    required double maxGlyphExtent,
    required double targetGlyphInkArea,
  }) async {
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    final glyph = await rasterizeWritingGlyph(
      character: character,
      fontFamily: fontFamily,
    );
    paintRasterizedWritingGlyph(
      canvas: canvas,
      size: size,
      glyph: glyph,
      color: Colors.white,
      padding: writingGuidePadding,
      sizeFactor: 1,
      maxExtent: maxGlyphExtent,
      targetInkArea: targetGlyphInkArea,
    );
    return _pictureToAlpha(recorder.endRecording(), size);
  }

  static Future<Uint8List> _renderUserMask({
    required List<Offset> strokes,
    required Size size,
  }) async {
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    final paint = Paint()
      ..color = Colors.white
      ..strokeWidth = 10
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    Offset scale(Offset point) => Offset(
      point.dx * size.width / 100,
      point.dy * size.height / 100,
    );

    for (var index = 0; index < strokes.length - 1; index++) {
      final start = strokes[index];
      final end = strokes[index + 1];
      if (start != Offset.infinite && end != Offset.infinite) {
        canvas.drawLine(scale(start), scale(end), paint);
      }
    }
    return _pictureToAlpha(recorder.endRecording(), size);
  }

  static Future<Uint8List> _pictureToAlpha(
    ui.Picture picture,
    Size size,
  ) async {
    final image = await picture.toImage(size.width.ceil(), size.height.ceil());
    final bytes = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
    image.dispose();
    picture.dispose();
    if (bytes == null) return Uint8List(size.width.ceil() * size.height.ceil());

    final rgba = bytes.buffer.asUint8List();
    final alpha = Uint8List(rgba.length ~/ 4);
    for (var index = 0; index < alpha.length; index++) {
      alpha[index] = rgba[index * 4 + 3];
    }
    return alpha;
  }

  static bool _hasInkNear(
    Uint8List mask,
    int width,
    int height,
    int x,
    int y,
    int radius,
  ) {
    final minX = math.max(0, x - radius);
    final maxX = math.min(width - 1, x + radius);
    final minY = math.max(0, y - radius);
    final maxY = math.min(height - 1, y + radius);
    final radiusSquared = radius * radius;
    for (var nearY = minY; nearY <= maxY; nearY++) {
      for (var nearX = minX; nearX <= maxX; nearX++) {
        final dx = nearX - x;
        final dy = nearY - y;
        if (dx * dx + dy * dy <= radiusSquared &&
            mask[nearY * width + nearX] > 20) {
          return true;
        }
      }
    }
    return false;
  }
}

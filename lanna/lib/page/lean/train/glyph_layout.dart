import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

const double writingGuidePadding = 104;
const double writingGlyphFontSize = 1000;
const double _rasterGlyphFontSize = 256;

@immutable
class RasterizedWritingGlyph {
  final ui.Image image;
  final Rect inkBounds;
  final int inkPixelCount;

  const RasterizedWritingGlyph({
    required this.image,
    required this.inkBounds,
    required this.inkPixelCount,
  });
}

final Map<String, Future<RasterizedWritingGlyph>> _glyphRasterCache = {};

Future<RasterizedWritingGlyph> rasterizeWritingGlyph({
  required String character,
  required String fontFamily,
}) {
  final normalized = normalizeWritingCharacter(character);
  final cacheKey = '$fontFamily\u0000$normalized';
  return _glyphRasterCache.putIfAbsent(cacheKey, () async {
    final painter = TextPainter(
      text: TextSpan(
        text: '\u00A0$normalized\u00A0',
        style: TextStyle(
          fontFamily: fontFamily,
          fontFamilyFallback: const ['PayapLanna', 'THSarabunNew', 'sans-serif'],
          fontSize: _rasterGlyphFontSize,
          height: 1,
          fontWeight: FontWeight.normal,
          color: Colors.white,
        ),
      ),
      textDirection: TextDirection.ltr,
      textAlign: TextAlign.center,
    )..layout();
    const margin = 256.0;
    final imageWidth = math.max(1, (painter.width + margin * 2).ceil());
    final imageHeight = math.max(1, (painter.height + margin * 2).ceil());
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    painter.paint(canvas, const Offset(margin, margin));
    final picture = recorder.endRecording();
    final image = await picture.toImage(imageWidth, imageHeight);
    picture.dispose();
    final bytes = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
    if (bytes == null) {
      return RasterizedWritingGlyph(
        image: image,
        inkBounds: Rect.fromLTWH(
          0,
          0,
          imageWidth.toDouble(),
          imageHeight.toDouble(),
        ),
        inkPixelCount: imageWidth * imageHeight,
      );
    }

    final rgba = bytes.buffer.asUint8List();
    var minX = imageWidth;
    var minY = imageHeight;
    var maxX = -1;
    var maxY = -1;
    var inkPixelCount = 0;
    for (var y = 0; y < imageHeight; y++) {
      for (var x = 0; x < imageWidth; x++) {
        if (rgba[(y * imageWidth + x) * 4 + 3] == 0) continue;
        inkPixelCount++;
        minX = math.min(minX, x);
        minY = math.min(minY, y);
        maxX = math.max(maxX, x);
        maxY = math.max(maxY, y);
      }
    }
    final bounds = maxX < minX || maxY < minY
        ? Rect.fromLTWH(0, 0, imageWidth.toDouble(), imageHeight.toDouble())
        : Rect.fromLTRB(
            minX.toDouble(),
            minY.toDouble(),
            (maxX + 1).toDouble(),
            (maxY + 1).toDouble(),
          );
    return RasterizedWritingGlyph(
      image: image,
      inkBounds: bounds,
      inkPixelCount: math.max(1, inkPixelCount),
    );
  });
}

void paintRasterizedWritingGlyph({
  required Canvas canvas,
  required Size size,
  required RasterizedWritingGlyph glyph,
  required Color color,
  required double padding,
  double sizeFactor = 1,
  double? maxExtent,
  double? targetInkArea,
}) {
  final availableWidth = math.max(1, size.width - padding * 2) * sizeFactor;
  final availableHeight = math.max(1, size.height - padding * 2) * sizeFactor;
  final available = Size(
    maxExtent == null ? availableWidth : math.min(availableWidth, maxExtent),
    maxExtent == null ? availableHeight : math.min(availableHeight, maxExtent),
  );
  final fitScale = math.min(
    available.width / glyph.inkBounds.width,
    available.height / glyph.inkBounds.height,
  );
  final inkBoundsArea = math.max(
    1.0,
    glyph.inkBounds.width * glyph.inkBounds.height,
  );
  final inkDensity = glyph.inkPixelCount / inkBoundsArea;
  final densityAdjustment = math
      .sqrt(0.30 / math.max(0.01, inkDensity))
      .clamp(0.55, 1.35);
  final opticalScale = targetInkArea == null
      ? fitScale
      : math.sqrt(targetInkArea / glyph.inkPixelCount) * densityAdjustment;
  final scale = math.min(fitScale, opticalScale);
  final destinationSize = Size(
    glyph.inkBounds.width * scale,
    glyph.inkBounds.height * scale,
  );
  final destination = Rect.fromCenter(
    center: Offset(size.width / 2, size.height / 2),
    width: destinationSize.width,
    height: destinationSize.height,
  );
  canvas.drawImageRect(
    glyph.image,
    glyph.inkBounds,
    destination,
    Paint()..colorFilter = ColorFilter.mode(color, BlendMode.srcIn),
  );
}

class CenteredWritingGlyph extends StatelessWidget {
  final String character;
  final String fontFamily;
  final Color color;
  final double padding;
  final double sizeFactor;
  final double? maxExtent;
  final double? targetInkArea;

  const CenteredWritingGlyph({
    super.key,
    required this.character,
    required this.fontFamily,
    required this.color,
    required this.padding,
    this.sizeFactor = 1,
    this.maxExtent,
    this.targetInkArea,
  });

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<RasterizedWritingGlyph>(
      future: rasterizeWritingGlyph(
        character: character,
        fontFamily: fontFamily,
      ),
      builder: (context, snapshot) {
        final glyph = snapshot.data;
        if (glyph == null) return const SizedBox.expand();
        return CustomPaint(
          painter: _RasterizedWritingGlyphPainter(
            glyph: glyph,
            color: color,
            padding: padding,
            sizeFactor: sizeFactor,
            maxExtent: maxExtent,
            targetInkArea: targetInkArea,
          ),
          size: Size.infinite,
        );
      },
    );
  }
}

class _RasterizedWritingGlyphPainter extends CustomPainter {
  final RasterizedWritingGlyph glyph;
  final Color color;
  final double padding;
  final double sizeFactor;
  final double? maxExtent;
  final double? targetInkArea;

  const _RasterizedWritingGlyphPainter({
    required this.glyph,
    required this.color,
    required this.padding,
    required this.sizeFactor,
    required this.maxExtent,
    required this.targetInkArea,
  });

  @override
  void paint(Canvas canvas, Size size) => paintRasterizedWritingGlyph(
    canvas: canvas,
    size: size,
    glyph: glyph,
    color: color,
    padding: padding,
    sizeFactor: sizeFactor,
    maxExtent: maxExtent,
    targetInkArea: targetInkArea,
  );

  @override
  bool shouldRepaint(covariant _RasterizedWritingGlyphPainter oldDelegate) =>
      glyph != oldDelegate.glyph ||
      color != oldDelegate.color ||
      padding != oldDelegate.padding ||
      sizeFactor != oldDelegate.sizeFactor ||
      maxExtent != oldDelegate.maxExtent ||
      targetInkArea != oldDelegate.targetInkArea;
}

String normalizeWritingCharacter(String character) =>
    character.replaceAll(RegExp(r'[\u200B-\u200F\u2060\uFEFF]'), '').trim();

bool isStandaloneWritingMark(String character) {
  final runes = normalizeWritingCharacter(character).runes.toList();
  if (runes.length != 1) return false;
  final codePoint = runes.single;
  return (codePoint >= 0x1A17 && codePoint <= 0x1A1B) ||
      (codePoint >= 0x1A55 && codePoint <= 0x1A5E) ||
      (codePoint >= 0x1A60 && codePoint <= 0x1A7C) ||
      codePoint == 0x1A7F;
}

double writingMarkVerticalFactor(String character) {
  // Practice glyphs are always centered as standalone shapes. Do not retain
  // their above/below position from normal syllable composition.
  return 0;
}

@immutable
class GlyphLayout {
  final String character;
  final String renderedCharacter;
  final String fontFamily;
  final TextPainter painter;
  final Rect sourceBounds;
  final double scale;
  final Offset offset;
  final Rect contentRect;

  const GlyphLayout({
    required this.character,
    required this.renderedCharacter,
    required this.fontFamily,
    required this.painter,
    required this.sourceBounds,
    required this.scale,
    required this.offset,
    required this.contentRect,
  });

  Rect get glyphRect => Rect.fromLTWH(
    offset.dx + sourceBounds.left * scale,
    offset.dy + sourceBounds.top * scale,
    sourceBounds.width * scale,
    sourceBounds.height * scale,
  );

  void paint(Canvas canvas, Color color) {
    final coloredPainter = TextPainter(
      text: TextSpan(
        text: renderedCharacter,
        style: TextStyle(
          fontFamily: fontFamily,
          fontFamilyFallback: const ['PayapLanna', 'THSarabunNew', 'sans-serif'],
          fontSize: writingGlyphFontSize,
          height: 1,
          fontWeight: FontWeight.normal,
          color: color,
        ),
      ),
      textDirection: TextDirection.ltr,
      textAlign: TextAlign.center,
    )..layout();

    canvas.save();
    canvas.translate(offset.dx, offset.dy);
    canvas.scale(scale);
    coloredPainter.paint(canvas, Offset.zero);
    canvas.restore();
  }

  Offset positionFromNormalized(Offset point) => Offset(
    glyphRect.left + point.dx * glyphRect.width / 100,
    glyphRect.top + point.dy * glyphRect.height / 100,
  );
}

GlyphLayout layoutWritingGlyph({
  required String character,
  required String fontFamily,
  required Size size,
  double padding = writingGuidePadding,
}) {
  final normalizedCharacter = normalizeWritingCharacter(character);
  final safePadding = math.min(
    padding,
    math.max(0.0, math.min(size.width, size.height) / 2 - 1.0),
  );
  final contentRect = Rect.fromLTWH(
    safePadding,
    safePadding,
    math.max(1.0, size.width - safePadding * 2),
    math.max(1.0, size.height - safePadding * 2),
  );
  TextPainter createPainter(String text) => TextPainter(
    text: TextSpan(
      text: text,
      style: TextStyle(
        fontFamily: fontFamily,
        fontFamilyFallback: const ['PayapLanna', 'THSarabunNew', 'sans-serif'],
        fontSize: writingGlyphFontSize,
        height: 1,
        fontWeight: FontWeight.normal,
        color: Colors.white,
      ),
    ),
    textDirection: TextDirection.ltr,
    textAlign: TextAlign.center,
  )..layout();
  var renderedCharacter = '\u00A0$normalizedCharacter\u00A0';
  var painter = createPainter(renderedCharacter);

  // Symmetric invisible anchors make every glyph use the same centered box as
  // the carousel preview, including multi-codepoint vowel sequences.
  final glyphBoxes = painter.getBoxesForSelection(
    TextSelection(baseOffset: 1, extentOffset: 1 + normalizedCharacter.length),
    boxHeightStyle: ui.BoxHeightStyle.tight,
    boxWidthStyle: ui.BoxWidthStyle.tight,
  );
  var sourceBounds = glyphBoxes.isEmpty
      ? Rect.fromLTWH(0, 0, painter.width, painter.height)
      : glyphBoxes.first.toRect();
  for (final box in glyphBoxes.skip(1)) {
    sourceBounds = sourceBounds.expandToInclude(box.toRect());
  }
  if (sourceBounds.width <= 1 || sourceBounds.height <= 1) {
    sourceBounds = Rect.fromLTWH(0, 0, painter.width, painter.height);
  }

  final scale = sourceBounds.width == 0 || sourceBounds.height == 0
      ? 1.0
      : math.min(
          contentRect.width / sourceBounds.width,
          contentRect.height / sourceBounds.height,
        );

  return GlyphLayout(
    character: normalizedCharacter,
    renderedCharacter: renderedCharacter,
    fontFamily: fontFamily,
    painter: painter,
    sourceBounds: sourceBounds,
    scale: scale,
    offset: Offset(
      contentRect.center.dx - sourceBounds.center.dx * scale,
      contentRect.center.dy - sourceBounds.center.dy * scale,
    ),
    contentRect: contentRect,
  );
}

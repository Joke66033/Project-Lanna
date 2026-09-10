import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:lanna/services/auth_provider.dart';
import 'package:lanna/services/lanna_char_service.dart';
import 'package:lanna/services/character_stroke_service.dart';
import 'glyph_layout.dart';
import 'stroke_order_model.dart';
import 'writing_data.dart';
import 'writing_canvas.dart';
import '../leaning/lanna_glyph_card.dart';

class WritingModePage extends StatefulWidget {
  final List<WritingItem> items;
  final String title;
  final int initialIndex;

  const WritingModePage({
    super.key,
    required this.items,
    required this.title,
    this.initialIndex = 0,
  });

  @override
  State<WritingModePage> createState() => _WritingModePageState();
}

class _WritingModePageState extends State<WritingModePage> {
  late int _index; // index ของตัวอักษร

  late final PageController _pageController;
  final GlobalKey<WritingCanvasState> _canvasKey =
      GlobalKey<WritingCanvasState>();
  final CharacterStrokeService _strokeService = CharacterStrokeService();

  @override
  void initState() {
    super.initState();
    _index = widget.initialIndex;
    _pageController = PageController(
      viewportFraction: 0.35,
      initialPage: widget.initialIndex,
    );
    _fetchCurrentStroke();
  }

  Future<void> _fetchCurrentStroke() async {
    if (widget.items.isEmpty || _index >= widget.items.length) return;
    final currentItem = widget.items[_index];
    await _strokeService.getStrokeByChar(currentItem.char);
    if (mounted) {
      setState(() {});
    }
  }

  void _showStrokeSheet(WritingItem item) {
    final strokeData = getStrokeData(item.char);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: 0.5),
      builder: (_) => _StrokeDetailSheet(
        char: item.char,
        reading: item.label,
        description: '',
        strokes: strokeData,
      ),
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    if (!auth.isLoggedIn) {
      return Scaffold(
        backgroundColor: const Color(0xFFFFFBF7),
        appBar: AppBar(
          backgroundColor: const Color(0xFFFFFBF7),
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Color(0xFF2C1A04)),
            onPressed: () => Navigator.pop(context),
          ),
          centerTitle: true,
          title: Text(
            widget.title,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: Color(0xFF2C1A04),
            ),
          ),
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.lock_outline_rounded, size: 64, color: Color(0xFF924E19)),
                const SizedBox(height: 16),
                const Text(
                  'กรุณาเข้าสู่ระบบก่อนใช้งานโหมดฝึกเขียน',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2C1A04),
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'เข้าสู่ระบบเพื่อฝึกเขียนและบันทึกความก้าวหน้าของคุณ',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 13,
                    color: Color(0xFF7A5C3A),
                  ),
                ),
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  onPressed: () {
                    Navigator.of(context, rootNavigator: true).pushNamed('/login');
                  },
                  icon: const Icon(Icons.login_rounded, color: Colors.white),
                  label: const Text(
                    'เข้าสู่ระบบ',
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF924E19),
                    padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final item = widget.items[_index];

    return Scaffold(
      backgroundColor: const Color(0xFFFFFBF7),

      /// ================= AppBar =================
      appBar: AppBar(
        backgroundColor: const Color(0xFFFFFBF7),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF2C1A04)),
          onPressed: () => Navigator.pop(context),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1.5),
          child: Container(color: const Color(0xFFEADBC8), height: 1.5),
        ),
        centerTitle: true,
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.edit_outlined, size: 24, color: Color(0xFF924E19)),
            const SizedBox(width: 8),
            Text(
              widget.title,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: Color(0xFF2C1A04),
              ),
            ),
          ],
        ),
      ),

      /// ================= Body =================
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            const SizedBox(height: 10),

            // ================= ตัวอักษร (Carousel) =================
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Row(
                children: [
                  const Icon(
                    Icons.school_outlined,
                    color: Color(0xFFBCAAA4),
                    size: 26,
                  ),
                  Expanded(
                    child: SizedBox(
                      height: 82,
                      child: PageView.builder(
                        controller: _pageController,
                        itemCount: widget.items.length,
                        onPageChanged: (i) {
                          setState(() {
                            _index = i;
                          });
                          _canvasKey.currentState?.clear();
                          _fetchCurrentStroke();
                        },
                        itemBuilder: (_, i) {
                          final active = i == _index;
                          final previewSizeFactor =
                              widget.items[i].type == WritingType.consonant
                              ? 0.55
                              : widget.items[i].type == WritingType.number
                              ? 0.45
                              : 0.35;
                          return AnimatedScale(
                            scale: active ? 1.0 : 0.82,
                            duration: const Duration(milliseconds: 250),
                            child: AnimatedOpacity(
                              opacity: active ? 1 : 0.6,
                              duration: const Duration(milliseconds: 250),
                              child: CenteredWritingGlyph(
                                character: widget.items[i].char,
                                fontFamily: 'LNTilok',
                                color: active
                                    ? const Color(0xFF924E19)
                                    : const Color(0xFFB99B83),
                                padding: 8,
                                sizeFactor: previewSizeFactor,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                  const Icon(
                    Icons.rate_review_outlined,
                    color: Color(0xFFBCAAA4),
                    size: 26,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 8),

            // ================= ชื่อตัวอักษร =================
            // แสดงตัวอักษรล้านนาด้วยฟอนต์ LannaAkkhara และ label ด้วยฟอนต์ปกติ
            Column(
              children: [
                RichText(
                  textAlign: TextAlign.center,
                  text: TextSpan(
                    children: [
                      TextSpan(
                        text: item.char,
                        style: const TextStyle(
                          fontSize: 18,
                          fontFamily: 'LNTilok',
                          fontFamilyFallback: ['LNTilok', 'LNTilok'],
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF924E19),
                        ),
                      ),
                      TextSpan(
                        text: '  (${item.label})',
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF2C1A04),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  '• ${_typeLabel(item.type)}',
                  style: const TextStyle(fontSize: 8, color: Color(0xFF7A5C3A)),
                ),
              ],
            ),

            const SizedBox(height: 4),

            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _navButton(
                  icon: Icons.arrow_back,
                  enabled: _index > 0,
                  isPrimary: false,
                  onTap: () {
                    _pageController.previousPage(
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeOut,
                    );
                  },
                ),
                const SizedBox(width: 12),

                // ── ปุ่มดูวิธีเขียน (ลำดับขีด) เหมือนรูปที่ 2 ──
                InkWell(
                  onTap: () => _showStrokeSheet(item),
                  borderRadius: BorderRadius.circular(20),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF3E0),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: const Color(0xFFEADBC8), width: 1.2),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF924E19).withValues(alpha: 0.08),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: const [
                        Icon(Icons.brush_rounded, size: 16, color: Color(0xFF924E19)),
                        SizedBox(width: 6),
                        Text(
                          'ดูวิธีเขียน (ลำดับขีด)',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF924E19),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(width: 12),
                _navButton(
                  icon: Icons.arrow_forward,
                  enabled: _index < widget.items.length - 1,
                  isPrimary: true,
                  onTap: () {
                    _pageController.nextPage(
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeOut,
                    );
                  },
                ),
              ],
            ),

            const SizedBox(height: 4),

            // ================= กระดานเขียน =================
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 6),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                      color: const Color(0xFFEADBC8),
                      width: 1.2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF7A5C3A).withValues(alpha: 0.05),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(24),
                    child: WritingCanvas(
                      key: _canvasKey,
                      guideChar: item.char,
                      character: item.char,
                      fontFamily: 'LNTilok',
                      maxGlyphExtent: item.type == WritingType.consonant
                          ? 280
                          : item.type == WritingType.number
                          ? 220
                          : 150,
                      targetGlyphInkArea: item.type == WritingType.consonant
                          ? 16000
                          : item.type == WritingType.number
                          ? 9000
                          : 3500,
                      onChanged: (points) {},
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ================= ปุ่มนำทาง =================
  Widget _navButton({
    required IconData icon,
    required bool enabled,
    required bool isPrimary,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: enabled
              ? (isPrimary ? const Color(0xFF924E19) : const Color(0xFFF3EAE1))
              : Colors.grey.shade200,
          boxShadow: enabled
              ? [
                  BoxShadow(
                    color:
                        (isPrimary
                                ? const Color(0xFF924E19)
                                : const Color(0xFFF3EAE1))
                            .withValues(alpha: 0.2),
                    blurRadius: 6,
                    offset: const Offset(0, 3),
                  ),
                ]
              : [],
        ),
        child: Icon(
          icon,
          color: enabled
              ? (isPrimary ? Colors.white : const Color(0xFF7A5C3A))
              : Colors.grey.shade400,
        ),
      ),
    );
  }

  // ================= แปลงประเภท =================
  String _typeLabel(WritingType type) {
    switch (type) {
      case WritingType.consonant:
        return 'พยัญชนะ';
      case WritingType.vowel:
        return 'สระ';
      case WritingType.tone:
        return 'วรรณยุกต์';
      case WritingType.number:
        return 'ตัวเลข';
    }
  }
}

class WritingCategoryLoaderPage extends StatefulWidget {
  final String title;
  final String categoryCharIds;
  final WritingType writingType;

  const WritingCategoryLoaderPage({
    super.key,
    required this.title,
    required this.categoryCharIds,
    required this.writingType,
  });

  @override
  State<WritingCategoryLoaderPage> createState() => _WritingCategoryLoaderPageState();
}

class _WritingCategoryLoaderPageState extends State<WritingCategoryLoaderPage> {
  final LannaCharService _charService = LannaCharService();
  final CharacterStrokeService _strokeService = CharacterStrokeService();
  List<WritingItem> _items = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final charsFuture = _charService.getAllCharacters(categoryCharId: widget.categoryCharIds);
      final strokesFuture = _strokeService.getAllStrokes();

      final results = await Future.wait([charsFuture, strokesFuture]);
      final chars = results[0] as List<dynamic>;

      if (mounted) {
        setState(() {
          _items = chars.map((c) => WritingItem(
            char: c.lannaChar,
            label: c.thaiEquivalent.split(' ').first,
            type: widget.writingType,
          )).toList();
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (_items.isEmpty) {
      return const Scaffold(
        body: Center(
          child: Text('ไม่มีข้อมูล'),
        ),
      );
    }

    return WritingModePage(
      title: widget.title,
      items: _items,
    );
  }
}

// ============================================================================
// LOCAL STROKE PAINTER (เหมือนในหน้ารายละเอียด รูปที่ 2)
// ============================================================================
class _LocalStrokePainter extends CustomPainter {
  final List<List<Offset>> strokes;
  final int currentIndex;
  final double progress;
  final String char;

  _LocalStrokePainter({
    required this.strokes,
    required this.currentIndex,
    required this.progress,
    required this.char,
  });

  @override
  void paint(Canvas canvas, Size size) {
    var activeStrokeIndex = currentIndex;
    var activeStrokeProgress = progress.clamp(0.0, 1.0);

    // 0. Dotted grid background
    final paintDot = Paint()
      ..color = const Color(0xFFDCC8B8).withValues(alpha: 0.4);
    const double spacing = 16.0;
    for (double x = spacing; x < size.width; x += spacing) {
      for (double y = spacing; y < size.height; y += spacing) {
        canvas.drawCircle(Offset(x, y), 1.0, paintDot);
      }
    }

    final characterRunes = char.runes.toList();
    final isFloatingVowelOrMark =
        characterRunes.length == 1 &&
        characterRunes.first >= 0x1A65 &&
        characterRunes.first <= 0x1A7C;

    final writingExampleSize = isFloatingVowelOrMark ? 38.0 : 68.0;
    final writingExamplePadding = math.max(
      0.0,
      (size.shortestSide - writingExampleSize) / 2,
    );
    final glyphLayout = layoutWritingGlyph(
      character: char,
      fontFamily: 'LNTilok',
      size: size,
      padding: writingExamplePadding,
    );

    double minX = 100.0, minY = 100.0, maxX = 0.0, maxY = 0.0;
    bool hasPoints = false;
    for (final stroke in strokes) {
      for (final pt in stroke) {
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

    final double targetSize = size.shortestSide * (isFloatingVowelOrMark ? 0.36 : 0.52);
    final double scale = targetSize / math.max(charWidth, charHeight);

    Offset strokeScale(Offset point) {
      final double scaledX = (point.dx - charCenterX) * scale;
      final double scaledY = (point.dy - charCenterY) * scale;
      return Offset(
        size.width / 2.0 + scaledX,
        size.height / 2.0 + scaledY,
      );
    }

    final usesGeneratedGuide = strokes.isNotEmpty;
    if (usesGeneratedGuide) {
      final guidePaint = Paint()
        ..color = const Color(0xFFD9D2CB).withValues(alpha: 0.5)
        ..strokeWidth = 3.5
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..style = PaintingStyle.stroke;
      for (final stroke in strokes) {
        if (stroke.isEmpty) continue;
        canvas.drawPath(buildStrokePath(stroke, strokeScale), guidePaint);
      }
    } else {
      glyphLayout.paint(canvas, const Color(0xFFE8DFD5));
      return;
    }

    final completedPaint = Paint()
      ..color = const Color(0xFF924E19)
      ..strokeWidth = 4.5
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;

    for (var index = 0; index < activeStrokeIndex; index++) {
      if (index >= strokes.length || strokes[index].isEmpty) continue;
      canvas.drawPath(
        buildStrokePath(strokes[index], strokeScale),
        completedPaint,
      );
    }

    if (activeStrokeIndex >= 0 && activeStrokeIndex < strokes.length) {
      final currentStroke = strokes[activeStrokeIndex];
      if (currentStroke.isNotEmpty) {
        final currentPath = buildStrokePath(currentStroke, strokeScale);
        for (final metric in currentPath.computeMetrics()) {
          canvas.drawPath(
            metric.extractPath(0, metric.length * activeStrokeProgress),
            completedPaint,
          );
        }
      }
    }

    final paintStartActive = Paint()
      ..color = const Color(0xFF924E19).withValues(alpha: 0.48);
    final paintStartInactive = Paint()
      ..color = const Color(0xFFC7B8AA).withValues(alpha: 0.32);

    for (int i = 0; i < strokes.length; i++) {
      if (strokes[i].isEmpty) continue;
      final startPt = strokeScale(strokes[i][0]);
      final isCurrentOrCompleted = i <= activeStrokeIndex;
      final isFirst = i == 0;
      canvas.drawCircle(
        startPt,
        7,
        isFirst
            ? (Paint()..color = const Color(0xFFFF9800).withValues(alpha: 0.58))
            : isCurrentOrCompleted
            ? paintStartActive
            : paintStartInactive,
      );
      final tp = TextPainter(
        text: TextSpan(
          text: '${i + 1}',
          style: TextStyle(
            fontSize: 7,
            fontWeight: FontWeight.bold,
            color: Colors.white.withValues(alpha: 0.88),
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
  }

  @override
  bool shouldRepaint(covariant _LocalStrokePainter old) => true;
}

// ============================================================================
// STROKE DETAIL BOTTOM SHEET (เหมือนในรูปที่ 2)
// ============================================================================
class _StrokeDetailSheet extends StatefulWidget {
  final String char;
  final String reading;
  final String description;
  final List<List<Offset>> strokes;

  const _StrokeDetailSheet({
    required this.char,
    required this.reading,
    required this.description,
    required this.strokes,
  });

  @override
  State<_StrokeDetailSheet> createState() => _StrokeDetailSheetState();
}

class _StrokeDetailSheetState extends State<_StrokeDetailSheet>
    with SingleTickerProviderStateMixin {
  int _currentStrokeIndex = 0;
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    );
    _animation =
        Tween<double>(begin: 0.0, end: 1.0).animate(
          CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
        )..addListener(() {
          setState(() {});
        });
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _replay() {
    _controller.reset();
    _controller.forward();
  }

  void _next() {
    if (_currentStrokeIndex < widget.strokes.length - 1) {
      setState(() => _currentStrokeIndex++);
      _replay();
    }
  }

  void _prev() {
    if (_currentStrokeIndex > 0) {
      setState(() => _currentStrokeIndex--);
      _replay();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: EdgeInsets.fromLTRB(
        24,
        12,
        24,
        MediaQuery.of(context).padding.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle
          Container(
            width: 40,
            height: 5,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          const SizedBox(height: 16),

          // Title row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'วิธีเขียน (ลำดับขีด) ${widget.reading.isNotEmpty ? "- ${widget.reading}" : ""}',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2D1A00),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          const SizedBox(height: 4),

          // Char display
          Text(
            formatLannaDisplayGlyph(widget.char),
            style: const TextStyle(
              fontSize: 32,
              fontFamily: 'LNTilok',
              fontFamilyFallback: ['LNTilok', 'THSarabunNew', 'sans-serif'],
              color: Color(0xFF924E19),
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),

          // Canvas 220x220
          Container(
            width: 220,
            height: 220,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: const Color(0xFFEADBC8), width: 1.2),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.02),
                  blurRadius: 16,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(24),
              child: CustomPaint(
                painter: _LocalStrokePainter(
                  strokes: widget.strokes,
                  currentIndex: _currentStrokeIndex,
                  progress: _animation.value,
                  char: widget.char,
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Stroke counter
          Text(
            widget.strokes.isNotEmpty
                ? 'เส้นที่ ${_currentStrokeIndex + 1} จากทั้งหมด ${widget.strokes.length} เส้น'
                : 'ไม่มีข้อมูลเส้นวาด',
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: Color(0xFF7A5C3A),
            ),
          ),
          const SizedBox(height: 20),

          // Navigation controls
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                icon: const Icon(Icons.skip_previous_rounded, size: 36),
                color: _currentStrokeIndex > 0
                    ? const Color(0xFF924E19)
                    : Colors.grey[300],
                onPressed: _currentStrokeIndex > 0 ? _prev : null,
              ),
              const SizedBox(width: 24),
              ElevatedButton.icon(
                onPressed: _replay,
                icon: const Icon(Icons.refresh_rounded),
                label: const Text(
                  'เล่นใหม่',
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF924E19),
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
              const SizedBox(width: 24),
              IconButton(
                icon: const Icon(Icons.skip_next_rounded, size: 36),
                color: _currentStrokeIndex < widget.strokes.length - 1
                    ? const Color(0xFF924E19)
                    : Colors.grey[300],
                onPressed: _currentStrokeIndex < widget.strokes.length - 1
                    ? _next
                    : null,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

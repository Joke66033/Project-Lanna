import 'package:flutter/material.dart';
import '../learning_navigation.dart';
import '../train/writing_mode.dart';
import '../train/writing_data.dart';
import '../train/stroke_order_model.dart';
import 'package:lanna/services/character_stroke_service.dart';

// ============================================================================
// CHAR DETAIL PAGE
// แสดงรายละเอียดตัวอักษรล้านนา 1 ตัว: เสียงอ่าน, อักษรไทยเทียบ, วิธีเขียน,
// และแบบฝึกเขียน
// ============================================================================
class CharDetailPage extends StatefulWidget {
  /// ตัวอักษรล้านนา Unicode
  final String char;

  /// เสียงอ่านหลัก เช่น "ก๋ะ"
  final String reading;

  /// อักษรไทยเทียบเสียง เช่น "ก"
  final String thai;

  /// คำอธิบายสั้น
  final String description;

  /// สถานะผู้ใช้งาน (แขก = ยังไม่ login)
  final bool isGuest;

  /// ประเภทสำหรับฝึกเขียน (consonant / vowel / tone / number)
  final WritingType writingType;

  /// List ของ {char, label} ทั้งหมดสำหรับ WritingModePage
  final List<Map<String, String>> allChars;

  /// Index เริ่มต้นสำหรับ WritingModePage
  final int initialWritingIndex;

  /// ชื่อหมวดหมู่ของอักขระจากข้อมูล API
  final String categoryName;

  const CharDetailPage({
    super.key,
    required this.char,
    required this.reading,
    required this.thai,
    required this.description,
    required this.isGuest,
    required this.writingType,
    required this.allChars,
    required this.initialWritingIndex,
    required this.categoryName,
  });

  @override
  State<CharDetailPage> createState() => _CharDetailPageState();
}

class _CharDetailPageState extends State<CharDetailPage>
    with SingleTickerProviderStateMixin {
  final CharacterStrokeService _strokeService = CharacterStrokeService();

  // ── Stroke animation ──────────────────────────────────────────────────────
  CharacterStrokeOrder? _strokeOrder;
  late List<List<Offset>> _strokes;
  late AnimationController _strokeController;
  late Animation<double> _strokeAnimation;

  @override
  void initState() {
    super.initState();

    _loadStrokesFromCache();

    // AnimationController: auto-play preview เมื่อเปิดหน้า
    _strokeController = AnimationController(
      vsync: this,
      duration: Duration(
        milliseconds: _strokes.isEmpty ? 1600 : _strokes.length * 2200,
      ),
    );
    _strokeAnimation =
        Tween<double>(begin: 0.0, end: 1.0).animate(
          CurvedAnimation(parent: _strokeController, curve: Curves.easeInOut),
        )..addListener(() {
          setState(() {});
        });

    _strokeController.forward();

    // 🔄 ดึงพิกัดจุดเส้นวาดจากฐานข้อมูล MySQL เซิร์ฟเวอร์หลัก (character_strokes_api.php)
    _fetchStrokesFromDatabase();
  }

  void _loadStrokesFromCache() {
    _strokeOrder = getCharacterStrokeOrder(widget.char);
    final sourceStrokes =
        _strokeOrder?.strokes.map((stroke) => stroke.points).toList() ??
        const <List<Offset>>[];
    _strokes = _orderStrokesForDetailPreview(sourceStrokes);
  }

  Future<void> _fetchStrokesFromDatabase() async {
    final strokeModel = await _strokeService.getStrokeByChar(widget.char);
    if (!mounted || strokeModel == null) return;
    setState(() {
      _loadStrokesFromCache();
      if (_strokes.isNotEmpty) {
        _strokeController.duration = Duration(
          milliseconds: _strokes.length * 2200,
        );
        _strokeController.forward(from: 0.0);
      }
    });
  }

  /// Stroke order is authored centrally in stroke_data.dart. Do not reorder it
  /// from geometry here: a right-hand loop can extend leftward and would be
  /// incorrectly promoted ahead of the true left-hand starting stroke.
  List<List<Offset>> _orderStrokesForDetailPreview(List<List<Offset>> source) {
    return source.map((stroke) => List<Offset>.of(stroke)).toList();
  }

  @override
  void dispose() {
    _strokeController.dispose();
    super.dispose();
  }

  // ── Stroke bottom sheet ───────────────────────────────────────────────────
  void _showStrokeSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: 0.5),
      builder: (_) => _StrokeDetailSheet(
        char: widget.char,
        reading: widget.reading,
        description: widget.description,
        strokes: _strokes,
      ),
    );
  }

  // ── Navigate to writing practice ─────────────────────────────────────────
  void _startWritingPractice() {
    final items = widget.allChars.map((m) {
      return WritingItem(
        char: m['char'] ?? '',
        label: m['label'] ?? '',
        type: widget.writingType,
      );
    }).toList();

    pushLearningPage(
      context,
      MaterialPageRoute(
        builder: (_) => WritingModePage(
          items: items,
          title: _writingTitle,
          initialIndex: widget.initialWritingIndex >= 0
              ? widget.initialWritingIndex
              : 0,
        ),
      ),
    );
  }

  String get _writingTitle {
    switch (widget.writingType) {
      case WritingType.consonant:
        return 'ฝึกเขียนพยัญชนะ';
      case WritingType.vowel:
        return 'ฝึกเขียนสระ';
      case WritingType.tone:
        return 'ฝึกเขียนวรรณยุกต์';
      case WritingType.number:
        return 'ฝึกเขียนตัวเลข';
    }
  }

  // =========================================================================
  // BUILD
  // =========================================================================
  @override
  Widget build(BuildContext context) {
    final hasStrokeData = _strokes.isNotEmpty;

    return Scaffold(
      backgroundColor: const Color(0xFFFFFBF7),
      appBar: _buildAppBar(),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 95),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Section 1: ตัวอักษรหลัก ──────────────────────────────────
            _buildCharDisplay(),
            const SizedBox(height: 20),

            // ── Section 2: ข้อมูลพื้นฐาน ─────────────────────────────────
            _buildInfoCard(),
            const SizedBox(height: 16),

            // ── Section 3: วิธีเขียน ─────────────────────────────────────
            _buildStrokeCard(hasStrokeData),
            const SizedBox(height: 16),

            // ── Section 4: แบบฝึกเขียน ───────────────────────────────────
            _buildPracticeCard(),
          ],
        ),
      ),
    );
  }

  // ── AppBar ────────────────────────────────────────────────────────────────
  AppBar _buildAppBar() {
    return AppBar(
      backgroundColor: const Color(0xFFFFFBF7),
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back, color: Color(0xFFE16905)),
        onPressed: () => Navigator.pop(context),
      ),
      centerTitle: true,
      title: Text(
        widget.categoryName,
        style: const TextStyle(
          fontSize: 15,
          color: Color(0xFF2D1A00),
          fontWeight: FontWeight.bold,
        ),
      ),
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(1.5),
        child: Container(color: const Color(0xFFEADBC8), height: 1.5),
      ),
    );
  }

  // ── Section 1: ตัวอักษรหลัก ──────────────────────────────────────────────
  Widget _buildCharDisplay() {
    return Center(
      child: Container(
        width: 120,
        height: 120,
        padding: const EdgeInsets.all(12),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: const Color(0xFFFFF3E0),
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF924E19).withValues(alpha: 0.10),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            widget.char,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 56,
              height: 1.15,
              fontFamily: 'LNTilok',
              fontFamilyFallback: ['LNTilok', 'THSarabunNew', 'sans-serif'],
              color: Color(0xFF924E19),
              fontWeight: FontWeight.normal,
            ),
          ),
        ),
      ),
    );
  }

  // ── Section 2: ข้อมูลพื้นฐาน ─────────────────────────────────────────────
  Widget _buildInfoCard() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFEADBC8), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // เสียงอ่านหลัก
            Row(
              children: [
                const Icon(
                  Icons.record_voice_over,
                  color: Color(0xFF924E19),
                  size: 20,
                ),
                const SizedBox(width: 8),
                const Text(
                  'เสียงอ่านหลัก',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2D1A00),
                  ),
                ),
                const SizedBox(width: 8),
                Flexible(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF3E0),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: const Color(0xFFEADBC8)),
                    ),
                    child: Text(
                      widget.reading,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF924E19),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Divider(color: Color(0xFFEADBC8), height: 1, thickness: 1),
            const SizedBox(height: 12),

            // อักษรไทยเทียบ
            Row(
              children: [
                const Icon(Icons.translate, color: Color(0xFF7A5C3A), size: 20),
                const SizedBox(width: 8),
                const Text(
                  'อักษรไทยเทียบ: ',
                  style: TextStyle(fontSize: 10, color: Color(0xFF7A5C3A)),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    widget.thai,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF924E19),
                    ),
                  ),
                ),
              ],
            ),

            // คำอธิบาย (ถ้ามี)
            if (widget.description.trim().isNotEmpty) ...[
              const SizedBox(height: 10),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    Icons.info_outline,
                    color: Color(0xFFB0A090),
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      widget.description,
                      style: TextStyle(
                        fontSize: 9,
                        color: Colors.grey.shade600,
                        height: 1.5,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  // ── Section 3: วิธีเขียน (Stroke Order) ──────────────────────────────────
  Widget _buildStrokeCard(bool hasStrokeData) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFEADBC8), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: const [
                Icon(Icons.brush_rounded, color: Color(0xFF924E19), size: 20),
                SizedBox(width: 8),
                Text(
                  'วิธีเขียน (ลำดับขีด)',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2D1A00),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            if (hasStrokeData) ...[
              // Preview canvas 200x200
              Center(
                child: Container(
                  width: 200,
                  height: 200,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: const Color(0xFFEADBC8),
                      width: 1.2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.03),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: CustomPaint(
                      painter: _LocalStrokePainter(
                        strokes: _strokes,
                        currentIndex: _strokes.length - 1,
                        progress: _strokeAnimation.value,
                        char: widget.char,
                        animateAllStrokes: true,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // ข้อมูลจำนวนเส้น
              Center(
                child: Text(
                  'ทั้งหมด ${_strokes.length} เส้น',
                  style: const TextStyle(
                    fontSize: 9,
                    color: Color(0xFF7A5C3A),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              if (_strokeOrder?.requiresExpertReview == true) ...[
                const SizedBox(height: 8),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF8E7),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFFE8C878)),
                  ),
                  child: const Text(
                    'ข้อมูลลำดับขีดนี้ต้องตรวจสอบกับผู้เชี่ยวชาญ/ตำราอักษรล้านนา',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 8,
                      color: Color(0xFF795B16),
                      height: 1.4,
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 12),

              // ปุ่มดูแบบเต็ม
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: _showStrokeSheet,
                  icon: const Icon(Icons.open_in_full_rounded, size: 16),
                  label: const Text(
                    'ดูแบบเต็ม',
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF924E19),
                    side: const BorderSide(
                      color: Color(0xFF924E19),
                      width: 1.4,
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 11),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ] else ...[
              // ถ้ายังไม่มีพิกัดลำดับขีด ให้แสดงรูปอักขระจริงแทนเสมอ
              // เพื่อให้การ์ดวิธีเขียนของทุกอักขระมีรูปแบบเดียวกัน
              Center(
                child: Container(
                  width: 200,
                  height: 200,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: const Color(0xFFEADBC8),
                      width: 1.2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.03),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: CustomPaint(
                      painter: _LocalStrokePainter(
                        strokes: const [],
                        currentIndex: -1,
                        progress: _strokeAnimation.value,
                        char: widget.char,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              const Center(
                child: Text(
                  'รูปแบบอักขระ',
                  style: TextStyle(
                    fontSize: 9,
                    color: Color(0xFF7A5C3A),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // ── Section 4: แบบฝึกเขียน ───────────────────────────────────────────────
  Widget _buildPracticeCard() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFEADBC8), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: const [
                Icon(
                  Icons.edit_note_rounded,
                  color: Color(0xFF924E19),
                  size: 22,
                ),
                SizedBox(width: 8),
                Text(
                  'ฝึกเขียนตาม',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2D1A00),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),

            if (widget.isGuest) ...[
              // ── ผู้ใช้เป็น Guest ─────────────────────────────────────
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF3E0),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFEADBC8)),
                ),
                child: Column(
                  children: [
                    const Icon(
                      Icons.lock_outline_rounded,
                      color: Color(0xFF924E19),
                      size: 32,
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'กรุณาเข้าสู่ระบบเพื่อใช้งานโหมดฝึกเขียน',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 9,
                        color: Color(0xFF7A5C3A),
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () => Navigator.of(
                          context,
                          rootNavigator: true,
                        ).pushNamed('/login'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF924E19),
                          foregroundColor: Colors.white,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text(
                          'เข้าสู่ระบบ',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ] else ...[
              // ── ผู้ใช้ login แล้ว ────────────────────────────────────
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _startWritingPractice,
                  icon: const Icon(Icons.brush_rounded, size: 18),
                  label: const Text(
                    'เริ่มฝึกเขียน',
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF924E19),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ============================================================================
// LOCAL STROKE PAINTER (static display — แสดงทุกเส้นพร้อมกัน)
// Copy logic จาก StrokePainter ใน consonant.dart แต่เป็น private class
// ============================================================================
class _LocalStrokePainter extends CustomPainter {
  final List<List<Offset>> strokes;
  final int currentIndex;
  final double progress;
  final String char;
  final bool animateAllStrokes;

  _LocalStrokePainter({
    required this.strokes,
    required this.currentIndex,
    required this.progress,
    required this.char,
    this.animateAllStrokes = false,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // 0. ตารางจุดพื้นหลัง (Dotted grid)
    final paintDot = Paint()
      ..color = const Color(0xFFDCC8B8).withValues(alpha: 0.4);
    const double spacing = 16.0;
    for (double x = spacing; x < size.width; x += spacing) {
      for (double y = spacing; y < size.height; y += spacing) {
        canvas.drawCircle(Offset(x, y), 1.0, paintDot);
      }
    }

    // 1. เรนเดอร์ตัวอักษรจริงจากฟอนต์ LNTilok ให้ตรงกับด้านบน 100%
    final double fontSize = size.shortestSide * 0.65;
    final textPainter = TextPainter(
      text: TextSpan(
        text: char,
        style: TextStyle(
          fontSize: fontSize,
          fontFamily: 'LNTilok',
          fontFamilyFallback: const ['LNTilok', 'THSarabunNew', 'sans-serif'],
          color: const Color(0xFFEADBC8),
          fontWeight: FontWeight.normal,
        ),
      ),
      textDirection: TextDirection.ltr,
      textAlign: TextAlign.center,
    )..layout();

    final textOffset = Offset(
      (size.width - textPainter.width) / 2.0,
      (size.height - textPainter.height) / 2.0,
    );

    // 1.1 วาดรูปทรงอักษรจริงสีจางเป็นลายน้ำแม่แบบ (Pale Guide)
    textPainter.paint(canvas, textOffset);

    // 2. วาดการเขียนหมึกสีน้ำตาลตามแอนิเมชัน (Ink Stroke Reveal)
    var currentProgress = progress.clamp(0.0, 1.0);
    if (currentProgress > 0) {
      canvas.save();
      // สร้าง Mask คลิปการเขียนตามทิศทางแอนิเมชัน
      final revealRect = Rect.fromLTWH(
        0,
        0,
        size.width * (currentProgress * 1.05).clamp(0.0, 1.0),
        size.height,
      );
      canvas.clipRect(revealRect);

      final inkPainter = TextPainter(
        text: TextSpan(
          text: char,
          style: TextStyle(
            fontSize: fontSize,
            fontFamily: 'LNTilok',
            fontFamilyFallback: const ['LNTilok', 'THSarabunNew', 'sans-serif'],
            color: const Color(0xFF924E19),
            fontWeight: FontWeight.normal,
          ),
        ),
        textDirection: TextDirection.ltr,
        textAlign: TextAlign.center,
      )..layout();

      inkPainter.paint(canvas, textOffset);
      canvas.restore();
    }

    // 3. วาดจุดเริ่มต้นลำดับขีด (1, 2, 3...)
    if (strokes.isNotEmpty) {
      // แม็ปพิกัดให้อยู่ในกรอบตัวอักษรจริง
      final charBox = Rect.fromLTWH(
        textOffset.dx + textPainter.width * 0.1,
        textOffset.dy + textPainter.height * 0.1,
        textPainter.width * 0.8,
        textPainter.height * 0.8,
      );

      Offset mapToChar(Offset pt) {
        return Offset(
          charBox.left + (pt.dx / 100.0) * charBox.width,
          charBox.top + (pt.dy / 100.0) * charBox.height,
        );
      }

      for (int i = 0; i < strokes.length; i++) {
        if (strokes[i].isEmpty) continue;
        final startPt = mapToChar(strokes[i][0]);
        final isFirst = i == 0;

        canvas.drawCircle(
          startPt,
          8,
          isFirst
              ? (Paint()..color = const Color(0xFFFF9800).withValues(alpha: 0.85))
              : (Paint()..color = const Color(0xFF924E19).withValues(alpha: 0.7)),
        );

        final tp = TextPainter(
          text: TextSpan(
            text: '${i + 1}',
            style: const TextStyle(
              fontSize: 8,
              fontWeight: FontWeight.bold,
              color: Colors.white,
              fontFamily: 'sans-serif',
            ),
          ),
          textDirection: TextDirection.ltr,
        )..layout();

        tp.paint(
          canvas,
          Offset(startPt.dx - tp.width / 2, startPt.dy - tp.height / 2),
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant _LocalStrokePainter old) => true;
}

// ============================================================================
// STROKE DETAIL BOTTOM SHEET
// แสดงลำดับขีดแบบเต็ม พร้อม prev/next/replay controls
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
                'วิธีเขียน ${widget.reading}',
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
            widget.char,
            style: const TextStyle(
              fontSize: 27,
              fontFamily: 'LNTilok',
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
            'เส้นที่ ${_currentStrokeIndex + 1} จากทั้งหมด ${widget.strokes.length} เส้น',
            style: const TextStyle(
              fontSize: 8,
              fontWeight: FontWeight.w500,
              color: Color(0xFF7A5C3A),
            ),
          ),
          const SizedBox(height: 12),

          // Description box
          if (widget.description.trim().isNotEmpty) ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFF5EAE1),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFEADBC8), width: 1.0),
              ),
              child: Text(
                widget.description,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2D1A00),
                  height: 1.4,
                ),
              ),
            ),
            const SizedBox(height: 20),
          ],

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
                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
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

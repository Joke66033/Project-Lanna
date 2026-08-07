import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'writing_canvas.dart';
import '../../../services/lanna_transliterator.dart';

/// หน้าฝึกเขียนคำที่ผู้ใช้กำหนดเอง
/// ผู้ใช้พิมพ์คำภาษาไทย → ระบบแปลงเป็นล้านนา → แสดง canvas ให้ฝึกเขียนทีละตัว
class WritingCustomWordPage extends StatefulWidget {
  const WritingCustomWordPage({super.key});

  @override
  State<WritingCustomWordPage> createState() => _WritingCustomWordPageState();
}

class _WritingCustomWordPageState extends State<WritingCustomWordPage> {
  static const int _maxInputLength = 25;
  final TextEditingController _inputCtrl = TextEditingController();
  final GlobalKey<WritingCanvasState> _canvasKey =
      GlobalKey<WritingCanvasState>();

  List<String> _lannaChars = [];
  String _thaiWord = '';
  String _lannaWord = '';
  int _inputLength = 0;

  static const Color _kPrimary = Color(0xFF924E19);

  void _startPractice() {
    final input = _inputCtrl.text.trim();
    if (input.isEmpty) return;

    final lanna = LannaTransliterator().thaiToLanna(input);
    final chars = lanna.split('').where((s) => s.trim().isNotEmpty).toList();

    if (chars.isEmpty) return;

    setState(() {
      _thaiWord = input;
      _lannaWord = lanna;
      _lannaChars = chars;
    });
    _canvasKey.currentState?.clear();
  }

  void _checkCoverage(List<Offset> points) {
    // ใช้ onChanged เพื่ออัปเดต state — accuracy จะถูกคำนวณโดย WritingCanvas
    // และแสดงผ่าน badge ภายใน canvas เอง
    setState(() {});
  }


  @override
  void dispose() {
    _inputCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFFBF7),
      appBar: AppBar(
        backgroundColor: const Color(0xFFFFFBF7),
        elevation: 0,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1.5),
          child: Container(color: const Color(0xFFEADBC8), height: 1.5),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: _kPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        centerTitle: true,
        title: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.edit_note_rounded, color: _kPrimary, size: 22),
            SizedBox(width: 8),
            Text(
              'ฝึกเขียนคำที่ต้องการ',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: Color(0xFF2D1A00),
              ),
            ),
          ],
        ),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── Phase 1: Input ──────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'พิมพ์คำภาษาไทยที่ต้องการฝึกเขียน',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF5C3A21),
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _inputCtrl,
                  maxLength: _maxInputLength,
                  inputFormatters: [
                    LengthLimitingTextInputFormatter(_maxInputLength),
                  ],
                  style: const TextStyle(
                    fontSize: 14,
                    color: Color(0xFF2D1A00),
                  ),
                  decoration: InputDecoration(
                    hintText: 'เช่น: สวัสดี, ขอบคุณ, ล้านนา...',
                    helperText:
                        'กรอกได้ไม่เกิน 25 ตัวอักษร (พิมพ์ไปแล้ว $_inputLength/$_maxInputLength ตัว)',
                    helperMaxLines: 2,
                    helperStyle: TextStyle(
                      fontSize: 11,
                      color: _inputLength >= 20
                          ? const Color(0xFF9B1C1C)
                          : const Color(0xFFC62828),
                      fontWeight: FontWeight.bold,
                    ),
                    counterText: '',
                    hintStyle: TextStyle(
                      fontSize: 12,
                      color: const Color(0xFF7A5C3A).withValues(alpha: 0.5),
                    ),
                    prefixIcon: const Icon(
                      Icons.keyboard_alt_outlined,
                      color: Color(0xFF7A5C3A),
                      size: 20,
                    ),
                    filled: true,
                    fillColor: Colors.white,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 14,
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: const BorderSide(
                        color: Color(0xFFEADBC8),
                        width: 1.5,
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: const BorderSide(
                        color: _kPrimary,
                        width: 1.5,
                      ),
                    ),
                  ),
                  onChanged: (value) {
                    setState(() {
                      _inputLength = value.characters.length;
                    });
                  },
                  onSubmitted: (_) => _startPractice(),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  height: 48,
                  child: ElevatedButton.icon(
                    onPressed: _startPractice,
                    icon: const Icon(Icons.play_arrow_rounded, size: 20),
                    label: const Text(
                      'เริ่มฝึกเขียน',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _kPrimary,
                      foregroundColor: Colors.white,
                      elevation: 2,
                      shadowColor: _kPrimary.withValues(alpha: 0.3),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // ── Phase 2: ฝึกเขียน ──────────────────────────────────────────
          if (_lannaChars.isNotEmpty) ...[
            // แสดงคำแปล
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF3E0),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFFFE0B2)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(
                      _thaiWord,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 14,
                        color: Color(0xFF5D4037),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 4),
                      child: Icon(
                        Icons.arrow_downward_rounded,
                        size: 16,
                        color: Color(0xFF9E9E9E),
                      ),
                    ),
                    SizedBox(
                      width: double.infinity,
                      child: Text(
                        _lannaWord,
                        textAlign: TextAlign.center,
                        softWrap: true,
                        style: const TextStyle(
                          fontFamily: 'PayapLanna',
                          fontSize: 22,
                          color: _kPrimary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 12),

            // Canvas
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // ป้ายบอกใบ้ "วาดตามแบบ"
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.gesture_rounded,
                          size: 14,
                          color: Color(0xFF9E9E9E),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'วาดตามแบบสีน้ำตาลอ่อนในกระดาน',
                          style: const TextStyle(
                            fontSize: 9,
                            color: Color(0xFF9E9E9E),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Expanded(
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
                              color: _kPrimary.withValues(alpha: 0.04),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(24),
                          child: WritingCanvas(
                            key: _canvasKey,
                            guideChar: _lannaWord,
                            character: _lannaWord,
                            fontFamily: 'PayapLanna',
                            showStrokeOrder: false,
                            showTracingGuide: true,
                            tracingText: _lannaWord,
                            onChanged: (pts) => _checkCoverage(pts),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Bottom hint — accuracy badge อยู่ใน canvas เรียบร้อยแล้ว
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.info_outline_rounded,
                    size: 12,
                    color: Color(0xFFBBAAA0),
                  ),
                  const SizedBox(width: 4),
                  const Text(
                    'ความถูกต้องแสดงในกระดาน • กดล้างเพื่อวาดใหม่',
                    style: TextStyle(fontSize: 9, color: Color(0xFFBBAAA0)),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

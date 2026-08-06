import 'package:flutter/material.dart';
import 'package:lanna/services/lanna_char_service.dart';
import 'glyph_layout.dart';
import 'writing_data.dart';
import 'writing_canvas.dart';

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

  @override
  void initState() {
    super.initState();
    _index = widget.initialIndex;
    _pageController = PageController(
      viewportFraction: 0.35,
      initialPage: widget.initialIndex,
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
                                fontFamily: 'PayapLanna',
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
                          fontFamily: 'PayapLanna',
                          fontFamilyFallback: ['PayapLanna', 'PayapLanna'],
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
                const SizedBox(width: 20),
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
                      fontFamily: 'PayapLanna',
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
  List<WritingItem> _items = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final chars = await _charService.getAllCharacters(categoryCharId: widget.categoryCharIds);
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

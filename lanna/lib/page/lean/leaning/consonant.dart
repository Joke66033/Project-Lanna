import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:lanna/services/lanna_char_service.dart';
import 'package:lanna/services/article_service.dart';
import 'package:lanna/models/article_model.dart';
import '../learning_navigation.dart';
import 'lanna_glyph_card.dart';
import 'char_detail_page.dart';
import '../train/writing_mode.dart';
import '../train/writing_data.dart';
import 'package:lanna/services/character_stroke_service.dart';

/// ============================================================================
/// MODEL : LANNA CONSONANT
/// ============================================================================
class LannaConsonant {
  final String char;       // อักษรล้านนา Unicode
  final String reading;    // คำอ่านภาษาไทย เช่น "ก๋ะ"
  final String thai;       // อักษรไทยเทียบเคียง เช่น "ก"
  final String description; // คำอธิบายวิธีเขียนสั้นๆ

  const LannaConsonant({
    required this.char,
    required this.reading,
    required this.thai,
    required this.description,
  });
}

class ConsonantGroup {
  final String name;
  final String categoryCharId;
  final List<LannaConsonant> consonants;

  const ConsonantGroup({
    required this.name,
    required this.categoryCharId,
    required this.consonants,
  });
}

/// ============================================================================
/// SCREEN : LANNA CONSONANTS LEARNING PAGE
/// ============================================================================
class ConsonantPage extends StatefulWidget {
  final bool isGuest;
  final VoidCallback? onBack;
  const ConsonantPage({super.key, this.isGuest = false, this.onBack});

  @override
  State<ConsonantPage> createState() => _ConsonantPageState();
}

class _ConsonantPageState extends State<ConsonantPage> with SingleTickerProviderStateMixin {
  late final FlutterTts _tts;
  TabController? _tabController;
  
  final LannaCharService _charService = LannaCharService();
  final ArticleService _articleService = ArticleService();

  List<ConsonantGroup> _groups = [];
  String _currentCategoryId = 'CL0001';
  final Map<String, ArticleModel?> _articlesMap = {};

  bool _isLoading = true;
  String? _errorMsg;

  @override
  void initState() {
    super.initState();
    _tts = FlutterTts();
    _initTts();
    _loadData();
  }

  Future<void> _initTts() async {
    await _tts.setLanguage('th-TH');
    await _tts.setSpeechRate(0.5);
    await _tts.setPitch(1.0);
    await _tts.setVolume(1.0);
  }

  Future<void> _speak(String text) async {
    await _tts.stop();
    await _tts.speak(text);
  }

  @override
  void dispose() {
    _tts.stop();
    _tabController?.removeListener(_handleTabChange);
    _tabController?.dispose();
    super.dispose();
  }

  void _handleTabChange() {
    if (_tabController != null && !_tabController!.indexIsChanging) {
      final index = _tabController!.index;
      if (index >= 0 && index < _groups.length) {
        final newCatId = _groups[index].categoryCharId;
        if (_currentCategoryId != newCatId) {
          setState(() {
            _currentCategoryId = newCatId;
          });
        }
      }
    }
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _errorMsg = null;
    });
    try {
      // 1. ดึงบทความอธิบายพยัญชนะทั้งหมด (CL0001, CL0002, CL0003)
      final apiArticles = await _articleService.getAllArticles(categoryCharId: 'CL0001,CL0002,CL0003');
      _articlesMap.clear();
      for (var art in apiArticles) {
        if (art.categoryCharId != null && art.content.trim().isNotEmpty) {
          _articlesMap[art.categoryCharId!] = art;
        }
      }

      // 2. ดึงอักขระพยัญชนะทั้งหมดตามกลุ่ม
      final apiConsonants = await _charService.getAllCharacters(categoryCharId: 'CL0001,CL0002,CL0003');
      final allCategories = await _charService.getAllCategories();
      final Map<String, String> catNames = {
        for (var c in allCategories) c.categoryCharId: c.name
      };

      final Map<String, List<LannaConsonant>> dynamicGroups = {};

      for (var c in apiConsonants) {
        final String rawThai = c.thaiEquivalent;
        String parsedReading = rawThai;
        if (rawThai.contains('(') && rawThai.contains(')')) {
          parsedReading = rawThai.substring(rawThai.indexOf('(') + 1, rawThai.indexOf(')'));
        }
        final consonant = LannaConsonant(
          char: c.lannaChar,
          reading: parsedReading,
          thai: rawThai.split(' ').first,
          description: 'พยัญชนะล้านนาตัว ${c.thaiEquivalent}',
        );

        final catId = c.categoryCharId;
        if (!dynamicGroups.containsKey(catId)) {
          dynamicGroups[catId] = [];
        }
        dynamicGroups[catId]!.add(consonant);
      }

      // Sort categories to maintain some order (CL0001, CL0002, CL0003)
      final sortedKeys = dynamicGroups.keys.toList()..sort();

      setState(() {
        _groups = sortedKeys.map((key) {
          return ConsonantGroup(
            name: catNames[key] ?? key,
            categoryCharId: key,
            consonants: dynamicGroups[key]!,
          );
        }).toList();

        _tabController = TabController(length: _groups.length, vsync: this);
        _tabController!.addListener(_handleTabChange);
        
        if (_groups.isNotEmpty) {
          _currentCategoryId = _groups.first.categoryCharId;
        }
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMsg = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(color: Color(0xFFD2691E)),
              SizedBox(height: 16),
              Text('กำลังโหลดพยัญชนะล้านนา...', style: TextStyle(fontSize: 10, color: Color(0xFF7A5C3A))),
            ],
          ),
        ),
      );
    }

    if (_errorMsg != null) {
      return Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.cloud_off, size: 60, color: Colors.redAccent),
                const SizedBox(height: 16),
                Text('ไม่สามารถโหลดข้อมูลได้\n$_errorMsg', textAlign: TextAlign.center, style: const TextStyle(fontSize: 10)),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: _loadData,
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFA0522D)),
                  child: const Text('ลองอีกครั้ง', style: TextStyle(color: Colors.white)),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final List<LannaConsonant> allConsonantsForTrain = _groups.expand((g) => g.consonants).toList();

    return Scaffold(
      backgroundColor: const Color(0xFFFFFBF7),
      appBar: AppBar(
        backgroundColor: const Color(0xFFFFFBF7),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFFE16905)),
          onPressed: () {
            if (widget.onBack != null) {
              widget.onBack!();
            } else {
              Navigator.pop(context);
            }
          },
        ),
        bottom: PreferredSize(preferredSize: const Size.fromHeight(1.5), child: Container(color: const Color(0xFFEADBC8), height: 1.5)),
        centerTitle: true,
        title: const Text(
          'พยัญชนะล้านนา',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.bold,
            color: Color(0xFF2D1A00),
          ),
        ),
      ),
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) {
          return [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: _IntroCard(
                  article: _articlesMap[_currentCategoryId],
                  categoryId: _currentCategoryId,
                ),
              ),
            ),
            SliverPersistentHeader(
              pinned: true,
              delegate: _SliverTabBarDelegate(
                TabBar(
                  controller: _tabController,
                  isScrollable: true,
                  indicatorColor: const Color(0xFFE16905),
                  indicatorWeight: 3.5,
                  indicatorSize: TabBarIndicatorSize.label,
                  labelColor: const Color(0xFFE16905),
                  labelStyle: const TextStyle(
                    fontSize: 8,
                    fontWeight: FontWeight.w400,
                  ),
                  unselectedLabelColor: const Color(0xFF7A5C3A),
                  unselectedLabelStyle: const TextStyle(
                    fontSize: 8,
                    fontWeight: FontWeight.w400,
                  ),
                  tabs: _groups.map((g) => Tab(text: g.name)).toList(),
                ),
              ),
            ),
          ];
        },
        body: TabBarView(
          controller: _tabController,
          children: _groups.map((group) {
            return PaginatedLannaGrid<LannaConsonant>(
              items: group.consonants,
              pageSize: 16,
              itemBuilder: (context, consonant, globalIndex) {
                final initialIndex = allConsonantsForTrain.indexWhere((c) => c.char == consonant.char);
                return GestureDetector(
                  onTap: () => pushLearningPage(
                    context,
                    MaterialPageRoute(
                      builder: (_) => CharDetailPage(
                        char: consonant.char,
                        reading: consonant.reading,
                        thai: consonant.thai,
                        description: consonant.description,
                        isGuest: widget.isGuest,
                        writingType: WritingType.consonant,
                        allChars: allConsonantsForTrain
                            .map((c) => {'char': c.char, 'label': c.reading})
                            .toList(),
                        initialWritingIndex: initialIndex >= 0 ? initialIndex : 0,
                        categoryName: group.name,
                      ),
                    ),
                  ),
                  child: LannaGlyphCard(
                    glyph: consonant.char,
                    thaiEquivalent: consonant.thai,
                  ),
                );
              },
            );
          }).toList(),
        ),
      ),
    );
  }



      void _showLoginRequiredAlert(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
        ),
        contentPadding: EdgeInsets.zero,
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 24),
            const Text(
              'ต้องเข้าสู่ระบบ',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: Color(0xFF2D1A00),
              ),
            ),
            const SizedBox(height: 12),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 24),
              child: Text(
                'คุณต้องเข้าสู่ระบบหรือสมัครสมาชิกก่อน\nจึงจะสามารถใช้งานเมนูฝึกเขียนได้',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 9,
                  height: 1.5,
                  color: Color(0xFF7A5C3A),
                ),
              ),
            ),
            const SizedBox(height: 20),
            const Divider(color: Color(0xFFEADBC8), height: 1, thickness: 1),
            InkWell(
              onTap: () {
                Navigator.pop(ctx);
                Navigator.pushNamed(context, '/login');
              },
              child: const Padding(
                padding: EdgeInsets.symmetric(vertical: 16),
                child: Text(
                  'เข้าสู่ระบบ',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF924E19),
                  ),
                ),
              ),
            ),
            const Divider(color: Color(0xFFEADBC8), height: 1, thickness: 1),
            InkWell(
              onTap: () {
                Navigator.pop(ctx);
                Navigator.pushNamed(context, '/register');
              },
              child: const Padding(
                padding: EdgeInsets.symmetric(vertical: 16),
                child: Text(
                  'สมัครสมาชิก',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF924E19),
                  ),
                ),
              ),
            ),
            const Divider(color: Color(0xFFEADBC8), height: 1, thickness: 1),
            InkWell(
              onTap: () => Navigator.pop(ctx),
              child: const Padding(
                padding: EdgeInsets.symmetric(vertical: 16),
                child: Text(
                  'ยกเลิก',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF7A5C3A),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// ============================================================================
/// COMPONENT : INTRO DESCRIPTION CARD
/// ============================================================================
class _IntroCard extends StatelessWidget {
  final ArticleModel? article;
  final String categoryId;
  const _IntroCard({this.article, required this.categoryId});

  String _getFallbackTitle() {
    switch (categoryId) {
      case 'CL0001':
        return 'กลุ่มอักขระในวรรค (๒๕ ตัวเดิม)';
      case 'CL0002':
        return 'กลุ่มอักขระนอกวรรค (๘ ตัวเดิม & ๑๑ ตัวใหม่)';
      case 'CL0003':
        return 'อักขระ ห นํา (๖ ตัวหลัก) & หมายเหตุการเทียบอักษร';
      default:
        return 'คู่มือเรียนภาษาล้านนา (ตัวเมือง)';
    }
  }

  String _getFallbackContent() {
    switch (categoryId) {
      case 'CL0001':
        return 'พยัญชนะในวรรคมี ๒๕ ตัว แบ่งเป็น ๕ วรรคตามฐานกรณ์:\n'
            '• วรรคก๋ะ: ก (ก๋ะ), ข (ข๋ะ), ค (ก๊ะ), ฆ (คะ), ง (งะ)\n'
            '• วรรคจ๋ะ: จ (จ๋ะ), ฉ (ฉะ), ช (จ๊ะ), ฌ (ซะ), ญ (ญะ)\n'
            '• วรรคระต๋ะ: ฏ (ระต๊ะ), ฐ (ระถะ), ฑ (ระทะ), ฒ (ระทะ), ณ (ระนะ)\n'
            '• วรรคต๋ะ: ต (ต๋ะ), ถ (ถ๋ะ), ท (ต๊ะ), ธ (ทะ), น (นะ)\n'
            '• วรรคป๋ะ: บ (บ๋ะ), ป (ป๋ะ), ผ (ผ๋ะ), พ (ป๊ะ), ม (มะ)';
      case 'CL0002':
        return 'อักขระนอกวรรคเดิมมี ๘ ตัว (ย, ร, ล, ว, ส, ห, ฬ, อ) และประดิษฐ์อักขระเพิ่มเติมอีก ๑๑ ตัว (ฃ, ฅ, ซ, บ, ป, ฝ, ฟ, ศ, ษ, อย/หย, ะ) เพื่อให้ครบถ้วนกับการปริวรรตภาษาไทยกลางและภาษาถิ่นล้านนา';
      case 'CL0003':
        return 'อักขระ ห นํา มี ๖ ตัวหลัก ได้แก่:\n'
            '• หงะ (ᩉ᩠ᨦ), หนะ (ᩉ᩠ᨶ), หมะ (ᩉ᩠ᨾ), หยะ (ᩉ᩠ᨿ), หละ (ᩉ᩠ᩃ), หวะ (ᩉ᩠ᩅ)\n'
            'หมายเหตุการเทียบอักษร: บ/ป (บ/ป), ด (ฏ/ฑ/ด), อย (ย/อย)';
      default:
        return 'อักขระพยัญชนะล้านนา ๕๓ รูปแบ่งเป็นอักขระในวรรค นอกวรรค และอักขระเพิ่มเติมตามหลักตำราล้านนา';
    }
  }

  @override
  Widget build(BuildContext context) {
    final title = article != null && article!.title.trim().isNotEmpty
        ? article!.title
        : _getFallbackTitle();
    final content = article != null && article!.content.trim().isNotEmpty
        ? article!.content
        : _getFallbackContent();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF3E0), // โทนส้มพาสเทลอ่อน
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF6B3A2A).withValues(alpha: 0.3)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF6B3A2A).withValues(alpha: 0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.menu_book_rounded, color: Color(0xFF6B3A2A), size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF6B3A2A),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            content,
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w500,
              color: Color(0xFF5C3D1E),
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}

class StrokePainter extends CustomPainter {
  final List<List<Offset>> strokes;
  final int currentIndex;
  final double progress;
  final String char;

  StrokePainter({
    required this.strokes,
    required this.currentIndex,
    required this.progress,
    required this.char,
  });

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

    // 1. วาดเส้นไกด์พื้นหลังสี #F5D5C0 (ตามพิกัดจริง)
    final paintGuide = Paint()
      ..color = const Color(0xFFF5D5C0)
      ..strokeWidth = 14
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    for (int i = 0; i < strokes.length; i++) {
      final pts = strokes[i];
      if (pts.isEmpty) continue;
      canvas.drawPath(catmullRomPath(pts, scale), paintGuide);
    }

    // 2. ปากกาสำหรับวาดเส้นที่เสร็จแล้ว (สีเทา #E5D5C5)
    final paintCompleted = Paint()
      ..color = const Color(0xFFE5D5C5)
      ..strokeWidth = 10
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    // 3. ปากกาสำหรับวาดเส้นที่กำลังทำอนิเมชัน (สีน้ำตาล #924E19)
    final paintCurrent = Paint()
      ..color = const Color(0xFF924E19)
      ..strokeWidth = 10
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    // วาดเส้นก่อนหน้าที่เสร็จไปแล้ว (smooth)
    for (int i = 0; i < currentIndex; i++) {
      final pts = strokes[i];
      if (pts.isEmpty) continue;
      canvas.drawPath(catmullRomPath(pts, scale), paintCompleted);
    }

    // วาดอนิเมชันเส้นปัจจุบัน (smooth)
    if (currentIndex < strokes.length) {
      final currentPoints = strokes[currentIndex];
      if (currentPoints.isNotEmpty) {
        final totalSegments = currentPoints.length - 1;
        final currentProgressSegment = progress * totalSegments;
        final fullSegments = currentProgressSegment.floor();
        final partialProgress = currentProgressSegment - fullSegments;
        final partialPoints = currentPoints.sublist(0, fullSegments + 1).toList();
        if (fullSegments < totalSegments) {
          final p1 = currentPoints[fullSegments];
          final p2 = currentPoints[fullSegments + 1];
          partialPoints.add(Offset(
            p1.dx + (p2.dx - p1.dx) * partialProgress,
            p1.dy + (p2.dy - p1.dy) * partialProgress,
          ));
        }
        canvas.drawPath(catmullRomPath(partialPoints, scale), paintCurrent);
      }
    }

    // 4. วาดจุดเริ่มต้นของเส้นหลัก (วงกลมพร้อมหมายเลขลำดับเส้น)
    final paintStartActive = Paint()..color = const Color(0xFF924E19);
    final paintStartInactive = Paint()..color = const Color(0xFFE5D5C5);

    for (int i = 0; i < strokes.length; i++) {
      if (strokes[i].isEmpty) continue;
      final startPt = scale(strokes[i][0]);
      final isCurrentOrCompleted = i <= currentIndex;
      canvas.drawCircle(
        startPt,
        10,
        isCurrentOrCompleted ? paintStartActive : paintStartInactive,
      );
      final textPainterNum = TextPainter(
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
      );
      textPainterNum.layout();
      textPainterNum.paint(
        canvas,
        Offset(startPt.dx - textPainterNum.width / 2, startPt.dy - textPainterNum.height / 2),
      );
    }
  }

  @override
  bool shouldRepaint(covariant StrokePainter oldDelegate) => true;
}

List<List<Offset>> getStrokePaths(String char) {
  return getStrokeData(char);
}


class _SliverTabBarDelegate extends SliverPersistentHeaderDelegate {
  final TabBar tabBar;
  _SliverTabBarDelegate(this.tabBar);

  @override
  double get minExtent => tabBar.preferredSize.height;
  @override
  double get maxExtent => tabBar.preferredSize.height;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      color: const Color(0xFFFFFBF7),
      child: tabBar,
    );
  }

  @override
  bool shouldRebuild(_SliverTabBarDelegate oldDelegate) {
    return false;
  }
}

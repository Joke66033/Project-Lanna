import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:lanna/services/lanna_char_service.dart';
import 'package:lanna/services/article_service.dart';
import 'package:lanna/models/article_model.dart';
import '../train/writing_mode.dart';
import '../train/writing_data.dart';
import '../train/stroke_data.dart' as sd;

/// ============================================================================
/// MODEL : LANNA SPELLING MODEL
/// ============================================================================
class LannaSpelling {
  final String char;
  final String reading;
  final String thai;
  final String description;

  const LannaSpelling({
    required this.char,
    required this.reading,
    required this.thai,
    required this.description,
  });
}

class SpellingGroup {
  final String name;
  final String categoryCharId;
  final List<LannaSpelling> spellings;

  const SpellingGroup({
    required this.name,
    required this.categoryCharId,
    required this.spellings,
  });
}

/// ============================================================================
/// SCREEN : LANNA SPELLING LEARNING PAGE
/// ============================================================================
class SpellingPage extends StatefulWidget {
  final bool isGuest;
  final VoidCallback? onBack;
  const SpellingPage({super.key, this.isGuest = false, this.onBack});

  @override
  State<SpellingPage> createState() => _SpellingPageState();
}

class _SpellingPageState extends State<SpellingPage> with SingleTickerProviderStateMixin {
  late final FlutterTts _tts;
  TabController? _tabController;

  final LannaCharService _charService = LannaCharService();
  final ArticleService _articleService = ArticleService();

  List<SpellingGroup> _groups = [];
  String _currentCategoryId = 'CL0008';
  final Map<String, ArticleModel?> _articlesMap = {};
  final Map<String, List<LannaSpelling>> _spellingsMap = {};
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
    if (_tabController != null) {
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
      // 1. ดึงบทความอธิบายตัวสะกดทั้งหมด (CL0008, CL0009, CL0010, CL0011)
      final apiArticles = await _articleService.getAllArticles(categoryCharId: 'CL0008,CL0009,CL0010,CL0011');
      _articlesMap.clear();
      for (var art in apiArticles) {
        if (art.categoryCharId != null && art.content.trim().isNotEmpty) {
          _articlesMap[art.categoryCharId!] = art;
        }
      }

      // 2. ดึงอักขระตัวสะกดทั้งหมดจาก API
      final apiSpellings = await _charService.getAllCharacters(categoryCharId: 'CL0008,CL0009,CL0010,CL0011');

      // ข้อมูลจำลองวิธีเขียนตัวสะกดเดิม
      final List<LannaSpelling> fallbackSpellings = [
        LannaSpelling(char: '᩠ᨦ', reading: 'งะตัวห้อย', thai: 'ง สะกด', description: 'เขียนหัวหยักโค้งเฉียงขึ้นซ้ายอยู่ใต้พยัญชนะต้น'),
        LannaSpelling(char: '᩠ᨶ', reading: 'นะตัวห้อย', thai: 'น สะกด', description: 'เขียนม้วนก้นโค้งมนด้านซ้ายเฉียงขวาอยู่ใต้พยัญชนะต้น'),
        LannaSpelling(char: '᩠ᨾ', reading: 'มะตัวห้อย', thai: 'ม สะกด', description: 'ลากม้วนหยักบนตวัดขึ้นขวาอยู่ใต้พยัญชนะต้น'),
        LannaSpelling(char: '᩠ᨿ', reading: 'ยะตัวห้อย', thai: 'ย สะกด/กล้ำ', description: 'เขียนขดเฉียงหัวในแล้วม้วนฐานปีกขวาใต้พยัญชนะต้น'),
        LannaSpelling(char: '᩠ᩁ', reading: 'ระวง / ไม้ส่าระ', thai: 'ร ควบกล้ำ', description: 'ลากโค้งเดี่ยวยกมนลอยใต้แนวบรรทัดโอบพยัญชนะต้น'),
        LannaSpelling(char: '᩠ᩃ', reading: 'ละตัวห้อย', thai: 'ล สะกด/กล้ำ', description: 'เขียนขยักสองส่วนขดม้วนลงล่างขวาใต้พยัญชนะต้น'),
        LannaSpelling(char: '᩠ᩅ', reading: 'วะตัวห้อย', thai: 'ว สะกด/กล้ำ', description: 'ม้วนฐานเฉียงขวาปัดโค้งปิดลอยใต้พยัญชนะต้น'),
        LannaSpelling(char: '᩠ᩈ', reading: 'สะตัวห้อย', thai: 'ส สะกด', description: 'เขียนโค้งก้นห้อยลอนคู่ปัดเฉียงขวาขึ้นใต้พยัญชนะต้น'),
        LannaSpelling(char: '᩠ᩉ', reading: 'ห นำตัวห้อย', thai: 'ห นำ', description: 'เขียนตวัดฐานไขว้ขึ้นขวาเฉียงอยู่ใต้พยัญชนะต้น'),
      ];

      // ดึงข้อมูลหมวดหมู่เพื่อเอาชื่อแสดงเป็นแท็บย่อย
      final categories = await _charService.getAllCategories();
      final Map<String, String> catNames = {
        for (var c in categories) c.categoryCharId: c.name
      };

      final List<LannaSpelling> listHN = [];
      final List<LannaSpelling> listRW = [];
      final List<LannaSpelling> listHoy = [];
      final List<LannaSpelling> listSpecial = [];

      for (var c in apiSpellings) {
        final String rawThai = c.thaiEquivalent;
        String parsedReading = rawThai;
        if (rawThai.contains('(') && rawThai.contains(')')) {
          parsedReading = rawThai.substring(rawThai.indexOf('(') + 1, rawThai.indexOf(')'));
        }
        
        final fallback = fallbackSpellings.firstWhere(
          (f) => f.char == c.lannaChar || f.char.endsWith(c.lannaChar) || c.lannaChar.endsWith(f.char),
          orElse: () => LannaSpelling(
            char: c.lannaChar,
            reading: parsedReading,
            thai: rawThai.split(' ').first,
            description: 'ตัวสะกดล้านนาตัว ${c.thaiEquivalent}',
          ),
        );
        
        final spelling = LannaSpelling(
          char: c.lannaChar,
          reading: fallback.reading,
          thai: rawThai,
          description: fallback.description,
        );

        if (c.categoryCharId == 'CL0008') {
          listHN.add(spelling);
        } else if (c.categoryCharId == 'CL0009') {
          listRW.add(spelling);
        } else if (c.categoryCharId == 'CL0010') {
          listHoy.add(spelling);
        } else if (c.categoryCharId == 'CL0011') {
          listSpecial.add(spelling);
        }
      }

      _spellingsMap['CL0008'] = listHN;
      _spellingsMap['CL0009'] = listRW;
      _spellingsMap['CL0010'] = listHoy;
      _spellingsMap['CL0011'] = listSpecial;

      setState(() {
        _groups = [
          SpellingGroup(name: catNames['CL0008'] ?? 'ห นำ', categoryCharId: 'CL0008', spellings: listHN),
          SpellingGroup(name: catNames['CL0009'] ?? 'ระวง (กล้ำ)', categoryCharId: 'CL0009', spellings: listRW),
          SpellingGroup(name: catNames['CL0010'] ?? 'ตัวห้อย (สะกด)', categoryCharId: 'CL0010', spellings: listHoy),
          SpellingGroup(name: catNames['CL0011'] ?? 'เครื่องหมายพิเศษ', categoryCharId: 'CL0011', spellings: listSpecial),
        ].where((g) => g.spellings.isNotEmpty).toList();

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
              Text('กำลังโหลดตัวสะกดล้านนา...', style: TextStyle(fontSize: 10, color: Color(0xFF7A5C3A))),
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

    final List<LannaSpelling> allSpellingsForTrain = _groups.expand((g) => g.spellings).toList();

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
          'ตัวสะกดล้านนา',
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
                child: _IntroCard(article: _articlesMap[_currentCategoryId]),
              ),
            ),
            SliverPersistentHeader(
              pinned: true,
              delegate: _SliverTabBarDelegate(
                TabBar(
                  controller: _tabController,
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
            return ListView.builder(
              padding: const EdgeInsets.fromLTRB(0, 8, 0, 80),
              itemCount: group.spellings.length,
              itemBuilder: (context, index) {
                final spelling = group.spellings[index];
                return _SpellingCard(
                  spelling: spelling,
                  onPlaySound: () => _speak(spelling.reading),
                  onTapStrokeOrder: () {
                    showModalBottomSheet(
                      context: context,
                      isScrollControlled: true,
                      backgroundColor: Colors.transparent,
                      barrierColor: Colors.black.withValues(alpha: 0.5),
                      builder: (context) => _StrokeOrderBottomSheet(spelling: spelling),
                    );
                  },
                  onTapPractice: () {
                    if (widget.isGuest) {
                      _showLoginRequiredAlert(context);
                      return;
                    }
                    final allWritingItems = allSpellingsForTrain.map((s) => WritingItem(
                      char: s.char,
                      label: s.reading,
                      type: WritingType.consonant,
                    )).toList();

                    final initialIndex = allSpellingsForTrain.indexWhere((s) => s.char == spelling.char);

                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => WritingModePage(
                          items: allWritingItems,
                          title: 'ฝึกเขียนตัวสะกด',
                          initialIndex: initialIndex >= 0 ? initialIndex : 0,
                        ),
                      ),
                    );
                  },
                );
              },
            );
          }).toList(),
        ),
      ),
    );
  }

  /// ==========================================================================
  /// MODAL BOTTOM SHEET
  /// ==========================================================================
  void showSpellingDetailsBottomSheet(
    BuildContext context,
    LannaSpelling spelling,
    List<LannaSpelling> allSpellings,
  ) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40,
                  height: 5,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                const SizedBox(height: 24),

                Stack(
                  alignment: Alignment.center,
                  children: [
                    Align(
                      alignment: Alignment.center,
                      child: Text(
                        spelling.char,
                        style: const TextStyle(
                          fontSize: 100,
                          fontFamily: 'LannaAkkhara',
                          color: Color(0xFFD2691E),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    Align(
                      alignment: Alignment.centerRight,
                      child: IconButton(
                        icon: const Icon(Icons.volume_up, color: Color(0xFFCD853F), size: 36),
                        onPressed: () => _speak(spelling.reading),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                Text(
                  'เสียงอ่าน: ${spelling.reading}',
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF2D1A00),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'เทียบภาษาไทย: ${spelling.thai}',
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF7A5C3A),
                  ),
                ),
                const SizedBox(height: 32),

                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.pop(context);
                          showModalBottomSheet(
                            context: context,
                            backgroundColor: Colors.transparent,
                            isScrollControlled: true,
                            builder: (context) => _StrokeOrderBottomSheet(spelling: spelling),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFFFFBF7),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                          elevation: 0,
                        ),
                        child: const Text(
                          'ดูวิธีเขียน',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () {
                          if (widget.isGuest) {
                            Navigator.pop(context); // ปิด BottomSheet
                            _showLoginRequiredAlert(context);
                            return;
                          }
                          Navigator.pop(context);
                          // แปลงข้อมูลไปฝึกเขียน
                          final allWritingItems = allSpellings.map((s) => WritingItem(
                            char: s.char,
                            label: s.reading,
                            type: WritingType.consonant, // ใช้โมเดลพยัญชนะสำหรับการลอนเส้น
                          )).toList();

                          final initialIndex = allSpellings.indexWhere((s) => s.char == spelling.char);

                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => WritingModePage(
                                items: allWritingItems,
                                title: 'ฝึกเขียนตัวสะกด',
                                initialIndex: initialIndex >= 0 ? initialIndex : 0,
                              ),
                            ),
                          );
                        },
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFFA0522D),
                          side: const BorderSide(color: Color(0xFFA0522D), width: 2),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: const Text(
                          'ฝึกเขียน',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
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
  const _IntroCard({this.article});

  @override
  Widget build(BuildContext context) {
    if (article == null) return const SizedBox.shrink();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF3E0),
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
              const Icon(Icons.info_outline, color: Color(0xFF6B3A2A), size: 22),
              const SizedBox(width: 8),
              Text(
                article!.title,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF6B3A2A),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            article!.content,
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

/// ============================================================================
/// COMPONENT : SPELLING GRID CARD
/// ============================================================================
class _SpellingCard extends StatelessWidget {
  final LannaSpelling spelling;
  final VoidCallback onPlaySound;
  final VoidCallback onTapStrokeOrder;
  final VoidCallback onTapPractice;

  const _SpellingCard({
    required this.spelling,
    required this.onPlaySound,
    required this.onTapStrokeOrder,
    required this.onTapPractice,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFEADBC8), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                // Square Lanna Character with Rounded corners background
                Container(
                  width: 64,
                  height: 64,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF5EAE1),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    spelling.char,
                    style: const TextStyle(
                      fontSize: 28,
                      fontFamily: 'LannaAkkhara',
                      color: Color(0xFF924E19),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                
                // Reading and Thai equivalent
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'เสียงอ่าน: ${spelling.reading}',
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF2C1A04),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'เทียบเสียงไทย: ${spelling.thai}',
                        style: const TextStyle(
                          fontSize: 8,
                          color: Color(0xFF7A5C3A),
                        ),
                      ),
                    ],
                  ),
                ),
                
                // Pronunciation Button (Small warm circle)
                Material(
                  color: const Color(0xFFF5EAE1),
                  shape: const CircleBorder(),
                  clipBehavior: Clip.antiAlias,
                  child: InkWell(
                    onTap: onPlaySound,
                    child: const Padding(
                      padding: EdgeInsets.all(10),
                      child: Icon(
                        Icons.volume_up_rounded,
                        color: Color(0xFF924E19),
                        size: 22,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Divider(color: Color(0xFFEADBC8), thickness: 1),
            const SizedBox(height: 8),
            
            // Description
            Text(
              spelling.description,
              style: TextStyle(
                fontSize: 8,
                color: Colors.grey.shade700,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 16),
            
            // Buttons: Stroke Order and Practice
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: onTapStrokeOrder,
                    icon: const Icon(Icons.menu_book_rounded, size: 16),
                    label: const Text('วิธีเขียน'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFF5EAE1),
                      foregroundColor: const Color(0xFF924E19),
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: onTapPractice,
                    icon: const Icon(Icons.brush_rounded, size: 16),
                    label: const Text('ฝึกเขียน'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF924E19),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }}


// ============================================================================
// STROKE ORDER BOTTOM SHEET FOR LANNASPELLING
// ============================================================================
class _StrokeOrderBottomSheet extends StatefulWidget {
  final LannaSpelling spelling;
  const _StrokeOrderBottomSheet({super.key, required this.spelling});

  @override
  State<_StrokeOrderBottomSheet> createState() => __StrokeOrderBottomSheetState();
}

class __StrokeOrderBottomSheetState extends State<_StrokeOrderBottomSheet>
    with SingleTickerProviderStateMixin {
  late List<List<Offset>> _strokes;
  int _currentStrokeIndex = 0;
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _strokes = getStrokePaths(widget.spelling.char);
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _animation = Tween<double>(begin: 0.0, end: 1.0).animate(
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
    if (_currentStrokeIndex < _strokes.length - 1) {
      setState(() {
        _currentStrokeIndex++;
      });
      _replay();
    }
  }

  void _prev() {
    if (_currentStrokeIndex > 0) {
      setState(() {
        _currentStrokeIndex--;
      });
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
          Container(
            width: 40,
            height: 5,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'วิธีเขียน ตั๋ว ${widget.spelling.reading}',
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
          Text(
            widget.spelling.char,
            style: const TextStyle(
              fontSize: 27,
              fontFamily: 'LannaAkkhara',
              color: Color(0xFF924E19),
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
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
            child: CustomPaint(
              painter: _StrokePainter(
                strokes: _strokes,
                currentIndex: _currentStrokeIndex,
                progress: _animation.value,
                char: widget.spelling.char,
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'เส้นที่ ${_currentStrokeIndex + 1} จากทั้งหมด ${_strokes.length} เส้น',
            style: const TextStyle(
              fontSize: 8,
              fontWeight: FontWeight.w500,
              color: Color(0xFF7A5C3A),
            ),
          ),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFF5EAE1),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFEADBC8), width: 1.0),
            ),
            child: Text(
              widget.spelling.description,
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
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                icon: const Icon(Icons.skip_previous_rounded, size: 36),
                color: _currentStrokeIndex > 0 ? const Color(0xFF924E19) : Colors.grey[300],
                onPressed: _currentStrokeIndex > 0 ? _prev : null,
              ),
              const SizedBox(width: 24),
              ElevatedButton.icon(
                onPressed: _replay,
                icon: const Icon(Icons.refresh),
                label: const Text(
                  'เล่นใหม่',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF924E19),
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
              ),
              const SizedBox(width: 24),
              IconButton(
                icon: const Icon(Icons.skip_next_rounded, size: 36),
                color: _currentStrokeIndex < _strokes.length - 1 ? const Color(0xFF924E19) : Colors.grey[300],
                onPressed: _currentStrokeIndex < _strokes.length - 1 ? _next : null,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StrokePainter extends CustomPainter {
  final List<List<Offset>> strokes;
  final int currentIndex;
  final double progress;
  final String char;

  _StrokePainter({
    required this.strokes,
    required this.currentIndex,
    required this.progress,
    required this.char,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // 1. วาดไกด์ตัวอักษรจางๆ ไว้ด้านหลัง
    final textPainter = TextPainter(
      text: TextSpan(
        text: char,
        style: TextStyle(
          fontSize: size.width * 0.8,
          fontFamily: 'LannaAkkhara',
          color: const Color(0xFFD2691E).withValues(alpha: 0.28),
          fontWeight: FontWeight.bold,
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();
    textPainter.paint(
      canvas,
      Offset((size.width - textPainter.width) / 2, (size.height - textPainter.height) / 2),
    );
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
  }

  @override
  bool shouldRepaint(covariant _StrokePainter oldDelegate) => true;
}


// Helper function to load stroke paths
List<List<Offset>> getStrokePaths(String char) {
  return sd.getStrokeData(char);
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

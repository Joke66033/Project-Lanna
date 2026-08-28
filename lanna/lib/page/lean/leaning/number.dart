import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:lanna/services/lanna_char_service.dart';
import 'package:lanna/services/article_service.dart';
import 'package:lanna/models/article_model.dart';
import 'package:lanna/models/category_model.dart';
import '../learning_navigation.dart';
import 'lanna_glyph_card.dart';
import 'char_detail_page.dart';
import '../train/writing_data.dart';
import 'package:lanna/services/character_stroke_service.dart';

/// ============================================================================
/// MODEL : LANNA NUMBER
/// ============================================================================
class LannaNumber {
  final String char;       // อักษรล้านนา Unicode
  final String reading;    // คำอ่านภาษาไทย เช่น "หนึ่ง"
  final String thai;       // เลขไทยเทียบเคียง เช่น "๑"
  final String description; // คำอธิบายวิธีเขียนสั้นๆ

  const LannaNumber({
    required this.char,
    required this.reading,
    required this.thai,
    required this.description,
  });
}

class NumberGroup {
  final String name;
  final String categoryCharId;
  final List<LannaNumber> numbers;

  const NumberGroup({
    required this.name,
    required this.categoryCharId,
    required this.numbers,
  });
}

/// ============================================================================
/// SCREEN : LANNA NUMBERS LEARNING PAGE
/// ============================================================================
class NumberPage extends StatefulWidget {
  final bool isGuest;
  final VoidCallback? onBack;
  const NumberPage({super.key, this.isGuest = false, this.onBack});

  @override
  State<NumberPage> createState() => _NumberPageState();
}

class _NumberPageState extends State<NumberPage> with SingleTickerProviderStateMixin {
  late final FlutterTts _tts;
  TabController? _tabController;

  final LannaCharService _charService = LannaCharService();
  final ArticleService _articleService = ArticleService();

  List<NumberGroup> _groups = [];
  String _currentCategoryId = 'CL0007';
  final Map<String, ArticleModel?> _articlesMap = {};
  bool _isLoading = true;
  String? _errorMsg;

  static const List<LannaNumber> _defaultThamNumbers = [
    LannaNumber(char: '᪀', reading: 'ศูนย์', thai: '๐ (ศูนย์)', description: 'เลขศูนย์ในธัมม์'),
    LannaNumber(char: '᪁', reading: 'หนึ่ง', thai: '๑ (หนึ่ง)', description: 'เลขหนึ่งในธัมม์'),
    LannaNumber(char: '᪂', reading: 'สอง', thai: '๒ (สอง)', description: 'เลขสองในธัมม์'),
    LannaNumber(char: '᪃', reading: 'สาม', thai: '๓ (สาม)', description: 'เลขสามในธัมม์'),
    LannaNumber(char: '᪄', reading: 'สี่', thai: '๔ (สี่)', description: 'เลขสี่ในธัมม์'),
    LannaNumber(char: '᪅', reading: 'ห้า', thai: '๕ (ห้า)', description: 'เลขห้าในธัมม์'),
    LannaNumber(char: '᪆', reading: 'หก', thai: '๖ (หก)', description: 'เลขหกในธัมม์'),
    LannaNumber(char: '᪇', reading: 'เจ็ด', thai: '๗ (เจ็ด)', description: 'เลขเจ็ดในธัมม์'),
    LannaNumber(char: '᪈', reading: 'แปด', thai: '๘ (แปด)', description: 'เลขแปดในธัมม์'),
    LannaNumber(char: '᪉', reading: 'เก้า', thai: '๙ (เก้า)', description: 'เลขเก้าในธัมม์'),
  ];

  static const List<LannaNumber> _defaultHoraNumbers = [
    LannaNumber(char: '᪐', reading: 'ศูนย์โหรา', thai: '๐ (ศูนย์)', description: 'เลขศูนย์โหรา'),
    LannaNumber(char: '᪑', reading: 'หนึ่งโหรา', thai: '๑ (หนึ่ง)', description: 'เลขหนึ่งโหรา'),
    LannaNumber(char: '᪒', reading: 'สองโหรา', thai: '๒ (สอง)', description: 'เลขสองโหรา'),
    LannaNumber(char: '᪓', reading: 'สามโหรา', thai: '๓ (สาม)', description: 'เลขสามโหรา'),
    LannaNumber(char: '᪔', reading: 'สี่โหรา', thai: '๔ (สี่)', description: 'เลขสี่โหรา'),
    LannaNumber(char: '᪕', reading: 'ห้าโหรา', thai: '๕ (ห้า)', description: 'เลขห้าโหรา'),
    LannaNumber(char: '᪖', reading: 'หกโหรา', thai: '๖ (หก)', description: 'เลขหกโหรา'),
    LannaNumber(char: '᪗', reading: 'เจ็ดโหรา', thai: '๗ (เจ็ด)', description: 'เลขเจ็ดโหรา'),
    LannaNumber(char: '᪘', reading: 'แปดโหรา', thai: '๘ (แปด)', description: 'เลขแปดโหรา'),
    LannaNumber(char: '᪙', reading: 'เก้าโหรา', thai: '๙ (เก้า)', description: 'เลขเก้าโหรา'),
  ];

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
      var subCategories = await _charService.getCategoriesByLearningCode('LC004');
      if (subCategories.isEmpty) {
        final allCats = await _charService.getAllCategories();
        subCategories = allCats.where((c) => 
          (c.learningCategoryCode != null && c.learningCategoryCode!.trim().toUpperCase() == 'LC004') || 
          c.categoryCharId.toUpperCase() == 'CL0007' || 
          c.categoryCharId.toUpperCase() == 'CL0014' ||
          c.name.contains('เลข')
        ).toList();
      }
      final List<String> catIds = subCategories.map((c) => c.categoryCharId).toList();
      final String effectiveCatIds = catIds.isNotEmpty ? catIds.join(',') : 'CL0007,CL0014';

      final nArticles = await _articleService.getAllArticles(
        categoryCharId: effectiveCatIds,
      );
      _articlesMap.clear();
      for (var art in nArticles) {
        if (art.categoryCharId != null && art.content.trim().isNotEmpty) {
          _articlesMap[art.categoryCharId!] = art;
        }
      }
      _articlesMap.putIfAbsent('CL0007', () => const ArticleModel(
        articleId: 'AR0007',
        title: 'เลขในธัมม์ คืออะไร?',
        content: 'เลขในธัมม์ หรือตัวเลขธัมม์ เป็นชุดตัวเลขที่ใช้บันทึกในคัมภีร์ใบลานและพับสาทางพระพุทธศาสนา วรรณกรรม และเอกสารโบราณล้านนา',
        categoryCharId: 'CL0007',
      ));
      _articlesMap.putIfAbsent('CL0014', () => const ArticleModel(
        articleId: 'AR0014',
        title: 'เลขโหรา คืออะไร?',
        content: 'เลขโหรา หรือตัวเลขโหราศาสตร์ ใช้บันทึกเอกสารทางโลก การทำนายปฏิทิน ฤกษ์ยาม และกฎหมายโบราณ มีรูปแบบคล้ายคลึงกับตัวเลขไทยโบราณ',
        categoryCharId: 'CL0014',
      ));

      final apiNumbers = await _charService.getAllCharacters(
        categoryCharId: effectiveCatIds,
      );

      final Map<String, List<LannaNumber>> dynamicMap = {};
      for (var c in apiNumbers) {
        final String rawThai = c.thaiEquivalent;
        String parsedReading = rawThai;
        if (rawThai.contains('(') && rawThai.contains(')')) {
          parsedReading = rawThai.substring(rawThai.indexOf('(') + 1, rawThai.indexOf(')'));
        }
        
        final numItem = LannaNumber(
          char: c.lannaChar,
          reading: parsedReading,
          thai: rawThai,
          description: 'ตัวเลขล้านนาตัว ${c.thaiEquivalent}',
        );

        final catId = c.categoryCharId.trim().toUpperCase();
        dynamicMap.putIfAbsent(catId, () => []).add(numItem);
      }

      final List<NumberGroup> groups = [];
      
      final listTham = dynamicMap['CL0007'] ?? [];
      final nameTham = subCategories.firstWhere((s) => s.categoryCharId.toUpperCase() == 'CL0007', orElse: () => const CategoryCharModel(categoryCharId: 'CL0007', name: 'เลขในธัมม์')).name;
      groups.add(NumberGroup(
        name: nameTham,
        categoryCharId: 'CL0007',
        numbers: listTham.isNotEmpty ? listTham : _defaultThamNumbers,
      ));

      final listHora = dynamicMap['CL0014'] ?? [];
      final nameHora = subCategories.firstWhere((s) => s.categoryCharId.toUpperCase() == 'CL0014', orElse: () => const CategoryCharModel(categoryCharId: 'CL0014', name: 'เลขโหรา')).name;
      groups.add(NumberGroup(
        name: nameHora,
        categoryCharId: 'CL0014',
        numbers: listHora.isNotEmpty ? listHora : _defaultHoraNumbers,
      ));

      for (var cat in subCategories) {
        final upId = cat.categoryCharId.toUpperCase();
        if (upId != 'CL0007' && upId != 'CL0014') {
          final listOther = dynamicMap[upId] ?? [];
          if (listOther.isNotEmpty) {
            groups.add(NumberGroup(
              name: cat.name,
              categoryCharId: cat.categoryCharId,
              numbers: listOther,
            ));
          }
        }
      }

      setState(() {
        _groups = groups;
        _tabController?.removeListener(_handleTabChange);
        _tabController?.dispose();
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
              Text('กำลังโหลดตัวเลขล้านนา...', style: TextStyle(fontSize: 10, color: Color(0xFF7A5C3A))),
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

    final List<LannaNumber> allNumbersForTrain = _groups.expand((g) => g.numbers).toList();

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
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1.5),
          child: Container(color: const Color(0xFFEADBC8), height: 1.5),
        ),
        centerTitle: true,
        title: const Text(
          'ตัวเลขล้านนา',
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
                  tabAlignment: TabAlignment.start,
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
            return PaginatedLannaGrid<LannaNumber>(
              items: group.numbers,
              pageSize: 16,
              itemBuilder: (context, number, globalIndex) {
                final initialIndex = allNumbersForTrain.indexWhere((n) => n.char == number.char);
                return GestureDetector(
                  onTap: () => pushLearningPage(
                    context,
                    MaterialPageRoute(
                      builder: (_) => CharDetailPage(
                        char: number.char,
                        reading: number.reading,
                        thai: number.thai,
                        description: number.description,
                        isGuest: widget.isGuest,
                        writingType: WritingType.number,
                        allChars: allNumbersForTrain
                            .map((n) => {'char': n.char, 'label': n.reading})
                            .toList(),
                        initialWritingIndex: initialIndex >= 0 ? initialIndex : 0,
                        categoryName: group.name,
                      ),
                    ),
                  ),
                  child: LannaGlyphCard(
                    glyph: number.char,
                    thaiEquivalent: number.thai,
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
      case 'CL0007':
        return 'เลขในธัมม์ คืออะไร?';
      case 'CL0014':
        return 'เลขโหรา คืออะไร?';
      default:
        return 'ตัวเลขล้านนา คืออะไร?';
    }
  }

  String _getFallbackContent() {
    switch (categoryId) {
      case 'CL0007':
        return 'เลขในธัมม์ หรือตัวเลขธัมม์ เป็นชุดตัวเลขที่ใช้บันทึกในคัมภีร์ใบลานและพับสาทางพระพุทธศาสนา วรรณกรรม และเอกสารโบราณล้านนา';
      case 'CL0014':
        return 'เลขโหรา หรือตัวเลขโหราศาสตร์ ใช้บันทึกเอกสารทางโลก การทำนายปฏิทิน ฤกษ์ยาม และกฎหมายโบราณ มีรูปแบบคล้ายคลึงกับตัวเลขไทยโบราณ';
      default:
        return 'ตัวเลขในภาษาล้านนามี ๒ ชุด คือ "เลขในธัมม์" นิยมใช้เขียนในคัมภีร์ใบลาน และ "เลขโหรา" นิยมใช้ในการคำนวณปฏิทินและฤกษ์ยาม มีรูปแบบ ๐-๙ เทียบเท่าเลขไทยและเลขอารบิก';
    }
  }

  @override
  Widget build(BuildContext context) {
    final title = article?.title.isNotEmpty == true ? article!.title : _getFallbackTitle();
    final content = article?.content.isNotEmpty == true ? article!.content : _getFallbackContent();

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
              const Icon(Icons.menu_book, color: Color(0xFF6B3A2A), size: 22),
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

/// ============================================================================
/// COMPONENT : NUMBER GRID CARD
/// ============================================================================
class _NumberCard extends StatelessWidget {
  final LannaNumber number;
  final VoidCallback onPlaySound;
  final VoidCallback onTapStrokeOrder;
  final VoidCallback onTapPractice;

  const _NumberCard({
    required this.number,
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
                    number.char,
                    style: const TextStyle(
                      fontSize: 28,
                      fontFamily: 'LNTilok',
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
                        'เสียงอ่าน: ${number.reading}',
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF2C1A04),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'เทียบเสียงไทย: ${number.thai}',
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
              number.description,
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
// STROKE ORDER BOTTOM SHEET FOR LANNANUMBER
// ============================================================================
class NumberStrokeOrderBottomSheet extends StatefulWidget {
  final LannaNumber number;
  const NumberStrokeOrderBottomSheet({super.key, required this.number});

  @override
  State<NumberStrokeOrderBottomSheet> createState() => _NumberStrokeOrderBottomSheetState();
}

class _NumberStrokeOrderBottomSheetState extends State<NumberStrokeOrderBottomSheet>
    with SingleTickerProviderStateMixin {
  late List<List<Offset>> _strokes;
  int _currentStrokeIndex = 0;
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _strokes = getStrokePaths(widget.number.char);
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
                'วิธีเขียน ตั๋ว ${widget.number.reading}',
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
            widget.number.char,
            style: const TextStyle(
              fontSize: 27,
              fontFamily: 'LNTilok',
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
              painter: NumberStrokePainter(
                strokes: _strokes,
                currentIndex: _currentStrokeIndex,
                progress: _animation.value,
                char: widget.number.char,
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
              widget.number.description,
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

class NumberStrokePainter extends CustomPainter {
  final List<List<Offset>> strokes;
  final int currentIndex;
  final double progress;
  final String char;

  NumberStrokePainter({
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
  bool shouldRepaint(covariant NumberStrokePainter oldDelegate) => true;
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

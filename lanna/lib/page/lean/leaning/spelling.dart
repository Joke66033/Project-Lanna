import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:lanna/services/auth_provider.dart';
import '../learning_navigation.dart';
import 'lanna_glyph_card.dart';
import 'package:lanna/services/lanna_char_service.dart';
import 'package:lanna/services/article_service.dart';
import 'package:lanna/models/article_model.dart';
import '../train/writing_mode.dart';
import '../train/writing_data.dart';
import 'package:lanna/services/character_stroke_service.dart' as sd;
import '../train/stroke_order_model.dart';
import 'char_detail_page.dart';

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

class _SpellingPageState extends State<SpellingPage>
    with SingleTickerProviderStateMixin {
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
    _loadData();
  }

  @override
  void dispose() {
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
      // 1. ดึงหมวดหมู่ย่อยทั้งหมดที่สังกัด LC005 จาก API
      var subCategories = await _charService.getCategoriesByLearningCode('LC005');
      if (subCategories.isEmpty) {
        final allCats = await _charService.getAllCategories();
        subCategories = allCats.where((c) => 
          (c.learningCategoryCode != null && c.learningCategoryCode!.trim().toUpperCase() == 'LC005') ||
          c.categoryCharId.toUpperCase() == 'CL0008' ||
          c.categoryCharId.toUpperCase() == 'CL0009' ||
          c.categoryCharId.toUpperCase() == 'CL0010' ||
          c.categoryCharId.toUpperCase() == 'CL0011' ||
          c.categoryCharId.toUpperCase() == 'CL0012' ||
          c.categoryCharId.toUpperCase() == 'CL0013' ||
          c.name.contains('สะกด') || c.name.contains('ห นำ') || c.name.contains('ระวง')
        ).toList();
      }
      final List<String> catIds = subCategories.map((c) => c.categoryCharId).toList();
      final String catIdQuery = catIds.join(',');

      // 2. ดึงบทความอธิบายตามรหัสหมวดหมู่ย่อย
      const String fallbackSpellingCatIds = 'CL0008,CL0009,CL0010,CL0011,CL0012,CL0013';
      final String effectiveCatIds = catIdQuery.isNotEmpty ? catIdQuery : fallbackSpellingCatIds;
      final apiArticles = await _articleService.getAllArticles(
        categoryCharId: effectiveCatIds,
      );
      _articlesMap.clear();
      for (var art in apiArticles) {
        if (art.categoryCharId != null && art.content.trim().isNotEmpty) {
          _articlesMap[art.categoryCharId!] = art;
        }
      }

      // 3. ดึงอักขระตัวสะกดทั้งหมดจาก API เฉพาะหมวดตัวสะกด
      final apiSpellings = await _charService.getAllCharacters(
        categoryCharId: effectiveCatIds,
      );

      final Map<String, List<LannaSpelling>> dynamicMap = {};
      for (var c in apiSpellings) {
        if (c.lannaChar.trim().isEmpty ||
            c.thaiEquivalent.contains('พินทุ') ||
            c.thaiEquivalent.contains('ไม้สะกด') ||
            c.thaiEquivalent.contains('เครื่องหมายทำตัวห้อย') ||
            c.lannaChar == '\u1A60' ||
            c.lannaChar == '\u0E3A') {
          continue;
        }
        final String rawThai = c.thaiEquivalent;
        String parsedReading = rawThai;
        if (rawThai.contains('(') && rawThai.contains(')')) {
          parsedReading = rawThai.substring(
            rawThai.indexOf('(') + 1,
            rawThai.indexOf(')'),
          );
        }

        final spelling = LannaSpelling(
          char: c.lannaChar,
          reading: parsedReading,
          thai: rawThai,
          description: 'ตัวสะกดล้านนาตัว ${c.thaiEquivalent}',
        );

        final catId = c.categoryCharId;
        dynamicMap.putIfAbsent(catId, () => []).add(spelling);
      }

      _spellingsMap.clear();
      _spellingsMap.addAll(dynamicMap);

      final List<SpellingGroup> groups = [];
      for (var cat in subCategories) {
        final list = dynamicMap[cat.categoryCharId] ?? [];
        if (list.isNotEmpty) {
          groups.add(SpellingGroup(
            name: cat.name,
            categoryCharId: cat.categoryCharId,
            spellings: list,
          ));
        }
      }

      setState(() {
        _groups = groups;
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
              Text(
                'กำลังโหลดตัวสะกดล้านนา...',
                style: TextStyle(fontSize: 10, color: Color(0xFF7A5C3A)),
              ),
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
                Text(
                  'ไม่สามารถโหลดข้อมูลได้\n$_errorMsg',
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 10),
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: _loadData,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFA0522D),
                  ),
                  child: const Text(
                    'ลองอีกครั้ง',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final List<LannaSpelling> allSpellingsForTrain = _groups
        .expand((g) => g.spellings)
        .toList();

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
            return PaginatedLannaGrid<LannaSpelling>(
              items: group.spellings,
              pageSize: 16,
              itemBuilder: (context, spelling, globalIndex) {
                final initialIndex = allSpellingsForTrain.indexWhere(
                  (s) => s.char == spelling.char,
                );
                return GestureDetector(
                  onTap: () => pushLearningPage(
                    context,
                    MaterialPageRoute(
                      builder: (_) => CharDetailPage(
                        char: spelling.char,
                        reading: spelling.reading,
                        thai: spelling.thai,
                        description: spelling.description,
                        isGuest: widget.isGuest,
                        writingType: WritingType.consonant,
                        allChars: allSpellingsForTrain
                            .map((s) => {'char': s.char, 'label': s.reading})
                            .toList(),
                        initialWritingIndex: initialIndex >= 0
                            ? initialIndex
                            : 0,
                        categoryName: group.name,
                      ),
                    ),
                  ),
                  child: LannaGlyphCard(
                    glyph: spelling.char,
                    thaiEquivalent: spelling.thai,
                  ),
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
                          fontFamily: 'LNTilok',
                          color: Color(0xFFD2691E),
                          fontWeight: FontWeight.bold,
                        ),
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
                            builder: (context) =>
                                _StrokeOrderBottomSheet(spelling: spelling),
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
                          final auth = context.read<AuthProvider>();
                          if (!auth.isLoggedIn) {
                            Navigator.pop(context);
                            _showLoginRequiredAlert(context);
                            return;
                          }
                          Navigator.pop(context);
                          // แปลงข้อมูลไปฝึกเขียน
                          final allWritingItems = allSpellings
                              .map(
                                (s) => WritingItem(
                                  char: s.char,
                                  label: s.reading,
                                  type: WritingType
                                      .consonant, // ใช้โมเดลพยัญชนะสำหรับการลอนเส้น
                                ),
                              )
                              .toList();

                          final initialIndex = allSpellings.indexWhere(
                            (s) => s.char == spelling.char,
                          );

                          pushLearningPage(
                            context,
                            MaterialPageRoute(
                              builder: (_) => WritingModePage(
                                items: allWritingItems,
                                title: 'ฝึกเขียนตัวสะกด',
                                initialIndex: initialIndex >= 0
                                    ? initialIndex
                                    : 0,
                              ),
                            ),
                          );
                        },
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFFA0522D),
                          side: const BorderSide(
                            color: Color(0xFFA0522D),
                            width: 2,
                          ),
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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
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
                Navigator.of(context, rootNavigator: true).pushNamed('/login');
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
                Navigator.of(
                  context,
                  rootNavigator: true,
                ).pushNamed('/register');
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
        color: const Color(0xFFF1F8F0),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFC7DCC7)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF2E6B34).withValues(alpha: 0.06),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.help_outline_rounded,
                color: Color(0xFF1B4D20),
                size: 22,
              ),
              const SizedBox(width: 8),
              Text(
                article!.title,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1B4D20),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            article!.content,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: Color(0xFF224424),
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// STROKE ORDER BOTTOM SHEET FOR LANNASPELLING
// ============================================================================
class _StrokeOrderBottomSheet extends StatefulWidget {
  final LannaSpelling spelling;
  const _StrokeOrderBottomSheet({required this.spelling});

  @override
  State<_StrokeOrderBottomSheet> createState() =>
      __StrokeOrderBottomSheetState();
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
                color: _currentStrokeIndex > 0
                    ? const Color(0xFF924E19)
                    : Colors.grey[300],
                onPressed: _currentStrokeIndex > 0 ? _prev : null,
              ),
              const SizedBox(width: 24),
              ElevatedButton.icon(
                onPressed: _replay,
                icon: const Icon(Icons.refresh),
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
                color: _currentStrokeIndex < _strokes.length - 1
                    ? const Color(0xFF924E19)
                    : Colors.grey[300],
                onPressed: _currentStrokeIndex < _strokes.length - 1
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
      if (scaled.length == 2) {
        path.lineTo(scaled[1].dx, scaled[1].dy);
        return path;
      }
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
      paintGuide.color = strokeOrderColors[i % strokeOrderColors.length]
          .withValues(alpha: 0.18);
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
        final partialPoints = currentPoints
            .sublist(0, fullSegments + 1)
            .toList();
        if (fullSegments < totalSegments) {
          final p1 = currentPoints[fullSegments];
          final p2 = currentPoints[fullSegments + 1];
          partialPoints.add(
            Offset(
              p1.dx + (p2.dx - p1.dx) * partialProgress,
              p1.dy + (p2.dy - p1.dy) * partialProgress,
            ),
          );
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
      final isFirst = i == 0;
      canvas.drawCircle(
        startPt,
        10,
        isFirst
            ? (Paint()..color = const Color(0xFFFF9800))
            : isCurrentOrCompleted
            ? paintStartActive
            : paintStartInactive,
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
        Offset(
          startPt.dx - textPainterNum.width / 2,
          startPt.dy - textPainterNum.height / 2,
        ),
      );
    }

    if (strokes.isNotEmpty && strokes.last.isNotEmpty) {
      canvas.drawCircle(
        scale(strokes.last.last),
        6,
        Paint()
          ..color = const Color(0xFF924E19)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _StrokePainter oldDelegate) => true;
}

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
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return Container(color: const Color(0xFFFFFBF7), child: tabBar);
  }

  @override
  bool shouldRebuild(_SliverTabBarDelegate oldDelegate) {
    return false;
  }
}


class AutoScrollingTabLabel extends StatefulWidget {
  final String text;
  final bool isSelected;

  const AutoScrollingTabLabel({
    super.key,
    required this.text,
    this.isSelected = false,
  });

  @override
  State<AutoScrollingTabLabel> createState() => _AutoScrollingTabLabelState();
}

class _AutoScrollingTabLabelState extends State<AutoScrollingTabLabel> {
  late final ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    if (widget.isSelected) {
      _startAutoScroll();
    }
  }

  @override
  void didUpdateWidget(AutoScrollingTabLabel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isSelected && !oldWidget.isSelected) {
      _startAutoScroll();
    }
  }

  void _startAutoScroll() async {
    await Future.delayed(const Duration(milliseconds: 400));
    if (!mounted || !_scrollController.hasClients) return;
    final maxScroll = _scrollController.position.maxScrollExtent;
    if (maxScroll <= 0) return;

    await _scrollController.animateTo(
      maxScroll,
      duration: Duration(milliseconds: (maxScroll * 35).toInt() + 1200),
      curve: Curves.easeInOutCubic,
    );
    await Future.delayed(const Duration(milliseconds: 600));
    if (!mounted || !_scrollController.hasClients) return;
    await _scrollController.animateTo(
      0,
      duration: const Duration(milliseconds: 600),
      curve: Curves.easeOut,
    );
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 240),
      child: SingleChildScrollView(
        controller: _scrollController,
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4.0, vertical: 6.0),
          child: Text(
            widget.text,
            style: TextStyle(
              fontSize: 13.5,
              fontWeight: widget.isSelected ? FontWeight.bold : FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:lanna/services/lanna_char_service.dart';
import 'package:lanna/services/article_service.dart';
import 'package:lanna/models/article_model.dart';
import '../train/writing_mode.dart';
import '../train/writing_data.dart';
import '../train/stroke_data.dart' as sd;

/// ============================================================================
/// MODEL : LANNA VOWEL
/// ============================================================================
class LannaVowel {
  final String char;       // อักษรล้านนา Unicode
  final String reading;    // คำอ่านภาษาไทย เช่น "ไม้ก๋า"
  final String thai;       // เทียบสระไทย เช่น "สระ อา"
  final String description; // คำอธิบายวิธีเขียนสั้นๆ

  const LannaVowel({
    required this.char,
    required this.reading,
    required this.thai,
    required this.description,
  });
}

class VowelGroup {
  final String name;
  final String categoryCharId;
  final List<LannaVowel> vowels;

  const VowelGroup({
    required this.name,
    required this.categoryCharId,
    required this.vowels,
  });
}

/// ============================================================================
/// SCREEN : LANNA VOWELS LEARNING PAGE
/// ============================================================================
class VowelPage extends StatefulWidget {
  final bool isGuest;
  final VoidCallback? onBack;
  const VowelPage({super.key, this.isGuest = false, this.onBack});

  @override
  State<VowelPage> createState() => _VowelPageState();
}

class _VowelPageState extends State<VowelPage> with SingleTickerProviderStateMixin {
  late final FlutterTts _tts;
  TabController? _tabController;

  final LannaCharService _charService = LannaCharService();
  final ArticleService _articleService = ArticleService();

  List<VowelGroup> _groups = [];
  String _currentCategoryId = 'CL0005';
  final Map<String, ArticleModel?> _articlesMap = {};
  final Map<String, List<LannaVowel>> _vowelsMap = {};
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
      // 1. ดึงบทความอธิบายสระทั้งหมด (CL0004 หรือ CL0005)
      final apiArticles = await _articleService.getAllArticles(categoryCharId: 'CL0004,CL0005');
      _articlesMap.clear();
      for (var art in apiArticles) {
        if (art.categoryCharId != null && art.content.trim().isNotEmpty) {
          _articlesMap[art.categoryCharId!] = art;
        }
      }

      // 2. ดึงสระทั้งหมดจาก API เฉพาะกลุ่ม CL0004 และ CL0005
      final apiVowels = await _charService.getAllCharacters(categoryCharId: 'CL0004,CL0005');

      // ดึงข้อมูลหมวดหมู่เพื่อเอาชื่อแสดงเป็นแท็บย่อย
      final categories = await _charService.getAllCategories();
      final Map<String, String> catNames = {
        for (var c in categories) c.categoryCharId: c.name
      };

      final List<LannaVowel> listJom = [];
      final List<LannaVowel> listLoy = [];

      for (var c in apiVowels) {
        final String rawThai = c.thaiEquivalent;
        String parsedReading = rawThai;
        if (rawThai.contains('(') && rawThai.contains(')')) {
          parsedReading = rawThai.substring(rawThai.indexOf('(') + 1, rawThai.indexOf(')'));
        }

        final vowel = LannaVowel(
          char: c.lannaChar,
          reading: parsedReading,
          thai: rawThai,
          description: 'สระล้านนาตัว ${c.thaiEquivalent}',
        );

        if (c.categoryCharId == 'CL0005') {
          listJom.add(vowel);
        } else {
          listLoy.add(vowel);
        }
      }

      _vowelsMap['CL0005'] = listJom;
      _vowelsMap['CL0004'] = listLoy;

      setState(() {
        _groups = [
          VowelGroup(name: catNames['CL0005'] ?? 'สระจม (ไม้)', categoryCharId: 'CL0005', vowels: listJom),
          VowelGroup(name: catNames['CL0004'] ?? 'สระลอย (หลวง)', categoryCharId: 'CL0004', vowels: listLoy),
        ].where((g) => g.vowels.isNotEmpty).toList();

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
              Text('กำลังโหลดสระล้านนา...', style: TextStyle(fontSize: 10, color: Color(0xFF7A5C3A))),
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

    final List<LannaVowel> allVowelsForTrain = _groups.expand((g) => g.vowels).toList();

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
          'สระล้านนา',
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
              itemCount: group.vowels.length,
              itemBuilder: (context, index) {
                final vowel = group.vowels[index];
                return _VowelCard(
                  vowel: vowel,
                  onPlaySound: () => _speak(vowel.reading),
                  onTapStrokeOrder: () {
                    showModalBottomSheet(
                      context: context,
                      isScrollControlled: true,
                      backgroundColor: Colors.transparent,
                      barrierColor: Colors.black.withValues(alpha: 0.5),
                      builder: (_) => VowelStrokeOrderBottomSheet(vowel: vowel),
                    );
                  },
                  onTapPractice: () {
                    if (widget.isGuest) {
                      _showLoginRequiredAlert(context);
                      return;
                    }
                    final allWritingItems = allVowelsForTrain.map((v) => WritingItem(
                      char: v.char,
                      label: v.reading,
                      type: WritingType.vowel,
                    )).toList();

                    final initialIndex = allVowelsForTrain.indexWhere((v) => v.char == vowel.char);

                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => WritingModePage(
                          items: allWritingItems,
                          title: 'ฝึกเขียนสระ',
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
/// COMPONENT : VOWEL GRID CARD
/// ============================================================================
class _VowelCard extends StatelessWidget {
  final LannaVowel vowel;
  final VoidCallback onPlaySound;
  final VoidCallback onTapStrokeOrder;
  final VoidCallback onTapPractice;

  const _VowelCard({
    required this.vowel,
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
                    vowel.char,
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
                        'เสียงอ่าน: ${vowel.reading}',
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF2C1A04),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'เทียบเสียงไทย: ${vowel.thai}',
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
              vowel.description,
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
// STROKE ORDER BOTTOM SHEET FOR LANNAVOWEL
// ============================================================================
class VowelStrokeOrderBottomSheet extends StatefulWidget {
  final LannaVowel vowel;
  const VowelStrokeOrderBottomSheet({super.key, required this.vowel});

  @override
  State<VowelStrokeOrderBottomSheet> createState() => _VowelStrokeOrderBottomSheetState();
}

class _VowelStrokeOrderBottomSheetState extends State<VowelStrokeOrderBottomSheet>
    with SingleTickerProviderStateMixin {
  late List<List<Offset>> _strokes;
  int _currentStrokeIndex = 0;
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _strokes = getStrokePaths(widget.vowel.char);
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
                'วิธีเขียน ตั๋ว ${widget.vowel.reading}',
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
            widget.vowel.char,
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
              painter: VowelStrokePainter(
                strokes: _strokes,
                currentIndex: _currentStrokeIndex,
                progress: _animation.value,
                char: widget.vowel.char,
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
              widget.vowel.description,
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

class VowelStrokePainter extends CustomPainter {
  final List<List<Offset>> strokes;
  final int currentIndex;
  final double progress;
  final String char;

  VowelStrokePainter({
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
  bool shouldRepaint(covariant VowelStrokePainter oldDelegate) => true;
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

import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:lanna/models/category_model.dart';
import 'package:lanna/models/lanna_char_model.dart';
import 'package:lanna/services/lanna_char_service.dart';
import '../learning_navigation.dart';
import 'lanna_glyph_card.dart';
import 'char_detail_page.dart';
import '../train/writing_data.dart';

class GenericLessonPage extends StatefulWidget {
  final CategoryModel category;
  const GenericLessonPage({super.key, required this.category});

  @override
  State<GenericLessonPage> createState() => _GenericLessonPageState();
}

class _GenericLessonPageState extends State<GenericLessonPage> with TickerProviderStateMixin {
  final LannaCharService _charService = LannaCharService();
  late final FlutterTts _tts;
  TabController? _tabController;

  bool _isLoading = true;
  String? _errorMsg;
  List<CategoryCharModel> _subCategories = [];
  final Map<String, List<LannaCharModel>> _charactersMap = {};

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
    _tabController?.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _errorMsg = null;
    });
    try {
      // 1. Fetch sub-categories filtered by this category code (e.g. LC006)
      var subCats = await _charService.getCategoriesByLearningCode(widget.category.categoryCode);
      
      // If no subcategory matches learningCategoryCode, check if any category matches by name/id
      if (subCats.isEmpty) {
        final allCats = await _charService.getAllCategories();
        subCats = allCats.where((c) => 
          (c.learningCategoryCode != null && c.learningCategoryCode!.trim().toUpperCase() == widget.category.categoryCode.trim().toUpperCase()) ||
          c.name.trim().toLowerCase() == widget.category.title.trim().toLowerCase() ||
          c.categoryCharId.trim().toLowerCase() == widget.category.categoryCode.trim().toLowerCase()
        ).toList();
      }

      // If still empty, check if characters exist directly under categoryCode
      if (subCats.isEmpty) {
        final directChars = await _charService.getAllCharacters(categoryCharId: widget.category.categoryCode);
        if (directChars.isNotEmpty) {
          subCats = [CategoryCharModel(categoryCharId: widget.category.categoryCode, name: widget.category.title)];
        }
      }

      // 2. Fetch characters for each subcategory
      final Map<String, List<LannaCharModel>> tempMap = {};
      for (var sub in subCats) {
        final chars = await _charService.getAllCharacters(categoryCharId: sub.categoryCharId);
        tempMap[sub.categoryCharId] = chars;
      }

      setState(() {
        _subCategories = subCats;
        _charactersMap.clear();
        _charactersMap.addAll(tempMap);
        _isLoading = false;
        
        // Re-initialize TabController if we have multiple tabs
        if (_subCategories.length > 1) {
          _tabController?.dispose();
          _tabController = TabController(length: _subCategories.length, vsync: this);
        } else {
          _tabController?.dispose();
          _tabController = null;
        }
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
    final bool showTabs = _subCategories.length > 1;

    return Scaffold(
      backgroundColor: const Color(0xFFFFFBF7),
      appBar: AppBar(
        backgroundColor: const Color(0xFFFFFBF7),
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFFE16905)),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          widget.category.title,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.bold,
            color: Color(0xFF2D1A00),
          ),
        ),
        bottom: (!showTabs || _isLoading)
            ? PreferredSize(
                preferredSize: const Size.fromHeight(1.5),
                child: Container(color: const Color(0xFFEADBC8), height: 1.5),
              )
            : TabBar(
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
                tabs: _subCategories.map((sub) => Tab(text: sub.name)).toList(),
              ),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFFD2691E)),
            )
          : _errorMsg != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.error_outline, size: 60, color: Colors.redAccent),
                        const SizedBox(height: 16),
                        Text(
                          'เกิดข้อผิดพลาดในการโหลดข้อมูล\n$_errorMsg',
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontSize: 10),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: _loadData,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFFFFBF7),
                            foregroundColor: Colors.white,
                          ),
                          child: const Text('ลองใหม่'),
                        ),
                      ],
                    ),
                  ),
                )
              : _subCategories.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.cloud_off,
                            size: 80,
                            color: Colors.grey.shade400,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'ไม่มีข้อมูล',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade600,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    )
                  : _subCategories.length == 1
                      ? _buildCategoryGrid(_subCategories.first)
                      : TabBarView(
                          controller: _tabController,
                          children: _subCategories.map((sub) => _buildCategoryGrid(sub)).toList(),
                        ),
    );
  }

  Widget _buildCategoryGrid(CategoryCharModel sub) {
    final chars = _charactersMap[sub.categoryCharId] ?? [];
    if (chars.isEmpty) {
      return Center(
        child: Text(
          'ไม่มีข้อมูลในกลุ่มนี้',
          style: TextStyle(fontSize: 10, color: Colors.grey.shade600),
        ),
      );
    }
    return PaginatedLannaGrid<LannaCharModel>(
      items: chars,
      pageSize: 16,
      itemBuilder: (context, charModel, globalIndex) {
        final initialIndex = chars.indexWhere((c) => c.lannaChar == charModel.lannaChar);
        String parsedReading = charModel.thaiEquivalent;
        if (parsedReading.contains('(') && parsedReading.contains(')')) {
          parsedReading = parsedReading.substring(
            parsedReading.indexOf('(') + 1,
            parsedReading.indexOf(')'),
          );
        }
        return GestureDetector(
          onTap: () => pushLearningPage(
            context,
            MaterialPageRoute(
              builder: (_) => CharDetailPage(
                char: charModel.lannaChar,
                reading: parsedReading,
                thai: charModel.thaiEquivalent,
                description: '${widget.category.title}ตัว ${charModel.thaiEquivalent}',
                isGuest: false,
                writingType: WritingType.consonant,
                allChars: chars
                    .map((c) => {'char': c.lannaChar, 'label': c.thaiEquivalent})
                    .toList(),
                initialWritingIndex: initialIndex >= 0 ? initialIndex : 0,
                categoryName: sub.name,
              ),
            ),
          ),
          child: LannaGlyphCard(
            glyph: charModel.lannaChar,
            thaiEquivalent: charModel.thaiEquivalent,
          ),
        );
      },
    );
  }
}

class _GenericCharCard extends StatelessWidget {
  final LannaCharModel charModel;
  final VoidCallback onPlaySound;

  const _GenericCharCard({
    required this.charModel,
    required this.onPlaySound,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shadowColor: Colors.black.withAlpha((0.05 * 255).toInt()),
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: const BorderSide(color: Color(0xFFF0E5D8), width: 1.5),
      ),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
        ),
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            // Big Lanna Character with Rounded Circle background
            Container(
              width: 64,
              height: 64,
              alignment: Alignment.center,
              decoration: const BoxDecoration(
                color: Color(0xFFFFF3E0),
                shape: BoxShape.circle,
              ),
              child: Text(
                charModel.lannaChar,
                style: const TextStyle(
                  fontSize: 28,
                  fontFamily: 'LNTilok',
                  color: Color(0xFFD2691E),
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
                    'อักษรเทียบเคียง: ${charModel.thaiEquivalent}',
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF2D1A00),
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'หมวดหมู่บทเรียนร่วมสมัย',
                    style: TextStyle(
                      fontSize: 8,
                      color: Color(0xFF7A5C3A),
                    ),
                  ),
                ],
              ),
            ),
            
            // Pronunciation Button
            Material(
              color: const Color(0xFFFFF3E0),
              shape: const CircleBorder(),
              clipBehavior: Clip.antiAlias,
              child: InkWell(
                onTap: onPlaySound,
                child: const Padding(
                  padding: EdgeInsets.all(10),
                  child: Icon(
                    Icons.volume_up_rounded,
                    color: Color(0xFFD2691E),
                    size: 22,
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

import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:lanna/services/lanna_char_service.dart';
import 'package:lanna/services/article_service.dart';
import 'package:lanna/models/article_model.dart';
import '../train/writing_mode.dart';
import '../train/writing_data.dart';
import '../train/stroke_data.dart' as sd;

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
  final Map<String, List<LannaConsonant>> _consonantsMap = {};
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

      // ข้อมูลจำลองและคำอธิบายลำดับเส้นเดิมที่มีความถูกต้องสูง
      final List<LannaConsonant> fallbackConsonants = [
        LannaConsonant(char: 'ᨠ', reading: 'ก๋ะ', thai: 'ก', description: 'เริ่มม้วนหัวกลมจากขวาล่าง ลากขึ้นขยักด้านบนแล้วลากลงคล้าย ก.ไก่'),
        LannaConsonant(char: 'ᨡ', reading: 'ข๋ะ', thai: 'ข', description: 'ม้วนหัวหยักจากบนซ้าย ลากมนโค้งทางขวา แล้วหยักลงล่างสุด'),
        LannaConsonant(char: 'ᨢ', reading: 'ขะหางยาว/ฃ๋ะ', thai: 'ฃ', description: 'ลักษณะเขียนคล้าย ตั๋ว ข๋ะ แต่ลากส่วนท้ายยาวตวัดขึ้นสูงขวา'),
        LannaConsonant(char: 'ᨣ', reading: 'ก๊ะ/คะ', thai: 'ค', description: 'ม้วนหัวกลมบน ลากลงขวาแล้วโค้งขยักขึ้นด้านขวาคล้าย ค.ควาย'),
        LannaConsonant(char: 'ᨤ', reading: 'คะหางยาว/ฅ๊ะ', thai: 'ฅ', description: 'เขียนคล้าย ตั๋ว ก๊ะ แต่ลากปลายตวัดหางขึ้นขมวดด้านขวาบน'),
        LannaConsonant(char: 'ᨥ', reading: 'ฆะ/ข๊ะ', thai: 'ฆ', description: 'ม้วนหัวกลมบน หยักโค้งด้านซ้าย แล้วตวัดโค้งมนขึ้นขวา'),
        LannaConsonant(char: 'ᨦ', reading: 'งะ', thai: 'ง', description: 'ม้วนหัวกลมบน ลากลาดลงล่างแล้วตวัดหางเฉียงขึ้นซ้าย'),
        LannaConsonant(char: 'ᨧ', reading: 'จ๋ะ', thai: 'จ', description: 'ม้วนหัวกลมบน ลากโค้งมนลงด้านล่าง ตวัดโค้งขมวดขวาขึ้นบน'),
        LannaConsonant(char: 'ᨨ', reading: 'ฉ๋ะ', thai: 'ฉ', description: 'เริ่มหัวม้วนบน โค้งหยักลอนซ้ายขวาคล้ายคลื่นน้ำ'),
        LannaConsonant(char: 'ᨩ', reading: 'จ๊ะ/ชะ', thai: 'ช', description: 'ม้วนหัวกลมซ้าย โค้งมนขยักขึ้นคล้าย ช.ช้าง แบบตั๋วเมือง'),
        LannaConsonant(char: 'ᨪ', reading: 'ซะ/ชะหางยาว', thai: 'ซ', description: 'เขียนเหมือน ตั๋ว ชะ แต่ลากส่วนหางพริ้วยาวเฉียงขึ้นขวา'),
        LannaConsonant(char: 'ᨫ', reading: 'ฌะ/ช๊ะ', thai: 'ฌ', description: 'ม้วนหัวกลมล่างซ้าย ลากหยักสูงโค้งมนขวาเฉียงลง'),
        LannaConsonant(char: 'ᨬ', reading: 'ญะ/ญ๋ะ', thai: 'ญ', description: 'ม้วนหัวกลมบน ลากลงล่างและมีหยักหางใต้ตัวอักษร'),
        LannaConsonant(char: 'ᨭ', reading: 'ระต๊ะ', thai: 'ฏ', description: 'ม้วนหัวกลมล่างซ้าย ลากโค้งมนบนแล้วขยักหางม้วนซ่อนใต้ฐาน'),
        LannaConsonant(char: 'ᨮ', reading: 'ระถะ', thai: 'ฐ', description: 'เริ่มลากเส้นหยักจากล่าง โค้งขึ้นวนขวาเป็นฐานหยักลอน'),
        LannaConsonant(char: 'ᨯ', reading: 'ด๋ะ/ด๊ะ', thai: 'ด/ฑ', description: 'ม้วนหัวบน ลากหยักลง แล้วลากมนโค้งขวาขึ้นบนคล้าย ด.เด็ก'),
        LannaConsonant(char: 'ᨰ', reading: 'ระทะ', thai: 'ฒ', description: 'ม้วนหัวซ้ายขยักสองลอน ลากลงขวาตวัดโค้งมนขึ้นบน'),
        LannaConsonant(char: 'ᨱ', reading: 'ระนะ', thai: 'ณ', description: 'ม้วนหัวหยักบน ลากฐานคู่หยักตวัดขมวดซ้ายขึ้นบน'),
        LannaConsonant(char: 'ᨲ', reading: 'ต๋ะ', thai: 'ต', description: 'ม้วนหัวกลมบน ลากลงขยักสองจังหวะคล้าย ต.เต่า ลอยตัว'),
        LannaConsonant(char: 'ᨳ', reading: 'ถ๋ะ', thai: 'ถ', description: 'ม้วนหัวล่างซ้าย โค้งมนตวัดก้นหยักขยักขวาคล้าย ถ.ถุง'),
        LannaConsonant(char: 'ᨴ', reading: 'ต๊ะ/ทะ', thai: 'ท', description: 'ม้วนหัวบน ลากฐานขยักลงแล้วเฉียงมนขวาขึ้นคล้าย ท.ทหาร'),
        LannaConsonant(char: 'ᨵ', reading: 'ท๊ะ/ธะ', thai: 'ธ', description: 'ม้วนหัวบนซ้าย ลากโค้งฐานขวากว้างม้วนโค้งขึ้นสอดไส้'),
        LannaConsonant(char: 'ᨶ', reading: 'นะ', thai: 'น', description: 'ม้วนหัวบน ลากเฉียงลงล่าง ม้วนฐานขมวดมนซ้ายแล้วเฉียงขวา'),
        LannaConsonant(char: 'ᨷ', reading: 'บะ/ป๋ะ', thai: 'บ/ป', description: 'ม้วนหัวกลมขวา ลากฐานโค้งกว้างลอนคู่ใต้เส้นคล้าย บ.ใบไม้'),
        LannaConsonant(char: 'ᨸ', reading: 'ป๋ะหางยาว/ผะ', thai: 'ป', description: 'คล้าย ตั๋ว ป๋ะ แต่ลากเส้นตั้งตรงด้านขวาชี้เฉียงสูงขึ้น'),
        LannaConsonant(char: 'ᨹ', reading: 'ผ๋ะ', thai: 'ผ', description: 'ม้วนหัวด้านในขวา หยักลอนล่างขึ้นบนลอยเฉียงซ้ายคล้าย ผ.ผึ้ง'),
        LannaConsonant(char: 'ᨺ', reading: 'ฝะ/ผ๋ะหางยาว', thai: 'ฝ', description: 'คล้าย ตั๋ว ผ๋ะ แต่ตวัดปลายเส้นตรงขวาสูงพ้นแนวบรรทัด'),
        LannaConsonant(char: 'ᨻ', reading: 'ป๊ะ/พะ', thai: 'พ', description: 'ม้วนหัวนอกขวา ลากหยักสูงโค้งมนขวาเฉียงขึ้นคล้าย พ.พาน'),
        LannaConsonant(char: 'ᨼ', reading: 'ฟะ/พ๊ะหางยาว', thai: 'ฟ', description: 'คล้าย ตั๋ว พะ แต่ลากหางตรงชวาขยับสูงขึ้นขวาพริ้วไหว'),
        LannaConsonant(char: 'ᨽ', reading: 'พ๊ะ/ภะ', thai: 'ภ', description: 'ม้วนหัวกลมล่างซ้าย ลากหัวขึ้นหยักโค้งกว้างขวาคล้าย ภ.สำเภา'),
        LannaConsonant(char: 'ᨾ', reading: 'มะ', thai: 'ม', description: 'ม้วนหัวหยักบน ลากฐานตรงลงล่างตวัดเฉียงขมวดขึ้นขวา'),
        LannaConsonant(char: 'ᨿ', reading: 'ย๊ะ/ยะ', thai: 'ย', description: 'ม้วนหัวหยักบน ลากหยักลอนกลางตัวแล้วม้วนฐานขวาขึ้น'),
        LannaConsonant(char: 'ᩀ', reading: 'ย๋ะ/ยะกลาง/ย่า', thai: 'ย', description: 'เริ่มหัวกลมกลาง ลากลงมาโค้งลอนใหญ่สองจังหวะโค้งมนขวา'),
        LannaConsonant(char: 'ᩁ', reading: 'ระ/ละ', thai: 'ร', description: 'เริ่มลากจากล่างโค้งขึ้น ลากหยักโค้งหงายบนคล้าย ร.เรือ ตั๋วเมือง'),
        LannaConsonant(char: 'ᩃ', reading: 'ล๊ะ/ละ', thai: 'ล', description: 'ม้วนหัวซ้ายล่าง โค้งขยักสองส่วนม้วนลงขวาคล้าย ล.ลิง'),
        LannaConsonant(char: 'ᩅ', reading: 'ว๊ะ/วะ', thai: 'ว', description: 'ม้วนหัวซ้ายล่าง ลากเฉียงขวาแล้วปัดโค้งปิดบนคล้าย ว.แหวน'),
        LannaConsonant(char: 'ᩈ', reading: 'สะ/ส๋ะ', thai: 'ส', description: 'ม้วนหัวซ้าย โค้งฐานล่างกว้างแล้วลากเฉียงหางขึ้นบนขวา'),
        LannaConsonant(char: 'ᩉ', reading: 'ห๋ะ/หะ', thai: 'ห', description: 'ม้วนหัวบน ลากเส้นตรงลงล่าง ตวัดม้วนฐานไขว้ขึ้นขวาเฉียง'),
        LannaConsonant(char: 'ᩋ', reading: 'อ๋ะ/อะ', thai: 'อ', description: 'ม้วนหัวซ้าย ลากโค้งอ่างก้นกว้าง ขยับปากเฉียงโค้งขึ้นบนขวา'),
        LannaConsonant(char: 'ᩌ', reading: 'ฮ๊ะ/ฮอ', thai: 'ฮ', description: 'เขียนคล้าย ตั๋ว อ๋ะ แต่ตวัดขมวดโค้งเฉียงขึ้นด้านบนขวาพริ้ว'),
        LannaConsonant(char: 'ᩊ', reading: 'ล๊ะ/ละ (ฬ)', thai: 'ฬ', description: 'เริ่มเขียนเหมือน ตั๋ว ล๊ะ แต่มีฐานขยักโค้งหย่อนใต้แนวเส้นบรรทัด'),
      ];

      final Set<String> groupKaChars = {'ᨠ', 'ᨡ', 'ᨢ', 'ᨣ', 'ᨤ', 'ᨥ', 'ᨦ'};
      final Set<String> groupCaChars = {'ᨧ', 'ᨨ', 'ᨩ', 'ᨪ', 'ᨫ', 'ᨬ'};
      final Set<String> groupRataChars = {'ᨭ', 'ᨮ', 'ᨯ', 'ᨰ', 'ᨱ'};
      final Set<String> groupTaChars = {'ᨲ', 'ᨳ', 'ᨴ', 'ᨵ', 'ᨶ'};
      final Set<String> groupPaChars = {'ᨷ', 'ᨸ', 'ᨹ', 'ᨺ', 'ᨻ', 'ᨼ', 'ᨽ', 'ᨾ'};

      final List<LannaConsonant> listKa = [];
      final List<LannaConsonant> listCa = [];
      final List<LannaConsonant> listRata = [];
      final List<LannaConsonant> listTa = [];
      final List<LannaConsonant> listPa = [];
      final List<LannaConsonant> listOut = [];
      final List<LannaConsonant> listAdd = [];

      for (var c in apiConsonants) {
        final String rawThai = c.thaiEquivalent;
        String parsedReading = rawThai;
        if (rawThai.contains('(') && rawThai.contains(')')) {
          parsedReading = rawThai.substring(rawThai.indexOf('(') + 1, rawThai.indexOf(')'));
        }
        
        final fallback = fallbackConsonants.firstWhere(
          (f) => f.char == c.lannaChar,
          orElse: () => LannaConsonant(
            char: c.lannaChar,
            reading: parsedReading,
            thai: rawThai.split(' ').first,
            description: 'พยัญชนะล้านนาตัว ${c.thaiEquivalent}',
          ),
        );
        
        final consonant = LannaConsonant(
          char: c.lannaChar,
          reading: fallback.reading,
          thai: rawThai,
          description: fallback.description,
        );

        if (c.categoryCharId == 'CL0001') {
          if (groupKaChars.contains(c.lannaChar)) {
            listKa.add(consonant);
          } else if (groupCaChars.contains(c.lannaChar)) {
            listCa.add(consonant);
          } else if (groupRataChars.contains(c.lannaChar)) {
            listRata.add(consonant);
          } else if (groupTaChars.contains(c.lannaChar)) {
            listTa.add(consonant);
          } else if (groupPaChars.contains(c.lannaChar)) {
            listPa.add(consonant);
          } else {
            listOut.add(consonant);
          }
        } else if (c.categoryCharId == 'CL0002') {
          listOut.add(consonant);
        } else if (c.categoryCharId == 'CL0003') {
          listAdd.add(consonant);
        }
      }

      _consonantsMap['KA'] = listKa;
      _consonantsMap['CA'] = listCa;
      _consonantsMap['RATA'] = listRata;
      _consonantsMap['TA'] = listTa;
      _consonantsMap['PA'] = listPa;
      _consonantsMap['CL0002'] = listOut;
      _consonantsMap['CL0003'] = listAdd;

      setState(() {
        _groups = [
          ConsonantGroup(name: 'วรรค กะ', categoryCharId: 'CL0001', consonants: listKa),
          ConsonantGroup(name: 'วรรค จะ', categoryCharId: 'CL0001', consonants: listCa),
          ConsonantGroup(name: 'วรรค ฏะ', categoryCharId: 'CL0001', consonants: listRata),
          ConsonantGroup(name: 'วรรค ตะ', categoryCharId: 'CL0001', consonants: listTa),
          ConsonantGroup(name: 'วรรค ปะ', categoryCharId: 'CL0001', consonants: listPa),
          ConsonantGroup(name: 'พยัญชนะนอกวรรค', categoryCharId: 'CL0002', consonants: listOut),
          ConsonantGroup(name: 'พยัญชนะเพิ่มเติม', categoryCharId: 'CL0003', consonants: listAdd),
        ].where((g) => g.consonants.isNotEmpty).toList();

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
                child: _IntroCard(article: _articlesMap[_currentCategoryId]),
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
            return ListView.builder(
              padding: const EdgeInsets.fromLTRB(0, 8, 0, 80),
              itemCount: group.consonants.length,
              itemBuilder: (context, index) {
                final consonant = group.consonants[index];
                    return _ConsonantCard(
                      consonant: consonant,
                      onPlaySound: () => _speak(consonant.reading),
                      onTapStrokeOrder: () {
                        showModalBottomSheet(
                          context: context,
                          isScrollControlled: true,
                          backgroundColor: Colors.transparent,
                          barrierColor: Colors.black.withValues(alpha: 0.5),
                          builder: (_) => StrokeOrderBottomSheet(consonant: consonant),
                        );
                      },
                      onTapPractice: () {
                        if (widget.isGuest) {
                          _showLoginRequiredAlert(context);
                          return;
                        }
                        final allWritingItems = allConsonantsForTrain.map((c) => WritingItem(
                          char: c.char,
                          label: c.reading,
                          type: WritingType.consonant,
                        )).toList();

                        final initialIndex = allConsonantsForTrain.indexWhere((c) => c.char == consonant.char);

                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => WritingModePage(
                              items: allWritingItems,
                              title: 'ฝึกเขียนพยัญชนะ',
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
/// COMPONENT : CONSONANT GRID CARD
/// ============================================================================
class _ConsonantCard extends StatelessWidget {
  final LannaConsonant consonant;
  final VoidCallback onPlaySound;
  final VoidCallback onTapStrokeOrder;
  final VoidCallback onTapPractice;

  const _ConsonantCard({
    required this.consonant,
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
                    consonant.char,
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
                        'เสียงอ่าน: ${consonant.reading}',
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF2C1A04),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'เทียบเสียงไทย: ${consonant.thai}',
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
              consonant.description,
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
// STROKE ORDER BOTTOM SHEET FOR LANNACONSONANT
// ============================================================================
class StrokeOrderBottomSheet extends StatefulWidget {
  final LannaConsonant consonant;
  const StrokeOrderBottomSheet({super.key, required this.consonant});

  @override
  State<StrokeOrderBottomSheet> createState() => _StrokeOrderBottomSheetState();
}

class _StrokeOrderBottomSheetState extends State<StrokeOrderBottomSheet>
    with SingleTickerProviderStateMixin {
  late List<List<Offset>> _strokes;
  int _currentStrokeIndex = 0;
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _strokes = getStrokePaths(widget.consonant.char);
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
                'วิธีเขียน ตั๋ว ${widget.consonant.reading}',
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
            widget.consonant.char,
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
              painter: StrokePainter(
                strokes: _strokes,
                currentIndex: _currentStrokeIndex,
                progress: _animation.value,
                char: widget.consonant.char,
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
              widget.consonant.description,
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

    // วาดเส้นก่อนหน้าที่เสร็จไปแล้ว
    for (int i = 0; i < currentIndex; i++) {
      final points = strokes[i];
      if (points.isEmpty) continue;
      final path = Path();
      path.moveTo(scale(points[0]).dx, scale(points[0]).dy);
      for (int j = 1; j < points.length; j++) {
        path.lineTo(scale(points[j]).dx, scale(points[j]).dy);
      }
      canvas.drawPath(path, paintCompleted);
    }

    // วาดอนิเมชันเส้นปัจจุบัน
    if (currentIndex < strokes.length) {
      final currentPoints = strokes[currentIndex];
      if (currentPoints.isNotEmpty) {
        final path = Path();
        final start = scale(currentPoints[0]);
        path.moveTo(start.dx, start.dy);

        final totalSegments = currentPoints.length - 1;
        final currentProgressSegment = progress * totalSegments;
        final fullSegments = currentProgressSegment.floor();
        final partialSegmentProgress = currentProgressSegment - fullSegments;

        for (int j = 1; j <= fullSegments; j++) {
          final pt = scale(currentPoints[j]);
          path.lineTo(pt.dx, pt.dy);
        }

        if (fullSegments < totalSegments) {
          final p1 = scale(currentPoints[fullSegments]);
          final p2 = scale(currentPoints[fullSegments + 1]);
          final partialPt = Offset(
            p1.dx + (p2.dx - p1.dx) * partialSegmentProgress,
            p1.dy + (p2.dy - p1.dy) * partialSegmentProgress,
          );
          path.lineTo(partialPt.dx, partialPt.dy);
        }
        canvas.drawPath(path, paintCurrent);
      }
    }
  }

  @override
  bool shouldRepaint(covariant StrokePainter oldDelegate) => true;
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

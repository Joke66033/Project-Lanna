import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import '../train/writing_mode.dart';
import '../train/writing_data.dart';
import '../train/stroke_data.dart' as sd;

/// ============================================================================
/// MODEL : LANNA CONSONANT
/// ============================================================================
class LannaConsonant {
  final String char; // อักษรล้านนา Unicode
  final String reading; // คำอ่านภาษาไทย เช่น "ก๋ะ"
  final String thai; // อักษรไทยเทียบเคียง เช่น "ก"
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
  final List<LannaConsonant> consonants;

  const ConsonantGroup({required this.name, required this.consonants});
}

/// ============================================================================
/// SCREEN : LANNA CONSONANTS LEARNING PAGE
/// ============================================================================
class LannaConsonantPage extends StatefulWidget {
  final bool isGuest;
  final VoidCallback? onBack;
  const LannaConsonantPage({super.key, this.isGuest = false, this.onBack});

  @override
  State<LannaConsonantPage> createState() => _LannaConsonantPageState();
}

class _LannaConsonantPageState extends State<LannaConsonantPage> {
  late final FlutterTts _tts;

  @override
  void initState() {
    super.initState();
    _tts = FlutterTts();
    _initTts();
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
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // 1. วรรค กะ (วรรคก๋ะ)
    const groupKa = ConsonantGroup(
      name: 'วรรค กะ',
      consonants: [
        LannaConsonant(
          char: 'ᨠ',
          reading: 'ก๋ะ',
          thai: 'ก',
          description:
              'เริ่มม้วนหัวกลมจากขวาล่าง ลากขึ้นขยักด้านบนแล้วลากลงคล้าย ก.ไก่',
        ),
        LannaConsonant(
          char: 'ᨡ',
          reading: 'ข๋ะ',
          thai: 'ข',
          description: 'ม้วนหัวหยักจากบนซ้าย ลากมนโค้งทางขวา แล้วหยักลงล่างสุด',
        ),
        LannaConsonant(
          char: 'ᨢ',
          reading: 'ขะหางยาว/ฃ๋ะ',
          thai: 'ฃ',
          description:
              'ลักษณะเขียนคล้าย ตั๋ว ข๋ะ แต่ลากส่วนท้ายยาวตวัดขึ้นสูงขวา',
        ),
        LannaConsonant(
          char: 'ᨣ',
          reading: 'ก๊ะ/คะ',
          thai: 'ค',
          description:
              'ม้วนหัวกลมบน ลากลงขวาแล้วโค้งขยักขึ้นด้านขวาคล้าย ค.ควาย',
        ),
        LannaConsonant(
          char: 'ᨤ',
          reading: 'คะหางยาว/ฅ๊ะ',
          thai: 'ฅ',
          description: 'เขียนคล้าย ตั๋ว ก๊ะ แต่ลากปลายตวัดหางขึ้นขมวดด้านขวาบน',
        ),
        LannaConsonant(
          char: 'ᨥ',
          reading: 'ฆะ/ข๊ะ',
          thai: 'ฆ',
          description: 'ม้วนหัวกลมบน หยักโค้งด้านซ้าย แล้วตวัดโค้งมนขึ้นขวา',
        ),
        LannaConsonant(
          char: 'ᨦ',
          reading: 'งะ',
          thai: 'ง',
          description: 'ม้วนหัวกลมบน ลากลาดลงล่างแล้วตวัดหางเฉียงขึ้นซ้าย',
        ),
      ],
    );

    // 2. วรรค จะ (วรรคจ๋ะ)
    const groupCa = ConsonantGroup(
      name: 'วรรค จะ',
      consonants: [
        LannaConsonant(
          char: 'ᨧ',
          reading: 'จ๋ะ',
          thai: 'จ',
          description: 'ม้วนหัวกลมบน ลากโค้งมนลงด้านล่าง ตวัดโค้งขมวดขวาขึ้นบน',
        ),
        LannaConsonant(
          char: 'ᨨ',
          reading: 'ฉ๋ะ',
          thai: 'ฉ',
          description: 'เริ่มหัวม้วนบน โค้งหยักลอนซ้ายขวาคล้ายคลื่นน้ำ',
        ),
        LannaConsonant(
          char: 'ᨩ',
          reading: 'จ๊ะ/ชะ',
          thai: 'ช',
          description: 'ม้วนหัวกลมซ้าย โค้งมนขยักขึ้นคล้าย ช.ช้าง แบบตั๋วเมือง',
        ),
        LannaConsonant(
          char: 'ᨪ',
          reading: 'ซะ/ชะหางยาว',
          thai: 'ซ',
          description: 'เขียนเหมือน ตั๋ว ชะ แต่ลากส่วนหางพริ้วยาวเฉียงขึ้นขวา',
        ),
        LannaConsonant(
          char: 'ᨫ',
          reading: 'ฌะ/ช๊ะ',
          thai: 'ฌ',
          description: 'ม้วนหัวกลมล่างซ้าย ลากหยักสูงโค้งมนขวาเฉียงลง',
        ),
        LannaConsonant(
          char: 'ᨬ',
          reading: 'ญะ/ญ๋ะ',
          thai: 'ญ',
          description: 'ม้วนหัวกลมบน ลากลงล่างและมีหยักหางใต้ตัวอักษร',
        ),
      ],
    );

    // 3. วรรค ฏะ (วรรคระต๊ะ / ตะเล็ก)
    const groupRata = ConsonantGroup(
      name: 'วรรค ฏะ',
      consonants: [
        LannaConsonant(
          char: 'ᨭ',
          reading: 'ระต๊ะ',
          thai: 'ฏ',
          description:
              'ม้วนหัวกลมล่างซ้าย ลากโค้งมนบนแล้วขยักหางม้วนซ่อนใต้ฐาน',
        ),
        LannaConsonant(
          char: 'ᨮ',
          reading: 'ระถะ',
          thai: 'ฐ',
          description: 'เริ่มลากเส้นหยักจากล่าง โค้งขึ้นวนขวาเป็นฐานหยักลอน',
        ),
        LannaConsonant(
          char: 'ᨯ',
          reading: 'ด๋ะ/ด๊ะ',
          thai: 'ด/ฑ',
          description: 'ม้วนหัวบน ลากหยักลง แล้วลากมนโค้งขวาขึ้นบนคล้าย ด.เด็ก',
        ),
        LannaConsonant(
          char: 'ᨰ',
          reading: 'ระทะ',
          thai: 'ฒ',
          description: 'ม้วนหัวซ้ายขยักสองลอน ลากลงขวาตวัดโค้งมนขึ้นบน',
        ),
        LannaConsonant(
          char: 'ᨱ',
          reading: 'ระนะ',
          thai: 'ณ',
          description: 'ม้วนหัวหยักบน ลากฐานคู่หยักตวัดขมวดซ้ายขึ้นบน',
        ),
      ],
    );

    // 4. วรรค ตะ (วรรคต๋ะ)
    const groupTa = ConsonantGroup(
      name: 'วรรค ตะ',
      consonants: [
        LannaConsonant(
          char: 'ᨲ',
          reading: 'ต๋ะ',
          thai: 'ต',
          description: 'ม้วนหัวกลมบน ลากลงขยักสองจังหวะคล้าย ต.เต่า ลอยตัว',
        ),
        LannaConsonant(
          char: 'ᨳ',
          reading: 'ถ๋ะ',
          thai: 'ถ',
          description: 'ม้วนหัวล่างซ้าย โค้งมนตวัดก้นหยักขยักขวาคล้าย ถ.ถุง',
        ),
        LannaConsonant(
          char: 'ᨴ',
          reading: 'ต๊ะ/ทะ',
          thai: 'ท',
          description: 'ม้วนหัวบน ลากฐานขยักลงแล้วเฉียงมนขวาขึ้นคล้าย ท.ทหาร',
        ),
        LannaConsonant(
          char: 'ᨵ',
          reading: 'ท๊ะ/ธะ',
          thai: 'ธ',
          description: 'ม้วนหัวบนซ้าย ลากโค้งฐานขวากว้างม้วนโค้งขึ้นสอดไส้',
        ),
        LannaConsonant(
          char: 'ᨶ',
          reading: 'นะ',
          thai: 'น',
          description: 'ม้วนหัวบน ลากเฉียงลงล่าง ม้วนฐานขมวดมนซ้ายแล้วเฉียงขวา',
        ),
      ],
    );

    // 5. วรรค ปะ (วรรคป๋ะ)
    const groupPa = ConsonantGroup(
      name: 'วรรค ปะ',
      consonants: [
        LannaConsonant(
          char: 'ᨷ',
          reading: 'บะ/ป๋ะ',
          thai: 'บ/ป',
          description:
              'ม้วนหัวกลมขวา ลากฐานโค้งกว้างลอนคู่ใต้เส้นคล้าย บ.ใบไม้',
        ),
        LannaConsonant(
          char: 'ᨸ',
          reading: 'ป๋ะหางยาว/ผะ',
          thai: 'ป',
          description: 'คล้าย ตั๋ว ป๋ะ แต่ลากเส้นตั้งตรงด้านขวาชี้เฉียงสูงขึ้น',
        ),
        LannaConsonant(
          char: 'ᨹ',
          reading: 'ผ๋ะ',
          thai: 'ผ',
          description:
              'ม้วนหัวด้านในขวา หยักลอนล่างขึ้นบนลอยเฉียงซ้ายคล้าย ผ.ผึ้ง',
        ),
        LannaConsonant(
          char: 'ᨺ',
          reading: 'ฝะ/ผ๋ะหางยาว',
          thai: 'ฝ',
          description: 'คล้าย ตั๋ว ผ๋ะ แต่ตวัดปลายเส้นตรงขวาสูงพ้นแนวบรรทัด',
        ),
        LannaConsonant(
          char: 'ᨻ',
          reading: 'ป๊ะ/พะ',
          thai: 'พ',
          description: 'ม้วนหัวนอกขวา ลากหยักสูงโค้งมนขวาเฉียงขึ้นคล้าย พ.พาน',
        ),
        LannaConsonant(
          char: 'ᨼ',
          reading: 'ฟะ/พ๊ะหางยาว',
          thai: 'ฟ',
          description: 'คล้าย ตั๋ว พะ แต่ลากหางตรงชวาขยับสูงขึ้นขวาพริ้วไหว',
        ),
        LannaConsonant(
          char: 'ᨽ',
          reading: 'พ๊ะ/ภะ',
          thai: 'ภ',
          description:
              'ม้วนหัวกลมล่างซ้าย ลากหัวขึ้นหยักโค้งกว้างขวาคล้าย ภ.สำเภา',
        ),
        LannaConsonant(
          char: 'ᨾ',
          reading: 'มะ',
          thai: 'ม',
          description: 'ม้วนหัวหยักบน ลากฐานตรงลงล่างตวัดเฉียงขมวดขึ้นขวา',
        ),
      ],
    );

    // 6. อักษรนอกวรรค (เศษวรรค / อวรรค)
    const groupOov = ConsonantGroup(
      name: 'นอกวรรค',
      consonants: [
        LannaConsonant(
          char: 'ᨿ',
          reading: 'ย๊ะ/ยะ',
          thai: 'ย',
          description: 'ม้วนหัวหยักบน ลากหยักลอนกลางตัวแล้วม้วนฐานขวาขึ้น',
        ),
        LannaConsonant(
          char: 'ᩀ',
          reading: 'ย๋ะ/ยะกลาง/ย่า',
          thai: 'ย',
          description: 'เริ่มหัวกลมกลาง ลากลงมาโค้งลอนใหญ่สองจังหวะโค้งมนขวา',
        ),
        LannaConsonant(
          char: 'ᩁ',
          reading: 'ระ/ละ',
          thai: 'ร',
          description:
              'เริ่มลากจากล่างโค้งขึ้น ลากหยักโค้งหงายบนคล้าย ร.เรือ ตั๋วเมือง',
        ),
        LannaConsonant(
          char: 'ᩃ',
          reading: 'ล๊ะ/ละ',
          thai: 'ล',
          description: 'ม้วนหัวซ้ายล่าง โค้งขยักสองส่วนม้วนลงขวาคล้าย ล.ลิง',
        ),
        LannaConsonant(
          char: 'ᩅ',
          reading: 'ว๊ะ/วะ',
          thai: 'ว',
          description:
              'ม้วนหัวซ้ายล่าง ลากเฉียงขวาแล้วปัดโค้งปิดบนคล้าย ว.แหวน',
        ),
        LannaConsonant(
          char: 'ᩈ',
          reading: 'สะ/ส๋ะ',
          thai: 'ส',
          description: 'ม้วนหัวซ้าย โค้งฐานล่างกว้างแล้วลากเฉียงหางขึ้นบนขวา',
        ),
        LannaConsonant(
          char: 'ᩉ',
          reading: 'ห๋ะ/หะ',
          thai: 'ห',
          description: 'ม้วนหัวบน ลากเส้นตรงลงล่าง ตวัดม้วนฐานไขว้ขึ้นขวาเฉียง',
        ),
        LannaConsonant(
          char: 'ᩋ',
          reading: 'อ๋ะ/อะ',
          thai: 'อ',
          description:
              'ม้วนหัวซ้าย ลากโค้งอ่างก้นกว้าง ขยับปากเฉียงโค้งขึ้นบนขวา',
        ),
        LannaConsonant(
          char: 'ᩌ',
          reading: 'ฮ๊ะ/ฮอ',
          thai: 'ฮ',
          description:
              'เขียนคล้าย ตั๋ว อ๋ะ แต่ตวัดขมวดโค้งเฉียงขึ้นด้านบนขวาพริ้ว',
        ),
        LannaConsonant(
          char: 'ᩊ',
          reading: 'ล๊ะ/ละ (ฬ)',
          thai: 'ฬ',
          description:
              'เริ่มเขียนเหมือน ตั๋ว ล๊ะ แต่มีฐานขยักโค้งหย่อนใต้แนวเส้นบรรทัด',
        ),
      ],
    );

    final List<ConsonantGroup> groups = [
      groupKa,
      groupCa,
      groupRata,
      groupTa,
      groupPa,
      groupOov,
    ];

    // สร้างลิสต์ของพยัญชนะทั้งหมดเพื่อส่งไปยังหน้าฝึกเขียน
    final List<LannaConsonant> allConsonants = groups
        .expand((g) => g.consonants)
        .toList();

    return DefaultTabController(
      length: groups.length,
      child: Scaffold(
        backgroundColor: const Color(0xFFFAFAFA),
        appBar: AppBar(
          backgroundColor: const Color(0xFFA0522D),
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () {
              if (widget.onBack != null) {
                widget.onBack!();
              } else {
                Navigator.pop(context);
              }
            },
          ),
          centerTitle: true,
          title: const Text(
            'พยัญชนะล้านนา',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: Colors.white,
              letterSpacing: 0.5,
            ),
          ),
        ),
        body: Column(
          children: [
            // อธิบายสั้นๆ ด้านบน
            const Padding(
              padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: _IntroCard(),
            ),

            // แท็บกลุ่มวรรค
            Container(
              margin: const EdgeInsets.symmetric(vertical: 8),
              height: 48,
              child: TabBar(
                isScrollable: true,
                indicatorColor: const Color(0xFFD2691E),
                indicatorWeight: 3.5,
                indicatorSize: TabBarIndicatorSize.label,
                labelColor: const Color(0xFF6B3A2A),
                labelStyle: const TextStyle(
                  fontFamily: 'LMF Lukchin',
                  fontSize: 8,
                  fontWeight: FontWeight.w400,
                ),
                unselectedLabelColor: const Color(0xFFBCAAA4),
                unselectedLabelStyle: const TextStyle(
                  fontFamily: 'LMF Lukchin',
                  fontSize: 8,
                  fontWeight: FontWeight.w400,
                ),
                tabs: groups.map((g) => Tab(text: g.name)).toList(),
              ),
            ),

            // ตารางพยัญชนะตามแต่ละวรรค
            Expanded(
              child: TabBarView(
                children: groups.map((group) {
                  return GridView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 80),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          crossAxisSpacing: 14,
                          mainAxisSpacing: 14,
                          childAspectRatio: 1.15,
                        ),
                    itemCount: group.consonants.length,
                    itemBuilder: (context, index) {
                      final consonant = group.consonants[index];
                      return _ConsonantCard(
                        consonant: consonant,
                        onPlaySound: () => _speak(consonant.reading),
                        onTap: () => _showConsonantDetailsBottomSheet(
                          context,
                          consonant,
                          allConsonants,
                        ),
                      );
                    },
                  );
                }).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// ==========================================================================
  /// MODAL BOTTOM SHEET
  /// ==========================================================================
  void _showConsonantDetailsBottomSheet(
    BuildContext context,
    LannaConsonant consonant,
    List<LannaConsonant> allConsonants,
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
                // เส้นดึงเลื่อนบาร์
                Container(
                  width: 40,
                  height: 5,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                const SizedBox(height: 24),

                // อักษรล้านนาขนาดใหญ่ (100sp) พร้อมปุ่มฟังเสียงถัดกัน
                Stack(
                  alignment: Alignment.center,
                  children: [
                    Align(
                      alignment: Alignment.center,
                      child: Text(
                        consonant.char,
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
                        icon: const Icon(
                          Icons.volume_up,
                          color: Color(0xFFCD853F),
                          size: 36,
                        ),
                        onPressed: () => _speak(consonant.reading),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // รายละเอียด
                Text(
                  'เสียงอ่าน: ${consonant.reading}',
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF333333),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'เทียบอักษรไทย: ${consonant.thai}',
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF777777),
                  ),
                ),
                const SizedBox(height: 32),

                // ปุ่ม ดูวิธีเขียน และ ฝึกเขียน
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.pop(context); // ปิด BottomSheet
                          showModalBottomSheet(
                            context: context,
                            isScrollControlled: true,
                            backgroundColor: Colors.transparent,
                            barrierColor: Colors.black.withOpacity(0.5),
                            builder: (_) =>
                                StrokeOrderBottomSheet(consonant: consonant),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFA0522D),
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
                          Navigator.pop(context); // ปิด BottomSheet
                          // แปลงข้อมูลไปฝึกเขียน
                          final allWritingItems = allConsonants
                              .map(
                                (c) => WritingItem(
                                  char: c.char,
                                  label: c.reading,
                                  type: WritingType.consonant,
                                ),
                              )
                              .toList();

                          final initialIndex = allConsonants.indexWhere(
                            (c) => c.char == consonant.char,
                          );

                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => WritingModePage(
                                items: allWritingItems,
                                title: 'ฝึกเขียนพยัญชนะ',
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
        backgroundColor: const Color(0xFFFFF8F2),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          'กรุณาเข้าสู่ระบบ',
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w700,
            color: Color(0xFF2D1A00),
          ),
        ),
        content: const Text(
          'คุณต้องเข้าสู่ระบบหรือสมัครสมาชิกก่อน จึงจะสามารถใช้งานเมนูฝึกเขียนได้',
          style: TextStyle(
            fontSize: 10,
            height: 1.4,
            fontWeight: FontWeight.w500,
            color: Color(0xFF5C3D1E),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text(
              'ยกเลิก',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w500,
                color: Color(0xFF7A5C3A),
              ),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              Navigator.pushNamed(context, '/login');
            },
            child: const Text(
              'เข้าสู่ระบบ',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w500,
                color: Color.fromARGB(255, 54, 84, 255),
              ),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              Navigator.pushNamed(context, '/register');
            },
            child: const Text(
              'สมัครสมาชิก',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w500,
                color: Color.fromARGB(255, 6, 197, 41),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// ============================================================================
/// COMPONENT : INTRO DESCRIPTION CARD
/// ============================================================================
class _IntroCard extends StatelessWidget {
  const _IntroCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF3E0), // โทนส้มพาสเทลอ่อน
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFF6B3A2A).withOpacity(0.3)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF6B3A2A).withOpacity(0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              Icon(Icons.info_outline, color: Color(0xFF6B3A2A), size: 22),
              SizedBox(width: 8),
              Text(
                'พยัญชนะล้านนา คืออะไร?',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF6B3A2A),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Text(
            'พยัญชนะล้านนา (ตั๋วเมือง) นิยมเขียนตามระบบอักขรวิธีของภาษาบาลี-สันสกฤต '
            'โดยแบ่งออกเป็น "พยัญชนะในวรรค" ทั้งหมด ๒๕ ตัว (แบ่งเป็น ๕ กลุ่มหลัก) '
            'และ "พยัญชนะนอกวรรค" หรือ "เศษวรรค" อีกจำนวนหนึ่ง '
            'เพื่อใช้ผสมคำและเขียนบันทึกเรื่องราวต่างๆ ในแถบภาคเหนือ',
            style: TextStyle(
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
  final VoidCallback onTap;
  final VoidCallback onPlaySound;

  const _ConsonantCard({
    required this.consonant,
    required this.onTap,
    required this.onPlaySound,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFD2691E).withOpacity(0.18)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned.fill(
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(18),
                onTap: onTap,
                splashColor: const Color(0xFFD2691E).withOpacity(0.1),
                highlightColor: const Color(0xFFD2691E).withOpacity(0.04),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Expanded(
                        child: Center(
                          child: Text(
                            consonant.char,
                            style: const TextStyle(
                              fontSize: 52,
                              fontFamily: 'LannaAkkhara',
                              color: Color(0xFFD2691E),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        consonant.reading,
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFF2E2E2E),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'เทียบ: ${consonant.thai}',
                        style: const TextStyle(
                          fontSize: 8,
                          fontWeight: FontWeight.w400,
                          color: Color(0xFF888888),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            top: 4,
            right: 4,
            child: IconButton(
              icon: const Icon(
                Icons.volume_up,
                color: Color(0xFFCD853F),
                size: 20,
              ),
              tooltip: 'ฟังเสียง',
              onPressed: onPlaySound,
            ),
          ),
        ],
      ),
    );
  }
}

/// ============================================================================
/// SCREEN / DIALOG : STROKE ORDER BOTTOM SHEET
/// ============================================================================
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
      duration: const Duration(milliseconds: 1000),
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
                'วิธีเขียน ตั๋ว ${widget.consonant.reading}',
                style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF2D1A00),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'พยัญชนะ: ${widget.consonant.char}',
            style: const TextStyle(
              fontSize: 19,
              fontFamily: 'LannaAkkhara',
              color: Color(0xFFD2691E),
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
              border: Border.all(
                color: const Color(0xFFD2691E).withOpacity(0.25),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 16,
                  offset: const Offset(0, 8),
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
              fontWeight: FontWeight.w400,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFFFF3E0),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: const Color(0xFF6B3A2A).withOpacity(0.2),
              ),
            ),
            child: Text(
              widget.consonant.description,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w500,
                color: Color(0xFF5C3D1E),
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
                    ? const Color(0xFFD2691E)
                    : Colors.grey[300],
                onPressed: _currentStrokeIndex > 0 ? _prev : null,
              ),
              const SizedBox(width: 24),
              ElevatedButton.icon(
                onPressed: _replay,
                icon: const Icon(Icons.refresh),
                label: const Text(
                  'เล่นใหม่',
                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.w500),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFA0522D),
                  foregroundColor: Colors.white,
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
                    ? const Color(0xFFD2691E)
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

/// ============================================================================
/// PAINTER: STROKE PAINTER FOR ANIME WRITING
/// ============================================================================
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
      Offset(
        (size.width - textPainter.width) / 2,
        (size.height - textPainter.height) / 2,
      ),
    );

    // 2. ปากกาสำหรับวาดเส้นที่เสร็จแล้ว (สีเทา #CCCCCC)
    final paintCompleted = Paint()
      ..color = const Color(0xFFCCCCCC)
      ..strokeWidth = 10
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    // 3. ปากกาสำหรับวาดเส้นที่กำลังทำอนิเมชัน (สีส้ม #D2691E)
    final paintCurrent = Paint()
      ..color = const Color(0xFFD2691E)
      ..strokeWidth = 10
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    // 4. วาดจุดเริ่มต้นของเส้นหลัก (วงกลมเล็กๆ)
    final paintStartActive = Paint()..color = const Color(0xFFD2691E);
    final paintStartInactive = Paint()..color = const Color(0xFFE0E0E0);

    // ฟังก์ชันแปลงพิกัด 100x100 เป็นพิกัดจริงตามขนาด Canvas
    Offset scale(Offset o) {
      return Offset(o.dx * size.width / 100, o.dy * size.height / 100);
    }

    // Helper: Catmull-Rom spline path from points
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

    // Draw dotted grid background
    final paintDot = Paint()
      ..color = const Color(0xFFDCC8B8).withValues(alpha: 0.3);
    const double spacing = 16.0;
    for (double x = spacing; x < size.width; x += spacing) {
      for (double y = spacing; y < size.height; y += spacing) {
        canvas.drawCircle(Offset(x, y), 1.0, paintDot);
      }
    }

    // วาดเส้นก่อนหน้าที่เสร็จไปแล้ว (smooth curves)
    for (int i = 0; i < currentIndex; i++) {
      final pts = strokes[i];
      if (pts.isEmpty) continue;
      canvas.drawPath(catmullRomPath(pts, scale), paintCompleted);
    }

    // วาดอนิเมชันเส้นปัจจุบัน (smooth curves)
    final currentPoints = strokes[currentIndex];
    if (currentPoints.isNotEmpty) {
      final totalSegments = currentPoints.length - 1;
      final currentProgressSegment = progress * totalSegments;
      final fullSegments = currentProgressSegment.floor();
      final partialProgress = currentProgressSegment - fullSegments;

      // Collect points up to progress
      final partialPoints = currentPoints.sublist(0, fullSegments + 1).toList();
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

    // 4. วาดจุดเริ่มต้นของเส้นหลัก (วงกลมพร้อมหมายเลขลำดับเส้น)
    for (int i = 0; i < strokes.length; i++) {
      if (strokes[i].isEmpty) continue;
      final startPt = scale(strokes[i][0]);
      final isCurrentOrCompleted = i <= currentIndex;
      canvas.drawCircle(
        startPt,
        10,
        isCurrentOrCompleted ? paintStartActive : paintStartInactive,
      );
      final textPainter = TextPainter(
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
      textPainter.layout();
      textPainter.paint(
        canvas,
        Offset(
          startPt.dx - textPainter.width / 2,
          startPt.dy - textPainter.height / 2,
        ),
      );
    }
  }

  @override
  bool shouldRepaint(covariant StrokePainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.currentIndex != currentIndex ||
        oldDelegate.char != char;
  }
}

/// ============================================================================
/// DATA HELPER: STROKE COORDINATES (100x100 Grid)
/// ============================================================================
List<List<Offset>> getStrokePaths(String char) {
  return sd.getStrokeData(char);
}

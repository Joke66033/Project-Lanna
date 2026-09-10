import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;

import 'writing_canvas.dart';
import '../../../core/api_config.dart';
import '../../../services/vocabulary_service.dart';
import '../../../services/lanna_transliterator.dart';

/// Item ข้อมูลคำศัพท์สำหรับ Dictionary Lookup
class _CustomDictItem {
  final String? vocabId;
  final String category;
  final String lanna;
  final String reading;
  final String thaiSound;
  final String meaning;

  _CustomDictItem({
    this.vocabId,
    required this.category,
    required this.lanna,
    required this.reading,
    required this.thaiSound,
    required this.meaning,
  });
}

/// หน้าฝึกเขียนคำที่ผู้ใช้กำหนดเอง
/// ผู้ใช้พิมพ์คำภาษาไทย → ระบบแปลงและจัดรูปอักขระล้านนาแท้ (Dictionary + AI + Kam Mueang Engine) → แสดง canvas ให้ฝึกเขียน
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

  final VocabularyService _vocabService = VocabularyService();
  List<_CustomDictItem> _dictItems = [];

  String _thaiWord = '';
  String _lannaWord = '';
  String _reading = '';
  String _meaning = '';
  int _inputLength = 0;
  bool _isTranslating = false;

  static const Color _kPrimary = Color(0xFF924E19);

  @override
  void initState() {
    super.initState();
    _loadDictionaryData();
  }

  Future<void> _loadDictionaryData() async {
    try {
      await LannaTransliterator.loadFromDatabase();
      final dbVocabs = await _vocabService.getAllVocabulary();
      if (!mounted) return;
      setState(() {
        _dictItems = dbVocabs
            .map(
              (v) => _CustomDictItem(
                vocabId: v.vocabId,
                category: v.category ?? 'คำศัพท์ทั่วไป',
                lanna: v.lannaWord,
                reading: v.reading,
                thaiSound: v.thaiWord,
                meaning: v.meaning,
              ),
            )
            .toList();
      });
    } catch (e) {
      debugPrint('Error loading vocabulary dictionary: $e');
    }
  }

  Future<void> _startPractice() async {
    final input = _inputCtrl.text.trim();
    if (input.isEmpty || _isTranslating) return;

    setState(() {
      _isTranslating = true;
    });

    final normalizedInput = input.toLowerCase();
    _CustomDictItem? matchedItem;

    // 1. ค้นหาคำตรงจากฐานข้อมูลคำศัพท์ (Exact Match)
    for (var item in _dictItems) {
      if (item.thaiSound.trim().toLowerCase() == normalizedInput ||
          item.lanna.trim() == input ||
          item.reading
                  .replaceAll(RegExp(r'[\[\]]'), '')
                  .trim()
                  .toLowerCase() ==
              normalizedInput) {
        matchedItem = item;
        break;
      }
    }

    // 2. ค้นหาแบบ Live จากฐานข้อมูล MySQL
    if (matchedItem == null) {
      try {
        final liveSearch = await _vocabService.searchVocabulary(input);
        for (var v in liveSearch) {
          if (v.thaiWord.trim().toLowerCase() == normalizedInput ||
              v.lannaWord.trim() == input ||
              v.reading
                      .replaceAll(RegExp(r'[\[\]]'), '')
                      .trim()
                      .toLowerCase() ==
                  normalizedInput) {
            matchedItem = _CustomDictItem(
              vocabId: v.vocabId,
              category: v.category ?? 'คำศัพท์ทั่วไป',
              lanna: v.lannaWord,
              reading: v.reading,
              thaiSound: v.thaiWord,
              meaning: v.meaning,
            );
            break;
          }
        }
      } catch (_) {}
    }

    String resultLanna = '';
    String resultReading = '';
    String resultMeaning = '';

    if (matchedItem != null) {
      resultLanna = matchedItem.lanna;
      resultReading = matchedItem.reading;
      resultMeaning = matchedItem.meaning;
    } else {
      // 3. ใช้ AI (Gemini Flash Live) หรือ Offline Kam Mueang Engine
      try {
        final aiResult = await _callGeminiAi(input);
        if (aiResult != null && mounted) {
          final notation = aiResult['lanna_notation']?.toString() ??
              aiResult['kam_mueang']?.toString() ??
              input;
          resultLanna = _parseLannaNotation(notation);
          resultReading = aiResult['phonetic']?.toString() ?? '[$input]';
          resultMeaning = aiResult['meaning']?.toString() ??
              'แปลและจัดอักขรวิธีล้านนาด้วย AI';
        } else {
          // Fallback: ใช้กฎการแปลคำเมืองออฟไลน์
          final offline = _translateKamMueangOffline(input);
          resultLanna = _parseLannaNotation(offline['notation']!);
          resultReading = offline['reading']!;
          resultMeaning = 'แปลตามหลักไวยากรณ์และอักขรวิธีคำเมือง';
        }
      } catch (e) {
        debugPrint('Translation error in custom writing: $e');
        final offline = _translateKamMueangOffline(input);
        resultLanna = _parseLannaNotation(offline['notation']!);
        resultReading = offline['reading']!;
        resultMeaning = 'แปลตามหลักไวยากรณ์และอักขรวิธีคำเมือง';
      }
    }

    if (resultLanna.trim().isEmpty) {
      resultLanna = LannaTransliterator().thaiToLanna(input);
    }

    if (!mounted) return;

    setState(() {
      _thaiWord = input;
      _lannaWord = resultLanna;
      _reading = resultReading;
      _meaning = resultMeaning;
      _isTranslating = false;
    });

    _canvasKey.currentState?.clear();
  }

  // ================= GEMINI AI LIVE =================
  Future<Map<String, dynamic>?> _callGeminiAi(String promptText) async {
    final apiKey = await ApiConfig.getActiveGeminiApiKey();
    const models = [
      'gemini-3.5-flash-lite',
      'gemini-3.5-flash',
      'gemini-3.6-flash',
      'gemini-flash-latest',
      'gemini-flash-lite-latest'
    ];
    const promptInstructions = '''
คุณคือผู้เชี่ยวชาญระดับศาสตราจารย์ด้านภาษาศาสตร์ล้านนา อักขรวิธีตั๋วเมืองตามตำราพจนานุกรมล้านนา มรภ.เชียงใหม่ (หน้า 17-22) และคู่มือฟอนต์ LN-TILOK มหาวิทยาลัยเชียงใหม่

จงแปลข้อความภาษาไทยเป็นภาษาคำเมืองแท้ ถอดคำอ่านสำเนียงคำเมือง และระบุโครงสร้างอักขระล้านนา (LN-TILOK Notation)

กฎการแปลคำเมืองแท้และสรรพนาม:
* สรรพนาม: "เธอ / คุณ / ตัวเอง" แปลว่า "ตั๋ว"
* สรรพนาม: "ฉัน / เรา" แปลว่า "เฮา", "ข้าเจ้า" หรือ "เปิ้น"
* คำทักทาย: "สวัสดีตอนเช้า" -> "สวัสสดีตอนเจ้า", "สวัสดีตอนเย็น" -> "สวัสสดีตอนแลง", "สวัสดี" -> "สวัสสดี"
* คำสั่งห้าม: "อย่า..." -> "จะไป...", "ห้ามไป" -> "บ่ดีไป", "ไม่ต้องไป" -> "บ่ต้องไป", "ไม่..." -> "บ่..."
* พืชผักผลไม้: "สับปะรด" -> "บ่าขะนัด", "มะม่วง" -> "บ่าม่วง", "มะละกอ" -> "บ่าก้วยเต้ด", "ฝรั่ง" -> "บ่าก้วยก๋า", "ฟักทอง" -> "บ่าน้ำแก้ว", "ขนุน" -> "บ่าหนุน", "มะเขือเทศ" -> "บ่าเขือส้ม", "มะนาว" -> "บ่านาว", "มะขาม" -> "บ่าขาม", "มะพร้าว" -> "บ่าป๊าว", "กระท้อน" -> "บ่าตื๋น"
* คำเฉพาะ: "ประตูช้างเผือก" -> "ปตูจ๊างเผือก", "ประตูท่าแพ" -> "ปตูท่าแพ", "ประตูสวนดอก" -> "ปตูสวนดอก", "ประตูเชียงใหม่" -> "ปตูเจียงใหม่", "เมืองอินทร์" -> "เมืองอินทร์", "ผองจาย" -> "ผองจาย", "มีความสุข" -> "มีความสุข", "ราชัน" -> "ราชัน", "ร่ำรวย" -> "ร่ำรวย"

กฎเหล็ก 4 ชั้น (LN-TILOK Notation):
1. เขียนอักษรชิดติดกันต่อเนื่อง
2. เครื่องหมายขีดล่าง "_" ให้ใส่เฉพาะหน้าพยัญชนะที่เป็นตัวสะกดท้ายพยางค์หรือพยัญชนะซ้อนสังโยค/อักษรนำ เช่น "ขอบ_คุณจ้า_ดนั_ก", "ส_วั\\u00AAดี", "กิ๋_นข้า_ว", "ค_วา_มสุ_ข", "รํ่_วว_ย", "ช_ย_งให_ม_่"
3. ห้ามใส่ "_" หน้าพยัญชนะต้นของคำทั่วไป เช่น "ไป", "มา", "ดี", "บ่", "จะ"
4. ห้ามใส่ "_" หน้าสระเด็ดขาด
5. ห้ามใส่ "_" ในฟิลด์ phonetic เด็ดขาด

ตอบกลับเป็น JSON เท่านั้น รูปแบบ:
{
  "kam_mueang": "คำแปลคำเมือง",
  "lanna_notation": "โครงสร้างอักขระที่ใส่ _ นำหน้าตัวห้อย",
  "phonetic": "[คำอ่านสำเนียงคำเมือง เป็นภาษาไทยล้วน ไม่มีเครื่องหมายขีดล่าง]",
  "meaning": "คำอธิบายความหมายและหน้าที่ของคำ 1 ประโยค"
}
''';

    for (final model in models) {
      try {
        final url = Uri.parse(
          'https://generativelanguage.googleapis.com/v1beta/models/$model:generateContent?key=$apiKey',
        );
        final res = await http.post(
          url,
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'contents': [
              {
                'parts': [
                  {
                    'text':
                        '$promptInstructions\n\nข้อความภาษาไทยที่ต้องการแปล: "$promptText"'
                  }
                ]
              }
            ]
          }),
        ).timeout(const Duration(seconds: 20));

        if (res.statusCode == 200) {
          final data = jsonDecode(res.body);
          final raw =
              data['candidates'][0]['content']['parts'][0]['text'] as String;
          final cleanJson =
              raw.replaceAll('```json', '').replaceAll('```', '').trim();
          return jsonDecode(cleanJson) as Map<String, dynamic>;
        }
      } catch (e) {
        debugPrint('Gemini AI Call error with model $model: $e');
      }
    }
    return null;
  }

  // ================= OFFLINE KAM MUEANG ENGINE =================
  Map<String, String> _translateKamMueangOffline(String thaiText) {
    var km = thaiText.trim();
    const phraseDict = {
      'สวัสดีตอนเช้า': 'สวัสสดีตอนเจ้า',
      'สวัสดีตอนสาย': 'สวัสสดีตอนสาย',
      'สวัสดีตอนเที่ยง': 'สวัสสดีตอนเที่ยง',
      'สวัสดีตอนบ่าย': 'สวัสสดีตอนบ่าย',
      'สวัสดีตอนเย็น': 'สวัสสดีตอนแลง',
      'สวัสดีตอนค่ำ': 'สวัสสดีตอนค่ำ',
      'สวัสดีตอนกลางคืน': 'สวัสสดีเมื่อคืน',
      'สวัสดีปีใหม่': 'สวัสสดีปีใหม่',
      'สวัสดี': 'สวัสสดี',
      'ยินดีต้อนรับ': 'ยินดีต้อนฮับ',
      'ยินดีต้อนฮับ': 'ยินดีต้อนฮับ',
      'ต้อนรับ': 'ต้อนฮับ',
      'รับ': 'ฮับ',
      'ตอนเช้า': 'ตอนเจ้า',
      'ตอนเย็น': 'ตอนแลง',
      'ตอนค่ำ': 'ตอนค่ำ',
      'ตอนกลางคืน': 'เมื่อคืน',
      'กลางคืน': 'เมื่อคืน',
      'เช้า': 'เจ้า',
      'เย็น': 'แลง',
      'ว่าไงนะ': 'ว่าใดนะ',
      'ว่าไงบ้าง': 'ว่าใดพ่อง',
      'ว่าไง': 'ว่าใด',
      'เป็นไงบ้าง': 'เป๋นใดพ่อง',
      'เป็นไง': 'เป๋นใด',
      'เป็นอย่างไร': 'เป๋นจะใด',
      'เป็นยังไง': 'เป๋นจะใด',
      'ยังไง': 'จะใด',
      'อย่างไง': 'จะใด',
      'ทำไม': 'ยะหยัง',
      'เมื่อไหร่': 'เมื่อใด',
      'ที่ไหน': 'ตางใด',
      'ใคร': 'ไผ',
      'อะไรนะ': 'หยังนะ',
      'อะไร': 'หยัง',
      'ทำอะไร': 'ยะหยัง',
      'ไปไหน': 'ไปตางใด',
      'สบายดีไหม': 'สบายดีก่อ',
      'สบายดีก่อ': 'สบายดีก่อ',
      'วันนี้เธอกินข้าวกับอะไร': 'วันนี้ตั๋วกิ๋นข้าวกับหยัง',
      'เธอกินข้าวกับอะไร': 'ตั๋วกิ๋นข้าวกับหยัง',
      'กินข้าวกับอะไร': 'กิ๋นข้าวกับหยัง',
      'กินข้าวไหม': 'กิ๋นข้าวก่อ',
      'กินข้าวหรือยัง': 'กิ๋นข้าวแล้วกา',
      'กินข้าว': 'กิ๋นข้าว',
      'กิน': 'กิ๋น',
      'ข้าว': 'ข้าว',
      'ไม่ต้องไป': 'บ่ต้องไป',
      'ไม่ต้อง': 'บ่ต้อง',
      'อย่าไป': 'จะไปไป',
      'อย่ามา': 'จะไปมา',
      'ห้ามไป': 'บ่ดีไป',
      'อย่าทำ': 'จะไปยะ',
      'อย่ากิน': 'จะไปกิ๋น',
      'อย่าพูด': 'จะไปอู้',
      'อย่า': 'บ่ดี',
      'ไม่ได้': 'บ่ได้',
      'ไม่เอา': 'บ่เอา',
      'ไม่ใช่': 'บ่ใจ้',
      'ไม่รู้': 'บ่ฮู้',
      'ไม่': 'บ่',
      'เธอ': 'ตั๋ว',
      'คุณ': 'ตั๋ว',
      'ตัวเอง': 'ตั๋ว',
      'ฉัน': 'เฮา',
      'ผม': 'เฮา',
      'เรา': 'เฮา',
      'ยินดีด้วย': 'ยินดีโตย',
      'ด้วย': 'โตย',
      'ขอบคุณมาก': 'ขอบคุณจ๊าดนัก',
      'ขอบคุณมากๆ': 'ขอบคุณจ๊าดนัก',
      'ขอบคุณ': 'ขอบคุณจ๊าดนัก',
      'ยินดีจ๊าดนัก': 'ยินดีจ๊าดนัก',
      'ไปเที่ยวไหน': 'ไปแอ่วไหน',
      'เที่ยวไหน': 'แอ่วไหน',
      'ไปเที่ยว': 'ไปแอ่ว',
      'เที่ยว': 'แอ่ว',
      'ทำ': 'ยะ',
      'พูดภาษาเหนือ': 'อู้กำเมือง',
      'พูดคำเมือง': 'อู้กำเมือง',
      'ภาษาเหนือ': 'กำเมือง',
      'คำเมือง': 'กำเมือง',
      'พูด': 'อู้',
      'มอง': 'ผ่อ',
      'ดู': 'ผ่อ',
      'เดิน': 'เตียว',
      'วิ่ง': 'แล่น',
      'คิดถึง': 'กึ๊ดเติงหา',
      'รัก': 'ฮัก',
      'รู้': 'ฮู้',
      'ไม่เป็นไร': 'บ่เป๋นหยัง',
      'ขอโทษ': 'สูมา',
      'ลาก่อน': 'ไปก่อนเน้อ',
      'ไปก่อนนะ': 'ไปก่อนเน้อ',
      'สุนัข': 'หมา',
      'ช้าง': 'จ๊าง',
      'วัว': 'งัว',
      'แมว': 'แมว',
      'ไก่': 'ไก่',
      'เป็ด': 'เป็ด',
      'หมู': 'หมู',
      'ปลา': 'ปลา',
      'ตลาด': 'กาด',
      'โกหก': 'ขี้จุ๊',
      'สวย': 'งาม',
      'อร่อย': 'ลำ',
      'หล่อ': 'หล่อ',
      'ร้อน': 'ฮ้อน',
      'หนาว': 'หนาว',
      'ใหญ่': 'หลวง',
      'เล็ก': 'น้อย',
      'ผู้ชาย': 'ป้อจาย',
      'ผู้หญิง': 'แม่ญิง',
      'เด็ก': 'ละอ่อน',
      'พ่อ': 'ป้อ',
      'แม่': 'แม่',
      'พี่': 'ปี้',
      'น้อง': 'น้อง',
      'รองเท้า': 'เกือก',
      'กางเกง': 'เตี่ยว',
      'ผ้าซิ่น': 'ซิ่น',
      'สับปะรด': 'บ่าขะนัด',
      'บ่าขะนัด': 'บ่าขะนัด',
      'มะม่วง': 'บ่าม่วง',
      'บ่าม่วง': 'บ่าม่วง',
      'บะม่วง': 'บ่าม่วง',
      'มะละกอ': 'บ่าก้วยเต้ด',
      'บ่าก้วยเต้ด': 'บ่าก้วยเต้ด',
      'ฝรั่ง': 'บ่าก้วยก๋า',
      'บ่าก้วยก๋า': 'บ่าก้วยก๋า',
      'ฟักทอง': 'บ่าน้ำแก้ว',
      'บ่าน้ำแก้ว': 'บ่าน้ำแก้ว',
      'ขนุน': 'บ่าหนุน',
      'บ่าหนุน': 'บ่าหนุน',
      'มะเขือเทศ': 'บ่าเขือส้ม',
      'บ่าเขือส้ม': 'บ่าเขือส้ม',
      'มะนาว': 'บ่านาว',
      'บ่านาว': 'บ่านาว',
      'มะขาม': 'บ่าขาม',
      'บ่าขาม': 'บ่าขาม',
      'มะพร้าว': 'บ่าป๊าว',
      'บ่าป๊าว': 'บ่าป๊าว',
      'กระท้อน': 'บ่าตื๋น',
      'ส้มตำ': 'ตำส้ม',
      'ตำส้ม': 'ตำส้ม',
      'ส้ม': 'ส้ม',
      'หมดแล้ว': 'เสี้ยงแล้ว',
      'หมด': 'เสี้ยง',
      'กินหมด': 'กิ๋นเสี้ยง',
      'หรือยัง': 'แล้วกา',
      'โรงเรียน': 'โฮงเฮียน',
      'โรงพยาบาล': 'โฮงยา',
      'เรือน': 'เฮือน',
      'บ้าน': 'เฮือน',
      'ภูเขา': 'ดอย',
      'มาก': 'นัก',
      'มากๆ': 'ขนาด',
      'เยอะ': 'นัก',
      'เหนื่อย': 'อิด',
      'สนุก': 'ม่วน',
      'สนุกมาก': 'ม่วนขนาด',
      'อิ่ม': 'อิ่ม',
      'หิว': 'อยาก',
      'หิวข้าว': 'อยากข้าว',
      'หิวน้ำ': 'หิวน้ำ',
      'เชียงราย': 'เชียงราย',
      'เชียงใหม่': 'เชียงใหม่',
      'น่าน': 'น่าน',
      'พะเยา': 'พระยาว',
      'แพร่': 'แพล่',
      'แม่ฮ่องสอน': 'แม่ร่องสอน',
      'ลำปาง': 'ลำพาง',
      'อุตรดิตถ์': 'อุตตรดิตถ์',
      'กัลยาณิวัฒนา': 'กัลยาณิวัฑฒนา',
      'เกาะคา': 'เกาะตา',
      'ขุนตาล': 'ขุนตาล',
      'จอมทอง': 'จอมทอง',
      'จุน': 'ชุน',
      'เด่นชัย': 'เด่นไชย',
      'ท่าปลา': 'ท่าปลา',
      'ท่าวังผา': 'ท่าวังผา',
      'ทุ่งเสลี่ยม': 'ทุ่งเสลี่ยม',
      'ทุ่งหัวช้าง': 'ทุ่งหัวช้าง',
      'เทิง': 'เริง',
      'นาน้อย': 'นาหน้อย',
      'นาหมื่น': 'นาหมื่น',
      'บ่อเกลือ': 'บ่อเกือ',
      'บ้านธิ': 'บ้านธิ',
      'บ้านหลวง': 'บ้านหลวง',
      'บ้านโฮ่ง': 'บ้านโห้ง',
      'ปง': 'ปง',
      'ป่าซาง': 'ป่าชาง',
      'ปาย': 'พาย',
      'เมืองลำพูน': 'เมืองละพูน',
      'แม่จริม': 'แม่จริม',
      'แม่จัน': 'แม่ชัน',
      'แม่แจ่ม': 'แม่แจ่ม',
      'แม่ใจ': 'แม่ไชย',
      'แม่แตง': 'แม่แตง',
      'แม่ทะ': 'แม่ธะ',
      'แม่ทา': 'แม่ทรา',
      'แม่พริก': 'แม่พริก',
      'แม่ฟ้าหลวง': 'แม่ฟ้าหลวง',
      'แม่เมาะ': 'แม่เมาะ',
      'แม่ริม': 'แม่ริม',
      'แม่ลาน้อย': 'แม่ลาหน้อย',
      'แม่ลาว': 'แม่ลาว',
      'แม่วาง': 'แม่วาง',
      'เวียงสา': 'เวียงสา',
      'เวียงหนองล่อง': 'เวียงหนองหล้อง',
      'เวียงแหง': 'เวียงแหง',
      'สบปราบ': 'สบปาบ',
      'สบเมย': 'สบเมย',
      'สอง': 'สรอง',
      'สองแคว': 'สองแคว',
      'สะเมิง': 'สะเมิง',
      'สันกำแพง': 'สันก่ำแพง',
      'สันติสุข': 'สันติสุข',
      'สันทราย': 'สันชาย',
      'สันป่าตอง': 'สันป่าทอง',
      'สารภี': 'สารพี',
      'สูงเม่น': 'สุงเหมั้น',
      'เสริมงาม': 'เสริมงาม',
      'ประตูช้างเผือก': 'ปตูจ๊างเผือก',
      'ประตูท่าแพ': 'ปตูท่าแพ',
      'ประตูสวนดอก': 'ปตูสวนดอก',
      'ประตูเชียงใหม่': 'ปตูเจียงใหม่',
      'ประตูแสนปุง': 'ปตูแสนปุง',
      'ประตูสวนปรุง': 'ปตูสวนปรุง',
      'ช้างเผือก': 'จ๊างเผือก',
      'ประตู': 'ปตู',
      'เผือก': 'เผือก',
      'เมืองอินทร์': 'เมืองอินทร์',
      'ผองจาย': 'ผองจาย',
      'มีความสุข': 'มีความสุข',
      'ราชัน': 'ราชัน',
      'ร่ำรวย': 'ร่ำรวย',
      'ความสุข': 'ความสุข',
      'ความ': 'ความ',
      'รวย': 'รวย',
      'สุข': 'สุข',
    };

    final sortedPhraseKeys = phraseDict.keys.toList()
      ..sort((a, b) => b.length.compareTo(a.length));
    for (final key in sortedPhraseKeys) {
      if (km.contains(key)) {
        km = km.replaceAll(key, phraseDict[key]!);
      }
    }

    var notation = km;
    const subWords = {
      'สวัสดีตอนเจ้า': 'ส_วั\u00AAดีตอ_นเจ้_า',
      'สวัสสดีตอนเจ้า': 'ส_วั\u00AAดีตอ_นเจ้_า',
      'สวัสดีตอนแลง': 'ส_วั\u00AAดีตอ_นแ_ล_ง',
      'สวัสสดีตอนแลง': 'ส_วั\u00AAดีตอ_นแ_ล_ง',
      'สวัสดีตอนสาย': 'ส_วั\u00AAดีตอ_นสา_ย',
      'สวัสสดีตอนสาย': 'ส_วั\u00AAดีตอ_นสา_ย',
      'สวัสดีตอนเที่ยง': 'ส_วั\u00AAดีตอ_นเ_ที่_ย_ง',
      'สวัสสดีตอนเที่ยง': 'ส_วั\u00AAดีตอ_นเ_ที่_ย_ง',
      'สวัสดีตอนบ่าย': 'ส_วั\u00AAดีตอ_นบ่า_ย',
      'สวัสสดีตอนบ่าย': 'ส_วั\u00AAดีตอ_นบ่า_ย',
      'สวัสดีตอนค่ำ': 'ส_วั\u00AAดีตอ_นค_่ำ',
      'สวัสสดีตอนค่ำ': 'ส_วั\u00AAดีตอ_นค_่ำ',
      'สวัสดีเมื่อคืน': 'ส_วั\u00AAดีเมื_่อคื_น',
      'สวัสสดีเมื่อคืน': 'ส_วั\u00AAดีเมื_่อคื_น',
      'สวัสดีปีใหม่': 'ส_วั\u00AAดี ปีใ_ห่_ม',
      'สวัสสดีปีใหม่': 'ส_วั\u00AAดี ปีใ_ห่_ม',
      'สวัสดี': 'ส_วั\u00AAดี',
      'สวัสสดี': 'ส_วั\u00AAดี',
      'ตอนเจ้า': 'ตอ_นเจ้_า',
      'ตอนแลง': 'ตอ_นแ_ล_ง',
      'ตอนสาย': 'ตอ_นสา_ย',
      'ตอนเที่ยง': 'ตอ_นเ_ที่_ย_ง',
      'ตอนบ่าย': 'ตอ_นบ่า_ย',
      'ตอนค่ำ': 'ตอ_นค_่ำ',
      'เมื่อคืน': 'เมื_่อคื_น',
      'เจ้า': 'เจ้_า',
      'แลง': 'แ_ล_ง',
      'ยินดีต้อนฮับ': 'ยิ_นดีต้อ_นฮั_บ',
      'ยินดีต้อนรับ': 'ยิ_นดีต้อ_นฮั_บ',
      'บ่ต้องไป': 'บ่ต้อ_งไป',
      'บ่ต้อง': 'บ่ต้อ_ง',
      'บ่ดีไป': 'บ่ดีไป',
      'จะไปไป': 'จะไปไป',
      'จะไปมา': 'จะไปมา',
      'จะไปยะ': 'จะไปยัง',
      'ตั๋ว': 'ตั๋_ว',
      'กิ๋น': 'กิ๋_น',
      'ข้าว': 'ข้า_ว',
      'กับ': 'กั_บ',
      'หยัง': 'ห_ยั_ง',
      'แมว': 'แม_ว',
      'หมา': 'ห_มา',
      'จ๊าง': 'จ๊า_ง',
      'งัว': 'ง_ว',
      'ไก่': 'ไก่',
      'โตย': 'โต_ย',
      'แอ่ว': 'แอ่_ว',
      'กาด': 'กา_ด',
      'งาม': 'งา_ม',
      'ลำ': 'ลำ',
      'สูมา': 'สูมา',
      'ยะหยัง': 'ยะห_ยั_ง',
      'บ่เป๋นหยัง': 'บ่เป๋_นห_ยั_ง',
      'ฉลาด': 'จ_รา_ด',
      'จะหลาด': 'จ_รา_ด',
      'ตลาด': 'ต_ลา_ด',
      'เสี้ยงแล้ว': 'สี้_ย_งแล้_ว',
      'เสี้ยง': 'สี้_ย_ง',
      'วัดมหาวัน': 'วั_ดมหาว_น',
      'มหาวัน': 'มหาว_น',
      'มะม่วง': 'บ_ะม_่ว_ง',
      'บ่าม่วง': 'บ_ะม_่ว_ง',
      'บะม่วง': 'บ_ะม_่ว_ง',
      'สับปะรด': 'บ่าขะนั_ด',
      'บ่าขะนัด': 'บ่าขะนั_ด',
      'มะละกอ': 'บ่าก_ว้_ยเต้_ด',
      'บ่าก้วยเต้ด': 'บ่าก_ว้_ยเต้_ด',
      'ฝรั่ง': 'บ่าก_ว้_ยก๋า',
      'บ่าก้วยก๋า': 'บ่าก_ว้_ยก๋า',
      'ฟักทอง': 'บ่าน้ำแก้_ว',
      'บ่าน้ำแก้ว': 'บ่าน้ำแก้_ว',
      'ขนุน': 'บ่าห_นุ_น',
      'บ่าหนุน': 'บ่าห_นุ_น',
      'มะเขือเทศ': 'บ่าเขื_อส_้ม',
      'บ่าเขือส้ม': 'บ่าเขื_อส_้ม',
      'มะนาว': 'บ_ะนา_ว',
      'บ่านาว': 'บ_ะนา_ว',
      'บะนาว': 'บ_ะนา_ว',
      'มะขาม': 'บ_ะขา_ม',
      'บ่าขาม': 'บ_ะขา_ม',
      'บะขาม': 'บ_ะขา_ม',
      'มะพร้าว': 'บ_ะป_้า_ว',
      'บ่าป๊าว': 'บ_ะป_้า_ว',
      'บะป๊าว': 'บ_ะป_้า_ว',
      'กระท้อน': 'บ่าตื๋_น',
      'บ่าตื๋น': 'บ่าตื๋_น',
      'ส้มตำ': 'ต_ำส_้ม',
      'ตำส้ม': 'ต_ำส_้ม',
      'ส้ม': 'ส_้ม',
      'โฮงเฮียน': 'โฮ_งเฮี_ย_น',
      'โรงเรียน': 'โฮ_งเฮี_ย_น',
      'โฮงยา': 'โฮ_งยา',
      'โรงพยาบาล': 'โฮ_งยา',
      'เฮือน': 'เฮื_อ_น',
      'เรือน': 'เฮื_อ_น',
      'บ้าน': 'เฮื_อ_น',
      'ดอย': 'ด_อย',
      'ภูเขา': 'ด_อย',
      'อิด': 'อิ_ด',
      'ม่วน': 'ม_่ว_น',
      'ม่วนขนาด': 'ม_่ว_นขนา_ด',
      'อู้': 'อู้',
      'อู้กำเมือง': 'อู้ก_ำเมื_อง',
      'ผ่อ': 'ผ_่อ',
      'เตียว': 'เตี_ย_ว',
      'แล่น': 'แ_ล_่_น',
      'กึ๊ดเติงหา': 'กึ๊_ดเติ_งหา',
      'ฮัก': 'ฮั_ก',
      'ฮู้': 'ฮู้',
      'ป้อจาย': 'ป้_อจา_ย',
      'แม่ญิง': 'แ_ม_่ญิ_ง',
      'ละอ่อน': 'ละอ่_อ_น',
      'เกือก': 'เกื_อ_ก',
      'เตี่ยว': 'เตี่_ย_ว',
      'เชียงราย': 'ช_ย_งรา_ย',
      'เชียงใหม่': 'ช_ย_งให_ม_่',
      'น่าน': 'น่า_น',
      'พะเยา': 'พยาว',
      'พระยาว': 'พยาว',
      'พยาว': 'พยาว',
      'แพร่': 'แ_พ_ล่',
      'แม่ฮ่องสอน': 'แ_ม_่ร_่อ_งส_่อร',
      'ลำปาง': 'ลำพา_ง',
      'อุตรดิตถ์': 'อุ_ต_ตระดิ_ต_ถ์',
      'กัลยาณิวัฒนา': 'กั_ลยาณิวั_ฒนา',
      'เกาะคา': 'เกาะตา',
      'ขุนตาล': 'ขุ_นตา_ล',
      'จอมทอง': 'จ_อมท_อง',
      'จุน': 'ชุ_น',
      'เด่นชัย': 'เด_่_นไช_ย',
      'ท่าปลา': 'ท่าป_ลา',
      'ท่าวังผา': 'ท่าวั_งผา',
      'ทุ่งเสลี่ยม': 'ทุ_่_งส_เลี_่ย_ม',
      'ทุ่งหัวช้าง': 'ทุ_่_งห_ัวจ_้า_ง',
      'เทิง': 'เริ_ง',
      'นาน้อย': 'นาห_น_้อ_ย',
      'นาหมื่น': 'นาห_ม_ื_่_น',
      'บ่อเกลือ': 'บ_่อเกื_อ',
      'บ้านธิ': 'บ_้า_นธิ',
      'บ้านหลวง': 'บ_้า_นห_ลว_ง',
      'บ้านโฮ่ง': 'บ_้า_นโห_้_ง',
      'ปง': 'ป_ง',
      'ป่าซาง': 'ป_่าจา_ง',
      'ปาย': 'พา_ย',
      'เมืองลำพูน': 'เมื_องละพู_น',
      'แม่จริม': 'แ_ม_่จริ_ม',
      'แม่จัน': 'แ_ม_่ชั_น',
      'แม่แจ่ม': 'แ_ม_่แ_จ_่_ม',
      'แม่ใจ': 'แ_ม_่ไช_ย',
      'แม่แตง': 'แ_ม_่แ_ต_ง',
      'แม่ทะ': 'แ_ม_่ธะ',
      'แม่ทา': 'แ_ม_่ท_รา',
      'แม่พริก': 'แ_ม_่พ_ริ_ก',
      'แม่ฟ้าหลวง': 'แ_ม_่ฟ_้าห_ลว_ง',
      'แม่เมาะ': 'แ_ม_่เมาะ',
      'แม่ริม': 'แ_ม_่ริ_ม',
      'แม่ลาน้อย': 'แ_ม_่ลาห_น_้อ_ย',
      'แม่ลาว': 'แ_ม_่ลา_ว',
      'แม่วาง': 'แ_ม_่วา_ง',
      'เวียงสา': 'ว_ย_งสา',
      'เวียงหนองล่อง': 'ว_ย_งห_น_องห_ล_้อ_ง',
      'เวียงแหง': 'ว_ย_งแ_ห_ง',
      'สบปราบ': 'ส_บปา_บ',
      'สบเมย': 'ส_บเม_ย',
      'สอง': 'ส_รอ_ง',
      'สองแคว': 'ส_องแ_ค_ว',
      'สะเมิง': 'สะเมิ_ง',
      'สันกำแพง': 'สั_นก_ำแ_พ_ง',
      'สันติสุข': 'สั_น_ติสุ_ข',
      'สันทราย': 'สั_นชา_ย',
      'สันป่าตอง': 'สั_นป_่าท_อง',
      'สารภี': 'สารพ_ี',
      'สูงเม่น': 'สุ_งห_ม_ั_้น',
      'เสริมงาม': 'เสริ_มงา_ม',
      'ประตูช้างเผือก': 'ปตูจ_้า_งเ_ผื_อ_ก',
      'ปตูจ๊างเผือก': 'ปตูจ_้า_งเ_ผื_อ_ก',
      'ประตูท่าแพ': 'ปตูท_่าแ_พ',
      'ประตูสวนดอก': 'ปตูส_วนด_อก',
      'ประตูเชียงใหม่': 'ปตูช_ย_งให_ม_่',
      'ปตูเจียงใหม่': 'ปตูช_ย_งให_ม_่',
      'ประตูแสนปุง': 'ปตูแ_ส_นปุ_ง',
      'ประตู': 'ปตู',
      'ปตู': 'ปตู',
      'ช้างเผือก': 'จ_้า_งเ_ผื_อ_ก',
      'จ๊างเผือก': 'จ_้า_งเ_ผื_อ_ก',
      'เผือก': 'เ_ผื_อ_ก',
      'เมืองอินทร์': 'เมื_องอิ_นท_ร์',
      'ผองจาย': 'ผ_งจา_ย',
      'มีความสุข': 'มีค_วา_มสุ_ข',
      'ราชัน': 'ราชั_น',
      'ร่ำรวย': 'ร\u0E4D\u0E48_วว_ย',
      'ความสุข': 'ค_วา_มสุ_ข',
      'ความ': 'ค_วา_ม',
      'รวย': 'ร_ว_ย',
      'สุข': 'สุ_ข',
    };

    final sortedSubKeys = subWords.keys.toList()
      ..sort((a, b) => b.length.compareTo(a.length));
    for (final key in sortedSubKeys) {
      if (notation.contains(key)) {
        notation = notation.replaceAll(key, subWords[key]!);
      }
    }

    const readingMap = {
      'ว่าใด': '[ว่า-ใด]',
      'ว่าใดนะ': '[ว่า-ใด-นะ]',
      'ว่าใดพ่อง': '[ว่า-ใด-พ่อง]',
      'เป๋นใด': '[เป๋น-ใด]',
      'เป๋นใดพ่อง': '[เป๋น-ใด-พ่อง]',
      'เป๋นจะใด': '[เป๋น-จะ-ใด]',
      'จะใด': '[จะ-ใด]',
      'ยะหยัง': '[ยะ-หยัง]',
      'เมื่อใด': '[เมื่อ-ใด]',
      'ตางใด': '[ตาง-ใด]',
      'ไผ': '[ไผ]',
      'หยังนะ': '[หยัง-นะ]',
      'หยัง': '[หยัง]',
      'ไปตางใด': '[ไป-ตาง-ใด]',
      'สบายดีก่อ': '[สะ-บาย-ดี-ก่อ]',
      'กิ๋นข้าว': '[กิ๋น-ข้าว]',
      'กิ๋น': '[กิ๋น]',
      'จะไปไป': '[จะ-ไป-ไป]',
      'จะไปมา': '[จะ-ไป-มา]',
      'จะไปยะ': '[จะ-ไป-ยะ]',
      'จะไปกิ๋น': '[จะ-ไป-กิ๋น]',
      'จะไปอู้': '[จะ-ไป-อู้]',
      'บ่ดีไป': '[บ่-ดี-ไป]',
      'บ่ต้องไป': '[บ่-ต้อง-ไป]',
      'บ่ต้อง': '[บ่-ต้อง]',
      'บ่ได้': '[บ่-ได้]',
      'บ่เอา': '[บ่-เอา]',
      'บ่ใจ้': '[บ่-ใจ้]',
      'บ่ฮู้': '[บ่-ฮู้]',
      'บ่': '[บ่]',
      'ตั๋ว': '[ตั๋ว]',
      'เฮา': '[เฮา]',
      'ยินดีโตย': '[ยิน-ดี-โตย]',
      'ขอบคุณจ๊าดนัก': '[ขอบ-คุณ-จ๊าด-นัก]',
      'ยินดีจ๊าดนัก': '[ยิน-ดี-จ๊าด-นัก]',
      'ไปแอ่ว': '[ไป-แอ่ว]',
      'แอ่ว': '[แอ่ว]',
      'อู้กำเมือง': '[อู้-กำ-เมือง]',
      'กำเมือง': '[กำ-เมือง]',
      'อู้': '[อู้]',
      'ผ่อ': '[ผ่อ]',
      'เตียว': '[เตียว]',
      'แล่น': '[แล่น]',
      'กึ๊ดเติงหา': '[กึ๊ด-เติง-หา]',
      'ฮัก': '[ฮัก]',
      'ฮู้': '[ฮู้]',
      'บ่เป๋นหยัง': '[บ่-เป๋น-หยัง]',
      'สูมา': '[สู-มา]',
      'ไปก่อนเน้อ': '[ไป-ก่อน-เน้อ]',
      'หมา': '[หมา]',
      'จ๊าง': '[จ๊าง]',
      'งัว': '[งัว]',
      'กาด': '[กาด]',
      'ขี้จุ๊': '[ขี้-จุ๊]',
      'งาม': '[งาม]',
      'ลำ': '[ลำ]',
      'ฮ้อน': '[ฮ้อน]',
      'หลวง': '[หลวง]',
      'น้อย': '[น้อย]',
      'ป้อจาย': '[ป้อ-จาย]',
      'แม่ญิง': '[แม่-ญิง]',
      'ละอ่อน': '[ละ-อ่อน]',
      'ป้อ': '[ป้อ]',
      'ปี้': '[ปี้]',
      'เกือก': '[เกือก]',
      'เตี่ยว': '[เตี่ยว]',
      'บ่าขะนัด': '[บ่า-ขะ-นัด]',
      'บ่าม่วง': '[บ่า-ม่วง]',
      'บ่าก้วยเต้ด': '[บ่า-ก้วย-เต้ด]',
      'บ่าก้วยก๋า': '[บ่า-ก้วย-ก๋า]',
      'บ่าน้ำแก้ว': '[บ่า-น้ำ-แก้ว]',
      'บ่าหนุน': '[บ่า-หนุน]',
      'บ่าเขือส้ม': '[บ่า-เขือ-ส้ม]',
      'บ่านาว': '[บ่า-นาว]',
      'บ่าขาม': '[บ่า-ขาม]',
      'บ่าป๊าว': '[บ่า-ป๊าว]',
      'บ่าตื๋น': '[บ่า-ตื๋น]',
      'ตำส้ม': '[ตำ-ส้ม]',
      'เสี้ยงแล้ว': '[เสี้ยง-แล้ว]',
      'เสี้ยง': '[เสี้ยง]',
      'กิ๋นเสี้ยง': '[กิ๋น-เสี้ยง]',
      'แล้วกา': '[แล้ว-กา]',
      'โฮงเฮียน': '[โฮง-เฮียน]',
      'โฮงยา': '[โฮง-ยา]',
      'เฮือน': '[เฮือน]',
      'ดอย': '[ดอย]',
      'อิด': '[อิด]',
      'ม่วน': '[ม่วน]',
      'ม่วนขนาด': '[ม่วน-ขะ-หนาด]',
      'อยากข้าว': '[อยาก-ข้าว]',
      'สวัสสดีตอนเจ้า': '[สะ-หวัด-ดี-ตอน-เจ้า]',
      'สวัสสดีตอนแลง': '[สะ-หวัด-ดี-ตอน-แลง]',
      'สวัสสดี': '[สะ-หวัด-ดี]',
      'ยินดีต้อนฮับ': '[ยิน-ดี-ต้อน-ฮับ]',
      'วันนี้ตั๋วกิ๋นข้าวกับหยัง': '[วัน-นี้-ตั๋ว-กิ๋น-ข้าว-กับ-หยัง]',
      'ประตูช้างเผือก': '[ปะ-ตู-จ๊าง-เผือก]',
      'ปตูจ๊างเผือก': '[ปะ-ตู-จ๊าง-เผือก]',
      'ประตูท่าแพ': '[ปะ-ตู-ท่า-แพ]',
      'ประตูสวนดอก': '[ปะ-ตู-สวน-ดอก]',
      'ประตูเชียงใหม่': '[ปะ-ตู-เจียง-ใหม่]',
      'ปตูเจียงใหม่': '[ปะ-ตู-เจียง-ใหม่]',
      'ประตูแสนปุง': '[ปะ-ตู-แสน-ปุง]',
      'ประตู': '[ปะ-ตู]',
      'ปตู': '[ปะ-ตู]',
      'ช้างเผือก': '[จ๊าง-เผือก]',
      'จ๊างเผือก': '[จ๊าง-เผือก]',
      'เผือก': '[เผือก]',
      'เมืองอินทร์': '[เมือง-อินทร์]',
      'ผองจาย': '[ผอง-จาย]',
      'มีความสุข': '[มี-ความ-สุข]',
      'ราชัน': '[รา-ชัน]',
      'ร่ำรวย': '[ร่ำ-รวย]',
      'ความสุข': '[ความ-สุข]',
      'ความ': '[ความ]',
      'รวย': '[รวย]',
      'สุข': '[สุข]',
    };

    final reading = readingMap[km] ?? (km.isNotEmpty ? '[$km]' : '');

    return {
      'kam_mueang': km,
      'notation': notation,
      'reading': reading,
    };
  }

  // ================= PARSE LANNA NOTATION =================
  String _parseLannaNotation(String notation) {
    const subMap = {
      'ก': '\uF001',
      'ข': '\uF002',
      'ฃ': '\uF003',
      'ค': '\uF004',
      'ฅ': '\uF005',
      'ฆ': '\uF006',
      'ง': '\uF007',
      'จ': '\uF008',
      'ฉ': '\uF009',
      'ช': '\uF00A',
      'ซ': '\uF00B',
      'ฌ': '\uF00C',
      'ญ': '\uF00D',
      'ฎ': '\uF00E',
      'ฏ': '\uF00F',
      'ฐ': '\uF010',
      'ฑ': '\uF011',
      'ฒ': '\uF012',
      'ณ': '\uF013',
      'ด': '\uF014',
      'ต': '\uF015',
      'ถ': '\uF016',
      'ท': '\uF017',
      'ธ': '\uF018',
      'น': '\uF019',
      'บ': '\uF01A',
      'ป': '\uF01B',
      'ผ': '\uF01C',
      'ฝ': '\uF01D',
      'พ': '\uF01E',
      'ฟ': '\uF01F',
      'ภ': '\uF020',
      'ม': '\uF021',
      'ย': '\uF022',
      'ร': '\uF023',
      'ฤ': '\uF024',
      'ล': '\uF025',
      'ฦ': '\uF026',
      'ว': '\uF027',
      'ศ': '\uF028',
      'ษ': '\uF029',
      'ส': '\uF02A',
      'ห': '\uF02B',
      'ฬ': '\uF02C',
      'อ': '\uF02D',
      'ฮ': '\uF02E',
      'สฺส': '\u00AA',
    };

    var cleanNotation = notation.replaceAllMapped(
      RegExp(r'เ([ก-ฮ])([ีิ])([่้๊๋]?)(ย|_ย)([ก-ฮ]|_[ก-ฮ])?'),
      (m) => '${m[1]}${m[3] ?? ''}${m[2]}_ย${m[5] ?? ''}',
    );

    final sb = StringBuffer();
    for (int i = 0; i < cleanNotation.length; i++) {
      if (cleanNotation[i] == '_' && i + 1 < cleanNotation.length) {
        final next = cleanNotation[i + 1];
        if (subMap.containsKey(next)) {
          sb.write(subMap[next]);
          i++;
          continue;
        }
      }
      sb.write(cleanNotation[i]);
    }
    var result = sb.toString();

    const upperVowels = ['\u0E34', '\u0E35', '\u0E36', '\u0E37', '\u0E31'];
    const tones = ['\u0E48', '\u0E49', '\u0E4A', '\u0E4B', '\u0E4C'];
    for (final v in upperVowels) {
      for (final t in tones) {
        while (result.contains('$v$t')) {
          result = result.replaceAll('$v$t', '$t$v');
        }
      }
    }

    result = result.replaceAll('_', '');
    return result;
  }

  void _checkCoverage(List<Offset> points) {
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
                    onPressed: _isTranslating ? null : _startPractice,
                    icon: _isTranslating
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : const Icon(Icons.play_arrow_rounded, size: 20),
                    label: Text(
                      _isTranslating ? 'กำลังแปลและจัดรูป...' : 'เริ่มฝึกเขียน',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _kPrimary,
                      foregroundColor: Colors.white,
                      disabledBackgroundColor: _kPrimary.withValues(alpha: 0.6),
                      disabledForegroundColor: Colors.white70,
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
          if (_lannaWord.isNotEmpty) ...[
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
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          _thaiWord,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 14,
                            color: Color(0xFF5D4037),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        if (_reading.isNotEmpty) ...[
                          const SizedBox(width: 8),
                          Text(
                            _reading,
                            style: const TextStyle(
                              fontSize: 12,
                              color: Color(0xFF8D6E63),
                              fontWeight: FontWeight.normal,
                            ),
                          ),
                        ],
                      ],
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
                          fontFamily: 'LNTilok',
                          fontSize: 24,
                          color: _kPrimary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    if (_meaning.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        _meaning,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 10.5,
                          color: const Color(0xFF7A5C3A).withValues(alpha: 0.8),
                        ),
                      ),
                    ],
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
                    const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.gesture_rounded,
                          size: 14,
                          color: Color(0xFF9E9E9E),
                        ),
                        SizedBox(width: 4),
                        Text(
                          'วาดตามแบบสีน้ำตาลอ่อนในกระดาน',
                          style: TextStyle(
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
                            fontFamily: 'LNTilok',
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

            // Bottom hint
            const Padding(
              padding: EdgeInsets.fromLTRB(20, 4, 20, 24),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.info_outline_rounded,
                    size: 12,
                    color: Color(0xFFBBAAA0),
                  ),
                  SizedBox(width: 4),
                  Text(
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

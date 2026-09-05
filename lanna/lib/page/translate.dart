import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:provider/provider.dart';
import 'package:permission_handler/permission_handler.dart';

import '../services/lanna_transliterator.dart';
import '../services/lanna_rules_data.dart';
import '../services/favorite_store.dart';
import '../services/api_service.dart';
import '../services/vocabulary_service.dart';
import '../services/translate_log_service.dart';
import '../services/auth_provider.dart';
import '../widgets/app_header.dart';
import '../core/api_config.dart';

const Color kPrimaryOrange = Color(0xFF924E19);

/// ================= MODEL =================

class LannaDictItem {
  final String? vocabId;
  final String category;
  final String lanna;
  final String reading;
  final String thaiSound;
  final String meaning;

  LannaDictItem({
    this.vocabId,
    required this.category,
    required this.lanna,
    required this.reading,
    required this.thaiSound,
    required this.meaning,
  });
}

class TranslatePage extends StatefulWidget {
  final bool isGuest;
  const TranslatePage({super.key, required this.isGuest});

  @override
  State<TranslatePage> createState() => _TranslatePageState();
}

class _TranslatePageState extends State<TranslatePage> {
  final _conv = LannaTransliterator();
  final _inputCtrl = TextEditingController();

  late final stt.SpeechToText _speech;

  bool _isListening = false;
  bool _speechReady = false;
  bool _thaiToLanna = true;
  bool _isFavorite = false;

  String _resultText = '';
  LannaDictItem? _matchingDictItem;
  bool _isTranslating = false;

  // Dictionary data — ใช้เพื่อ match ผลแปลการใน result section
  List<LannaDictItem> _dictItems = [];

  final _vocabService = VocabularyService();
  final _translateLogService = TranslateLogService();

  @override
  void initState() {
    super.initState();
    _speech = stt.SpeechToText();

    _initSpeech();
    _inputCtrl.addListener(_onInputEdited);
    _loadDictionaryData();
  }

  /// โหลดข้อมูลพจนานุกรมและตารางอักขระล้านนาเพื่อใช้ match ผลการแปล
  Future<void> _loadDictionaryData() async {
    if (!mounted) return;
    try {
      // โหลดพยัญชนะ สระ และไวยากรณ์จากฐานข้อมูล MySQL (`lanna_char`)
      await Future.wait([
        LannaTransliterator.loadFromDatabase(),
        LannaRulesData.loadFromDatabase(),
      ]);

      final dbVocabs = await _vocabService.getAllVocabulary();

      if (!mounted) return;
      setState(() {
        _dictItems = dbVocabs
            .map(
              (v) => LannaDictItem(
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
      debugPrint('Error loading dictionary: $e');
    }
  }

  // ⭐ FIX: initialize speech แค่ครั้งเดียว
  Future<void> _initSpeech() async {
    _speechReady = await _speech.initialize(
      onStatus: (status) {
        debugPrint('Speech status: $status');
        if (status == 'done' || status == 'notListening') {
          setState(() => _isListening = false);
        }
      },
      onError: (error) {
        debugPrint('Speech error: $error');
        setState(() => _isListening = false);
      },
    );

    debugPrint('Speech ready = $_speechReady');
  }

  @override
  void dispose() {
    _inputCtrl.dispose();
    _speech.stop();
    super.dispose();
  }

  // ================= TRANSLATE =================
  void _onInputEdited() {
    if (!mounted) return;
    setState(() {
      _resultText = '';
      _matchingDictItem = null;
      _isFavorite = false;
    });
  }

  Future<void> _translate() async {
    final input = _inputCtrl.text.trim();

    if (input.isEmpty) {
      setState(() {
        _resultText = '';
        _matchingDictItem = null;
        _isFavorite = false;
      });
      return;
    }

    LannaDictItem? matchedItem;
    final normalizedInput = input.trim().toLowerCase();

    // ตรวจสอบชนิดตัวอักษรของข้อมูลที่ป้อนเข้ามา
    final hasLannaChar = RegExp(r'[\u1A20-\u1AAF]').hasMatch(normalizedInput);
    final hasThaiChar = RegExp(r'[\u0E00-\u0E7F]').hasMatch(normalizedInput);

    // 1. ค้นหาคำตรงจากฐานข้อมูลจริง (MySQL Database: Vocabulary Table)
    for (var item in _dictItems) {
      final primaryCandidate = _thaiToLanna ? item.thaiSound : item.lanna;
      final secondaryCandidate = _thaiToLanna ? item.lanna : item.thaiSound;
      if (primaryCandidate.trim().toLowerCase() == normalizedInput) {
        matchedItem = item;
        break;
      } else if (secondaryCandidate.trim().toLowerCase() == normalizedInput) {
        matchedItem = item;
        break;
      }
    }

    // 2. ค้นหาจากคำอ่านที่ตรงกับคำทั้งหมดพอดี
    if (matchedItem == null) {
      for (var item in _dictItems) {
        if (item.reading.replaceAll(RegExp(r'[\[\]]'), '').trim().toLowerCase() == normalizedInput) {
          matchedItem = item;
          break;
        }
      }
    }

    // 3. ยิงค้นหาตรงแบบ Live จากฐานข้อมูล MySQL ทันที (ต้องตรงกับคำศัพท์แบบ Exact Match เท่านั้น)
    if (matchedItem == null) {
      try {
        final liveSearch = await _vocabService.searchVocabulary(input.trim());
        for (var v in liveSearch) {
          if (v.thaiWord.trim().toLowerCase() == normalizedInput ||
              v.lannaWord.trim() == normalizedInput ||
              v.reading.replaceAll(RegExp(r'[\[\]]'), '').trim().toLowerCase() == normalizedInput) {
            matchedItem = LannaDictItem(
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

    String result;
    if (matchedItem != null) {
      if (_thaiToLanna) {
        result = matchedItem.lanna;
      } else {
        result = matchedItem.thaiSound;
      }
    } else {
      if (_thaiToLanna) {
        result = _translateCharByChar(input);
      } else {
        // หากผู้ใช้พิมพ์ภาษาไทยเข้ามาขณะอยู่ในโหมด ล้านนา -> ไทย
        if (!hasLannaChar && hasThaiChar) {
          result = input;
        } else {
          result = _conv.lannaToThai(input);
        }
      }
    }
    var needsReview = matchedItem == null;

    // 3. ใช้ AI (Gemini Flash Live) วิเคราะห์คำเมืองและจัดรูปอักขระล้านนาอัตโนมัติ
    if (_thaiToLanna && needsReview) {
      setState(() => _isTranslating = true);
      try {
        final aiResult = await _callGeminiAi(input);
        if (aiResult != null && mounted) {
          final notation = aiResult['lanna_notation']?.toString() ??
              aiResult['kam_mueang']?.toString() ??
              input;
          result = _parseLannaNotation(notation);
          matchedItem = LannaDictItem(
            category: '✨ แปลด้วย AI (Gemini Flash)',
            lanna: result,
            reading: aiResult['phonetic']?.toString() ?? '[$input]',
            thaiSound: input,
            meaning: aiResult['meaning']?.toString() ??
                'แปลและจัดอักขรวิธีล้านนาด้วย AI',
          );
        } else {
          // Fallback: ใช้กฎการแปลคำเมืองออฟไลน์ (Offline Kam Mueang Engine)
          final offlineKamMueang = _translateKamMueangOffline(input);
          result = _parseLannaNotation(offlineKamMueang['notation']!);
          matchedItem = LannaDictItem(
            category: 'กฎไวยากรณ์คำเมืองล้านนา',
            lanna: result,
            reading: offlineKamMueang['reading']!,
            thaiSound: input,
            meaning: 'แปลตามหลักไวยากรณ์และอักขรวิธีคำเมือง',
          );
        }
      } catch (error) {
        debugPrint('Gemini translation error: $error');
        final offlineKamMueang = _translateKamMueangOffline(input);
        result = _parseLannaNotation(offlineKamMueang['notation']!);
        matchedItem = LannaDictItem(
          category: 'กฎไวยากรณ์คำเมืองล้านนา',
          lanna: result,
          reading: offlineKamMueang['reading']!,
          thaiSound: input,
          meaning: 'แปลตามหลักไวยากรณ์และอักขรวิธีคำเมือง',
        );
      } finally {
        if (mounted) setState(() => _isTranslating = false);
      }
    }
    if (!mounted) return;
    final store = context.read<FavoriteStore>();
    final key = _thaiToLanna ? input : result;

    setState(() {
      _resultText = result;
      _matchingDictItem = matchedItem;
      _isFavorite = store.contains(key);
    });

    _saveTranslateLog(input, result);
  }

  Future<void> _saveTranslateLog(String input, String output) async {
    if (input.isEmpty || output.isEmpty) return;

    try {
      final sessionType = await ApiService.getSessionType();
      String userId = 'guest';
      if (sessionType == 'admin') {
        final admin = await ApiService.getCachedAdmin();
        userId = admin?.adminId ?? 'admin';
      } else if (sessionType == 'user') {
        final user = await ApiService.getCachedUser();
        userId = user?.userId ?? 'user';
      }

      await _translateLogService.createLog(
        userId,
        input,
        output,
        categoryVocabId: _matchingDictItem?.category,
      );
      debugPrint('Logged translation: $input -> $output for user: $userId');
    } catch (e) {
      debugPrint('Failed to create translation log: $e');
    }
  }

  String _translateCharByChar(String text) {
    return _thaiToLanna ? _conv.thaiToLanna(text) : _conv.lannaToThai(text);
  }

  /// แปลงภาษาไทยเป็นภาษาคำเมืองแท้แบบออฟไลน์
  Map<String, String> _translateKamMueangOffline(String thaiText) {
    var km = thaiText.trim();
    const phraseDict = {
      // คำทักทายและการสนทนา
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
    };

    // จัดเรียงจากคำยาวไปคำสั้น เพื่อให้คำผสมถูกแปลก่อนคำเดี่ยว
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
    };

    final reading = readingMap[km] ?? (km.isNotEmpty ? '[$km]' : '');

    return {
      'kam_mueang': km,
      'notation': notation,
      'reading': reading,
    };
  }

  /// แปลง Notation จาก AI ที่มีขีดล่าง _ ให้เป็นอักขระ LN-TILOK และสลับวรรณยุกต์ยกสูง
  String _parseLannaNotation(String notation) {
    const subMap = {
      'ก': '\uF001', 'ข': '\uF002', 'ฃ': '\uF003', 'ค': '\uF004', 'ฅ': '\uF005', 'ฆ': '\uF006',
      'ง': '\uF007', 'จ': '\uF008', 'ฉ': '\uF009', 'ช': '\uF00A', 'ซ': '\uF00B', 'ฌ': '\uF00C',
      'ญ': '\uF00D', 'ฎ': '\uF00E', 'ฏ': '\uF00F', 'ฐ': '\uF010', 'ฑ': '\uF011', 'ฒ': '\uF012',
      'ณ': '\uF013', 'ด': '\uF014', 'ต': '\uF015', 'ถ': '\uF016', 'ท': '\uF017', 'ธ': '\uF018',
      'น': '\uF019', 'บ': '\uF01A', 'ป': '\uF01B', 'ผ': '\uF01C', 'ฝ': '\uF01D', 'พ': '\uF01E',
      'ฟ': '\uF01F', 'ภ': '\uF020', 'ม': '\uF021', 'ย': '\uF022', 'ร': '\uF023', 'ฤ': '\uF024',
      'ล': '\uF025', 'ฦ': '\uF026', 'ว': '\uF027', 'ศ': '\uF028', 'ษ': '\uF029', 'ส': '\uF02A',
      'ห': '\uF02B', 'ฬ': '\uF02C', 'อ': '\uF02D', 'ฮ': '\uF02E',
      'สฺส': '\u00AA',
    };

    // 1. จัดการสระเอียล้านนา: สระเอียในตั๋วเมืองแท้ใช้ สระอี + ย ห้อย (ไม่ใช้สระ เ ด้านหน้า เพื่อไม่ให้ทับซ้อนกัน)
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

    // 2. สลับลำดับสระบนและวรรณยุกต์ เพื่อให้วรรณยุกต์ลอยขึ้นไปบนชั้น 4 ไม่ทับซ้อนกับสระบนชั้น 3
    const upperVowels = ['\u0E34', '\u0E35', '\u0E36', '\u0E37', '\u0E31']; // ิ, ี, ึ, ื, ั
    const tones = ['\u0E48', '\u0E49', '\u0E4A', '\u0E4B', '\u0E4C']; // ่, ้, ๊, ๋, ์
    for (final v in upperVowels) {
      for (final t in tones) {
        while (result.contains('$v$t')) {
          result = result.replaceAll('$v$t', '$t$v');
        }
      }
    }

    // 3. ลบเครื่องหมาย _ ที่อาจหลงเหลืออยู่ออกให้หมด
    result = result.replaceAll('_', '');

    return result;
  }

  /// เรียก Gemini Flash AI Live
  Future<Map<String, dynamic>?> _callGeminiAi(String promptText) async {
    final apiKey = ApiConfig.geminiApiKey;
    const models = ['gemini-flash-lite-latest', 'gemini-3.5-flash', 'gemini-flash-latest'];
    const promptInstructions = '''
คุณคือผู้เชี่ยวชาญระดับศาสตราจารย์ด้านภาษาศาสตร์ล้านนา อักขรวิธีตั๋วเมืองตามตำราพจนานุกรมล้านนา มรภ.เชียงใหม่ (หน้า 17-22) และคู่มือฟอนต์ LN-TILOK มหาวิทยาลัยเชียงใหม่

จงแปลข้อความภาษาไทยเป็นภาษาคำเมืองแท้ ถอดคำอ่านสำเนียงคำเมือง และระบุโครงสร้างอักขระล้านนา (LN-TILOK Notation)

กฎการแปลคำเมืองแท้และสรรพนาม:
* สรรพนาม: "เธอ / คุณ / ตัวเอง" แปลว่า "ตั๋ว" (ห้ามแปลว่า "เปิ้น" เด็ดขาด เพราะ "เปิ้น" หมายถึง ฉัน/เขา/คนอื่น)
* สรรพนาม: "ฉัน / เรา" แปลว่า "เฮา", "ข้าเจ้า" หรือ "เปิ้น"
* คำทักทายตามช่วงเวลา:
  - "สวัสดีตอนเช้า" แปลเป็น "สวัสดีตอนเจ้า" หรือ "สวัสสดีต๋อนเจ๊า" (คำอ่าน: [สวัสดีตอนเจ้า] หรือ [สวัสสดีตอนเจ้า], ตั๋วเมือง: "ส_วั\\u00AAดีตอ_นเจ้_า")
  - "ตอนเช้า" แปลเป็น "ตอนเจ้า" หรือ "ต๋อนเจ๊า" (คำอ่าน: [ตอนเจ้า])
  - "สวัสดีตอนเย็น" แปลเป็น "สวัสดีตอนแลง" หรือ "สวัสสดีต๋อนแลง" (คำอ่าน: [สวัสดีตอนแลง])
  - "ตอนเย็น" แปลเป็น "ตอนแลง"
  - "เช้า" แปลเป็น "เจ้า" / "เจ๊า"
  - "เย็น" แปลเป็น "แลง"
* คำสั่งห้าม/ปฏิเสธ "อย่า..." ในภาษาคำเมืองแท้ให้ใช้ "จะไป..." หรือ "จะไปดี...":
  - "อย่าไป" แปลว่า "จะไปไป" (คำอ่าน: [จะ-ไป-ไป], ตั๋วเมือง: "จะไ_ปไ_ป") หรือ "จะไปดีไป" / "บ่าต้องไป"
  - "อย่ามา" แปลว่า "จะไปมา" (คำอ่าน: [จะ-ไป-มา], ตั๋วเมือง: "จะไ_ปมา") หรือ "จะไปดีมา" / "บ่าต้องมา"
  - "อย่าทำ" แปลว่า "จะไปยะ" (คำอ่าน: [จะ-ไป-ยะ]) หรือ "จะไปดียะ"
  - "อย่ากิน" แปลว่า "จะไปกิ๋น" (คำอ่าน: [จะ-ไป-กิ๋น])
  - "อย่าพูด" แปลว่า "จะไปอู้" (คำอ่าน: [จะ-ไป-อู้])
  - "ห้ามไป" แปลว่า "บ่ดีไป" หรือ "บ่หื้อไป" (คำอ่าน: [บ่-ดี-ไป])
  - "ไม่ต้องไป" แปลว่า "บ่ต้องไป" (คำอ่าน: [บ่-ต้อง-ไป])
  - "ไม่..." แปลว่า "บ่..." หรือ "บ่า..."
* กฎชื่อผลไม้และพืชผักพื้นเมืองล้านนา (คนเหนือใช้ "บ่า..." หรือ "บะ..." นำหน้า ห้ามใช้ภาษาอีสาน เช่น ห้ามใช้คำว่า บัก... เด็ดขาด):
  - "สับปะรด" แปลว่า "บ่าขะนัด" (คำอ่าน: [บ่า-ขะ-นัด], ตั๋วเมือง: "บ่าขะนั_ด") ห้ามแปลว่า บักนัด เด็ดขาด
  - "กระท้อน" แปลว่า "บ่าต้อง" หรือ "บ่าตื๋น" (คำอ่าน: [บ่า-ต้อง] หรือ [บ่า-ตื๋น], ตั๋วเมือง: "บ่าต้อ_ง")
  - "มะม่วง" แปลว่า "บ่าม่วง" (คำอ่าน: [บ่า-ม่วง], ตั๋วเมือง: "บ่ามั_ว่_ง")
  - "มะละกอ" แปลว่า "บ่าก้วยเต้ด" (คำอ่าน: [บ่า-ก้วย-เต้ด], ตั๋วเมือง: "บ่าก_ว้_ยเต้_ด")
  - "ฝรั่ง" แปลว่า "บ่าก้วยก๋า" (คำอ่าน: [บ่า-ก้วย-ก๋า], ตั๋วเมือง: "บ่าก_ว้_ยก๋า")
  - "ฟักทอง" แปลว่า "บ่าน้ำแก้ว" (คำอ่าน: [บ่า-น้ำ-แก้ว], ตั๋วเมือง: "บ่าน้ำแก้_ว")
  - "ขนุน" แปลว่า "บ่าหนุน" (คำอ่าน: [บ่า-หนุน], ตั๋วเมือง: "บ่าห_นุ_น")
  - "น้อยหน่า" แปลว่า "บ่าน่อแน่" (คำอ่าน: [บ่า-น่อ-แน่])
  - "มะเขือเทศ" แปลว่า "บ่าเขือส้ม" (คำอ่าน: [บ่า-เขือ-ส้ม])
  - "มะยม" แปลว่า "บ่ายม", "มะนาว" แปลว่า "บ่านาว", "มะขาม" แปลว่า "บ่าขาม", "มะเขือ" แปลว่า "บ่าเขือ"
* "อะไร" แปลว่า "อะหยัง" หรือ "หยัง"
* "หมด / หมดแล้ว" แปลว่า "เสี้ยง / เสี้ยงแล้ว" (คำอ่าน: [เสี้ยง] / [เสี้ยง-แล้ว], ตั๋วเมือง: "สี้_ย_ง" / "สี้_ย_งแล้_ว") ห้ามแปลเป็น ตายลืม หรือ ต๋ายลืม เด็ดขาด
* "กินหมด" แปลว่า "กิ๋นเสี้ยง" (คำอ่าน: [กิ๋น-เสี้ยง])
* "วันนี้เธอกินข้าวกับอะไร" แปลเป็น "วันนี้ตั๋วกิ๋นข้าวกับหยัง" (คำอ่าน: [วัน-นี้-ตั๋ว-กิ๋น-ข้าว-กับ-หยัง])
* "ขอบคุณมาก / ขอบคุณมากๆ" แปลเป็น "ขอบคุณจ๊าดนัก" หรือ "ยินดีจ๊าดนัก" (ห้ามแปลเป็น นักๆ)
* "กินข้าวไหม / กินข้าวหรือยัง" แปลเป็น "กิ๋นข้าวก่อ / กิ๋นข้าวแล้วกา"
* "ไปเที่ยวไหน" แปลเป็น "ไปแอ่วไหน"
* "ทำอะไร" แปลเป็น "ยะหยัง"
* "สบายดีไหม" แปลเป็น "สบายดีก่อ"

กฎเหล็ก 4 ชั้น (4 Vertical Layers) ตามตำราหน้า 17-22:
1. เขียนอักษรชิดติดกันต่อเนื่อง ห้ามเคาะเว้นวรรคระหว่างพยางค์ (เช่น "ขอบ_คุณจ้า_ดนั_ก")
2. เครื่องหมายขีดล่าง "_" ให้ใส่เฉพาะหน้าพยัญชนะที่เป็น "ตัวสะกดท้ายพยางค์" หรือ "พยัญชนะซ้อนสังโยค/อักษรนำ" เท่านั้น เช่น:
   * มหาวิทยาลัยเชียงใหม่ -> "มหาวิท_ยาลั_ยช_ย_งให_ม_่"
   * วัดพระสิงห์ วรมหาวิหาร -> "วั_ดพ_ระสิ_งห์ วรมหาวิหา_ร"
   * วัดมหาวัน -> "วั_ดมหาว_น"
   * ขอสืบสานอักษรล้านนา -> "ขอสื_บสา_นอัก_ษ_รล้า_นนา"
   * คนเมืองอู้เมือง เขียนตั๋วเมือง -> "ค_นเมื_องอู้เมื_อง ขี้_ย_นตั๋_วเมื_อง"
   * สวัสดี -> "ส_วั" + "\\u00AA" + "ดี"
   * วัดป่าอ้อเมืองอินทร์ -> "วั_ดป่าอ้อเมื_องอิ_นท_ร์"
   * วัดมังคลถาวรราม -> "วั_ดมั_งคลถาวรา_ม"
   * ชีวิตธรรมดา -> "ชีวิตธ_มดา"
   * วันนี้ -> "วั_นนี้"
   * ตั๋ว -> "ตั๋_ว"
   * อย่าไป -> "จะไปไป" (ห้ามใส่ _ หน้า ป ในคำว่า "ไป" เพราะ ป เป็นพยัญชนะต้น)
   * อย่ามา -> "จะไปมา" (ห้ามใส่ _ หน้า ป ในคำว่า "ไป" เพราะ ป เป็นพยัญชนะต้น)
   * บ่ดีไป -> "บ่ดีไป"
   * บ่ต้องไป -> "บ่ต้อ_งไป"
   * กินข้าว -> "กิ๋_นข้า_ว"
   * กับหยัง -> "กั_บห_ยั_ง"
   * แม่ กก: ผัก -> "ผั_ก", นก -> "น_ก", ลูก -> "ลู_ก"
   * แม่ กง: กงหาง -> "ก_งหา_ง", สอง -> "ส_ง", เมือง -> "เมื_อง"
   * แม่ กด: วัด -> "วั_ด", ปิด -> "ปิ_ด", มด -> "ม_ด"
   * แม่ กน: กิ๋น -> "กิ๋_น", บ้าน -> "บ้า_น", น่าน -> "น่า_น"
   * แม่ กบ: สบ -> "ส_บ", แอบ -> "แ_อบ", กับ -> "กั_บ"
   * แม่ กม: งาม -> "งา_ม", สาม -> "สา_ม"
   * แม่ เกย: โตย -> "โต_ย", ดอย -> "ด_อย"
   * แม่ เกอว: แมว -> "แม_ว", ข้าว -> "ข้า_ว", แอ่ว -> "แอ่_ว", ตั๋ว -> "ตั๋_ว"
   * อักษรนำ/ควบ: หมา -> "ห_มา", พระ -> "พ_ระ", แพร่ -> "แ_พ_ล่", ฉลาด -> "จ_รา_ด" (คำอ่าน: "[จะ-หลาด]"), ตลาด -> "ต_ลา_ด" (คำอ่าน: "[ตะ-หลาด]")
   * ตัวอย่างชื่อบ้าน-นามเมือง: ท่าวังผา -> "ท่าวั_งผา", เวียงสา -> "ว_ย_งสา", สบปราบ -> "ส_บปา_บ", สันกำแพง -> "สั_นก_ำแ_พ_ง", น่าน -> "น่า_น", ลำปาง -> "ลำพา_ง", แม่ฮ่องสอน -> "แ_ม_่ร_่อ_งส_่อร", พะเยา -> "พยา \\uF027", สารภี -> "สารพ_ี", สอง -> "ส_รอ_ง"
3. ข้อห้ามเด็ดขาด:
   * ห้ามใส่ "_" หน้าพยัญชนะต้นของคำทั่วไป เช่น "ไป", "มา", "ดี", "บ่", "จะ" (ให้เขียน "จะไปไป", "จะไปมา" ห้ามเขียน "จะไ_ป" เด็ดขาด)
   * ห้ามใส่ "_" หน้าสระเด็ดขาด (ห้าม _า, _ิ, _ี, _เ, _แ, _โ, _อ, _ไ, _ั, _ุ, _ู)
   * ห้ามใส่ "_" ในฟิลด์ phonetic เด็ดขาด! (คำอ่านต้องเป็นตัวอักษรไทยล้วน เช่น "[จะ-ไป-ไป]" หรือ "[จะ-ไป-มา]")
4. สระหน้า (เ, แ, โ, ใ, ไ) ต้องวางหน้าพยัญชนะต้นเสมอ

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
                    'text': '$promptInstructions\n\nข้อความภาษาไทยที่ต้องการแปล: "$promptText"'
                  }
                ]
              }
            ]
          }),
        ).timeout(const Duration(seconds: 20));

        if (res.statusCode == 200) {
          final data = jsonDecode(res.body);
          final raw = data['candidates'][0]['content']['parts'][0]['text'] as String;
          final cleanJson = raw.replaceAll('```json', '').replaceAll('```', '').trim();
          return jsonDecode(cleanJson) as Map<String, dynamic>;
        }
      } catch (e) {
        debugPrint('Gemini AI Call error with model $model: $e');
      }
    }
    return null;
  }

  // ================= MIC =================
  Future<void> _toggleMic() async {
    final status = await Permission.microphone.request();
    if (!mounted) return;
    if (!status.isGranted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('กรุณาอนุญาตการใช้ไมโครโฟน')),
      );
      return;
    }

    if (_isListening) {
      await _speech.stop();
      setState(() => _isListening = false);
      return;
    }

    if (!_speechReady) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Speech service ยังไม่พร้อม')),
      );
      return;
    }

    setState(() {
      _isListening = true;
    });

    await _speech.listen(
      localeId: 'th-TH',
      listenOptions: stt.SpeechListenOptions(
        listenMode: stt.ListenMode.dictation,
        partialResults: true,
      ),
      onResult: (result) {
        setState(() {
          _inputCtrl.text = result.recognizedWords;
          _inputCtrl.selection = TextSelection.collapsed(
            offset: _inputCtrl.text.length,
          );
        });
      },
    );
  }

  // ================= FAVORITE =================
  void _toggleFavorite() {
    final auth = context.read<AuthProvider>();
    if (!auth.isLoggedIn) {
      _showLoginRequiredAlert(context);
      return;
    }

    final input = _inputCtrl.text.trim();
    if (input.isEmpty) return;

    final store = context.read<FavoriteStore>();
    final thai = _thaiToLanna ? input : _resultText;

    LannaDictItem? matchingDictItem;
    final normalizedThai = thai.trim().toLowerCase();
    final normalizedInput = input.toLowerCase();
    for (var item in _dictItems) {
      if (item.thaiSound.trim().toLowerCase() == normalizedThai ||
          item.lanna.trim().toLowerCase() == normalizedInput) {
        matchingDictItem = item;
        break;
      }
    }

    final lanna = _thaiToLanna
        ? _resultText
        : (matchingDictItem?.lanna ??
            (RegExp(r'[\u0E00-\u0E7F]').hasMatch(input)
                ? _conv.thaiToLanna(input)
                : input));

    if (_isFavorite) {
      store.remove(thai);
    } else {
      store.add(
        FavoriteItem(
          thai: thai,
          lanna: lanna,
          roman: matchingDictItem?.reading ?? thai,
          vocabId: matchingDictItem?.vocabId,
        ),
      );
    }

    setState(() => _isFavorite = !_isFavorite);
  }

  void _showLoginRequiredAlert(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          'กรุณาเข้าสู่ระบบ',
          style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700),
        ),
        content: const Text(
          'คุณต้องเข้าสู่ระบบหรือสมัครสมาชิกก่อน จึงจะสามารถใช้งานระบบรายการโปรดได้',
          style: TextStyle(
            fontSize: 10,
            height: 1.4,
            fontWeight: FontWeight.w500,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text(
              'ยกเลิก',
              style: TextStyle(fontSize: 10, fontWeight: FontWeight.w500),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              Navigator.of(context, rootNavigator: true).pushNamed('/login');
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
        ],
      ),
    );
  }

  // ================= UI =================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFFBF7),
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            const AppHeader(title: 'แปลภาษาล้านนา'),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _inputBox(),
                    const SizedBox(height: 16),
                    FilledButton.icon(
                      onPressed: (_inputCtrl.text.trim().isEmpty || _isTranslating)
                          ? null
                          : _translate,
                      icon: _isTranslating
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : const Icon(Icons.translate_rounded),
                      label: Text(
                        _isTranslating ? 'กำลังแปลด้วย AI...' : 'แปลภาษาล้านนา',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      style: FilledButton.styleFrom(
                        backgroundColor: kPrimaryOrange,
                        foregroundColor: Colors.white,
                        disabledBackgroundColor: const Color(0xFFEADBC8),
                        minimumSize: const Size.fromHeight(48),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    _resultSection(),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ================= ACTION BUTTONS =================
  Widget _circularActionButton({
    required IconData icon,
    required Color color,
    required Color bgColor,
    required VoidCallback onTap,
  }) {
    return Material(
      color: bgColor,
      shape: const CircleBorder(),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Container(
          width: 42,
          height: 42,
          alignment: Alignment.center,
          child: Icon(icon, size: 20, color: color),
        ),
      ),
    );
  }

  // ================= INPUT BOX =================
  Widget _inputBox() {
    final hasText = _inputCtrl.text.isNotEmpty;
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: hasText
              ? kPrimaryOrange.withValues(alpha: 0.6)
              : const Color(0xFFEADBC8),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: hasText
                ? kPrimaryOrange.withValues(alpha: 0.05)
                : Colors.black.withValues(alpha: 0.02),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _thaiToLanna ? 'ข้อความภาษาไทย' : 'ข้อความภาษาล้านนา',
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: Color(0xFF2D1A00),
            ),
          ),
          const SizedBox(height: 12),
          Stack(
            alignment: Alignment.bottomRight,
            children: [
              Padding(
                padding: const EdgeInsets.only(bottom: 40),
                child: TextField(
                  controller: _inputCtrl,
                  maxLines: null,
                  minLines: 1,
                  textInputAction: TextInputAction.send,
                  onSubmitted: (_) {
                    if (_inputCtrl.text.trim().isNotEmpty && !_isTranslating) {
                      _translate();
                    }
                  },
                  style: const TextStyle(
                    fontSize: 16,
                    height: 1.4,
                    color: Color(0xFF2D1A00),
                    fontFamilyFallback: ['LNTilok'],
                  ),
                  decoration: InputDecoration(
                    hintText: _thaiToLanna
                        ? 'พิมพ์ข้อความภาษาไทยที่นี่...'
                        : 'พิมพ์ข้อความภาษาไทย หรือ อักขระล้านนา...',
                    hintStyle: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w400,
                      color: const Color(0xFF7A5C3A).withValues(alpha: 0.5),
                    ),
                    border: InputBorder.none,
                    isDense: true,
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  if (hasText) ...[
                    _circularActionButton(
                      icon: Icons.clear_rounded,
                      color: const Color(0xFF7A5C3A),
                      bgColor: const Color(0xFFFFF8F2),
                      onTap: () {
                        setState(() {
                          _inputCtrl.clear();
                          _resultText = '';
                          _isFavorite = false;
                        });
                      },
                    ),
                    const SizedBox(width: 12),
                  ],
                  _circularActionButton(
                    icon: _isListening ? Icons.mic : Icons.mic_none_rounded,
                    color: _isListening ? Colors.white : kPrimaryOrange,
                    bgColor: _isListening
                        ? kPrimaryOrange
                        : const Color(0xFFFFF3E0),
                    onTap: _toggleMic,
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ================= RESULT =================
  Widget _resultSection() {
    final bool hasText = _resultText.isNotEmpty;
    final dictItem = _matchingDictItem;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFF5E6D3), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF8B5A2B).withValues(alpha: 0.05),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_isTranslating) ...[
            const LinearProgressIndicator(
              color: Color(0xFF924E19),
              backgroundColor: Color(0xFFFFF3E0),
            ),
            const SizedBox(height: 12),
          ],
          if (_thaiToLanna)
            Row(
              children: [
                Expanded(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Text(
                      dictItem != null && dictItem.category.isNotEmpty
                          ? 'ผลลัพธ์อักขระล้านนา (${dictItem.category})'
                          : 'ผลลัพธ์อักขระล้านนา (ตั๋วเมือง)',
                      maxLines: 1,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF7A5C3A),
                      ),
                    ),
                  ),
                ),
                TextButton(
                  onPressed: _showTransliterationInfo,
                  style: TextButton.styleFrom(
                    foregroundColor: const Color(0xFF924E19),
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    minimumSize: const Size(0, 32),
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: const Text(
                    'ถอดอักษรตามหลักวิธี',
                    style: TextStyle(fontSize: 9, fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            )
          else
            const Text(
              'ผลลัพธ์ภาษาไทย',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: Color(0xFF7A5C3A),
              ),
            ),
          const SizedBox(height: 20),

          if (_thaiToLanna && hasText) ...[
            Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(minHeight: 90),
                child: Center(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      _thaiToLanna
                          ? _conv.toTilokFontString(
                              (dictItem?.lanna.isNotEmpty ?? false)
                                  ? dictItem!.lanna
                                  : (_resultText.isNotEmpty
                                      ? _resultText
                                      : _inputCtrl.text.trim()),
                              _inputCtrl.text.trim(),
                            )
                          : (dictItem?.thaiSound ?? _resultText),
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 46,
                        height: 1.35,
                        fontFamily: 'LNTilok',
                        fontFamilyFallback: ['LN TILOK', 'PayapLanna'],
                        color: Color(0xFFE16905),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 18),
            const Divider(color: Color(0xFFF0E1D0), height: 1),
            const SizedBox(height: 18),
            const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.record_voice_over_rounded,
                  size: 18,
                  color: Color(0xFF924E19),
                ),
                SizedBox(width: 7),
                Text(
                  'คำอ่าน (Pronunciation)',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF7A5C3A),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: Text(
                dictItem != null && dictItem.reading.isNotEmpty
                    ? (dictItem.reading.startsWith('[')
                        ? dictItem.reading
                        : '[${dictItem.reading}]')
                    : '[${_inputCtrl.text.trim()}]',
                textAlign: TextAlign.center,
                softWrap: true,
                style: const TextStyle(
                  fontSize: 16,
                  height: 1.5,
                  color: Color(0xFFE16905),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(height: 20),
            const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.menu_book_rounded,
                  size: 18,
                  color: Color(0xFF924E19),
                ),
                SizedBox(width: 7),
                Text(
                  'ความหมาย',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF7A5C3A),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: Text(
                dictItem != null && dictItem.meaning.isNotEmpty
                    ? dictItem.meaning
                    : 'ผลถอดอักษรอัตโนมัติ โปรดตรวจสอบ',
                textAlign: TextAlign.center,
                softWrap: true,
                style: const TextStyle(
                  fontSize: 14,
                  height: 1.5,
                  color: Color(0xFF2D1A00),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ] else ...[
            Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(minHeight: 60),
                child: Center(
                  child: Text(
                    _resultText.isEmpty ? '—' : _resultText,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 32,
                      height: 1.35,
                      color: Color(0xFFE16905),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
            if (hasText && dictItem != null && dictItem.meaning.isNotEmpty) ...[
              const SizedBox(height: 18),
              const Divider(color: Color(0xFFF0E1D0), height: 1),
              const SizedBox(height: 18),
              const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.menu_book_rounded,
                    size: 18,
                    color: Color(0xFF924E19),
                  ),
                  SizedBox(width: 7),
                  Text(
                    'ความหมาย',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF7A5C3A),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                child: Text(
                  dictItem.meaning,
                  textAlign: TextAlign.center,
                  softWrap: true,
                  style: const TextStyle(
                    fontSize: 14,
                    height: 1.5,
                    color: Color(0xFF2D1A00),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ],

          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              _circularActionButton(
                icon: _isFavorite
                    ? Icons.star_rounded
                    : Icons.star_border_rounded,
                color: hasText
                    ? (_isFavorite
                          ? const Color(0xFFFFB300)
                          : const Color(0xFFE16905))
                    : Colors.grey.shade400,
                bgColor: hasText
                    ? const Color(0xFFFFF3E0)
                    : Colors.grey.shade100,
                onTap: hasText ? _toggleFavorite : () {},
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showTransliterationInfo() {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text(
          'ถอดอักษรตามหลักวิธี',
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
        ),
        content: const Text(
          'ระบบเลือกใช้รูปคำจากพจนานุกรมล้านนาก่อน '
          'และใช้กฎอักขรวิทยาล้านนาสำหรับคำที่ไม่พบในพจนานุกรม',
          style: TextStyle(fontSize: 11, height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('ตกลง'),
          ),
        ],
      ),
    );
  }
}

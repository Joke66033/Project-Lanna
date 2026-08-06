import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:flutter_tts/flutter_tts.dart';
import 'package:provider/provider.dart';
import 'package:permission_handler/permission_handler.dart';

import '../services/lanna_transliterator.dart';
import '../services/favorite_store.dart';
import '../services/api_service.dart';
import '../services/vocabulary_service.dart';
import '../services/translate_log_service.dart';
import '../services/auth_provider.dart';
import '../widgets/app_header.dart';

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
  final FlutterTts _tts = FlutterTts();

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
    _initTts();
    _inputCtrl.addListener(_onInputEdited);
    _loadDictionaryData();
  }

  /// โหลดข้อมูลพจนานุกรมเพื่อใช้ match ผลการแปล
  Future<void> _loadDictionaryData() async {
    if (!mounted) return;
    try {
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

  Future<void> _initTts() async {
    await _tts.setLanguage('th-TH');
    await _tts.setSpeechRate(0.45);
    await _tts.setPitch(1.0);
    await _tts.setVolume(1.0);

    // ⭐ สำคัญมากสำหรับ Android
    await _tts.awaitSpeakCompletion(false);
  }

  @override
  void dispose() {
    _inputCtrl.dispose();
    _speech.stop();
    _tts.stop();
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

    // 1. ค้นหาคำตรงในพจนานุกรม
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

    // 2. ค้นหาจากความหมาย
    if (matchedItem == null) {
      final directDefPattern = RegExp(
        r'^([a-zA-Zก-ฮ]+\.\s*)?' + RegExp.escape(normalizedInput) + r'(\s*|;|,|$)',
        caseSensitive: false,
      );

      for (var item in _dictItems) {
        if (directDefPattern.hasMatch(item.meaning.trim()) ||
            item.meaning.trim().toLowerCase() == normalizedInput) {
          matchedItem = item;
          break;
        }
      }
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

    // Only call remote translation API if we don't have a verified dictionary match
    if (_thaiToLanna && needsReview) {
      setState(() => _isTranslating = true);
      try {
        final apiResult = await _vocabService.translate(input);
        if (!mounted) return;
        result = apiResult['lanna_word']?.toString() ?? result;
        needsReview = apiResult['needs_review'] as bool? ?? needsReview;
        matchedItem = LannaDictItem(
          category: needsReview ? 'ผลลัพธ์อัตโนมัติ' : 'พจนานุกรม',
          lanna: result,
          reading: apiResult['reading']?.toString() ?? '[$input]',
          thaiSound: input,
          meaning:
              apiResult['meaning']?.toString() ??
              (needsReview ? 'ผลถอดอักษรอัตโนมัติ โปรดตรวจสอบ' : ''),
        );
      } catch (error) {
        debugPrint(
          'Hybrid translation API unavailable; using local fallback: $error',
        );
      } finally {
        if (mounted) setState(() => _isTranslating = false);
      }
    }
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

  // ================= TTS =================
  Future<void> _speak() async {
    if (_resultText.isEmpty) return;

    final textToSpeak = _thaiToLanna ? _inputCtrl.text : _resultText;

    await _tts.stop();
    await _tts.speak(textToSpeak);
  }

  Future<void> _speakReading(String reading) async {
    if (reading.isEmpty) return;

    await _tts.stop();
    await _tts.setLanguage('th-TH');
    await _tts.setSpeechRate(0.45);
    await _tts.setPitch(1.0);
    await _tts.speak(reading);
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
                    _languageToggle(),
                    const SizedBox(height: 16),
                    _inputBox(),
                    const SizedBox(height: 16),
                    FilledButton.icon(
                      onPressed: _inputCtrl.text.trim().isEmpty
                          ? null
                          : _translate,
                      icon: const Icon(Icons.translate_rounded),
                      label: const Text('แปล'),
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

  // ================= LANGUAGE TOGGLE =================
  Widget _languageToggle() {
    return Container(
      height: 48,
      decoration: BoxDecoration(
        color: const Color(0xFFF5EFE9), // Soft warm cream grey
        borderRadius: BorderRadius.circular(16),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.maxWidth / 2;
          return Stack(
            children: [
              // Sliding Active Tab Indicator
              AnimatedPositioned(
                duration: const Duration(milliseconds: 250),
                curve: Curves.easeInOutCubic,
                left: _thaiToLanna ? 4 : width - 4,
                top: 4,
                bottom: 4,
                width: width,
                child: Container(
                  decoration: BoxDecoration(
                    color: kPrimaryOrange,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: kPrimaryOrange.withValues(alpha: 0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                ),
              ),
              // Tab text buttons
              Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () {
                        if (_thaiToLanna) return;
                        setState(() {
                          _thaiToLanna = true;
                          _resultText = '';
                          _matchingDictItem = null;
                          _isFavorite = false;
                        });
                      },
                      child: Center(
                        child: AnimatedDefaultTextStyle(
                          duration: const Duration(milliseconds: 200),
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: _thaiToLanna
                                ? Colors.white
                                : const Color(0xFF7A5C3A),
                          ),
                          child: const Text('ไทย → ล้านนา'),
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () {
                        if (!_thaiToLanna) return;
                        setState(() {
                          _thaiToLanna = false;
                          _resultText = '';
                          _matchingDictItem = null;
                          _isFavorite = false;
                        });
                      },
                      child: Center(
                        child: AnimatedDefaultTextStyle(
                          duration: const Duration(milliseconds: 200),
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: !_thaiToLanna
                                ? Colors.white
                                : const Color(0xFF7A5C3A),
                          ),
                          child: const Text('ล้านนา → ไทย'),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          );
        },
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
                  style: TextStyle(
                    fontSize: _thaiToLanna ? 16 : 22,
                    height: _thaiToLanna ? 1.4 : 1.6,
                    color: const Color(0xFF2D1A00),
                    fontFamily: _thaiToLanna ? null : 'PayapLanna',
                    fontFamilyFallback: _thaiToLanna
                        ? null
                        : const ['PayapLanna', 'PayapLanna'],
                  ),
                  decoration: InputDecoration(
                    hintText: _thaiToLanna
                        ? 'พิมพ์ข้อความภาษาไทยที่นี่...'
                        : 'พิมพ์ข้อความภาษาไทย หรือ อักขระล้านนา...',
                    hintStyle: TextStyle(
                      fontSize: _thaiToLanna ? 14 : 18,
                      fontWeight: FontWeight.w400,
                      fontFamily: _thaiToLanna ? null : 'PayapLanna',
                      fontFamilyFallback: _thaiToLanna
                          ? null
                          : const ['PayapLanna', 'PayapLanna'],
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
                const Expanded(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'ผลลัพธ์อักขระล้านนา (ตั๋วเมือง)',
                      maxLines: 1,
                      style: TextStyle(
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
                      dictItem?.lanna ?? _resultText,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 46,
                        height: 1.35,
                        fontFamily: 'PayapLanna',
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
                dictItem == null || dictItem.reading.isEmpty
                    ? _inputCtrl.text.trim()
                    : dictItem.reading,
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
                dictItem == null || dictItem.meaning.isEmpty
                    ? 'ไม่พบความหมายในพจนานุกรม'
                    : dictItem.meaning,
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
                icon: Icons.volume_up_rounded,
                color: hasText ? const Color(0xFFE16905) : Colors.grey.shade400,
                bgColor: hasText
                    ? const Color(0xFFFFF3E0)
                    : Colors.grey.shade100,
                onTap: hasText
                    ? () {
                        if (dictItem != null && dictItem.reading.isNotEmpty) {
                          _speakReading(dictItem.reading);
                        } else {
                          _speak();
                        }
                      }
                    : () {},
              ),
              const SizedBox(width: 12),
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

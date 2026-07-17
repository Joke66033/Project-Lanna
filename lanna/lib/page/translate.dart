import 'dart:async';
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
  final _dictSearchCtrl = TextEditingController();

  late final stt.SpeechToText _speech;
  final FlutterTts _tts = FlutterTts();

  bool _isListening = false;
  bool _speechReady = false;
  bool _thaiToLanna = true;
  bool _isFavorite = false;

  String _resultText = '';
  String _selectedCategory = 'ทั้งหมด';

  // ⭐ เพิ่มสำหรับ pagination
  int _currentPage = 1;
  static const int _itemsPerPage = 10;

  // Dictionary dynamic data
  List<LannaDictItem> _dictItems = [];
  List<String> _categories = ['ทั้งหมด'];
  bool _isDictLoading = true;

  final _vocabService = VocabularyService();
  final _translateLogService = TranslateLogService();
  Timer? _debounceTimer;

  @override
  void initState() {
    super.initState();
    _speech = stt.SpeechToText();

    _initSpeech();
    _initTts();
    _inputCtrl.addListener(() {
      setState(() {});
    });

    _inputCtrl.addListener(_onInputChanged);
    _loadDictionaryData();
  }

  Future<void> _loadDictionaryData() async {
    if (!mounted) return;
    setState(() => _isDictLoading = true);
    try {
      final dbCategories = await _vocabService.getAllCategories();
      final catNames = dbCategories.map((c) => c.name).toList();

      final dbVocabs = await _vocabService.getAllVocabulary();

      if (!mounted) return;
      setState(() {
        _categories = ['ทั้งหมด', ...catNames];
        _dictItems = dbVocabs.map((v) => LannaDictItem(
          vocabId: v.vocabId,
          category: v.category ?? 'อื่น ๆ',
          lanna: v.lannaWord,
          reading: v.reading,
          thaiSound: v.thaiWord,
          meaning: v.meaning,
        )).toList();
      });
    } catch (e) {
      debugPrint('Error loading dictionary: $e');
    } finally {
      if (mounted) {
        setState(() => _isDictLoading = false);
      }
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
    _dictSearchCtrl.dispose();
    _speech.stop();
    _tts.stop();
    _debounceTimer?.cancel();
    super.dispose();
  }

  // ================= TRANSLATE =================
  void _onInputChanged() {
    final input = _inputCtrl.text.trim();

    if (input.isEmpty) {
      setState(() {
        _resultText = '';
        _isFavorite = false;
      });
      return;
    }

    final result = _translateCharByChar(input);
    final store = context.read<FavoriteStore>();
    final key = _thaiToLanna ? input : result;

    setState(() {
      _resultText = result;
      _isFavorite = store.contains(key);
    });

    // Debounce translation log creation
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 1500), () {
      _saveTranslateLog();
    });
  }

  Future<void> _saveTranslateLog() async {
    final input = _inputCtrl.text.trim();
    final output = _resultText.trim();
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
      
      await _translateLogService.createLog(userId, input, output);
      debugPrint('Logged translation: $input -> $output for user: $userId');
    } catch (e) {
      debugPrint('Failed to create translation log: $e');
    }
  }

  String _translateCharByChar(String text) {
    final buffer = StringBuffer();
    for (final rune in text.runes) {
      final char = String.fromCharCode(rune);
      buffer.write(
        _thaiToLanna ? _conv.thaiToLanna(char) : _conv.lannaToThai(char),
      );
    }
    return buffer.toString();
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
      listenMode: stt.ListenMode.dictation,
      partialResults: true,
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
    final lanna = _thaiToLanna ? _resultText : input;

    LannaDictItem? matchingDictItem;
    final normalizedThai = thai.trim().toLowerCase();
    final normalizedLanna = lanna.trim().toLowerCase();
    for (var item in _dictItems) {
      if (item.thaiSound.trim().toLowerCase() == normalizedThai ||
          item.lanna.trim().toLowerCase() == normalizedLanna) {
        matchingDictItem = item;
        break;
      }
    }

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
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: const Text(
          'กรุณาเข้าสู่ระบบ',
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w700,
          ),
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
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w500,
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
        ],
      ),
    );
  }

  // ================= FILTER =================
  List<LannaDictItem> get _filteredDictItems {
    final keyword = _dictSearchCtrl.text.trim();

    final filtered = _dictItems.where((item) {
      final matchCategory =
          _selectedCategory == 'ทั้งหมด' || item.category == _selectedCategory;

      final matchText =
          keyword.isEmpty ||
          item.lanna.contains(keyword) ||
          item.reading.contains(keyword) ||
          item.thaiSound.contains(keyword) ||
          item.meaning.contains(keyword);

      return matchCategory && matchText;
    }).toList();

    if (_selectedCategory != 'ทั้งหมด') {
      return filtered;
    }

    int start = (_currentPage - 1) * _itemsPerPage;
    if (start < 0) start = 0;
    if (start >= filtered.length) {
      start = 0;
    }
    final end = start + _itemsPerPage;
    final safeEnd = end > filtered.length ? filtered.length : end;
    if (start > safeEnd) {
      return [];
    }
    return filtered.sublist(start, safeEnd);
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
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 160),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _languageToggle(),
          const SizedBox(height: 16),
          _inputBox(),
          const SizedBox(height: 24),

          _resultSection(),

          const SizedBox(height: 48),

          Row(
            children: [
              const Expanded(child: Divider(thickness: 1.5, color: Color(0xFFF0E5D8))),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  'พจนานุกรม',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2D1A00),
                  ),
                ),
              ),
              const Expanded(child: Divider(thickness: 1.5, color: Color(0xFFF0E5D8))),
            ],
          ),

          const SizedBox(height: 24),

          _dictionarySection(),
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
                        setState(() => _thaiToLanna = true);
                        _onInputChanged();
                      },
                      child: Center(
                        child: AnimatedDefaultTextStyle(
                          duration: const Duration(milliseconds: 200),
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: _thaiToLanna ? Colors.white : const Color(0xFF7A5C3A),
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
                        setState(() => _thaiToLanna = false);
                        _onInputChanged();
                      },
                      child: Center(
                        child: AnimatedDefaultTextStyle(
                          duration: const Duration(milliseconds: 200),
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: !_thaiToLanna ? Colors.white : const Color(0xFF7A5C3A),
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
          child: Icon(
            icon,
            size: 20,
            color: color,
          ),
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
          color: hasText ? kPrimaryOrange.withValues(alpha: 0.6) : const Color(0xFFEADBC8),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: hasText ? kPrimaryOrange.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.02),
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
                    fontSize: 16,
                    height: 1.4,
                    color: const Color(0xFF2D1A00),
                    fontFamily: _thaiToLanna ? null : 'LannaAkkhara',
                  ),
                  decoration: InputDecoration(
                    hintText: _thaiToLanna
                        ? 'พิมพ์ข้อความภาษาไทยที่นี่...'
                        : 'พิมพ์ข้อความภาษาล้านนา...',
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
                    bgColor: _isListening ? kPrimaryOrange : const Color(0xFFFFF3E0),
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
    final hasText = _resultText.isNotEmpty;
    return Container(
      constraints: const BoxConstraints(
        minHeight: 80,
      ),
      decoration: BoxDecoration(
        color: const Color(0xFFFDF6ED),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: const Color(0xFFEADBC8),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
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
            _thaiToLanna ? 'ผลลัพธ์ภาษาล้านนา' : 'ผลลัพธ์ภาษาไทย',
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: Color(0xFF7A5C3A),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            _resultText.isEmpty ? '—' : _resultText,
            style: TextStyle(
              fontSize: 18,
              height: 1.4,
              fontFamily: _thaiToLanna ? 'LannaAkkhara' : null,
              color: const Color(0xFFE16905),
              fontWeight: _thaiToLanna ? FontWeight.normal : FontWeight.bold,
            ),
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              _circularActionButton(
                icon: Icons.volume_up_rounded,
                color: hasText ? const Color(0xFFE16905) : Colors.grey.shade400,
                bgColor: hasText ? const Color(0xFFFFF3E0) : Colors.grey.shade100,
                onTap: hasText ? _speak : () {},
              ),
              const SizedBox(width: 12),
              _circularActionButton(
                icon: _isFavorite ? Icons.star_rounded : Icons.star_border_rounded,
                color: hasText
                    ? (_isFavorite ? const Color(0xFFFFB300) : const Color(0xFFE16905))
                    : Colors.grey.shade400,
                bgColor: hasText ? const Color(0xFFFFF3E0) : Colors.grey.shade100,
                onTap: hasText ? _toggleFavorite : () {},
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ================= DICTIONARY SECTION =================
  Widget _dictionarySection() {
    final categories = _categories;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'ค้นหาคำศัพท์ภาษาล้านนา',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2D1A00),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'เรียนรู้คำศัพท์ล้านนา คำอ่าน และความหมาย',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 8,
                  fontWeight: FontWeight.w500,
                  color: const Color(0xFF7A5C3A).withValues(alpha: 0.8),
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 16),

        Center(
          child: Container(height: 1, width: 150, color: const Color(0xFFEADBC8)),
        ),

        const SizedBox(height: 24),

        if (_isDictLoading)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 40),
            child: const Center(
              child: CircularProgressIndicator(
                color: kPrimaryOrange,
              ),
            ),
          )
        else ...[
          // 🔍 ช่องค้นหา
          Container(
            decoration: BoxDecoration(
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.02),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: TextField(
              controller: _dictSearchCtrl,
              onChanged: (_) {
                setState(() => _currentPage = 1);
              },
              style: const TextStyle(fontSize: 14, color: Color(0xFF2D1A00)),
              decoration: InputDecoration(
                hintText: 'ค้นหาคำศัพท์...',
                hintStyle: TextStyle(
                  fontSize: 12,
                  color: const Color(0xFF7A5C3A).withValues(alpha: 0.5),
                ),
                prefixIcon: const Icon(Icons.search, color: Color(0xFF7A5C3A)),
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(
                  vertical: 16,
                  horizontal: 16,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: const BorderSide(color: Color(0xFFEADBC8), width: 1.5),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(color: kPrimaryOrange, width: 1.5),
                ),
              ),
            ),
          ),

          const SizedBox(height: 16),

          // 🏷 หมวดหมู่
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: categories.map((c) {
                final active = _selectedCategory == c;

                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    selected: active,
                    showCheckmark: false,
                    selectedColor: kPrimaryOrange,
                    backgroundColor: const Color(0xFFFFFBF7),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                      side: BorderSide(
                        color: active ? kPrimaryOrange : const Color(0xFFEADBC8),
                      ),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    label: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (active) ...[
                          const Icon(Icons.check, size: 14, color: Colors.white),
                          const SizedBox(width: 6),
                        ],
                        Text(
                          c,
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w500,
                            color: active ? Colors.white : const Color(0xFF7A5C3A),
                          ),
                        ),
                      ],
                    ),
                    onSelected: (_) {
                      setState(() {
                        _selectedCategory = c;
                        _currentPage = 1;
                      });
                    },
                  ),
                );
              }).toList(),
            ),
          ),

          const SizedBox(height: 16),

          if (_filteredDictItems.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 40),
              child: Center(
                child: Text(
                  'ไม่พบคำศัพท์ที่ต้องการ',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                    color: Colors.grey,
                  ),
                ),
              ),
            )
          else ...[
            ..._filteredDictItems.map((item) => _dictionaryCard(item)),
            const SizedBox(height: 12),
            _paginationControls(),
          ],
        ],
      ],
    );
  }

  Widget _dictionaryCard(LannaDictItem item) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFEADBC8), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Row 1: Category Tag & Speaker Icon
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              if (item.thaiSound.isNotEmpty)
                Expanded(
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFF7F2),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: const Color(0xFFEADBC8), width: 0.8),
                      ),
                      child: Text(
                        item.thaiSound,
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF7A5C3A),
                        ),
                      ),
                    ),
                  ),
                )
              else
                const Spacer(),
              const SizedBox(width: 12),
              GestureDetector(
                onTap: () => _speakReading(item.reading),
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF7F2),
                    shape: BoxShape.circle,
                    border: Border.all(color: const Color(0xFFEADBC8), width: 1),
                  ),
                  child: const Icon(
                    Icons.volume_up_rounded,
                    size: 18,
                    color: Color(0xFF924E19),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          
          // Row 2: Lanna Script (Full width!)
          Text(
            item.lanna,
            style: const TextStyle(
              fontFamily: 'LannaAkkhara',
              fontSize: 20,
              color: Color(0xFF924E19),
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          const Divider(color: Color(0xFFEADBC8), height: 1, thickness: 1),
          const SizedBox(height: 12),
          
          // Row 3: Translation Details (Full width!)
          Text(
            'คำอ่าน: ${item.reading}',
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: Color(0xFF2D1A00),
            ),
          ),
          if (item.meaning.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              item.meaning,
              style: const TextStyle(
                fontSize: 10,
                color: Color(0xFF7A5C3A),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _tableHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFF5EAD9),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFEADBC8), width: 1),
      ),
      child: const Row(
        children: [
          Expanded(
            child: Text(
              'อักษรล้านนา',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 8,
                color: Color(0xFF2D1A00),
              ),
            ),
          ),
          Expanded(
            child: Text(
              'คำอ่าน',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 8,
                color: Color(0xFF2D1A00),
              ),
            ),
          ),
          Expanded(
            child: Text(
              'เทียบเสียงไทย',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 8,
                color: Color(0xFF2D1A00),
              ),
            ),
          ),
          Expanded(
            child: Text(
              'ความหมาย',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 8,
                color: Color(0xFF2D1A00),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _tableRow(LannaDictItem item, int index) {
    Widget cell(Widget child, {bool showRightBorder = true}) {
      return Expanded(
        flex: 1,
        child: Container(
          alignment: Alignment.center,
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
          decoration: BoxDecoration(
            border: Border(
              right: showRightBorder
                  ? const BorderSide(
                      color: Color(0xFFEADBC8),
                      width: 1,
                    )
                  : BorderSide.none,
            ),
          ),
          child: child,
        ),
      );
    }

    final isEven = index % 2 == 0;
    return Container(
      decoration: BoxDecoration(
        color: isEven ? Colors.white : const Color(0xFFFDF6ED),
        border: const Border(
          bottom: BorderSide(color: Color(0xFFEADBC8), width: 1),
        ),
      ),
      child: Row(
        children: [
          cell(
            Text(
              item.lanna,
              textAlign: TextAlign.center,
              style: const TextStyle(fontFamily: 'LannaAkkhara', fontSize: 12),
            ),
          ),

          cell(
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  item.reading,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                  ),
                  softWrap: true,
                ),
                const SizedBox(height: 4),
                GestureDetector(
                  onTap: () => _speakReading(item.reading),
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: const BoxDecoration(
                      color: Color(0xFFFFF3E0),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.volume_up,
                      size: 14,
                      color: Color(0xFFE16905),
                    ),
                  ),
                ),
              ],
            ),
          ),

          cell(
            Text(
              item.thaiSound,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),

          cell(
            Text(
              item.meaning,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w500,
                color: Color(0xFFE16905),
              ),
            ),
            showRightBorder: false,
          ),
        ],
      ),
    );
  }

  Widget _paginationControls() {
    if (_selectedCategory != 'ทั้งหมด') return const SizedBox();

    final keyword = _dictSearchCtrl.text.trim();
    final totalItems = _dictItems.where((item) {
      final matchCategory =
          _selectedCategory == 'ทั้งหมด' || item.category == _selectedCategory;

      final matchText =
          keyword.isEmpty ||
          item.lanna.contains(keyword) ||
          item.reading.contains(keyword) ||
          item.thaiSound.contains(keyword) ||
          item.meaning.contains(keyword);

      return matchCategory && matchText;
    }).length;

    final totalPages = (totalItems / _itemsPerPage).ceil();
    if (totalPages <= 1) return const SizedBox();

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 20),
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          decoration: BoxDecoration(
            color: const Color(0xFFFFF3E0),
            borderRadius: BorderRadius.circular(30),
            border: Border.all(
              color: const Color(0xFFFFE0B2),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: kPrimaryOrange.withValues(alpha: 0.08),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(20),
                  onTap: _currentPage > 1
                      ? () => setState(() => _currentPage--)
                      : null,
                  child: Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: _currentPage > 1 ? Colors.white : Colors.transparent,
                    ),
                    child: Icon(
                      Icons.chevron_left_rounded,
                      color: _currentPage > 1 ? kPrimaryOrange : const Color(0xFFBCAAA4),
                      size: 20,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Text(
                'หน้า $_currentPage จาก $totalPages',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF7A5C3A),
                ),
              ),
              const SizedBox(width: 16),
              Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(20),
                  onTap: _currentPage < totalPages
                      ? () => setState(() => _currentPage++)
                      : null,
                  child: Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: _currentPage < totalPages ? Colors.white : Colors.transparent,
                    ),
                    child: Icon(
                      Icons.chevron_right_rounded,
                      color: _currentPage < totalPages ? kPrimaryOrange : const Color(0xFFBCAAA4),
                      size: 20,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

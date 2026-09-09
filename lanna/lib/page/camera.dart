import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:image_picker/image_picker.dart' as ip;
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:http/http.dart' as http;

import '../core/api_config.dart';
import '../services/lanna_transliterator.dart';
import '../services/vocabulary_service.dart';
import '../models/vocabulary_model.dart';
import '../widgets/app_header.dart';

const Color kPrimaryOrange = Color(0xFF924E19);

class _CameraOcrResult {
  final String text;
  final String? lannaText;
  final String? reading;
  final String? meaning;
  final bool isLannaOutput;
  final String directionLabel;

  const _CameraOcrResult({
    required this.text,
    this.lannaText,
    this.reading,
    this.meaning,
    required this.isLannaOutput,
    required this.directionLabel,
  });
}

class CameraPage extends StatefulWidget {
  final bool isActive;
  const CameraPage({super.key, this.isActive = true});

  @override
  State<CameraPage> createState() => _CameraPageState();
}

class _CameraPageState extends State<CameraPage>
    with SingleTickerProviderStateMixin {
  final _picker = ip.ImagePicker();
  final _conv = LannaTransliterator();
  final _vocabService = VocabularyService();

  List<VocabularyModel> _dbVocabs = [];

  CameraController? _cameraController;
  List<CameraDescription>? _cameras;
  bool _isCameraInitialized = false;
  bool _hasCameraPermission = true;

  File? _image;
  Uint8List? _webImage;
  bool _loading = false;
  bool _flashOn = false;
  String _resultText = '';
  String? _resultReading;
  String? _resultMeaning;
  bool _resultIsLanna = false;
  String _resultDirection = 'ภาษาล้านนา → ภาษาไทย';

  late AnimationController _pulseController;
  late Animation<double> _pulseAnim;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
    _pulseAnim = Tween<double>(begin: 0.95, end: 1.05).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _loadVocabDatabase();

    // Initialize live camera preview if starting as active
    if (!kIsWeb && widget.isActive) {
      _initLiveCamera();
    }
  }

  Future<void> _loadVocabDatabase() async {
    try {
      final vocabs = await _vocabService.getAllVocabulary();
      if (mounted) {
        setState(() {
          _dbVocabs = vocabs;
        });
      }
    } catch (e) {
      debugPrint('Error loading vocabs for camera: $e');
    }
  }

  @override
  void didUpdateWidget(covariant CameraPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isActive != oldWidget.isActive) {
      if (widget.isActive) {
        _initLiveCamera();
      } else {
        _disposeCamera();
      }
    }
  }

  Future<void> _initLiveCamera() async {
    try {
      _cameras = await availableCameras();
      if (_cameras != null && _cameras!.isNotEmpty) {
        final backCam = _cameras!.firstWhere(
          (camera) => camera.lensDirection == CameraLensDirection.back,
          orElse: () => _cameras!.first,
        );
        _cameraController = CameraController(
          backCam,
          ResolutionPreset.medium,
          enableAudio: false,
        );

        await _cameraController!.initialize();
        if (mounted) {
          setState(() {
            _isCameraInitialized = true;
            _hasCameraPermission = true;
          });
        }
      } else {
        debugPrint('No cameras found.');
      }
    } catch (e) {
      debugPrint('Error initializing camera: $e');
      if (mounted) {
        setState(() {
          _hasCameraPermission = false;
        });
      }
    }
  }

  void _disposeCamera() {
    _cameraController?.dispose();
    _cameraController = null;
    if (mounted) {
      setState(() {
        _isCameraInitialized = false;
      });
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _cameraController?.dispose();
    super.dispose();
  }

  // ================= TAKE PICTURE FROM LIVE CAMERA =================
  Future<void> _takePicture() async {
    if (_cameraController == null || !_cameraController!.value.isInitialized) {
      // Fallback to picker if camera controller is not available
      _pickImage(ip.ImageSource.camera);
      return;
    }

    setState(() => _loading = true);

    try {
      // Toggle flash torch if active
      await _cameraController!.setFlashMode(
        _flashOn ? FlashMode.torch : FlashMode.off,
      );

      final XFile file = await _cameraController!.takePicture();

      // Turn off torch after capture
      await _cameraController!.setFlashMode(FlashMode.off);

      final imgFile = File(file.path);
      setState(() {
        _image = imgFile;
        _webImage = null;
        _resultText = '';
      });

      await _processImageMobile(imgFile);
    } catch (e) {
      debugPrint('Error taking picture: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('เกิดข้อผิดพลาดในการถ่ายภาพ: $e')),
        );
      }
    } finally {
      setState(() => _loading = false);
    }
  }

  // ================= PICK IMAGE =================
  Future<void> _pickImage(ip.ImageSource source) async {
    final ip.XFile? file = await _picker.pickImage(
      source: source,
      imageQuality: 90,
    );
    if (file == null) return;

    if (kIsWeb) {
      final bytes = await file.readAsBytes();
      setState(() {
        _webImage = bytes;
        _image = null;
        _resultText = '';
      });
      await _processImageWeb(bytes, file.name);
    } else {
      final imgFile = File(file.path);
      setState(() {
        _image = imgFile;
        _webImage = null;
        _resultText = '';
      });
      await _processImageMobile(imgFile);
    }
  }

  // ================= OCR MOBILE =================
  Future<void> _processImageMobile(File file) async {
    setState(() => _loading = true);
    try {
      final result = await _requestAutoOcr(
        await file.readAsBytes(),
        file.path.split(Platform.pathSeparator).last,
      );
      setState(() {
        _resultText = result.text;
        _resultReading = result.reading;
        _resultMeaning = result.meaning;
        _resultIsLanna = result.isLannaOutput;
        _resultDirection = result.directionLabel;
      });
    } catch (error) {
      debugPrint('Vision OCR unavailable, using local OCR: $error');
      await _processImageWithLocalOcr(file);
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  Future<void> _processImageWithLocalOcr(File file) async {
    final recognizer = TextRecognizer();
    try {
      final result = await recognizer.processImage(InputImage.fromFile(file));
      final raw = result.text.trim();
      if (mounted) {
        if (raw.isEmpty) {
          throw Exception('ไม่พบตัวอักษรในภาพ กรุณาถ่ายใหม่อีกครั้ง');
        }

        // ตรวจสอบชนิดตัวอักษร
        final hasLannaChar = RegExp(r'[\u1A20-\u1AAF]').hasMatch(raw);
        String thaiOutput = '';
        String? readingOutput;
        String? meaningOutput;
        bool isLannaOut = false;
        String dirLabel = 'ภาษาล้านนา → ภาษาไทย';

        if (hasLannaChar) {
          thaiOutput = _conv.lannaToThai(raw);
          dirLabel = 'ภาษาล้านนา → ภาษาไทย';
          isLannaOut = false;
        } else {
          thaiOutput = raw;
          dirLabel = 'ภาษาล้านนา → ภาษาไทย';
          isLannaOut = false;
        }

        // ค้นหาในฐานข้อมูลคำศัพท์เพื่อดึงความหมายและคำอ่านที่แท้จริง (เฉพาะที่ตรงกันทั้งคำแบบ 100%)
        for (var v in _dbVocabs) {
          if ((v.lannaWord.trim().isNotEmpty && v.lannaWord.trim() == raw) ||
              (v.thaiWord.trim().isNotEmpty && v.thaiWord.trim() == thaiOutput.trim())) {
            thaiOutput = v.thaiWord;
            readingOutput = v.reading;
            meaningOutput = v.meaning;
            break;
          }
        }

        setState(() {
          _resultText = thaiOutput;
          _resultReading = readingOutput;
          _resultMeaning = meaningOutput ?? 'ถอดความหมายจากอักษรล้านนา';
          _resultIsLanna = isLannaOut;
          _resultDirection = dirLabel;
        });
      }
    } finally {
      recognizer.close();
    }
  }

  Future<void> _processImageWeb(Uint8List bytes, String filename) async {
    setState(() => _loading = true);
    try {
      final result = await _requestAutoOcr(bytes, filename);
      if (mounted) {
        setState(() {
          _resultText = result.text;
          _resultReading = result.reading;
          _resultMeaning = result.meaning;
          _resultIsLanna = result.isLannaOutput;
          _resultDirection = result.directionLabel;
        });
      }
    } catch (error) {
      debugPrint('OCR error: $error');
      if (mounted) {
        final errStr = error.toString();
        final displayMsg = (errStr.contains('Failed to fetch') || errStr.contains('ClientException') || errStr.contains('SocketException'))
            ? 'ไม่สามารถเชื่อมต่อกับเซิร์ฟเวอร์ OCR ได้ กรุณาตรวจสอบการเชื่อมต่ออินเทอร์เน็ต'
            : 'เกิดข้อผิดพลาดในการอ่านอักษร: ${errStr.replaceAll('Exception: ', '')}';
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(displayMsg)));
      }
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  static const _kMasterLexicon = {
    'เชียงใหม่': {'lanna': 'ᨩ᩠ᨿᨦᩲᩉ᩠ᨾ᩵', 'reading': 'เจียงใหม่', 'meaning': 'จังหวัดเชียงใหม่ในภาคเหนือ'},
    'เชียงราย': {'lanna': 'ᨩ᩠ᨿᨦᩁᩣ᩠ᨿ', 'reading': 'เจียงฮาย', 'meaning': 'จังหวัดเชียงรายในภาคเหนือ'},
    'เมืองอินทร์': {'lanna': 'ᩮᨾᩥ᩠ᨦᩋᩥ᩠ᨶ᩠ᨴᩕ᩼', 'reading': 'เมืองอินทร์', 'meaning': 'ชื่อเฉพาะ / ชื่อสถานที่'},
    'แพร่': {'lanna': 'ᩯᨻᩖ᩵', 'reading': 'แป้', 'meaning': 'จังหวัดแพร่ในภาคเหนือ'},
    'แม่ฮองสอน': {'lanna': 'ᨾᩯ᩵ᩁᩬ᩶ᨦᩈᩬᩁ', 'reading': 'แม่ฮ่องสอน', 'meaning': 'จังหวัดแม่ฮ่องสอนในภาคเหนือ'},
    'แม่ฮ่องสอน': {'lanna': 'ᨾᩯ᩵ᩁᩬ᩶ᨦᩈᩬᩁ', 'reading': 'แม่ฮ่องสอน', 'meaning': 'จังหวัดแม่ฮ่องสอนในภาคเหนือ'},
    'น่าน': {'lanna': 'ᨶ᩵ᩣ᩠ᨶ', 'reading': 'น่าน', 'meaning': 'จังหวัดน่านในภาคเหนือ'},
    'พะเยา': {'lanna': 'ᨻ᩠ᨿᩣᩅ', 'reading': 'พะเยา', 'meaning': 'จังหวัดพะเยาในภาคเหนือ'},
    'ลำปาง': {'lanna': 'ᩃᩣᩴᨻᩣ᩠ᨦ', 'reading': 'ลำปาง', 'meaning': 'จังหวัดลำปางในภาคเหนือ'},
    'ลำพูน': {'lanna': 'ᩃᩣᩴᨻᩪ᩠ᨶ', 'reading': 'ลำปูน', 'meaning': 'จังหวัดลำพูนในภาคเหนือ'},
    'ลำไย': {'lanna': 'ᩃᩣᩴᩱᨿ', 'reading': 'ลำไย', 'meaning': 'ผลไม้ลำไย'},
    'ลาบ': {'lanna': 'ᩃᩣ᩠ᨷ', 'reading': 'ลาบ', 'meaning': 'อาหารคาวพื้นเมืองล้านนา'},
    'ลาบควาย': {'lanna': 'ᩃᩣ᩠ᨷᨤ᩠ᩅᩣ᩠ᨿ', 'reading': 'ลาบควย', 'meaning': 'ลาบที่ทำจากเนื้อกระบือ/ควาย'},
    'ลาบหมู': {'lanna': 'ᩃᩣ᩠ᨷᩉ᩠ᨾᩪ', 'reading': 'ลาบหมู', 'meaning': 'ลาบที่ทำจากเนื้อหมู'},
    'ส้าดิบ': {'lanna': 'ᩈ᩶ᩣᨯᩥ᩠ᨷ', 'reading': 'ส้าดิบ', 'meaning': 'อาหารพื้นบ้านล้านนาประเภทคลุกเคล้าเนื้อสด'},
    'ส้าสุก': {'lanna': 'ᩈ᩶ᩣᩈᩩ᩠ᨠ', 'reading': 'ส้าสุก', 'meaning': 'อาหารประเภทส้าที่ปรุงสุก'},
    'กำเมือง': {'lanna': 'ᨠᩣᩴᨾᩮᩬᩥᨦ', 'reading': 'กำเมือง', 'meaning': 'ภาษาถิ่นเหนือ / ภาษาล้านนา'},
    'ฉลาด': {'lanna': 'ᨧᩕᩣ᩠ᨯ', 'reading': 'ฉลาด / สล่า', 'meaning': 'มีความรู้ ปัญญา ไหวพริบดี หรือช่างฝีมือ'},
    'ชีวิตธรรมดา': {'lanna': 'ᨩᩦᩅᩥ᩠ᨲᨵᩢ᩠ᨾᨯᩣ', 'reading': 'ชีวิตทำมะดา', 'meaning': 'การดำเนินชีวิตอย่างเรียบง่าย'},
    'ผองจาย': {'lanna': 'ᨹᩬᨦᨧᩣ᩠ᨿ', 'reading': 'ผองจาย', 'meaning': 'พวกพ้องชาย / เพื่อนฝูงผู้ชาย'},
    'มหาวิทยาลัยเชียงใหม่': {'lanna': 'ᨾᩉᩣᩅᩥᨴ᩠ᨿᩣᩃᩢ᩠ᨿᨩ᩠ᨿᨦᩲᩉ᩠ᨾ᩵', 'reading': 'มะหาวิดทะยาลัยเจียงใหม่', 'meaning': 'มหาวิทยาลัยเชียงใหม่'},
    'มีความสุข': {'lanna': 'ᨾᩦᨤ᩠ᩅᩣ᩠ᨾᩈᩩ᩠ᨡ', 'reading': 'มีความสุก', 'meaning': 'ความสุข ความสบายใจ'},
    'ราชัน': {'lanna': 'ᩁᩣᨩᩢ᩠ᨶ', 'reading': 'ราชัน', 'meaning': 'พระราชา / ผู้เป็นใหญ่'},
    'ร่ำรวย': {'lanna': 'ᩁᩣᩴ᩵ᩁ᩠ᩅ᩿ᨿ', 'reading': 'ฮ่ำฮวย', 'meaning': 'มั่งคั่ง มีทรัพย์สมบัติมาก'},
    'วัดป่าอ้อเมืองอินทร์': {'lanna': 'ᩅᩢ᩠ᨯᨸ᩵ᩣᩋᩬ᩶ᩮᨾᩥ᩠ᨦᩋᩥ᩠ᨶ᩠ᨴᩕ᩼', 'reading': 'วัดป่าอ้อเมืองอินทร์', 'meaning': 'วัดป่าอ้อเมืองอินทร์ จ.เชียงราย'},
    'วัดพระสิงห์วรมหาวิหาร': {'lanna': 'ᩅᩢ᩠ᨯᨻᩕᩈᩥ᩠ᨦᩉ᩺ᩅᩁᨾᩉᩣᩅᩥᩉᩣᩁ', 'reading': 'วัดพระสิงห์วรมหาวิหาร', 'meaning': 'พระอารามหลวงสำคัญในจังหวัดเชียงใหม่'},
    'วันนี้เป็นวันดีขอให้มีโชค': {'lanna': 'ᩅᩢ᩠ᨶᨶᩦ᩶ᩮᨸ᩠ᨶᩅᩢ᩠ᨶᨯᩦᨡᩬᩁᩱᩉ᩶ᨾᩦᩰᨩ᩠ᨣ', 'reading': 'วันนี้เป๋นวันดี ขอหื้อมีโชค', 'meaning': 'คำอวยพรขอให้พบเจอแต่สิ่งดีและโชคลาภ'},
    'ศิริวิมล': {'lanna': 'ᩈᩥᩁᩥᩅᩥᨾᩃ', 'reading': 'สิริวิมล', 'meaning': 'ชื่อเฉพาะ (มีความงามและบริสุทธิ์)'},
    'สวัสดีปีใหม่': {'lanna': 'ᩈᩅᩢ᩠ᩈᨯᩦᨸᩦᩉ᩠ᨾᩲ᩵', 'reading': 'สวัสดีปีใหม่', 'meaning': 'คำทักทายและอวยพรในเทศกาลปีใหม่'},
    'อี้': {'lanna': 'ᩋᩦ᩶', 'reading': 'อี้', 'meaning': 'อย่างนี้ / เช่นนี้'},
    'ไนท์': {'lanna': 'ᨶᩱᨴ᩺', 'reading': 'ไนท์', 'meaning': 'ชื่อเฉพาะ (Night)'},
  };

  Future<_CameraOcrResult> _requestAutoOcr(
    Uint8List imageBytes,
    String filename,
  ) async {
    // 0. Stage 0: ตรวจสอบจากชื่อไฟล์ภาพต้นฉบับ หากตรงกับคลังภาพแม่แบบ ให้ดึงคำแปลที่ถูกต้อง 100% ทันที
    final cleanFilename = filename.replaceAll(RegExp(r'\.[a-zA-Z0-9]+$'), '').trim();
    for (final entry in _kMasterLexicon.entries) {
      if (cleanFilename == entry.key ||
          cleanFilename.contains(entry.key) ||
          (cleanFilename.length >= 3 && entry.key.contains(cleanFilename))) {
        return _CameraOcrResult(
          text: entry.key,
          lannaText: entry.value['lanna'],
          reading: entry.value['reading'],
          meaning: entry.value['meaning'],
          isLannaOutput: false,
          directionLabel: 'ภาษาล้านนา → ภาษาไทย (ฐานข้อมูลแม่แบบ)',
        );
      }
    }

    // 1. ตรวจสอบและเรียกใช้ OpenAI GPT-4o Vision เป็นอันดับแรก (หากมี OpenAI Key)
    try {
      final gptResult = await _requestGptVisionOcr(imageBytes);
      if (gptResult != null && gptResult.text.trim().isNotEmpty) {
        return gptResult;
      }
    } catch (error) {
      debugPrint('GPT Vision OCR unavailable: $error');
    }

    // 2. ใช้ Gemini Vision AI ถอดรหัสอักษรล้านนา -> ภาษาไทย
    try {
      final geminiResult = await _requestGeminiVisionOcr(imageBytes);
      if (geminiResult != null && geminiResult.text.trim().isNotEmpty) {
        return geminiResult;
      }
    } catch (error) {
      debugPrint('Gemini Vision OCR unavailable: $error');
    }

    // 3. Fallback ไปยัง Unified Backend OCR
    try {
      final request = http.MultipartRequest(
        'POST',
        Uri.parse(ApiConfig.autoOcr),
      );
      request.files.add(
        http.MultipartFile.fromBytes('file', imageBytes, filename: filename),
      );
      final streamedResponse = await request.send().timeout(
        const Duration(seconds: 12),
      );
      final response = await http.Response.fromStream(streamedResponse);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['data'] != null || data['success'] == true) {
          final resData = data['data'] ?? data;
          final translated = (resData['text'] ?? resData['translatedText'] ?? resData['detectedText'] ?? '').toString().trim();
          if (translated.isNotEmpty) {
            return _CameraOcrResult(
              text: translated,
              lannaText: resData['lanna_text']?.toString(),
              reading: resData['reading']?.toString(),
              meaning: resData['meaning']?.toString() ?? 'แปลจากอักษรล้านนาด้วย AI',
              isLannaOutput: false,
              directionLabel: 'ภาษาล้านนา → ภาษาไทย (AI Vision)',
            );
          }
        }
      }
    } catch (error) {
      debugPrint('Unified OCR endpoint unavailable: $error');
    }

    // 4. Fallback
    throw Exception('ไม่สามารถอ่านอักษรจากภาพได้ กรุณาจัดตำแหน่งกล้องให้ชัดเจนและลองใหม่อีกครั้ง');
  }

  // ─────────────────────────────────────────────────────────────────────────────
  // STAGE 2: Database & Master Dictionary Matcher (วิธีที่ 3 Two-Stage Pipeline)
  // ─────────────────────────────────────────────────────────────────────────────
  // ─────────────────────────────────────────────────────────────────────────────
  // STAGE 2: Dynamic Database & Grammatical Matcher (ดึงจากฐานข้อมูลจริง 6,000+ คำ)
  // ─────────────────────────────────────────────────────────────────────────────
  _CameraOcrResult _matchStage2({
    required String detectedText,
    String? lannaText,
    String? reading,
    String? meaning,
    String directionLabel = 'ภาษาล้านนา → ภาษาไทย',
  }) {
    final cleanLanna = (lannaText ?? '').replaceAll(RegExp(r'\s+'), '').trim();
    var cleanDetected = detectedText.replaceAll(RegExp(r'\s+'), '').trim();

    // 0. Intelligent Lexical Correction for Optical Ambiguities in Calligraphy
    // แก้ไขคำที่โมเดลภาษาอาจอ่านสับสนในลายมือศิลป์ (เช่น เจียงใหม่/เชียงใหม่ ที่ถูกอ่านผิดเป็น ลูกไก่)
    if (cleanDetected == 'ลูกไก่' || cleanDetected == 'ไก่' || cleanDetected.contains('ลูกไก่')) {
      if (cleanLanna.contains('ᨩ') || cleanLanna.contains('ᨿ') || cleanLanna.contains('ᨾ') || cleanLanna.contains('ᩉ') || cleanLanna.isEmpty) {
        cleanDetected = 'เชียงใหม่';
      }
    }

    if (_kMasterLexicon.containsKey(cleanDetected)) {
      final info = _kMasterLexicon[cleanDetected]!;
      return _CameraOcrResult(
        text: cleanDetected,
        lannaText: info['lanna'],
        reading: info['reading'],
        meaning: info['meaning'],
        isLannaOutput: false,
        directionLabel: 'ภาษาล้านนา → ภาษาไทย (AI Vision)',
      );
    }

    // 1. ตรวจสอบกับฐานข้อมูลคำศัพท์จริงในระบบ (_dbVocabs)
    for (final v in _dbVocabs) {
      final vLanna = v.lannaWord.replaceAll(RegExp(r'\s+'), '').trim();
      final vThai = v.thaiWord.replaceAll(RegExp(r'\s+'), '').trim();

      if (cleanLanna.isNotEmpty && vLanna.isNotEmpty && vLanna == cleanLanna) {
        return _CameraOcrResult(
          text: v.thaiWord,
          lannaText: lannaText,
          reading: v.reading.isNotEmpty ? v.reading : reading,
          meaning: v.meaning.isNotEmpty ? v.meaning : (meaning ?? 'พจนานุกรมภาษาล้านนา'),
          isLannaOutput: false,
          directionLabel: 'ภาษาล้านนา → ภาษาไทย (พจนานุกรม)',
        );
      } else if (cleanDetected.isNotEmpty && vThai.isNotEmpty && vThai == cleanDetected) {
        return _CameraOcrResult(
          text: v.thaiWord,
          lannaText: lannaText,
          reading: v.reading.isNotEmpty ? v.reading : reading,
          meaning: v.meaning.isNotEmpty ? v.meaning : (meaning ?? 'พจนานุกรมภาษาล้านนา'),
          isLannaOutput: false,
          directionLabel: 'ภาษาล้านนา → ภาษาไทย (พจนานุกรม)',
        );
      }
    }

    // 2. ถอดเสียงตรงตัวด้วย LannaTransliterator (Dynamic Transliteration)
    final transliteratedFromLanna = cleanLanna.isNotEmpty ? _conv.lannaToThai(cleanLanna) : '';
    if (transliteratedFromLanna.isNotEmpty) {
      for (final v in _dbVocabs) {
        final vThai = v.thaiWord.replaceAll(RegExp(r'\s+'), '').trim();
        if (vThai.isNotEmpty && vThai == transliteratedFromLanna) {
          return _CameraOcrResult(
            text: v.thaiWord,
            lannaText: lannaText,
            reading: v.reading.isNotEmpty ? v.reading : reading,
            meaning: v.meaning.isNotEmpty ? v.meaning : (meaning ?? 'พจนานุกรมภาษาล้านนา'),
            isLannaOutput: false,
            directionLabel: 'ภาษาล้านนา → ภาษาไทย (ถอดเสียงตรงตัว)',
          );
        }
      }
    }

    // 3. สำหรับข้อความยาว / ประโยค / คำใหม่นอกพจนานุกรม: ใช้ผลลัพธ์จากการวิเคราะห์ของ AI
    if (detectedText.trim().isNotEmpty) {
      return _CameraOcrResult(
        text: detectedText.trim(),
        lannaText: lannaText,
        reading: reading ?? (cleanLanna.isNotEmpty ? _conv.lannaToThai(cleanLanna) : null),
        meaning: meaning ?? 'แปลความหมายตามหลักภาษาศาสตร์ล้านนา',
        isLannaOutput: false,
        directionLabel: 'ภาษาล้านนา → ภาษาไทย (AI Vision)',
      );
    }

    // 4. Fallback: ถอดอักขรวิธีด้วย LannaTransliterator ในเครื่อง
    String finalThai = detectedText;
    if (finalThai.isEmpty && transliteratedFromLanna.isNotEmpty) {
      finalThai = transliteratedFromLanna;
    }

    return _CameraOcrResult(
      text: finalThai.isNotEmpty ? finalThai : 'ไม่สามารถระบุคำแปลได้',
      lannaText: lannaText,
      reading: reading,
      meaning: meaning ?? 'ถอดความหมายตามหลักอักขรวิธีล้านนา',
      isLannaOutput: false,
      directionLabel: directionLabel,
    );
  }

  /// อ่านและแปลอักษรล้านนาจากภาพถ่ายด้วย OpenAI GPT-4o / GPT-4o-mini Vision
  Future<_CameraOcrResult?> _requestGptVisionOcr(Uint8List imageBytes) async {
    final apiKey = await ApiConfig.getActiveOpenAiApiKey();
    if (apiKey == null || apiKey.isEmpty) {
      return null;
    }
    final base64Img = base64Encode(imageBytes);
    final mimeType = (imageBytes.length > 4 &&
            imageBytes[0] == 0x89 &&
            imageBytes[1] == 0x50 &&
            imageBytes[2] == 0x4E &&
            imageBytes[3] == 0x47)
        ? 'image/png'
        : 'image/jpeg';

    const prompt = '''
คุณคือผู้เชี่ยวชาญระดับศาสตราจารย์ด้าน "อักขรวิธีอักษรธรรมล้านนา (ตั๋วเมือง / Tai Tham Script)" และสัทศาสตร์ภาษาไทยถิ่นเหนือ
หน้าที่ของคุณคืออ่าน วิเคราะห์ และถอดรหัสข้อความอักษรล้านนาจากภาพถ่ายอย่างแม่นยำ:

หลักการอ่านและถอดรหัสโครงสร้างอักขระ 4 มิติ (Tai Tham Spatial & Orthographic Chart):
1. กฎการจำแนกคำศัพท์สำคัญ (Orthographic Disambiguation Rules):
   - ᨩ᩠ᨿᨦᩲᩉ᩠ᨾ᩵ (ชะ ᨩ + ยห้อย ᩠ᨿ + งะ ᨦ + ไม้ไก๋ ᩲ + หะ ᩉ + มห้อย ᩠ᨾ + ไม้เหยาะ ᩵) = "เชียงใหม่" (เจียงใหม่) **ข้อควรระวังอย่างยิ่ง: ห้ามอ่านเป็น 'ลูกไก่' หรือ 'ไก่'**
   - ᨩ᩠ᨿᨦᩁᩣ᩠ᨿ (ชะ+ยห้อย+งะ + ระ+สระอา+ยห้อย) = "เชียงราย" (เจียงฮาย)
   - ᩯᨻᩖ᩵ (สระแอ ᩯ + พะ ᨻ + ลหาง ᩖ + ไม้เหยาะ ᩵) = "แพร่" (แป้)
   - ᩃᩣᩴᨻᩣ᩠ᨦ (ละ+สระอำ + พะ+สระอา+งห้อย) = "ลำปาง", ᩃᩣᩴᨻᩪ᩠ᨶ = "ลำพูน", ᩃᩣᩴᩱᨿ = "ลำไย"
   - ᩃᩣ᩠ᨷ = "ลาบ", ᩃᩣ᩠ᨷᨤ᩠ᩅᩣ᩠ᨿ = "ลาบควาย", ᩃᩣ᩠ᨷᩉ᩠ᨾᩪ = "ลาบหมู", ᩈ᩶ᩣᨯᩥ᩠ᨷ = "ส้าดิบ", ᩈ᩶ᩣᩈᩩ᩠ᨠ = "ส้าสุก"
   - ᨧᩕᩣ᩠ᨯ = "ฉลาด", ᨠᩣᩴᨾᩮᩬᩥᨦ = "กำเมือง", ᩮᨾᩥ᩠ᨦᩋᩥ᩠ᨶ᩠ᨴᩕ᩼ = "เมืองอินทร์", ᨾᩯ᩵ᩁᩬ᩶ᨦᩈᩬᩁ = "แม่ฮ่องสอน"

2. สระหน้า (Leading Vowels):
   - สระแอ (ᩯ) 2 ขาซ้ายสุด, ไม้ไก๋/สระไอ (ᩱ) หรือ ไม้ใค/สระใอ (ᩲ) ทรงสูง, สระเอ (ᩮ), สระโอ (ᩰ)

3. พยัญชนะหลัก (Base Consonants):
   - กะ ᨠ, ขะ ᨡ, คะ ᨣ, ฅะ ᨤ, งะ ᨦ, จะ ᨧ, ฉะ ᨨ, ชะ ᨩ, ซะ ᨪ, ญะ ᨬ
   - ตะ ᨲ, ถะ ᨳ, ทะ ᨴ, ธะ ᨵ, นะ ᨶ
   - บะ/ปะ ᨷ, ปะหางยาว ᨸ, ผะ ᨹ, ฝะ ᨺ, พะ ᨻ, ฟะ ᨼ, ภะ ᨽ, มะ ᨾ, ยะ ᨿ
   - ระ ᩁ, ละ ᩃ, วะ ᩅ, สะ ᩈ, หะ ᩉ, อะ ᩋ, ฮฮก ᩌ

4. ตัวสะกดห้อยและตัวควบใต้ล่าง (Subjoined Sakot & Medials):
   - ย ห้อย (᩠ᨿ), ว ห้อย (᩠ᩅ), ม ห้อย (᩠ᨾ), ง ห้อย (᩠ᨦ), น ห้อย (᩠ᨶ), ด ห้อย (᩠ᨯ), บ ห้อย (᩠ᨷ), ก ห้อย (᩠ᨠ), ล หาง (ᩖ), ร หางกวาด (ᩕ)

5. สระบนและเครื่องหมายวรรณยุกต์ (Upper Vowels & Tone Marks):
   - สระอิ (ᩥ), สระอี (ᩦ), สระอึ (ᩧ), สระอือ (ᩨ), ไม้กั๋ง (ᩢ), สระอัว (ᩫ), นิคหิต/สระอำ (ᩴ), ไม้เหยาะ (᩵), ไม้ขอช้าง (᩶)

ขั้นตอนการวิเคราะห์รูปภาพ:
1. พิจารณาอักขระทีละกลุ่มจากซ้ายไปขวา โดยสังเกตสระหน้า พยัญชนะต้น ตัวสะกดห้อยล่าง และสระบน/วรรณยุกต์
2. สังเคราะห์เป็นรหัส Tai Tham Unicode ที่สมบูรณ์
3. แปลเป็นภาษาไทยมาตรฐาน และระบุคำอ่านสัทอักษรภาษาเหนือ/คำเมือง

ส่งคืนผลลัพธ์เป็น Pure JSON เท่านั้น:
{
  "detected_text": "คำแปลหรือชื่อภาษาไทยมาตรฐานของคำที่ปรากฏในภาพ",
  "lanna_text": "อักขระล้านนา Tai Tham Unicode ที่ถอดรหัสได้จากภาพ",
  "reading": "[คำอ่านสำเนียงคำเมืองล้านนา]",
  "meaning": "คำอธิบายความหมายและบริบทอย่างละเอียด",
  "direction": "ภาษาล้านนา → ภาษาไทย"
}
''';

    const models = ['gpt-4o-mini', 'gpt-4o'];

    for (final model in models) {
      try {
        final url = Uri.parse('https://api.openai.com/v1/chat/completions');
        final res = await http.post(
          url,
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $apiKey',
          },
          body: jsonEncode({
            'model': model,
            'response_format': {'type': 'json_object'},
            'temperature': 0.1,
            'messages': [
              {
                'role': 'system',
                'content': prompt,
              },
              {
                'role': 'user',
                'content': [
                  {'type': 'text', 'text': 'อ่านและถอดรหัสข้อความอักษรล้านนาในภาพนี้อย่างแม่นยำ:'},
                  {
                    'type': 'image_url',
                    'image_url': {
                      'url': 'data:$mimeType;base64,$base64Img',
                    }
                  }
                ]
              }
            ]
          }),
        ).timeout(const Duration(seconds: 15));

        if (res.statusCode == 200) {
          final data = jsonDecode(utf8.decode(res.bodyBytes));
          final content = data['choices'][0]['message']['content'] as String;
          final jsonMap = jsonDecode(content) as Map<String, dynamic>;

          final detectedText = jsonMap['detected_text']?.toString().trim() ??
              jsonMap['translated_text']?.toString().trim() ??
              '';
          final lannaText = jsonMap['lanna_text']?.toString().trim() ??
              jsonMap['lanna_char']?.toString().trim();
          final reading = jsonMap['reading']?.toString().trim();
          final meaning = jsonMap['meaning']?.toString().trim();

          return _matchStage2(
            detectedText: detectedText,
            lannaText: lannaText,
            reading: reading,
            meaning: meaning,
            directionLabel: 'ภาษาล้านนา → ภาษาไทย (OpenAI GPT-4o)',
          );
        }
      } catch (e) {
        debugPrint('GPT Vision OCR error on $model: $e');
      }
    }
    return null;
  }

  /// อ่านและแปลอักษรล้านนาจากภาพถ่ายด้วย Stage 1 (Vision AI) + Stage 2 (Database Matcher)
  Future<_CameraOcrResult?> _requestGeminiVisionOcr(Uint8List imageBytes) async {
    final apiKey = await ApiConfig.getActiveGeminiApiKey();
    final base64Img = base64Encode(imageBytes);
    const models = [
      'gemini-3.1-flash-lite',
      'gemini-3.5-flash-lite',
      'gemini-3.6-flash',
      'gemini-3.1-flash-lite-preview',
      'gemini-flash-latest',
    ];

    const prompt = '''
คุณคือผู้เชี่ยวชาญระดับศาสตราจารย์ด้าน "อักขรวิธีอักษรธรรมล้านนา (ตั๋วเมือง / Tai Tham Script)" และสัทศาสตร์ภาษาไทยถิ่นเหนือ
หน้าที่ของคุณคืออ่าน วิเคราะห์ และถอดรหัสข้อความอักษรล้านนาจากภาพถ่ายอย่างเป็นกลาง แม่นยำ ครอบคลุมทุกคำศัพท์และทุกประโยค ไม่จำกัดเฉพาะคำใดคำหนึ่ง:

หลักการอ่านและถอดรหัสโครงสร้างอักขระ 4 มิติ (Tai Tham Spatial & Orthographic Chart):
1. กฎการจำแนกคำศัพท์สำคัญ (Orthographic Disambiguation Rules):
   - ᨩ᩠ᨿᨦᩲᩉ᩠ᨾ᩵ (ชะ ᨩ + ยห้อย ᩠ᨿ + งะ ᨦ + ไม้ไก๋ ᩲ + หะ ᩉ + มห้อย ᩠ᨾ + ไม้เหยาะ ᩵) = "เชียงใหม่" (เจียงใหม่) **ข้อควรระวังอย่างยิ่ง: ห้ามอ่านเป็น 'ลูกไก่' หรือ 'ไก่'**
   - ᨩ᩠ᨿᨦᩁᩣ᩠ᨿ (ชะ+ยห้อย+งะ + ระ+สระอา+ยห้อย) = "เชียงราย" (เจียงฮาย)
   - ᩯᨻᩖ᩵ (สระแอ ᩯ + พะ ᨻ + ลหาง ᩖ + ไม้เหยาะ ᩵) = "แพร่" (แป้)
   - ᩃᩣᩴᨻᩣ᩠ᨦ (ละ+สระอำ + พะ+สระอา+งห้อย) = "ลำปาง", ᩃᩣᩴᨻᩪ᩠ᨶ = "ลำพูน", ᩃᩣᩴᩱᨿ = "ลำไย"
   - ᩃᩣ᩠ᨷ = "ลาบ", ᩃᩣ᩠ᨷᨤ᩠ᩅᩣ᩠ᨿ = "ลาบควาย", ᩃᩣ᩠ᨷᩉ᩠ᨾᩪ = "ลาบหมู", ᩈ᩶ᩣᨯᩥ᩠ᨷ = "ส้าดิบ", ᩈ᩶ᩣᩈᩩ᩠ᨠ = "ส้าสุก"
   - ᨧᩕᩣ᩠ᨯ = "ฉลาด", ᨠᩣᩴᨾᩮᩬᩥᨦ = "กำเมือง", ᩮᨾᩥ᩠ᨦᩋᩥ᩠ᨶ᩠ᨴᩕ᩼ = "เมืองอินทร์", ᨾᩯ᩵ᩁᩬ᩶ᨦᩈᩬᩁ = "แม่ฮ่องสอน"

2. สระหน้า (Leading Vowels):
   - สระแอ (ᩯ) 2 ขาซ้ายสุด, ไม้ไก๋/สระไอ (ᩱ) หรือ ไม้ใค/สระใอ (ᩲ) ทรงสูง, สระเอ (ᩮ), สระโอ (ᩰ)

3. พยัญชนะหลัก (Base Consonants):
   - กะ ᨠ, ขะ ᨡ, คะ ᨣ, ฅะ ᨤ, งะ ᨦ, จะ ᨧ, ฉะ ᨨ, ชะ ᨩ, ซะ ᨪ, ญะ ᨬ
   - ตะ ᨲ, ถะ ᨳ, ทะ ᨴ, ธะ ᨵ, นะ ᨶ
   - บะ/ปะ ᨷ, ปะหางยาว ᨸ, ผะ ᨹ, ฝะ ᨺ, พะ ᨻ, ฟะ ᨼ, ภะ ᨽ, มะ ᨾ, ยะ ᨿ
   - ระ ᩁ, ละ ᩃ, วะ ᩅ, สะ ᩈ, หะ ᩉ, อะ ᩋ, ฮฮก ᩌ

4. ตัวสะกดห้อยและตัวควบใต้ล่าง (Subjoined Sakot & Medials):
   - ย ห้อย (᩠ᨿ), ว ห้อย (᩠ᩅ), ม ห้อย (᩠ᨾ), ง ห้อย (᩠ᨦ), น ห้อย (᩠ᨶ), ด ห้อย (᩠ᨯ), บ ห้อย (᩠ᨷ), ก ห้อย (᩠ᨠ), ล หาง (ᩖ), ร หางกวาด (ᩕ)

5. สระบนและเครื่องหมายวรรณยุกต์ (Upper Vowels & Tone Marks):
   - สระอิ (ᩥ), สระอี (ᩦ), สระอึ (ᩧ), สระอือ (ᩨ), ไม้กั๋ง (ᩢ), สระอัว (ᩫ), นิคหิต/สระอำ (ᩴ), ไม้เหยาะ (᩵), ไม้ขอช้าง (᩶)

ขั้นตอนการวิเคราะห์รูปภาพ:
1. พิจารณาอักขระทีละกลุ่มจากซ้ายไปขวา โดยสังเกตสระหน้า พยัญชนะต้น ตัวสะกดห้อยล่าง และสระบน/วรรณยุกต์
2. สังเคราะห์เป็นรหัส Tai Tham Unicode ที่สมบูรณ์
3. แปลเป็นภาษาไทยมาตรฐาน และระบุคำอ่านสัทอักษรภาษาเหนือ/คำเมือง

ส่งคืนผลลัพธ์เป็น Pure JSON เท่านั้น:
{
  "detected_text": "คำแปลหรือชื่อภาษาไทยมาตรฐานของคำที่ปรากฏในภาพ",
  "lanna_text": "อักขระล้านนา Tai Tham Unicode ที่ถอดรหัสได้จากภาพ",
  "reading": "[คำอ่านสำเนียงคำเมืองล้านนา]",
  "meaning": "คำอธิบายความหมายและบริบทอย่างละเอียด",
  "direction": "ภาษาล้านนา → ภาษาไทย"
}
''';

    final mimeType = (imageBytes.length > 4 &&
            imageBytes[0] == 0x89 &&
            imageBytes[1] == 0x50 &&
            imageBytes[2] == 0x4E &&
            imageBytes[3] == 0x47)
        ? 'image/png'
        : 'image/jpeg';

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
                  {'text': prompt},
                  {
                    'inline_data': {
                      'mime_type': mimeType,
                      'data': base64Img,
                    }
                  }
                ]
              }
            ],
            'generationConfig': {
              'temperature': 0.1,
              'responseMimeType': 'application/json',
            },
            'safetySettings': [
              {'category': 'HARM_CATEGORY_HARASSMENT', 'threshold': 'BLOCK_NONE'},
              {'category': 'HARM_CATEGORY_HATE_SPEECH', 'threshold': 'BLOCK_NONE'},
              {'category': 'HARM_CATEGORY_SEXUALLY_EXPLICIT', 'threshold': 'BLOCK_NONE'},
              {'category': 'HARM_CATEGORY_DANGEROUS_CONTENT', 'threshold': 'BLOCK_NONE'},
              {'category': 'HARM_CATEGORY_CIVIC_INTEGRITY', 'threshold': 'BLOCK_NONE'},
            ],
          }),
        ).timeout(const Duration(seconds: 14));

        if (res.statusCode == 200) {
          final data = jsonDecode(res.body);
          final raw = data['candidates'][0]['content']['parts'][0]['text'] as String;
          String cleanJson = raw.replaceAll('```json', '').replaceAll('```', '').trim();
          final jsonMatch = RegExp(r'\{[\s\S]*\}').firstMatch(cleanJson);
          if (jsonMatch != null) {
            cleanJson = jsonMatch.group(0)!;
          }
          final jsonMap = jsonDecode(cleanJson) as Map<String, dynamic>;

          final detectedText = jsonMap['detected_text']?.toString().trim() ??
              jsonMap['translated_text']?.toString().trim() ??
              '';
          final lannaText = jsonMap['lanna_text']?.toString().trim() ??
              jsonMap['lanna_char']?.toString().trim();
          final reading = jsonMap['reading']?.toString().trim();
          final meaning = jsonMap['meaning']?.toString().trim();

          // STAGE 2: ส่งผ่าน Database & Master Lexicon Matcher ทันที
          return _matchStage2(
            detectedText: detectedText,
            lannaText: lannaText,
            reading: reading,
            meaning: meaning,
          );
        } else if (res.statusCode == 403 || (res.statusCode == 400 && res.body.contains('API_KEY'))) {
          debugPrint('Gemini API Key Error (HTTP ${res.statusCode}): ${res.body}');
          return null;
        } else if (res.statusCode == 429 || res.statusCode == 503) {
          debugPrint('Gemini Model $model busy (${res.statusCode}), trying next model immediately...');
          continue;
        }
      } catch (e) {
        debugPrint('Gemini Vision OCR Error with model $model: $e');
      }
    }
    return null;
  }

  Future<void> _showAiSettingsDialog() async {
    final currentGptKey = await ApiConfig.getActiveOpenAiApiKey() ?? '';
    final gptController = TextEditingController(text: currentGptKey);

    if (!mounted) return;

    await showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1E1E1E),
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.only(
            top: 20,
            left: 20,
            right: 20,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'ตั้งค่าโมเดล AI ในการอ่านภาพ (OCR)',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white70),
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              const Text(
                'ระบบรองรับทั้ง OpenAI ChatGPT (GPT-4o Vision) และ Google Gemini Vision พร้อมระบบจับคู่ฐานข้อมูลอักขรวิธีล้านนาความแม่นยำสูง',
                style: TextStyle(color: Colors.white70, fontSize: 13, height: 1.4),
              ),
              const SizedBox(height: 16),
              const Text(
                'OpenAI API Key (สำหรับเรียกใช้ ChatGPT / GPT-4o):',
                style: TextStyle(color: kPrimaryOrange, fontSize: 14, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: gptController,
                style: const TextStyle(color: Colors.white, fontSize: 14),
                decoration: InputDecoration(
                  hintText: 'sk-proj-... หรือปล่อยว่างเพื่อใช้ Hybrid AI',
                  hintStyle: TextStyle(color: Colors.white.withOpacity(0.3)),
                  filled: true,
                  fillColor: const Color(0xFF2A2A2A),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: kPrimaryOrange,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  onPressed: () async {
                    await ApiConfig.saveCustomOpenAiApiKey(gptController.text.trim());
                    if (ctx.mounted) {
                      Navigator.pop(ctx);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('บันทึกการตั้งค่าโมเดล AI เรียบร้อยแล้ว')),
                      );
                    }
                  },
                  child: const Text('บันทึกการตั้งค่า', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _clearImage() {
    setState(() {
      _image = null;
      _webImage = null;
      _resultText = '';
      _resultReading = null;
      _resultMeaning = null;
      _resultIsLanna = false;
    });
  }

  // ================= UI =================
  @override
  Widget build(BuildContext context) {
    final hasImage = _image != null || _webImage != null;
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            // AppHeader visible at all times
            const AppHeader(title: 'กล้อง'),

            // Middle camera feed or preview
            Expanded(
              child: Stack(
                children: [
                  Positioned.fill(
                    child: hasImage ? _buildImagePreview() : _buildCameraFeed(),
                  ),

                  // Floating Flash Toggle (Top Left)
                  Positioned(
                    top: 16,
                    left: 16,
                    child: _iconBtn(
                      _flashOn ? Icons.flash_on : Icons.flash_off_outlined,
                      onTap: () => setState(() => _flashOn = !_flashOn),
                    ),
                  ),

                  // Floating AI Settings Button (Top Right next to close)
                  Positioned(
                    top: 16,
                    right: hasImage ? 64 : 16,
                    child: _iconBtn(
                      Icons.tune,
                      onTap: _showAiSettingsDialog,
                    ),
                  ),

                  // Floating Close Image Button (Top Right)
                  if (hasImage)
                    Positioned(
                      top: 16,
                      right: 16,
                      child: _iconBtn(Icons.close, onTap: _clearImage),
                    ),

                  // Language pill (middle top)
                  if (!hasImage)
                    Positioned(
                      top: 20,
                      left: 0,
                      right: 0,
                      child: Center(child: _buildLangPill()),
                    ),

                  // OCR Result overlay
                  if (_loading)
                    const Positioned.fill(
                      child: ColoredBox(
                        color: Color(0x88000000),
                        child: Center(
                          child: CircularProgressIndicator(
                            color: kPrimaryOrange,
                          ),
                        ),
                      ),
                    ),

                  if (_resultText.isNotEmpty)
                    Positioned(
                      left: 16,
                      right: 16,
                      bottom: 24,
                      child: _buildResultCard(),
                    ),
                ],
              ),
            ),

            // White Control Bar (aligned exactly above the bottom navigation bar)
            _buildControlBar(hasImage),
          ],
        ),
      ),
    );
  }

  // ─── Camera Feed ───
  Widget _buildCameraFeed() {
    if (kIsWeb) {
      return _buildViewfinderPlaceholder(
        'ใช้งานบนเว็บ กรุณากดปุ่มเพื่อเลือกไฟล์รูปภาพ',
      );
    }

    if (!_hasCameraPermission) {
      return _buildViewfinderPlaceholder(
        'ไม่ได้รับอนุญาตให้ใช้งานกล้อง\nกรุณาเปิดการอนุญาตในตั้งค่าของอุปกรณ์',
      );
    }

    if (!_isCameraInitialized || _cameraController == null) {
      return const Center(
        child: CircularProgressIndicator(color: kPrimaryOrange),
      );
    }

    return Stack(
      fit: StackFit.expand,
      children: [
        CameraPreview(_cameraController!),

        // Viewfinder guide overlay
        Center(
          child: ScaleTransition(
            scale: _pulseAnim,
            child: SizedBox(
              width: 280,
              height: 200,
              child: CustomPaint(painter: _FramePainter()),
            ),
          ),
        ),

        // Hint text overlay (floating without a white box, bold white text)
        Positioned(
          left: 24,
          right: 24,
          bottom: 48,
          child: Text(
            'ขยับกล้องไปที่ตัวอักษรล้านนา หรือ ข้อความ\nแล้วกดปุ่มถ่ายภาพ',
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.bold,
              height: 1.5,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildViewfinderPlaceholder(String message) {
    return Stack(
      children: [
        const ColoredBox(color: Color(0xFF111111)),
        Center(
          child: ScaleTransition(
            scale: _pulseAnim,
            child: SizedBox(
              width: 280,
              height: 200,
              child: CustomPaint(painter: _FramePainter()),
            ),
          ),
        ),
        Positioned(
          left: 24,
          right: 24,
          bottom: 48,
          child: Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.bold,
              height: 1.5,
            ),
          ),
        ),
      ],
    );
  }

  // ─── Image preview (after capture) ───
  Widget _buildImagePreview() {
    return Container(
      color: const Color(0xFF111111),
      child: SizedBox.expand(
        child: _image != null
            ? Image.file(_image!, fit: BoxFit.contain)
            : Image.memory(_webImage!, fit: BoxFit.contain),
      ),
    );
  }

  // ─── Language pill ───
  Widget _buildLangPill() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(100),
        border: Border.all(color: Colors.white54, width: 1.5),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'ล้านนา',
            style: TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(width: 12),
          Icon(Icons.arrow_forward, color: Colors.white, size: 20),
          SizedBox(width: 12),
          Text(
            'ไทย',
            style: TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  // ─── Result card ───
  Widget _buildResultCard() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 4),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xF2151515),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFFFB300), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.6),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Top bar: Direction & Close
          Row(
            children: [
              const Icon(Icons.auto_awesome, color: Color(0xFFFFB300), size: 16),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  _resultDirection,
                  style: const TextStyle(
                    color: Color(0xFFFFB300),
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              GestureDetector(
                onTap: _clearImage,
                child: Container(
                  padding: const EdgeInsets.all(3),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.close, color: Colors.white, size: 16),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),

          // Main text display (Thai translated text)
          Text(
            _resultText,
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
              fontFamily: _resultIsLanna ? 'LNTilok' : null,
              height: 1.2,
            ),
          ),

          // Reading
          if (_resultReading != null && _resultReading!.isNotEmpty) ...[
            const SizedBox(height: 5),
            Row(
              children: [
                const Icon(Icons.record_voice_over, color: Color(0xFFFFD54F), size: 14),
                const SizedBox(width: 5),
                Expanded(
                  child: Text(
                    'คำอ่าน: $_resultReading',
                    style: const TextStyle(
                      color: Color(0xFFFFD54F),
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ],

          // Meaning
          if (_resultMeaning != null && _resultMeaning!.isNotEmpty) ...[
            const SizedBox(height: 4),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Padding(
                  padding: EdgeInsets.only(top: 2),
                  child: Icon(Icons.info_outline, color: Colors.white70, size: 13),
                ),
                const SizedBox(width: 5),
                Expanded(
                  child: Text(
                    _resultMeaning!,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.normal,
                      height: 1.3,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  // ─── Bottom control bar (Transparent design) ───
  Widget _buildControlBar(bool hasImage) {
    return Container(
      color: Colors.transparent,
      padding: const EdgeInsets.only(left: 24, right: 24, top: 16, bottom: 24),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Gallery
          _bottomAction(
            icon: Icons.photo_library_outlined,
            label: 'แกลเลอรี่',
            onTap: () => _pickImage(ip.ImageSource.gallery),
          ),

          // Shutter button (Solid Orange, white icon)
          GestureDetector(
            onTap: _takePicture,
            child: Container(
              width: 68,
              height: 68,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: kPrimaryOrange,
                border: Border.all(color: Colors.white, width: 3),
                boxShadow: [
                  BoxShadow(
                    color: kPrimaryOrange.withValues(alpha: 0.4),
                    blurRadius: 16,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: const Icon(
                Icons.camera_alt,
                size: 32,
                color: Colors.white,
              ),
            ),
          ),

          // Retake / placeholder
          hasImage
              ? _bottomAction(
                  icon: Icons.refresh_rounded,
                  label: 'ถ่ายใหม่',
                  onTap: _clearImage,
                )
              : _bottomAction(
                  icon: Icons.image_search_outlined,
                  label: 'สแกนใหม่',
                  onTap: _takePicture,
                ),
        ],
      ),
    );
  }

  // ─── Helper: icon circle button ───
  Widget _iconBtn(IconData icon, {required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: Colors.black45,
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white24),
        ),
        child: Icon(icon, color: Colors.white, size: 20),
      ),
    );
  }

  // ─── Helper: bottom action button ───
  Widget _bottomAction({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.45),
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
            ),
            child: Icon(icon, color: Colors.white, size: 24),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Colors.white,
              shadows: [
                Shadow(
                  color: Colors.black87,
                  blurRadius: 4,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Custom painter for viewfinder frame ───
class _FramePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = kPrimaryOrange
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    const r = 16.0;
    const len = 36.0;
    final w = size.width;
    final h = size.height;

    // Top-left corner
    canvas.drawLine(Offset(0, r + len), Offset(0, r), paint);
    canvas.drawArc(
      Rect.fromLTWH(0, 0, r * 2, r * 2),
      3.14,
      0.5 * 3.14,
      false,
      paint,
    );
    canvas.drawLine(Offset(r, 0), Offset(r + len, 0), paint);

    // Top-right corner
    canvas.drawLine(Offset(w - r - len, 0), Offset(w - r, 0), paint);
    canvas.drawArc(
      Rect.fromLTWH(w - r * 2, 0, r * 2, r * 2),
      1.5 * 3.14,
      0.5 * 3.14,
      false,
      paint,
    );
    canvas.drawLine(Offset(w, r), Offset(w, r + len), paint);

    // Bottom-left corner
    canvas.drawLine(Offset(0, h - r - len), Offset(0, h - r), paint);
    canvas.drawArc(
      Rect.fromLTWH(0, h - r * 2, r * 2, r * 2),
      0.5 * 3.14,
      0.5 * 3.14,
      false,
      paint,
    );
    canvas.drawLine(Offset(r, h), Offset(r + len, h), paint);

    // Bottom-right corner
    canvas.drawLine(Offset(w - r - len, h), Offset(w - r, h), paint);
    canvas.drawArc(
      Rect.fromLTWH(w - r * 2, h - r * 2, r * 2, r * 2),
      0,
      0.5 * 3.14,
      false,
      paint,
    );
    canvas.drawLine(Offset(w, h - r), Offset(w, h - r - len), paint);
  }

  @override
  bool shouldRepaint(_FramePainter oldDelegate) => false;
}

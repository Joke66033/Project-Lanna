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
import '../widgets/app_header.dart';

const Color kPrimaryOrange = Color(0xFF924E19);

class _CameraOcrResult {
  final String text;
  final String? reading;
  final String? meaning;
  final bool isLannaOutput;
  final String directionLabel;

  const _CameraOcrResult({
    required this.text,
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
  bool _resultIsLanna = true;
  String _resultDirection = 'ภาษาไทย → ภาษาล้านนา';

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

    // Initialize live camera preview if starting as active
    if (!kIsWeb && widget.isActive) {
      _initLiveCamera();
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
      debugPrint('Typhoon OCR unavailable, using local OCR: $error');
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
        setState(() {
          _resultText = raw.isEmpty ? '' : _conv.thaiToLanna(raw);
          _resultReading = null;
          _resultMeaning = null;
          _resultIsLanna = true;
          _resultDirection = 'ภาษาไทย → ภาษาล้านนา';
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
            ? 'ไม่สามารถเชื่อมต่อกับเซิร์ฟเวอร์ OCR ได้ กรุณาตรวจสอบการเชื่อมต่ออินเทอร์เน็ต หรือสถานะเซิร์ฟเวอร์'
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

  Future<_CameraOcrResult> _requestAutoOcr(
    Uint8List imageBytes,
    String filename,
  ) async {
    // 1. ใช้ Gemini Vision AI
    try {
      final geminiResult = await _requestGeminiVisionOcr(imageBytes);
      if (geminiResult != null && geminiResult.text.trim().isNotEmpty) {
        return geminiResult;
      }
    } catch (error) {
      debugPrint('Gemini Vision OCR unavailable: $error');
    }

    // 2. Fallback ไปยัง Unified Backend OCR
    try {
      final request = http.MultipartRequest(
        'POST',
        Uri.parse(ApiConfig.autoOcr),
      );
      request.files.add(
        http.MultipartFile.fromBytes('file', imageBytes, filename: filename),
      );
      final streamedResponse = await request.send().timeout(
        const Duration(seconds: 40),
      );
      final response = await http.Response.fromStream(streamedResponse);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          final translated = (data['translatedText'] ?? '').toString().trim();
          final detected = (data['detectedText'] ?? '').toString().trim();
          final isLannaToThai = (data['detectedLanguage'] ?? '') == 'lanna';
          return _CameraOcrResult(
            text: translated.isNotEmpty ? translated : detected,
            reading: data['reading']?.toString(),
            meaning: data['meaning']?.toString(),
            isLannaOutput: !isLannaToThai,
            directionLabel: isLannaToThai
                ? 'ภาษาล้านนา → ภาษาไทย (AI Vision)'
                : 'ภาษาไทย → ภาษาล้านนา',
          );
        }
      }
    } catch (error) {
      debugPrint('Unified OCR endpoint unavailable: $error');
    }

    // Compatibility fallback
    return _requestLegacyAutoOcr(imageBytes, filename);
  }

  /// อ่านและแปลอักษรล้านนาจากภาพถ่ายด้วย Google Gemini Vision AI
  Future<_CameraOcrResult?> _requestGeminiVisionOcr(Uint8List imageBytes) async {
    const apiKey = 'AIzaSyCj8rr8MGBBYGOVJgP0oaIplIZLDe7ub-c';
    final base64Img = base64Encode(imageBytes);
    const models = ['gemini-3.5-flash', 'gemini-3.5-flash-lite', 'gemini-flash-latest'];

    const prompt = '''
You are a leading expert in Tai Tham (Lanna script / ตั๋วเมือง), Northern Thai dialect (คำเมือง), and Thai typography/signboard OCR.

Carefully inspect the image:
1. Detect and transcribe the main text in the image. The text may be Lanna script (ตั๋วเมือง), Thai text, or a signboard with English subtitle (e.g. 'CHIWIT THAMMA DA' -> 'ชีวิตธรรมดา').
2. Accurately decipher the Lanna script characters (e.g. ᨩᩦᩅᩥ᩠ᨲ = ชีวิต, ᨵᨾ᩠ᨾᨯᩣ = ธรรมดา, ᩈ᩠ᩅᩢᩔᨯᩦ = สวัสดี, ᨩ᩠ᨿᨦᩁᩣᨿ = เชียงราย, ᨩ᩠ᨿᨦᩲᩉ᩠ᨾ᩵ = เชียงใหม่, ᩃᩣ᩠ᨷ = ลาบ, ᩯᨾ᩵ᩁᩬ᩵ᨦᩈᩬᩁ = แม่ฮ่องสอน, etc.).
3. Provide the accurate Thai translation, the Northern Thai / Thai phonetic pronunciation in square brackets, and a helpful contextual meaning/explanation.

Output strictly pure JSON format:
{
  "detected_text": "ข้อความภาษาไทยที่แปล/ถอดความได้จากภาพ (เช่น ชีวิตธรรมดา หรือ สวัสดี)",
  "reading": "[คำอ่านสำเนียง เช่น ชี-วิด-ทำ-มะ-ดา]",
  "meaning": "คำอธิบายความหมาย บริบท หรือสถานที่ให้เข้าใจง่าย 1-2 ประโยค"
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
                  {'text': prompt},
                  {
                    'inline_data': {
                      'mime_type': 'image/jpeg',
                      'data': base64Img,
                    }
                  }
                ]
              }
            ]
          }),
        ).timeout(const Duration(seconds: 25));

        if (res.statusCode == 200) {
          final data = jsonDecode(res.body);
          final raw = data['candidates'][0]['content']['parts'][0]['text'] as String;
          final cleanJson = raw.replaceAll('```json', '').replaceAll('```', '').trim();
          final jsonMap = jsonDecode(cleanJson) as Map<String, dynamic>;

          final detectedText = jsonMap['detected_text']?.toString().trim() ??
              jsonMap['translated_text']?.toString().trim() ??
              '';

          if (detectedText.isNotEmpty) {
            return _CameraOcrResult(
              text: detectedText,
              reading: jsonMap['reading']?.toString().trim(),
              meaning: jsonMap['meaning']?.toString().trim(),
              isLannaOutput: false,
              directionLabel: 'ภาษาล้านนา → ภาษาไทย (AI Vision)',
            );
          }
        }
      } catch (e) {
        debugPrint('Gemini Vision OCR Error with model $model: $e');
      }
    }
    return null;
  }

  Future<_CameraOcrResult> _requestLegacyAutoOcr(
    Uint8List imageBytes,
    String filename,
  ) async {
    // Prefer Lanna -> Thai only when the experimental classifier is confident.
    // A low-confidence Lanna result must never override readable Thai OCR.
    try {
      final lannaResult = await _requestLannaOcr(imageBytes, filename);
      if (lannaResult != null) return lannaResult;
    } catch (error) {
      debugPrint('Experimental Lanna OCR unavailable: $error');
    }

    final thaiText = await _requestTyphoonOcr(imageBytes, filename);
    final lannaText = _conv.thaiToLanna(thaiText);
    if (lannaText.trim().isEmpty) {
      throw Exception('ไม่พบข้อความภาษาไทยในภาพ');
    }
    return _CameraOcrResult(
      text: lannaText,
      isLannaOutput: true,
      directionLabel: 'ภาษาไทย → ภาษาล้านนา',
    );
  }

  Future<_CameraOcrResult?> _requestLannaOcr(
    Uint8List imageBytes,
    String filename,
  ) async {
    final request = http.MultipartRequest(
      'POST',
      Uri.parse(ApiConfig.lannaOcr),
    );
    request.files.add(
      http.MultipartFile.fromBytes('file', imageBytes, filename: filename),
    );
    final streamedResponse = await request.send().timeout(
      const Duration(seconds: 120),
    );
    final response = await http.Response.fromStream(streamedResponse);
    if (response.statusCode < 200 || response.statusCode >= 300) return null;

    final decoded = jsonDecode(response.body) as Map<String, dynamic>;
    final data = decoded['data'] as Map<String, dynamic>?;
    final isLowConfidence = data?['is_low_confidence'] as bool? ?? true;
    final confidence = (data?['confidence'] as num?)?.toDouble() ?? 0;
    final text = (data?['text'] as String? ?? '').trim();
    if (isLowConfidence || confidence < 0.65 || text.isEmpty) return null;

    return _CameraOcrResult(
      text: text,
      isLannaOutput: false,
      directionLabel: 'ภาษาล้านนา → ภาษาไทย (ทดลอง)',
    );
  }

  Future<String> _requestTyphoonOcr(
    Uint8List imageBytes,
    String filename,
  ) async {
    final request = http.MultipartRequest(
      'POST',
      Uri.parse(ApiConfig.typhoonOcr),
    );
    request.files.add(
      http.MultipartFile.fromBytes('file', imageBytes, filename: filename),
    );

    final streamedResponse = await request.send().timeout(
      const Duration(seconds: 120),
    );
    final response = await http.Response.fromStream(streamedResponse);
    final decoded = jsonDecode(response.body) as Map<String, dynamic>;

    if (response.statusCode < 200 || response.statusCode >= 300) {
      final error = decoded['error'] as Map<String, dynamic>?;
      throw Exception(error?['message'] ?? 'ไม่สามารถอ่านภาพได้');
    }

    final data = decoded['data'] as Map<String, dynamic>?;
    final text = (data?['text'] as String? ?? '').trim();
    if (text.isEmpty) {
      throw Exception('ไม่พบอักษรในภาพ');
    }
    return text;
  }

  void _clearImage() {
    setState(() {
      _image = null;
      _webImage = null;
      _resultText = '';
      _resultReading = null;
      _resultMeaning = null;
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
            'ขยับกล้องไปที่ข้อความภาษาไทย\nแล้ว กด ปุ่มถ่ายภาพ',
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 10,
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
            'ไทย',
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
            'ล้านนา',
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
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xE61E1E1E),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: kPrimaryOrange.withValues(alpha: 0.6)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.5),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              const Icon(Icons.auto_awesome, color: kPrimaryOrange, size: 18),
              const SizedBox(width: 6),
              Text(
                _resultDirection,
                style: const TextStyle(
                  color: kPrimaryOrange,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              GestureDetector(
                onTap: _clearImage,
                child: const Icon(Icons.close, color: Colors.white54, size: 20),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            _resultText,
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
              fontFamily: _resultIsLanna ? 'LNTilok' : null,
              height: 1.4,
            ),
          ),
          if (_resultReading != null && _resultReading!.isNotEmpty) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.record_voice_over, color: Color(0xFFFFB74D), size: 16),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    'คำอ่าน: $_resultReading',
                    style: const TextStyle(
                      color: Color(0xFFFFB74D),
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ],
          if (_resultMeaning != null && _resultMeaning!.isNotEmpty) ...[
            const SizedBox(height: 8),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Padding(
                  padding: EdgeInsets.only(top: 2),
                  child: Icon(Icons.menu_book_rounded, color: Colors.white60, size: 15),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    _resultMeaning!,
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 13,
                      height: 1.4,
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

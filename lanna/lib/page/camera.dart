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
  final bool isLannaOutput;
  final String directionLabel;

  const _CameraOcrResult({
    required this.text,
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
        _resultIsLanna = result.isLannaOutput;
        _resultDirection = result.directionLabel;
      });
    } catch (error) {
      debugPrint('Typhoon OCR unavailable, using local OCR: $error');
      await _processImageWithLocalOcr(file);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Typhoon OCR ยังไม่พร้อม ระบบจึงใช้การอ่านภาษาไทยบนเครื่องแทน',
            ),
          ),
        );
      }
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
          _resultIsLanna = result.isLannaOutput;
          _resultDirection = result.directionLabel;
        });
      }
    } catch (error) {
      debugPrint('Typhoon OCR error: $error');
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
    try {
      final request = http.MultipartRequest(
        'POST',
        Uri.parse(ApiConfig.autoOcr),
      );
      request.files.add(
        http.MultipartFile.fromBytes('file', imageBytes, filename: filename),
      );
      final streamedResponse = await request.send().timeout(
        const Duration(seconds: 150),
      );
      final response = await http.Response.fromStream(streamedResponse);
      final decoded = jsonDecode(response.body) as Map<String, dynamic>;
      if (response.statusCode >= 200 && response.statusCode < 300) {
        final data = decoded['data'] as Map<String, dynamic>?;
        final text = (data?['text'] as String? ?? '').trim();
        final isLannaOutput = data?['is_lanna_output'] as bool? ?? false;
        final direction = data?['direction'] as String? ?? '';
        if (text.isNotEmpty) {
          return _CameraOcrResult(
            text: text,
            isLannaOutput: isLannaOutput,
            directionLabel: direction == 'lanna_to_thai'
                ? 'ภาษาล้านนา → ภาษาไทย (ทดลอง)'
                : 'ภาษาไทย → ภาษาล้านนา',
          );
        }
      }
    } catch (error) {
      debugPrint('Unified OCR endpoint unavailable: $error');
    }

    // Compatibility fallback while an older PHP backend is still deployed.
    return _requestLegacyAutoOcr(imageBytes, filename);
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
    });
  }

  // ================= UI =================
  @override
  Widget build(BuildContext context) {
    final hasImage = _image != null || _webImage != null;
    return Scaffold(
      backgroundColor: Colors.white,
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
        color: Colors.black.withValues(alpha: 0.75),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: kPrimaryOrange.withValues(alpha: 0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.translate, color: kPrimaryOrange, size: 18),
              const SizedBox(width: 6),
              const Text(
                'ผลการแปล',
                style: TextStyle(
                  color: kPrimaryOrange,
                  fontSize: 8,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              GestureDetector(
                onTap: () => setState(() => _resultText = ''),
                child: const Icon(Icons.close, color: Colors.white54, size: 18),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            _resultDirection,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            _resultText,
            style: TextStyle(
              color: Colors.white,
              fontSize: 19,
              fontFamily: _resultIsLanna ? 'PayapLanna' : null,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  // ─── Bottom control bar (White design) ───
  Widget _buildControlBar(bool hasImage) {
    return Container(
      padding: const EdgeInsets.only(left: 24, right: 24, top: 12, bottom: 12),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 10,
            offset: Offset(0, -2),
          ),
        ],
      ),
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
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: kPrimaryOrange,
                boxShadow: [
                  BoxShadow(
                    color: kPrimaryOrange.withValues(alpha: 0.35),
                    blurRadius: 12,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: const Icon(
                Icons.camera_alt,
                size: 30,
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
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: const Color(0xFFF5EAE1),
              shape: BoxShape.circle,
              border: Border.all(color: const Color(0xFFEADBC8)),
            ),
            child: Icon(icon, color: kPrimaryOrange, size: 22),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(
              fontSize: 8,
              fontWeight: FontWeight.bold,
              color: Color(0xFF7A5C3A),
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

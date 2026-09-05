import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ApiConfig {
  // --- HOSTING CONFIGURATION ---
  // ตั้งค่าเป็น true เมื่อต้องการเชื่อมต่อกับ Hosting จริง
  // Hosting is the default because the local PHP server cannot access the
  // hosting database. It can still be overridden for local-only development
  // with: --dart-define=USE_HOSTING=false
  // Production API is the single source of truth for the app. Keep this
  // fixed so a stale local dart-define cannot redirect normal app traffic.
  static const bool useHosting = true;
  static const String _hostingUrl = 'https://siripaporn.lnw.mn';
  // Translation is intentionally isolated from the production PHP API.
  // Only the translate page calls this local AI service.
  static const String aiTranslationBaseUrl = 'http://localhost:8005';

  // Google Gemini API Key for Live Vision and Smart Translation
  // You can obtain a free key at: https://aistudio.google.com/app/apikey
  static final String _defaultKey = utf8.decode(
    base64.decode('QVEuQWI4Uk42SVctZUVRdVdWMXdnZ0lZRFhWUUdWMHFneXFRd2MweHJoQ0llOFpwbElmaXc='),
  );
  static String? _customGeminiApiKey;

  static String get geminiApiKey => _defaultKey;

  static Future<String> getActiveGeminiApiKey() async {
    if (_customGeminiApiKey != null && _customGeminiApiKey!.isNotEmpty) {
      return _customGeminiApiKey!;
    }
    try {
      final prefs = await SharedPreferences.getInstance();
      final saved = prefs.getString('custom_gemini_api_key');
      if (saved != null && saved.trim().isNotEmpty) {
        _customGeminiApiKey = saved.trim();
        return _customGeminiApiKey!;
      }
    } catch (_) {}
    return _defaultKey;
  }

  static Future<void> saveCustomGeminiApiKey(String key) async {
    _customGeminiApiKey = key.trim();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('custom_gemini_api_key', key.trim());
    } catch (_) {}
  }

  // Base URLs for different environments (Localhost/Debug)
  static const String _androidEmulatorUrl = 'http://10.10.100.104:8000';
  static const String _localhostUrl = 'http://10.10.100.104:8000';

  // Set this to your host computer's IP address when debugging on a physical mobile device
  static const String physicalDeviceUrl = 'http://10.10.100.104:8000';

  static String get baseUrl {
    if (useHosting) {
      return _hostingUrl;
    }

    if (kIsWeb) {
      return _localhostUrl;
    }

    // Check target platform
    if (defaultTargetPlatform == TargetPlatform.android) {
      // Use emulator loopback address by default for Android
      // Switch to _physicalDeviceUrl if testing on physical device
      return _androidEmulatorUrl;
    }

    return _localhostUrl;
  }

  // Helper getters for specific endpoint files
  static String get users => '$baseUrl/endpoints/users_api.php';
  static String get adminUser => '$baseUrl/endpoints/admin_user_api.php';
  static String get articles => '$baseUrl/endpoints/articles_api.php';
  static String get categoryLannaChar =>
      '$baseUrl/endpoints/category_lanna_char_api.php';
  static String get categoryVocab =>
      '$baseUrl/endpoints/category_vocab_api.php';
  static String get lannaChar => '$baseUrl/endpoints/lanna_char_api.php';
  static String get vocabulary => '$baseUrl/endpoints/vocabulary_api.php';
  static String get favorites => '$baseUrl/endpoints/favorites_api.php';
  static String get translateLogs =>
      '$baseUrl/endpoints/translate_logs_api.php';
  static String get uploadProfile =>
      '$baseUrl/endpoints/upload_profile_api.php';
  static String get otp => '$baseUrl/endpoints/otp_api.php';
  static String get learningCategory =>
      '$baseUrl/endpoints/learning_category_api.php';
  static String get typhoonOcr => '$baseUrl/endpoints/typhoon_ocr_api.php';
  static String get lannaOcr => '$baseUrl/endpoints/lanna_ocr_api.php';
  static String get autoOcr => '$baseUrl/endpoints/auto_ocr_api.php';
  static String get characterStrokes =>
      '$baseUrl/endpoints/character_strokes_api.php';
}

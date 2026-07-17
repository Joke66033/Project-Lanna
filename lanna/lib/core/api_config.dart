import 'package:flutter/foundation.dart';

class ApiConfig {
  // --- HOSTING CONFIGURATION ---
  // ตั้งค่าเป็น true เมื่อต้องการเชื่อมต่อกับ Hosting จริง
  static const bool useHosting = true;
  static const String _hostingUrl = 'https://siripaporn.lnw.mn';

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
}

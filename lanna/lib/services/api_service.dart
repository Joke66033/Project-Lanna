import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_model.dart';
import '../models/admin_model.dart';

class ApiService {
  static const String _userKey = 'cached_user';
  static const String _adminKey = 'cached_admin';
  static const String _sessionTypeKey = 'session_type'; // 'user', 'admin', or 'guest'
  static const String _tokenKey = 'auth_token';

  static String? _token;

  static String? get token => _token;

  /// Initialize token from local storage
  static Future<void> initToken() async {
    final prefs = await SharedPreferences.getInstance();
    _token = prefs.getString(_tokenKey);
  }

  /// Save token to local storage and memory
  static Future<void> saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, token);
    _token = token;
  }

  /// Clear token from memory and storage
  static Future<void> clearToken() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
    _token = null;
  }

  // ================= SESSION STORAGE =================

  /// Save normal user session
  static Future<void> saveUserSession(UserModel user) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_userKey, jsonEncode(user.toJson()));
    await prefs.setString(_sessionTypeKey, 'user');
  }

  /// Save admin user session
  static Future<void> saveAdminSession(AdminModel admin) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_adminKey, jsonEncode(admin.toJson()));
    await prefs.setString(_sessionTypeKey, 'admin');
  }

  /// Clear all sessions (logout)
  static Future<void> clearSession() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_userKey);
    await prefs.remove(_adminKey);
    await prefs.remove(_tokenKey);
    _token = null;
    await prefs.setString(_sessionTypeKey, 'guest');
  }

  /// Get current session type
  static Future<String> getSessionType() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_sessionTypeKey) ?? 'guest';
  }

  /// Retrieve cached UserModel
  static Future<UserModel?> getCachedUser() async {
    final prefs = await SharedPreferences.getInstance();
    final userStr = prefs.getString(_userKey);
    if (userStr == null) return null;
    try {
      return UserModel.fromJson(jsonDecode(userStr));
    } catch (e) {
      debugPrint('Error decoding cached user: $e');
      return null;
    }
  }

  /// Retrieve cached AdminModel
  static Future<AdminModel?> getCachedAdmin() async {
    final prefs = await SharedPreferences.getInstance();
    final adminStr = prefs.getString(_adminKey);
    if (adminStr == null) return null;
    try {
      return AdminModel.fromJson(jsonDecode(adminStr));
    } catch (e) {
      debugPrint('Error decoding cached admin: $e');
      return null;
    }
  }

  // ================= GENERAL NETWORK WRAPPERS =================

  static Map<String, String> get _headers {
    final Map<String, String> headers = {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };
    if (_token != null && _token!.isNotEmpty) {
      headers['Authorization'] = 'Bearer $_token';
    }
    return headers;
  }

  /// Make GET request and parse standard response format
  static Future<dynamic> get(String url) async {
    try {
      debugPrint('GET REQUEST: $url');
      final response = await http.get(Uri.parse(url), headers: _headers);
      debugPrint('GET RESPONSE [${response.statusCode}]: ${response.body}');
      return _parseResponse(response);
    } catch (e) {
      debugPrint('GET ERROR: $e');
      // ignore: avoid_print
      print(e.toString());
      throw Exception('ไม่สามารถเชื่อมต่อเซิร์ฟเวอร์ได้: $e');
    }
  }

  /// Make POST request with JSON body and parse standard response format
  static Future<dynamic> post(String url, Map<String, dynamic> body) async {
    try {
      debugPrint('POST REQUEST: $url | Body: $body');
      final response = await http.post(
        Uri.parse(url),
        headers: _headers,
        body: jsonEncode(body),
      );
      debugPrint('POST RESPONSE [${response.statusCode}]: ${response.body}');
      return _parseResponse(response);
    } catch (e) {
      debugPrint('POST ERROR: $e');
      // ignore: avoid_print
      print(e.toString());
      throw Exception('ไม่สามารถเชื่อมต่อเซิร์ฟเวอร์ได้: $e');
    }
  }

  /// Helper to parse standard response: {"data": ..., "error": ...}
  static dynamic _parseResponse(http.Response response) {
    final body = response.body.trim();
    if (body.isEmpty) {
      throw Exception('เซิร์ฟเวอร์ตอบกลับด้วยข้อมูลที่ว่างเปล่า');
    }

    final contentType = response.headers['content-type']?.toLowerCase() ?? '';
    final looksLikeHtml =
        contentType.contains('text/html') ||
        body.startsWith('<!DOCTYPE') ||
        body.startsWith('<html') ||
        body.startsWith('<HTML');

    if (looksLikeHtml) {
      throw Exception(
        'เซิร์ฟเวอร์ส่งหน้าเว็บกลับมาแทนข้อมูล API '
        '(HTTP ${response.statusCode}) กรุณาตรวจสอบ URL ของ API',
      );
    }

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception(
        'เซิร์ฟเวอร์ตอบกลับ HTTP ${response.statusCode}: '
        '${body.length > 160 ? '${body.substring(0, 160)}…' : body}',
      );
    }

    dynamic decoded;
    try {
      decoded = jsonDecode(body);
    } on FormatException {
      throw Exception(
        'ข้อมูลจากเซิร์ฟเวอร์ไม่ใช่ JSON ที่ถูกต้อง '
        '(Content-Type: ${contentType.isEmpty ? 'ไม่ระบุ' : contentType})',
      );
    }
    if (decoded is Map<String, dynamic>) {
      if (decoded.containsKey('error') && decoded['error'] != null) {
        final errorMsg = decoded['error']['message'] ?? 'เกิดข้อผิดพลาดในการดึงข้อมูล';
        throw Exception(errorMsg);
      }
      if (decoded.containsKey('data')) {
        return decoded['data'];
      }
    }
    return decoded;
  }
}

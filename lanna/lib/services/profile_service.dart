import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../core/api_config.dart';

class ProfileService {
  /// Upload profile image using absolute file path (Mobile / Desktop)
  Future<String> uploadProfileImage(String id, File file) async {
    try {
      final uri = Uri.parse(ApiConfig.uploadProfile);
      final request = http.MultipartRequest('POST', uri);

      request.fields['id'] = id;
      request.files.add(await http.MultipartFile.fromPath('file', file.path));

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final decoded = jsonDecode(response.body);
        if (decoded['error'] != null) {
          throw Exception(decoded['error']['message'] ?? 'เกิดข้อผิดพลาดในการอัปโหลดรูปโปรไฟล์');
        }
        return decoded['data']['avatar'] ?? '';
      } else {
        throw Exception('เซิร์ฟเวอร์เกิดข้อผิดพลาด: รหัส ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('ล้มเหลวในการอัปโหลดรูปภาพ: $e');
    }
  }

  /// Upload profile image using raw bytes (Web)
  Future<String> uploadProfileImageBytes(String id, Uint8List bytes, String filename) async {
    try {
      final uri = Uri.parse(ApiConfig.uploadProfile);
      final request = http.MultipartRequest('POST', uri);

      request.fields['id'] = id;
      request.files.add(http.MultipartFile.fromBytes('file', bytes, filename: filename));

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final decoded = jsonDecode(response.body);
        if (decoded['error'] != null) {
          throw Exception(decoded['error']['message'] ?? 'เกิดข้อผิดพลาดในการอัปโหลดรูปโปรไฟล์');
        }
        return decoded['data']['avatar'] ?? '';
      } else {
        throw Exception('เซิร์ฟเวอร์เกิดข้อผิดพลาด: รหัส ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('ล้มเหลวในการอัปโหลดรูปภาพ: $e');
    }
  }
}

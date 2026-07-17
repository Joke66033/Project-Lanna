import 'package:flutter/material.dart';
import 'package:lanna/models/user_model.dart';
import 'api_service.dart';
import 'auth_service.dart';

class AuthProvider extends ChangeNotifier {
  UserModel? _user;
  String _sessionType = 'guest'; // 'guest', 'user'
  bool _isLoading = false;

  UserModel? get user => _user;
  String get sessionType => _sessionType;
  bool get isLoading => _isLoading;
  bool get isLoggedIn => _sessionType != 'guest';

  String get currentUserId => _user?.userId ?? '';
  String get currentUsername => _user?.name ?? '';

  final _authService = AuthService();

  AuthProvider() {
    loadPersistedSession();
  }

  /// Initialize and load session from SharedPreferences
  Future<void> loadPersistedSession() async {
    await ApiService.initToken();
    _sessionType = await ApiService.getSessionType();
    if (_sessionType == 'user') {
      _user = await ApiService.getCachedUser();
    } else {
      _user = null;
      _sessionType = 'guest';
    }
    notifyListeners();
  }

  /// Login as User
  Future<void> loginAsUser(String email, String password) async {
    // ห้ามเปลี่ยนไปเรียก admin_user_api.php เด็ดขาด ตารางนี้ใช้สำหรับผู้ใช้ทั่วไปเท่านั้น
    _isLoading = true;
    notifyListeners();

    try {
      final userProfile = await _authService.login(email, password);
      await ApiService.saveUserSession(userProfile);
      _user = userProfile;
      _sessionType = 'user';
      notifyListeners();
    } catch (e) {
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Register as User
  Future<void> register(String username, String email, String password) async {
    _isLoading = true;
    notifyListeners();

    try {
      final userProfile = await _authService.register(username, email, password);
      // Automatically log in after registration
      await ApiService.saveUserSession(userProfile);
      _user = userProfile;
      _sessionType = 'user';
      notifyListeners();
    } catch (e) {
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Update user profile properties in the current state
  void updateSession(dynamic profile) {
    if (profile is UserModel) {
      _user = profile;
    }
    notifyListeners();
  }

  /// Logout
  Future<void> logout() async {
    await ApiService.clearSession();
    await ApiService.clearToken();
    _user = null;
    _sessionType = 'guest';
    notifyListeners();
  }
}

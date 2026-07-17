import '../core/api_config.dart';
import '../models/user_model.dart';
import 'api_service.dart';

class AuthService {
  /// Register a new user
  Future<UserModel> register(String username, String email, String password) async {
    final body = {
      'username': username,
      'email': email,
      'password': password,
    };
    final data = await ApiService.post('${ApiConfig.users}?action=register', body);
    
    // Save token if present
    if (data is Map && data['token'] != null) {
      await ApiService.saveToken(data['token'].toString());
    }

    final userData = data is Map ? (data['user'] ?? data) : data;
    return UserModel.fromJson(userData);
  }

  /// Login a user
  Future<UserModel> login(String email, String password) async {
    final body = {
      'email': email,
      'password': password,
    };
    final data = await ApiService.post('${ApiConfig.users}?action=login', body);
    
    // Save token if present
    if (data is Map && data['token'] != null) {
      await ApiService.saveToken(data['token'].toString());
    }

    final userData = data is Map ? (data['user'] ?? data) : data;
    return UserModel.fromJson(userData);
  }
}

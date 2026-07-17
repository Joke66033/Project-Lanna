import '../core/api_config.dart';
import '../models/user_model.dart';
import 'api_service.dart';

class UserService {
  /// Get all users
  Future<List<UserModel>> getAllUsers() async {
    final data = await ApiService.get('${ApiConfig.users}?action=getAll');
    if (data == null) return [];
    return (data as List).map((x) => UserModel.fromJson(x)).toList();
  }

  /// Get user by ID
  Future<UserModel?> getUserById(String id) async {
    final data = await ApiService.get('${ApiConfig.users}?action=getById&id=$id');
    if (data == null) return null;
    return UserModel.fromJson(data);
  }

  /// Create a new user
  Future<UserModel> createUser(String username, String email) async {
    final body = {
      'username': username,
      'email': email,
    };
    final data = await ApiService.post('${ApiConfig.users}?action=create', body);
    return UserModel.fromJson(data);
  }

  /// Update user status
  Future<UserModel> updateUserStatus(String id, String status) async {
    final body = {'status': status};
    final data = await ApiService.post('${ApiConfig.users}?action=update&id=$id', body);
    return UserModel.fromJson(data);
  }

  /// Update user profile details
  Future<UserModel> updateUser(String id, Map<String, dynamic> fields) async {
    final data = await ApiService.post('${ApiConfig.users}?action=update&id=$id', fields);
    return UserModel.fromJson(data);
  }

  /// Delete user
  Future<UserModel> deleteUser(String id) async {
    final data = await ApiService.post('${ApiConfig.users}?action=delete&id=$id', {});
    return UserModel.fromJson(data);
  }
}

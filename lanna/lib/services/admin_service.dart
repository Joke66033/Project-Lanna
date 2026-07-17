import '../core/api_config.dart';
import '../models/admin_model.dart';
import 'api_service.dart';

class AdminService {
  /// Get all admins
  Future<List<AdminModel>> getAllAdmins() async {
    final data = await ApiService.get('${ApiConfig.adminUser}?action=getAll');
    if (data == null) return [];
    return (data as List).map((x) => AdminModel.fromJson(x)).toList();
  }

  /// Get admin by ID
  Future<AdminModel?> getAdminById(String id) async {
    final data = await ApiService.get('${ApiConfig.adminUser}?action=getById&id=$id');
    if (data == null) return null;
    return AdminModel.fromJson(data);
  }

  /// Find admin by email
  Future<AdminModel?> getAdminByEmail(String email) async {
    try {
      final data = await ApiService.get('${ApiConfig.adminUser}?action=getByEmail&email=$email');
      if (data == null) return null;
      return AdminModel.fromJson(data);
    } catch (e) {
      // If endpoint returns error or 404
      return null;
    }
  }

  /// Get OTP details for password reset
  Future<Map<String, dynamic>?> getOtpByEmail(String email) async {
    final data = await ApiService.get('${ApiConfig.adminUser}?action=getOtpByEmail&email=$email');
    if (data == null) return null;
    return {
      'otp_code': data['otp_code']?.toString(),
      'otp_expires_at': data['otp_expires_at']?.toString(),
    };
  }

  /// Create new admin
  Future<AdminModel> createAdmin(AdminModel admin) async {
    final data = await ApiService.post('${ApiConfig.adminUser}?action=create', admin.toJson());
    return AdminModel.fromJson(data);
  }

  /// Update admin profile by ID
  Future<AdminModel> updateAdmin(String id, Map<String, dynamic> fields) async {
    final data = await ApiService.post('${ApiConfig.adminUser}?action=update&id=$id', fields);
    return AdminModel.fromJson(data);
  }

  /// Update admin by email (e.g. OTP generation or password resetting)
  Future<AdminModel> updateAdminByEmail(String email, Map<String, dynamic> fields) async {
    final data = await ApiService.post('${ApiConfig.adminUser}?action=updateByEmail&email=$email', fields);
    return AdminModel.fromJson(data);
  }

  /// Delete admin
  Future<AdminModel> deleteAdmin(String id) async {
    final data = await ApiService.post('${ApiConfig.adminUser}?action=delete&id=$id', {});
    return AdminModel.fromJson(data);
  }
}

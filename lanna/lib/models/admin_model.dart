class AdminModel {
  final String adminId;
  final String email;
  final String? passwordHash;
  final String? passwordPlain;
  final String name;
  final String? avatar;
  final String role;
  final String? otpCode;
  final String? otpExpiresAt;

  AdminModel({
    required this.adminId,
    required this.email,
    this.passwordHash,
    this.passwordPlain,
    required this.name,
    this.avatar,
    required this.role,
    this.otpCode,
    this.otpExpiresAt,
  });

  factory AdminModel.fromJson(Map<String, dynamic> json) {
    return AdminModel(
      adminId: json['admin_id']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      passwordHash: json['password_hash']?.toString(),
      passwordPlain: json['password_plain']?.toString(),
      name: json['name']?.toString() ?? '',
      avatar: json['avatar']?.toString(),
      role: json['role']?.toString() ?? 'admin',
      otpCode: json['otp_code']?.toString(),
      otpExpiresAt: json['otp_expires_at']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'admin_id': adminId,
      'email': email,
      if (passwordHash != null) 'password_hash': passwordHash,
      if (passwordPlain != null) 'password_plain': passwordPlain,
      'name': name,
      if (avatar != null) 'avatar': avatar,
      'role': role,
      if (otpCode != null) 'otp_code': otpCode,
      if (otpExpiresAt != null) 'otp_expires_at': otpExpiresAt,
    };
  }
}

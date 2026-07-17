class UserModel {
  final String userId;
  final String name;
  final String email;
  final String status;
  final String? avatar;
  final String? createdAt;

  UserModel({
    required this.userId,
    required this.name,
    required this.email,
    required this.status,
    this.avatar,
    this.createdAt,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      userId: json['user_id']?.toString() ?? '',
      name: (json['username'] ?? json['name'])?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      status: json['status']?.toString() ?? 'active',
      avatar: json['avatar']?.toString(),
      createdAt: json['created_at']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'user_id': userId,
      'username': name,
      'email': email,
      'status': status,
      'avatar': avatar,
      'created_at': createdAt,
    };
  }
}

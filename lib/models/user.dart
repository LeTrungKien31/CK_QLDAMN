// lib/models/user.dart
class User {
  final int? id;
  final String username;
  final String email;
  final String fullName;
  final String role;
  final String? phone;
  final String? avatarUrl;
  final bool isActive;
  final DateTime? createdAt;

  User({
    this.id,
    required this.username,
    required this.email,
    required this.fullName,
    required this.role,
    this.phone,
    this.avatarUrl,
    this.isActive = true,
    this.createdAt,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'],
      username: json['username'],
      email: json['email'],
      fullName: json['full_name'],
      role: json['role'],
      phone: json['phone'],
      avatarUrl: json['avatar_url'],
      isActive: json['is_active'] ?? true,
      createdAt: json['created_at'] != null 
          ? DateTime.parse(json['created_at']) 
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'username': username,
      'email': email,
      'full_name': fullName,
      'role': role,
      'phone': phone,
      'avatar_url': avatarUrl,
      'is_active': isActive,
    };
  }

  bool isAdmin() => role == 'admin';
  bool isTeacher() => role == 'teacher';
  bool isStudent() => role == 'student';
}

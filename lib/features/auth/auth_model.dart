import 'dart:convert';

// ── Top-level helpers ──────────────────────────────────────────────────────

AuthResponse authResponseFromJson(String str) =>
    AuthResponse.fromJson(json.decode(str));

// ── Enums ──────────────────────────────────────────────────────────────────

enum UserRole {
  admin,
  customer;

  static UserRole fromString(String? value) {
    return UserRole.values.firstWhere(
      (e) => e.name.toLowerCase() == value?.toLowerCase(),
      orElse: () => UserRole.customer,
    );
  }
}

// ── Auth Response ──────────────────────────────────────────────────────────

class AuthResponse {
  final bool success;
  final AuthData data;

  const AuthResponse({required this.success, required this.data});

  factory AuthResponse.fromJson(Map<String, dynamic> json) => AuthResponse(
        success: json['success'] as bool,
        data: AuthData.fromJson(json['data'] as Map<String, dynamic>),
      );
}

class AuthData {
  final String token;
  final AuthUser user;

  const AuthData({required this.token, required this.user});

  factory AuthData.fromJson(Map<String, dynamic> json) => AuthData(
        token: json['token'] as String,
        user: AuthUser.fromJson(json['user'] as Map<String, dynamic>),
      );
}

class AuthUser {
  final String id;
  final String name;
  final String? email;
  final String? phone;
  final UserRole role;
  final String status;

  const AuthUser({
    required this.id,
    required this.name,
    this.email,
    this.phone,
    required this.role,
    required this.status,
  });

  bool get isActive => status == 'active';

  factory AuthUser.fromJson(Map<String, dynamic> json) => AuthUser(
        id: json['id'].toString(),
        name: json['name'] as String,
        email: json['email'] as String?,
        phone: json['phone'] as String?,
        role: UserRole.fromString(json['role'] as String?),
        status: json['status'] as String? ?? 'active',
      );
}
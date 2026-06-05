import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:senkukoadmin/constant/api_constant.dart';

class AuthService {
  AuthService._();

  /// POST /login/admin — admin login dengan name + password
  static Future<http.Response> loginAdmin({
    required String name,
    required String password,
  }) async {
    final url = Uri.parse('${ApiConstants.baseUrl}/auth/login/admin');
    final body = jsonEncode({'name': name, 'password': password});

    debugPrint('=== LOGIN REQUEST ===');
    debugPrint('URL: $url');
    debugPrint('Body: $body');

    final res = await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        'ngrok-skip-browser-warning': 'true', // ← wajib untuk ngrok
      },
      body: body,
    );

    debugPrint('=== LOGIN RESPONSE ===');
    debugPrint('Status: ${res.statusCode}');
    debugPrint('Body: ${res.body}');

    return res;
  }

  /// GET /me — ambil profil user dari token yang tersimpan
  static Future<http.Response> getMe() {
    return http.get(
      Uri.parse('${ApiConstants.baseUrl}/me'),
      headers: ApiConstants.headers,
    );
  }
}
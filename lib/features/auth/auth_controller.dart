import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:senkukoadmin/constant/api_helper.dart';
import 'package:senkukoadmin/constant/app_toast.dart';
import 'package:senkukoadmin/features/auth/auth_model.dart';
import 'package:senkukoadmin/features/auth/auth_service.dart';
import 'package:senkukoadmin/routes/routes.dart';

class AuthController extends GetxController {
  // ── Storage ───────────────────────────────────────────────────────────────
  final _box = GetStorage();
  static const _keyToken = 'auth_token';
  static const _keyUser = 'auth_user';

  // ── State ─────────────────────────────────────────────────────────────────
  final isLoading = false.obs;
  final obscurePassword = true.obs;
  final Rxn<AuthUser> currentUser = Rxn<AuthUser>();
  final token = ''.obs;

  // ── Form controllers ──────────────────────────────────────────────────────
  final nameC = TextEditingController();
  final passwordC = TextEditingController();

  bool _disposed = false;

  // ── Getters ───────────────────────────────────────────────────────────────
  bool get isLoggedIn => token.value.isNotEmpty;

  // ── Lifecycle ─────────────────────────────────────────────────────────────
  @override
  void onInit() {
    super.onInit();
    _disposed = false;
  }

  @override
  void onClose() {
    _disposed = true;
    nameC.dispose();
    passwordC.dispose();
    super.onClose();
  }

  // ── Session Check (dipanggil dari SplashPage) ─────────────────────────────
  Future<void> checkSession() async {
    await Future.delayed(const Duration(milliseconds: 1500));

    final savedToken = _box.read<String>(_keyToken) ?? '';

    if (savedToken.isEmpty) {
      Get.offAllNamed(AppRoutes.login);
      return;
    }

    if (_isTokenExpired(savedToken)) {
      _box.remove(_keyToken);
      _box.remove(_keyUser);
      Get.offAllNamed(AppRoutes.login);
      return;
    }

    token.value = savedToken;
    final userJson = _box.read<Map>(_keyUser);
    if (userJson != null) {
      currentUser.value =
          AuthUser.fromJson(Map<String, dynamic>.from(userJson));
    }
    Get.offAllNamed(AppRoutes.dashboard);
  }

  // ── Login ─────────────────────────────────────────────────────────────────
  Future<void> login() async {
    final name = nameC.text.trim();
    final pass = passwordC.text;

    if (name.isEmpty) {
      AppToast.show('Nama wajib diisi');
      return;
    }
    if (pass.isEmpty) {
      AppToast.show('Password wajib diisi');
      return;
    }

    isLoading.value = true;
    try {
      final res = await AuthService.loginAdmin(name: name, password: pass);

      if (res.statusCode == 200) {
        final auth = authResponseFromJson(res.body);
        _saveSession(auth);
        Get.offAllNamed(AppRoutes.dashboard);
      } else {
        final msg = ApiHelper.parseError(res.body, _mapError(res.statusCode));
        AppToast.show(msg);
      }
    } catch (e) {
      debugPrint('login error: $e');
      AppToast.show('Terjadi kesalahan. Coba lagi.');
    } finally {
      isLoading.value = false;
    }
  }

  // ── Logout ────────────────────────────────────────────────────────────────
  void logout() {
    _clearSession();
    Get.offAllNamed(AppRoutes.login);
  }

  // ── Token Expiry Check ────────────────────────────────────────────────────
  bool _isTokenExpired(String t) {
    if (t.isEmpty) return true;
    try {
      final parts = t.split('.');
      if (parts.length != 3) return true;

      String payload = parts[1];
      final mod = payload.length % 4;
      if (mod != 0) payload += '=' * (4 - mod);

      final decoded = json.decode(
        utf8.decode(base64Url.decode(payload)),
      ) as Map<String, dynamic>;

      final exp = decoded['exp'];
      if (exp == null) return false;

      final expiry = DateTime.fromMillisecondsSinceEpoch((exp as int) * 1000);
      return DateTime.now().isAfter(expiry.subtract(const Duration(seconds: 30)));
    } catch (_) {
      return true;
    }
  }

  // ── Helpers ───────────────────────────────────────────────────────────────
  void toggleObscure() => obscurePassword.toggle();

  void _saveSession(AuthResponse auth) {
    token.value = auth.data.token;
    currentUser.value = auth.data.user;
    _box.write(_keyToken, auth.data.token);
    _box.write(_keyUser, {
      'id': auth.data.user.id,
      'name': auth.data.user.name,
      'email': auth.data.user.email,
      'phone': auth.data.user.phone,
      'role': auth.data.user.role.name,
      'status': auth.data.user.status,
    });
  }

  void _clearSession() {
    token.value = '';
    currentUser.value = null;
    _box.remove(_keyToken);
    _box.remove(_keyUser);
    if (!_disposed) {
      nameC.clear();
      passwordC.clear();
    }
  }

  String _mapError(int statusCode) {
    switch (statusCode) {
      case 401:
        return 'Nama atau password salah';
      case 403:
        return 'Akun tidak aktif';
      case 408:
        return 'Koneksi timeout. Coba lagi.';
      case 503:
        return 'Tidak ada koneksi internet';
      default:
        return 'Login gagal. Coba lagi.';
    }
  }
}
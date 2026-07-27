import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:senkukoadmin/features/auth/auth_controller.dart';

/// Wrapper tipis di atas `package:http` — satu titik pusat buat nanganin
/// token expired/invalid. Semua service (transaction, product, dll) manggil
/// lewat sini alih-alih `http.get/post/...` langsung.
///
/// Begitu ADA response 401 dari endpoint manapun, langsung trigger logout +
/// redirect ke login, tanpa perlu cek manual di tiap page/controller. Ini
/// nutup gap yang gak bisa dicover cek expiry lokal (`checkSession()` di
/// AuthController) — misal token di-revoke dari server (akun dihapus/
/// dinonaktifin admin lain, atau server rotate secret) padahal secara lokal
/// `exp` di JWT-nya masih keliatan valid.
class ApiClient {
  ApiClient._();

  static Future<http.Response> get(
    Uri url, {
    Map<String, String>? headers,
  }) => _wrap(http.get(url, headers: headers));

  static Future<http.Response> post(
    Uri url, {
    Map<String, String>? headers,
    Object? body,
  }) => _wrap(http.post(url, headers: headers, body: body));

  static Future<http.Response> put(
    Uri url, {
    Map<String, String>? headers,
    Object? body,
  }) => _wrap(http.put(url, headers: headers, body: body));

  static Future<http.Response> patch(
    Uri url, {
    Map<String, String>? headers,
    Object? body,
  }) => _wrap(http.patch(url, headers: headers, body: body));

  static Future<http.Response> delete(
    Uri url, {
    Map<String, String>? headers,
    Object? body,
  }) => _wrap(http.delete(url, headers: headers, body: body));

  static Future<http.Response> _wrap(Future<http.Response> request) async {
    final res = await request;

    // Sengaja gak di-await terpisah / gak throw — caller tetep terima
    // response apa adanya (kadang mau baca `message` errornya dulu),
    // logout jalan di background begitu 401 kedetect.
    if (res.statusCode == 401 && Get.isRegistered<AuthController>()) {
      Get.find<AuthController>().handleUnauthorized();
    }

    return res;
  }
}
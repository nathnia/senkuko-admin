import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiHelper {
  ApiHelper._(); // prevent instantiation

  /// Parse pesan error dari response body API
  /// Kalau body tidak valid JSON atau tidak ada field 'message',
  /// return fallback string
  static String parseError(String body, [String fallback = 'Terjadi kesalahan']) {
    try {
      return json.decode(body)['message'] as String? ?? fallback;
    } catch (_) {
      return fallback;
    }
  }

  /// Cek apakah response adalah timeout (408) atau no-internet (503)
  /// Ini return code dari ProductService._safe() wrapper
  static bool isNetworkError(http.Response res) =>
      res.statusCode == 408 || res.statusCode == 503;
}
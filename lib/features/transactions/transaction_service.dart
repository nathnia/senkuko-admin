import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:senkukoadmin/constant/api_client.dart';
import 'package:senkukoadmin/constant/api_constant.dart';

class TransactionService {
  static const _timeout = Duration(seconds: 60);

  // Sama kayak ProductService._safe — satu titik buat nanganin timeout &
  // gagal koneksi, dan (lewat ApiClient) auto-logout kalau 401.
  static Future<http.Response> _safe(Future<http.Response> request) async {
    try {
      return await request.timeout(_timeout);
    } on TimeoutException {
      return http.Response(
        jsonEncode({'success': false, 'message': 'Request timeout, coba lagi'}),
        408,
      );
    } catch (e) {
      return http.Response(
        jsonEncode({
          'success': false,
          'message': 'Tidak dapat terhubung ke server',
        }),
        503,
      );
    }
  }

  static Future<http.Response> getAllTransactions() => _safe(
    ApiClient.get(
      Uri.parse('${ApiConstants.baseUrl}/transactions'),
      headers: ApiConstants.headers,
    ),
  );

  static Future<http.Response> getTransactionById(String id) => _safe(
    ApiClient.get(
      Uri.parse('${ApiConstants.baseUrl}/transactions/$id'),
      headers: ApiConstants.headers,
    ),
  );

  static Future<http.Response> updateTransactionStatus(
    String id,
    String status,
  ) => _safe(
    ApiClient.patch(
      Uri.parse('${ApiConstants.baseUrl}/transactions/$id/status'),
      headers: ApiConstants.headers,
      body: json.encode({'status': status}),
    ),
  );
}
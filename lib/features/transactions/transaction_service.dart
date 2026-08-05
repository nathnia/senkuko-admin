import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:senkukoadmin/constant/api_client.dart';
import 'package:senkukoadmin/constant/api_constant.dart';
import 'package:senkukoadmin/features/transactions/transaction_summary_model.dart';
import 'package:senkukoadmin/features/transactions/transaction_export_row_model.dart';

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

  static String _dateOnly(DateTime d) => d.toIso8601String().split('T').first;

  static String _extractMessage(http.Response res, String fallback) {
    try {
      final body = json.decode(res.body) as Map<String, dynamic>;
      return body['message'] as String? ?? fallback;
    } catch (_) {
      return fallback;
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

  // Endpoint khusus admin — beda dari endpoint /cancel yang dipakai customer
  // (yang ngecek ownership customer_id). /admin-cancel skip ownership check
  // dan tetep jalanin restore stock + rollback promo/voucher/total_spend.
  static Future<http.Response> cancelTransaction(String id) => _safe(
    ApiClient.patch(
      Uri.parse('${ApiConstants.baseUrl}/transactions/$id/admin-cancel'),
      headers: ApiConstants.headers,
    ),
  );

  // ===================== SUMMARY & EXPORT =====================
  // Ditambahin buat gantiin pendekatan N+1 (fetch detail per transaksi).
  // Backend nyediain endpoint teragregasi (1 query buat summary,
  // 3 query buat export — lihat dokumentasi backend), jadi app cukup
  // panggil ini sekali/beberapa kali (pagination), bukan sekali per transaksi.

  static Future<TransactionSummary> fetchSummary({
    required DateTime start,
    required DateTime end,
  }) async {
    final res = await _safe(
      ApiClient.get(
        Uri.parse(
          '${ApiConstants.baseUrl}/transactions/summary'
          '?start=${_dateOnly(start)}&end=${_dateOnly(end)}',
        ),
        headers: ApiConstants.headers,
      ),
    );

    if (res.statusCode != 200) {
      throw Exception(_extractMessage(res, 'Gagal memuat ringkasan transaksi'));
    }

    final body = json.decode(res.body) as Map<String, dynamic>;
    return TransactionSummary.fromJson(body['data'] as Map<String, dynamic>);
  }

  static Future<TransactionExportPage> fetchExportPage({
    required DateTime start,
    required DateTime end,
    int offset = 0,
    int limit = 500,
  }) async {
    final res = await _safe(
      ApiClient.get(
        Uri.parse(
          '${ApiConstants.baseUrl}/transactions/export'
          '?start=${_dateOnly(start)}&end=${_dateOnly(end)}'
          '&offset=$offset&limit=$limit',
        ),
        headers: ApiConstants.headers,
      ),
    );

    if (res.statusCode != 200) {
      throw Exception(_extractMessage(res, 'Gagal memuat data export'));
    }

    final body = json.decode(res.body) as Map<String, dynamic>;
    return TransactionExportPage.fromJson(body['data'] as Map<String, dynamic>);
  }

  /// Loop semua halaman sampai has_more == false. Ini yang gantiin
  /// N+1 fetch per transaksi — cuma sejumlah `total / 500` request,
  /// bukan sejumlah `total` request.
  static Future<List<TransactionExportRow>> fetchAllExportRows({
    required DateTime start,
    required DateTime end,
  }) async {
    final rows = <TransactionExportRow>[];
    int offset = 0;
    const limit = 500;

    while (true) {
      final page = await fetchExportPage(
        start: start,
        end: end,
        offset: offset,
        limit: limit,
      );
      rows.addAll(page.data);
      if (!page.hasMore) break;
      offset += limit;
    }

    return rows;
  }
}
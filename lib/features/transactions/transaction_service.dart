import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:senkukoadmin/constant/api_constant.dart';

class TransactionService {
  static Future<http.Response> getAllTransactions() {
    return http.get(
      Uri.parse('${ApiConstants.baseUrl}/transactions'),
      headers: ApiConstants.headers,
    );
  }

  static Future<http.Response> getTransactionById(String id) {
    return http.get(
      Uri.parse('${ApiConstants.baseUrl}/transactions/$id'),
      headers: ApiConstants.headers,
    );
  }

  static Future<http.Response> updateTransactionStatus(
    String id,
    String status,
  ) {
    return http.patch(
      Uri.parse('${ApiConstants.baseUrl}/transactions/$id/status'),
      headers: ApiConstants.headers,
      body: json.encode({'status': status}),
    );
  }
}
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:senkukoadmin/constant/api_constant.dart';

class VoucherService {
  static Future<http.Response> getAllVouchers() {
    return http.get(
      Uri.parse('${ApiConstants.baseUrl}/vouchers'),
      headers: ApiConstants.headers,
    );
  }

  static Future<http.Response> getVoucherById(String id) {
    return http.get(
      Uri.parse('${ApiConstants.baseUrl}/vouchers/$id'),
      headers: ApiConstants.headers,
    );
  }

  static Future<http.Response> createVoucher(Map<String, dynamic> body) {
    return http.post(
      Uri.parse('${ApiConstants.baseUrl}/vouchers'),
      headers: ApiConstants.headers,
      body: jsonEncode(body),
    );
  }

  static Future<http.Response> updateVoucher(
      String id, Map<String, dynamic> body) {
    return http.put(
      Uri.parse('${ApiConstants.baseUrl}/vouchers/$id'),
      headers: ApiConstants.headers,
      body: jsonEncode(body),
    );
  }

  static Future<http.Response> deleteVoucher(String id) {
    return http.delete(
      Uri.parse('${ApiConstants.baseUrl}/vouchers/$id'),
      headers: ApiConstants.headers,
    );
  }
}
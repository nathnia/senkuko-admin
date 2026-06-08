import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:senkukoadmin/constant/api_constant.dart';

class CustomerService {
  static Future<http.Response> getAllCustomers() {
    return http.get(
      Uri.parse('${ApiConstants.baseUrl}/customers'),
      headers: ApiConstants.headers,
    );
  }

  static Future<http.Response> getCustomerById(String id) {
    return http.get(
      Uri.parse('${ApiConstants.baseUrl}/customers/$id'),
      headers: ApiConstants.headers,
    );
  }

  static Future<http.Response> createCustomer(Map<String, dynamic> body) {
    return http.post(
      Uri.parse('${ApiConstants.baseUrl}/auth/admin/customers'),
      headers: ApiConstants.headers,
      body: jsonEncode(body),
    );
  }

  static Future<http.Response> updateCustomer(
    String id,
    Map<String, dynamic> body,
  ) {
    return http.put(
      Uri.parse('${ApiConstants.baseUrl}/customers/$id'),
      headers: ApiConstants.headers,
      body: jsonEncode(body),
    );
  }

  static Future<http.Response> updateCustomerStatus(String id, String status) {
    return http.patch(
      Uri.parse('${ApiConstants.baseUrl}/customers/$id/status'),
      headers: ApiConstants.headers,
      body: jsonEncode({'status': status}),
    );
  }
}
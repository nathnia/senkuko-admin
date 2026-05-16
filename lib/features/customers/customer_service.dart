import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:senkukoadmin/constant/api_constant.dart';

class CustomerService {
  // GET ALL CUSTOMERS
  static Future<http.Response> getAllCustomers() {
    return http.get(
      Uri.parse('${ApiConstants.baseUrl}/customers'),
      headers: ApiConstants.headers,
    );
  }

  // GET CUSTOMER BY ID
  static Future<http.Response> getCustomerById(String id) {
    return http.get(
      Uri.parse('${ApiConstants.baseUrl}/customers/$id'),
      headers: ApiConstants.headers,
    );
  }

  // UPDATE STATUS — terima String karena controller kirim newStatus.name
  static Future<http.Response> updateCustomerStatus(String id, String status) {
    return http.patch(
      Uri.parse('${ApiConstants.baseUrl}/customers/$id/status'),
      headers: ApiConstants.headers,
      body: jsonEncode({'status': status}),
    );
  }
}
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:senkukoadmin/constant/api_constant.dart';

class CustomerService {

  // GET ALL CUSTOMERS
  static Future<http.Response> getAllCustomers() {
    return http.get(
      Uri.parse("${ApiConstants.baseUrl}/customers"),
      headers: ApiConstants.headers,
    );
  }

  // GET CUSTOMER BY ID
  static Future<http.Response> getCustomerById(String id) {
    return http.get(
      Uri.parse("${ApiConstants.baseUrl}/customers/$id"),
      headers: ApiConstants.headers,
    );
  }

  // CREATE CUSTOMER
  static Future<http.Response> createCustomer({
    required String name,
    String? phone,
    String? email,
    required String memberType,
  }) {
    return http.post(
      Uri.parse("${ApiConstants.baseUrl}/customers"),
      headers: ApiConstants.headers,
      body: jsonEncode({
        "name": name,
        "phone": phone,
        "email": email,
        "member_type": memberType,
      }),
    );
  }

  // UPDATE CUSTOMER
  static Future<http.Response> updateCustomer({
    required String id,
    required String name,
    String? phone,
    String? email,
    required String memberType,
  }) {
    return http.put(
      Uri.parse("${ApiConstants.baseUrl}/customers/$id"),
      headers: ApiConstants.headers,
      body: jsonEncode({
        "name": name,
        "phone": phone,
        "email": email,
        "member_type": memberType,
      }),
    );
  }

  // DELETE CUSTOMER
  static Future<http.Response> deleteCustomer(String id) {
    return http.delete(
      Uri.parse("${ApiConstants.baseUrl}/customers/$id"),
      headers: ApiConstants.headers,
    );
  }
}
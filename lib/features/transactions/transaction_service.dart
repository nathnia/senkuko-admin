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
}
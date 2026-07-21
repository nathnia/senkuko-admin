import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:get_storage/get_storage.dart';

class ApiConstants {
  static String get baseUrl => dotenv.env['BASE_URL']!;

  static String get products => '$baseUrl/products';
  static String get productPrices => '$baseUrl/product-prices';

  static Map<String, String> get headers {
    final token = GetStorage().read<String>('auth_token') ?? '';
    return {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      'ngrok-skip-browser-warning': 'true',
      if (token.isNotEmpty) 'Authorization': 'Bearer $token',
    };
  }
}
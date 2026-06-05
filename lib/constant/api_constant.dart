import 'package:get_storage/get_storage.dart';

class ApiConstants {
  static const String baseUrl = 'https://nonflaky-predoubtfully-kayleigh.ngrok-free.dev/api';

  static const String products = '$baseUrl/products';
  static const String productPrices = '$baseUrl/product-prices';

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
class ApiConstants {
  static const String baseUrl = 'http://senkuko.rplrus.com/api';

  static const String products = '$baseUrl/products';
  static const String productPrices = '$baseUrl/product-prices';

  static Map<String, String> get headers => {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
    // "User-Agent": "Mozilla/5.0"
  };
}

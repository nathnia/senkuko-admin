class ApiConstants {
  static const String baseUrl = 'https://nonflaky-predoubtfully-kayleigh.ngrok-free.dev/api';
  // static const String baseUrl = 'http://senkuko.rplrus.com/api';

  static const String products = '$baseUrl/products';
  static const String productPrices = '$baseUrl/product-prices';

  static Map<String, String> get headers => {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
  };
}

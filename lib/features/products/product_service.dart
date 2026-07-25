import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:senkukoadmin/constant/api_constant.dart';

class ProductService {
  static const _timeout = Duration(seconds: 60);

  static Future<http.Response> _safe(Future<http.Response> request) async {
    try {
      return await request.timeout(_timeout);
    } on TimeoutException {
      return http.Response(
        jsonEncode({'success': false, 'message': 'Request timeout, coba lagi'}),
        408,
      );
    } catch (e) {
      return http.Response(
        jsonEncode({
          'success': false,
          'message': 'Tidak dapat terhubung ke server',
        }),
        503,
      );
    }
  }

  // ===================== PRODUCTS =====================
  static Future<http.Response> getProducts() => _safe(
    http.get(Uri.parse(ApiConstants.products), headers: ApiConstants.headers),
  );

  static Future<http.Response> getProductById(String id) => _safe(
    http.get(
      Uri.parse('${ApiConstants.baseUrl}/products/$id'),
      headers: ApiConstants.headers,
    ),
  );

  static Future<http.Response> createProduct({
    required String name,
    required String skuCode,
    required String description,
    required String barcode,
    String? categoryId,
  }) => _safe(
    http.post(
      Uri.parse(ApiConstants.products),
      headers: ApiConstants.headers,
      body: jsonEncode({
        'name': name,
        'sku_code': skuCode,
        'description': description,
        'barcode': barcode.isEmpty ? null : barcode,
        'category_id': categoryId,
        'is_active': true,
      }),
    ),
  );

  static Future<http.Response> updateProduct({
    required String id,
    required String name,
    required String skuCode,
    required String description,
    required String barcode,
    String? categoryId,
    bool isActive = true,
  }) => _safe(
    http.put(
      Uri.parse('${ApiConstants.baseUrl}/products/$id'),
      headers: ApiConstants.headers,
      body: jsonEncode({
        'name': name,
        'sku_code': skuCode,
        'description': description,
        'barcode': barcode.isEmpty ? null : barcode,
        'category_id': categoryId,
        'is_active': isActive,
      }),
    ),
  );

  static Future<http.Response> deleteProduct(String productId) {
    final url = '${ApiConstants.baseUrl}/products/$productId';
    return _safe(http.delete(Uri.parse(url), headers: ApiConstants.headers));
  }

  // ===================== VARIANTS =====================
  static Future<http.Response> getAllVariants() => _safe(
    http.get(
      Uri.parse('${ApiConstants.baseUrl}/product-variants'),
      headers: ApiConstants.headers,
    ),
  );

  static Future<http.Response> getVariants(String productId) => _safe(
    http.get(
      Uri.parse('${ApiConstants.baseUrl}/products/$productId/variants'),
      headers: ApiConstants.headers,
    ),
  );

  static Future<http.Response> createVariant({
    required String productId,
    required String unitId,
    required String name,
    required int stock,
    int crisisStock = 0,
    String? barcode,
    bool isBaseUnit = false,
  }) => _safe(
    http.post(
      Uri.parse('${ApiConstants.baseUrl}/product-variants'),
      headers: ApiConstants.headers,
      body: jsonEncode({
        'product_id': productId,
        'unit_id': unitId,
        'name': name,
        'barcode': (barcode == null || barcode.isEmpty) ? null : barcode,
        'stock_qty': stock,
        'min_stock_qty': 1,
        'crisis_stock': crisisStock,
        'conversion_factor': 1,
        'is_base_unit': isBaseUnit,
        'is_active': true,
      }),
    ),
  );

  static Future<http.Response> updateVariant({
    required String id,
    required String name,
    required int stock,
    required String unitId,
    required bool isBaseUnit,
    int crisisStock = 0,
    String? barcode,
  }) => _safe(
    http.put(
      Uri.parse('${ApiConstants.baseUrl}/product-variants/$id'),
      headers: ApiConstants.headers,
      body: jsonEncode({
        'name': name,
        'stock_qty': stock,
        'unit_id': unitId,
        'barcode': (barcode == null || barcode.isEmpty) ? null : barcode,
        'min_stock_qty': 1,
        'crisis_stock': crisisStock,
        'conversion_factor': 1,
        'is_base_unit': isBaseUnit,
        'is_active': true,
      }),
    ),
  );

  // BARU — sebelumnya tidak ada sama sekali
  static Future<http.Response> deleteVariant(String variantId) => _safe(
    http.delete(
      Uri.parse('${ApiConstants.baseUrl}/product-variants/$variantId'),
      headers: ApiConstants.headers,
    ),
  );

  // ===================== PRICES =====================
  static Future<http.Response> getPrices() => _safe(
    http.get(
      Uri.parse(ApiConstants.productPrices),
      headers: ApiConstants.headers,
    ),
  );

  static Future<http.Response> getPricesByVariant(String variantId) => _safe(
    http.get(
      Uri.parse('${ApiConstants.baseUrl}/product-prices/variant/$variantId'),
      headers: ApiConstants.headers,
    ),
  );

  static Future<http.Response> createPrice({
    required String variantId,
    required String priceListId,
    required double price,
  }) => _safe(
    http.post(
      Uri.parse('${ApiConstants.baseUrl}/product-prices'),
      headers: ApiConstants.headers,
      body: jsonEncode({
        'product_variant_id': variantId,
        'price_list_id': priceListId,
        'min_qty': 1,
        'price': price,
        'is_active': true,
      }),
    ),
  );

  static Future<http.Response> updatePrice({
    required String priceId,
    required String priceListId,
    required double price,
  }) => _safe(
    http.put(
      Uri.parse('${ApiConstants.baseUrl}/product-prices/$priceId'),
      headers: ApiConstants.headers,
      body: jsonEncode({
        'price_list_id': priceListId,
        'min_qty': 1,
        'price': price,
        'is_active': true,
      }),
    ),
  );

  static Future<http.Response> deletePrice(String priceId) => _safe(
    http.delete(
      Uri.parse('${ApiConstants.baseUrl}/product-prices/$priceId'),
      headers: ApiConstants.headers,
    ),
  );

  // ===================== UNITS =====================
  static Future<http.Response> getUnits() => _safe(
    http.get(
      Uri.parse('${ApiConstants.baseUrl}/units'),
      headers: ApiConstants.headers,
    ),
  );

  static Future<http.Response> createUnit({
    required String name,
    required String symbol,
    String? description,
  }) => _safe(
    http.post(
      Uri.parse('${ApiConstants.baseUrl}/units'),
      headers: ApiConstants.headers,
      body: jsonEncode({
        'name': name,
        'symbol': symbol,
        'description': description,
      }),
    ),
  );

  static Future<http.Response> deleteUnit(String id) => _safe(
    http.delete(
      Uri.parse('${ApiConstants.baseUrl}/units/$id'),
      headers: ApiConstants.headers,
    ),
  );

  // ===================== CATEGORIES =====================
  static Future<http.Response> getCategories() => _safe(
    http.get(
      Uri.parse('${ApiConstants.baseUrl}/categories'),
      headers: ApiConstants.headers,
    ),
  );

  static Future<http.Response> createCategory({
    required String name,
    String? parentId,
  }) => _safe(
    http.post(
      Uri.parse('${ApiConstants.baseUrl}/categories'),
      headers: ApiConstants.headers,
      body: jsonEncode({
        'name': name,
        'slug': name.toLowerCase().replaceAll(' ', '-'),
        'parent_id': parentId,
        'sort_order': 0,
        'is_active': true,
      }),
    ),
  );

  static Future<http.Response> deleteCategory(String id) => _safe(
    http.delete(
      Uri.parse('${ApiConstants.baseUrl}/categories/$id'),
      headers: ApiConstants.headers,
    ),
  );

  // ===================== PRICE LISTS =====================
  static Future<http.Response> getPriceLists() => _safe(
    http.get(
      Uri.parse('${ApiConstants.baseUrl}/price-lists'),
      headers: ApiConstants.headers,
    ),
  );

  // ===================== IMAGES =====================
  static Future<http.Response> getProductImages(String productId) => _safe(
    http.get(
      Uri.parse('${ApiConstants.baseUrl}/products/$productId/images'),
      headers: ApiConstants.headers,
    ),
  );

  // Upload image perlu handle sendiri karena pakai MultipartRequest
  static Future<http.Response> uploadProductImage({
    required String productId,
    required List<int> imageBytes,
    required String fileName,
  }) async {
    try {
      final uri = Uri.parse(
        '${ApiConstants.baseUrl}/products/$productId/images',
      );
      final request = http.MultipartRequest('POST', uri);

      ApiConstants.headers.forEach((key, value) {
        if (key.toLowerCase() != 'content-type') {
          request.headers[key] = value;
        }
      });

      request.files.add(
        http.MultipartFile.fromBytes('image', imageBytes, filename: fileName),
      );

      final streamed = await request.send().timeout(_timeout);
      return http.Response.fromStream(streamed);
    } on TimeoutException {
      return http.Response(
        jsonEncode({'success': false, 'message': 'Upload timeout, coba lagi'}),
        408,
      );
    } catch (e) {
      return http.Response(
        jsonEncode({'success': false, 'message': 'Gagal upload gambar'}),
        503,
      );
    }
  }

  static Future<http.Response> deleteProductImage(
    String productId,
    String imageId,
  ) => _safe(
    http.delete(
      Uri.parse('${ApiConstants.baseUrl}/products/$productId/images/$imageId'),
      headers: ApiConstants.headers,
    ),
  );
}
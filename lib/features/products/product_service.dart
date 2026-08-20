import 'dart:async';
import 'dart:convert';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:senkukoadmin/constant/api_client.dart';
import 'package:senkukoadmin/constant/api_constant.dart';
import 'package:senkukoadmin/features/auth/auth_controller.dart';

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
    ApiClient.get(Uri.parse(ApiConstants.products), headers: ApiConstants.headers),
  );

  static Future<http.Response> getProductById(String id) => _safe(
    ApiClient.get(
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
    ApiClient.post(
      Uri.parse(ApiConstants.products),
      headers: ApiConstants.headers,
      body: jsonEncode({
        'name': name,
        'sku_code': skuCode,
        'description': description,
        // FIX: sebelumnya `barcode.isEmpty ? null : barcode` — backend
        // menolak barcode bernilai null dengan 400 "Invalid value"
        // (validator cuma terima string, termasuk string kosong, tapi
        // bukan null). Produk tanpa barcode jadi selalu gagal disimpan.
        // Sekarang kirim apa adanya (string, bisa kosong).
        'barcode': barcode,
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
    ApiClient.put(
      Uri.parse('${ApiConstants.baseUrl}/products/$id'),
      headers: ApiConstants.headers,
      body: jsonEncode({
        'name': name,
        'sku_code': skuCode,
        'description': description,
        // FIX: sama kayak createProduct() — INI FIX UTAMA bug "beberapa
        // produk gak bisa di-update". barcode.isEmpty ? null : barcode
        // bikin request ditolak backend (400, path: barcode, value: null)
        // untuk SEMUA produk yang kolom barcode-nya kosong. Kirim string
        // apa adanya biar konsisten dengan yang backend harapkan.
        'barcode': barcode,
        'category_id': categoryId,
        'is_active': isActive,
      }),
    ),
  );

  static Future<http.Response> deleteProduct(String productId) {
    final url = '${ApiConstants.baseUrl}/products/$productId';
    return _safe(ApiClient.delete(Uri.parse(url), headers: ApiConstants.headers));
  }

  // ===================== VARIANTS =====================
  static Future<http.Response> getAllVariants() => _safe(
    ApiClient.get(
      Uri.parse('${ApiConstants.baseUrl}/product-variants'),
      headers: ApiConstants.headers,
    ),
  );

  static Future<http.Response> getVariants(String productId) => _safe(
    ApiClient.get(
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
    ApiClient.post(
      Uri.parse('${ApiConstants.baseUrl}/product-variants'),
      headers: ApiConstants.headers,
      body: jsonEncode({
        'product_id': productId,
        'unit_id': unitId,
        'name': name,
        // NOTE: pola null-untuk-kosong yang sama juga masih ada di sini.
        // Belum dikonfirmasi menyebabkan error yang sama (belum ada log
        // gagal untuk endpoint variant), tapi berpotensi bug serupa kalau
        // barcode variant dikosongkan. Kalau nanti ketemu kasus "variant
        // gagal diupdate" dengan pesan validasi barcode yang sama, ganti
        // baris ini jadi `'barcode': barcode ?? '',` juga.
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
    ApiClient.put(
      Uri.parse('${ApiConstants.baseUrl}/product-variants/$id'),
      headers: ApiConstants.headers,
      body: jsonEncode({
        'name': name,
        'stock_qty': stock,
        'unit_id': unitId,
        // NOTE: sama seperti createVariant() di atas — pola null-untuk-
        // kosong ini belum dikonfirmasi bermasalah, tapi kalau ada laporan
        // "variant gagal diupdate" dengan error validasi barcode yang
        // serupa, ganti jadi `'barcode': barcode ?? '',`.
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
    ApiClient.delete(
      Uri.parse('${ApiConstants.baseUrl}/product-variants/$variantId'),
      headers: ApiConstants.headers,
    ),
  );

  // ===================== PRICES =====================
  static Future<http.Response> getPrices() => _safe(
    ApiClient.get(
      Uri.parse(ApiConstants.productPrices),
      headers: ApiConstants.headers,
    ),
  );

  static Future<http.Response> getPricesByVariant(String variantId) => _safe(
    ApiClient.get(
      Uri.parse('${ApiConstants.baseUrl}/product-prices/variant/$variantId'),
      headers: ApiConstants.headers,
    ),
  );

  static Future<http.Response> createPrice({
    required String variantId,
    required String priceListId,
    required double price,
  }) => _safe(
    ApiClient.post(
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
    ApiClient.put(
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
    ApiClient.delete(
      Uri.parse('${ApiConstants.baseUrl}/product-prices/$priceId'),
      headers: ApiConstants.headers,
    ),
  );

  // ===================== UNITS =====================
  static Future<http.Response> getUnits() => _safe(
    ApiClient.get(
      Uri.parse('${ApiConstants.baseUrl}/units'),
      headers: ApiConstants.headers,
    ),
  );

  static Future<http.Response> createUnit({
    required String name,
    required String symbol,
    String? description,
  }) => _safe(
    ApiClient.post(
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
    ApiClient.delete(
      Uri.parse('${ApiConstants.baseUrl}/units/$id'),
      headers: ApiConstants.headers,
    ),
  );

  // ===================== CATEGORIES =====================
  static Future<http.Response> getCategories() => _safe(
    ApiClient.get(
      Uri.parse('${ApiConstants.baseUrl}/categories'),
      headers: ApiConstants.headers,
    ),
  );

  static Future<http.Response> createCategory({
    required String name,
    String? parentId,
  }) => _safe(
    ApiClient.post(
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
    ApiClient.delete(
      Uri.parse('${ApiConstants.baseUrl}/categories/$id'),
      headers: ApiConstants.headers,
    ),
  );

  // ===================== PRICE LISTS =====================
  static Future<http.Response> getPriceLists() => _safe(
    ApiClient.get(
      Uri.parse('${ApiConstants.baseUrl}/price-lists'),
      headers: ApiConstants.headers,
    ),
  );

  // ===================== IMAGES =====================
  static Future<http.Response> getProductImages(String productId) => _safe(
    ApiClient.get(
      Uri.parse('${ApiConstants.baseUrl}/products/$productId/images'),
      headers: ApiConstants.headers,
    ),
  );

  // Menentukan Content-Type multipart berdasarkan ekstensi nama file.
  // FIX: http.MultipartFile.fromBytes() TIDAK otomatis mendeteksi
  // Content-Type dari nama file — kalau parameter `contentType` tidak
  // diisi, defaultnya `application/octet-stream`. Backend menolak ini
  // dengan 400 "Invalid file type" karena mengharapkan Content-Type
  // image/* pada bagian multipart-nya (bukan cuma cek ekstensi nama
  // file). Postman berhasil karena otomatis mengisi Content-Type sesuai
  // ekstensi file yang dipilih — makanya file yang sama gagal di app
  // tapi sukses di Postman.
  static MediaType? _mimeTypeFromFileName(String fileName) {
    final ext = fileName.split('.').last.toLowerCase();
    switch (ext) {
      case 'jpg':
      case 'jpeg':
        return MediaType('image', 'jpeg');
      case 'png':
        return MediaType('image', 'png');
      case 'webp':
        return MediaType('image', 'webp');
      default:
        // Ekstensi tak dikenal — biarkan http yang menentukan default.
        // Seharusnya tidak pernah kejadian karena ProductImageController
        // sudah membatasi ekstensi ke jpg/jpeg/png/webp sebelum file
        // masuk ke pendingImages/pendingEditImages.
        return null;
    }
  }

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
        http.MultipartFile.fromBytes(
          'image',
          imageBytes,
          filename: fileName,
          // FIX: eksplisit set Content-Type sesuai ekstensi file,
          // supaya sama seperti perilaku Postman.
          contentType: _mimeTypeFromFileName(fileName),
        ),
      );

      final streamed = await request.send().timeout(_timeout);
      final res = await http.Response.fromStream(streamed);

      // Multipart request gak lewat ApiClient.post biasa (butuh
      // MultipartRequest manual) — jadi cek 401-nya diulang di sini biar
      // tetep konsisten kena auto-logout kayak endpoint lain.
      if (res.statusCode == 401 && Get.isRegistered<AuthController>()) {
        Get.find<AuthController>().handleUnauthorized();
      }

      return res;
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
    ApiClient.delete(
      Uri.parse('${ApiConstants.baseUrl}/products/$productId/images/$imageId'),
      headers: ApiConstants.headers,
    ),
  );
}
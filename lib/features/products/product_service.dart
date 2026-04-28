import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:senkukoadmin/constant/api_constant.dart';

class ProductService {
  // ===================== PRODUCTS =====================
  static Future<http.Response> getProducts() {
    return http.get(
      Uri.parse(ApiConstants.products),
      headers: ApiConstants.headers,
    );
  }

  static Future<http.Response> getProductById(String id) {
    return http.get(
      Uri.parse("${ApiConstants.baseUrl}/products/$id"),
      headers: ApiConstants.headers,
    );
  }

  static Future<http.Response> getProductDetail(String id) {
    return http.get(
      Uri.parse("${ApiConstants.baseUrl}/products/$id"),
      headers: ApiConstants.headers,
    );
  }

  static Future<http.Response> createProduct({
    required String name,
    required String skuCode,
    required String description,
    required String barcode,
    String? categoryId,
  }) {
    return http.post(
      Uri.parse(ApiConstants.products),
      headers: ApiConstants.headers,
      body: jsonEncode({
        "name": name,
        "sku_code": skuCode,
        "description": description,
        "barcode": barcode.isEmpty ? null : barcode,
        "category_id": categoryId,
        "is_active": true,
      }),
    );
  }

  static Future<http.Response> updateProduct({
    required String id,
    required String name,
    required String skuCode,
    required String description,
    required String barcode,
    String? categoryId,
    bool isActive = true, // ← tambah ini
  }) {
    return http.put(
      Uri.parse("${ApiConstants.baseUrl}/products/$id"),
      headers: ApiConstants.headers,
      body: jsonEncode({
        "name": name,
        "sku_code": skuCode,
        "description": description,
        "barcode": barcode.isEmpty ? null : barcode,
        "category_id": categoryId,
        "is_active": isActive, // ← ganti dari true ke isActive
      }),
    );
  }

  // ===================== VARIANTS =====================
  static Future<http.Response> getVariants(String productId) {
    return http.get(
      Uri.parse("${ApiConstants.baseUrl}/products/$productId/variants"),
      headers: ApiConstants.headers,
    );
  }

  static Future<http.Response> createVariant({
    required String productId,
    required String unitId,
    required String name,
    required int stock,
    String? barcode,
    bool isBaseUnit = false,
  }) {
    return http.post(
      Uri.parse("${ApiConstants.baseUrl}/product-variants"),
      headers: ApiConstants.headers,
      body: jsonEncode({
        "product_id": productId,
        "unit_id": unitId,
        "name": name,
        "barcode": (barcode == null || barcode.isEmpty) ? null : barcode,
        "stock_qty": stock,
        "min_stock_qty": 1,
        "conversion_factor": 1,
        "is_base_unit": isBaseUnit,
        "is_active": true,
      }),
    );
  }

  static Future<http.Response> updateVariant({
    required String id,
    required String name,
    required int stock,
    required String unitId,
    required bool isBaseUnit,
    String? barcode,
  }) {
    return http.put(
      Uri.parse("${ApiConstants.baseUrl}/product-variants/$id"),
      headers: ApiConstants.headers,
      body: jsonEncode({
        "name": name,
        "stock_qty": stock,
        "unit_id": unitId,
        "barcode": (barcode == null || barcode.isEmpty) ? null : barcode,
        "min_stock_qty": 1,
        "conversion_factor": 1,
        "is_base_unit": isBaseUnit,
        "is_active": true,
      }),
    );
  }

  // ===================== PRICES =====================
  static Future<http.Response> getPrices() {
    return http.get(
      Uri.parse(ApiConstants.productPrices),
      headers: ApiConstants.headers,
    );
  }

  static Future<http.Response> getPricesByVariant(String variantId) {
    return http.get(
      Uri.parse("${ApiConstants.baseUrl}/product-prices/variant/$variantId"),
      headers: ApiConstants.headers,
    );
  }

  static Future<http.Response> createPrice({
    required String variantId,
    required String priceListId,
    required double price,
  }) {
    return http.post(
      Uri.parse("${ApiConstants.baseUrl}/product-prices"),
      headers: ApiConstants.headers,
      body: jsonEncode({
        "product_variant_id": variantId,
        "price_list_id": priceListId,
        "min_qty": 1,
        "price": price,
        "is_active": true,
      }),
    );
  }

  // update harga by price ID
  static Future<http.Response> updatePrice({
    required String priceId,
    required String priceListId,
    required double price,
  }) {
    return http.put(
      Uri.parse("${ApiConstants.baseUrl}/product-prices/$priceId"),
      headers: ApiConstants.headers,
      body: jsonEncode({
        "price_list_id": priceListId,
        "min_qty": 1,
        "price": price,
        "is_active": true,
      }),
    );
  }

  // hapus harga by price ID
  static Future<http.Response> deletePrice(String priceId) {
    return http.delete(
      Uri.parse("${ApiConstants.baseUrl}/product-prices/$priceId"),
      headers: ApiConstants.headers,
    );
  }

  // DELETE PRODUCT
  static Future<http.Response> deleteProduct(String productId) async {
    final url = "${ApiConstants.baseUrl}/products/$productId";
    debugPrint("DELETE URL: $url"); // ← Tambahkan ini untuk debug

    return http.delete(Uri.parse(url), headers: ApiConstants.headers);
  }

  // ===================== UNITS =====================
  static Future<http.Response> getUnits() {
    return http.get(
      Uri.parse("${ApiConstants.baseUrl}/units"),
      headers: ApiConstants.headers,
    );
  }

  static Future<http.Response> createUnit({
    required String name,
    required String symbol,
    String? description,
  }) {
    return http.post(
      Uri.parse("${ApiConstants.baseUrl}/units"),
      headers: ApiConstants.headers,
      body: jsonEncode({
        "name": name,
        "symbol": symbol,
        "description": description,
      }),
    );
  }

  static Future<http.Response> deleteUnit(String id) {
    return http.delete(
      Uri.parse("${ApiConstants.baseUrl}/units/$id"),
      headers: ApiConstants.headers,
    );
  }

  // ===================== CATEGORIES =====================
  static Future<http.Response> getCategories() {
    return http.get(
      Uri.parse("${ApiConstants.baseUrl}/categories"),
      headers: ApiConstants.headers,
    );
  }

  static Future<http.Response> createCategory(String name) {
    return http.post(
      Uri.parse("${ApiConstants.baseUrl}/categories"),
      headers: ApiConstants.headers,
      body: jsonEncode({
        "name": name,
        "slug": name.toLowerCase().replaceAll(" ", "-"),
        "parent_id": null,
        "sort_order": 0,
        "is_active": true,
      }),
    );
  }

  static Future<http.Response> deleteCategory(String id) {
    return http.delete(
      Uri.parse("${ApiConstants.baseUrl}/categories/$id"),
      headers: ApiConstants.headers,
    );
  }

  // ===================== PRICE LISTS =====================
  static Future<http.Response> getPriceLists() {
    return http.get(
      Uri.parse("${ApiConstants.baseUrl}/price-lists"),
      headers: ApiConstants.headers,
    );
  }

  static Future<http.Response> getProductImages(String productId) {
    return http.get(
      Uri.parse("${ApiConstants.baseUrl}/products/$productId/images"),
      headers: ApiConstants.headers,
    );
  }

  static Future<http.Response> uploadProductImage({
    required String productId,
    required List<int> imageBytes,
    required String fileName,
    // required String mimeType,
  }) async {
    final uri = Uri.parse("${ApiConstants.baseUrl}/products/$productId/images");
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
        // contentType: MediaType.parse(mimeType),
      ),
    );

    final streamed = await request.send();
    return http.Response.fromStream(streamed);
  }

  static Future<http.Response> deleteProductImage(
    String productId,
    String imageId,
  ) async {
    return http.delete(
      Uri.parse("${ApiConstants.baseUrl}/products/$productId/images/$imageId"),
      headers: ApiConstants.headers,
    );
  }
}

import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:senkukoadmin/constant/api_client.dart';
import 'package:senkukoadmin/constant/api_constant.dart';

class BannerService {
  // ===================== READ =====================
  static Future<http.Response> getAllBanners() {
    return ApiClient.get(
      Uri.parse('${ApiConstants.baseUrl}/banners'),
      headers: ApiConstants.headers,
    );
  }

  static Future<http.Response> getActiveBanners() {
    return ApiClient.get(
      Uri.parse('${ApiConstants.baseUrl}/banners/active'),
      headers: ApiConstants.headers,
    );
  }

  static Future<http.Response> getBannerById(String id) {
    return ApiClient.get(
      Uri.parse('${ApiConstants.baseUrl}/banners/$id'),
      headers: ApiConstants.headers,
    );
  }

  // ===================== CREATE (multipart, image wajib) =====================
  static Future<http.Response> createBanner({
    required File image,
    String? title,
    int? sortOrder,
    bool? isActive,
  }) async {
    final uri = Uri.parse('${ApiConstants.baseUrl}/banners');
    final request = http.MultipartRequest('POST', uri)
      ..headers.addAll(_multipartHeaders())
      ..files.add(await http.MultipartFile.fromPath('image', image.path));

    if (title != null && title.trim().isNotEmpty) {
      request.fields['title'] = title.trim();
    }
    if (sortOrder != null) {
      request.fields['sort_order'] = sortOrder.toString();
    }
    if (isActive != null) {
      request.fields['is_active'] = isActive ? '1' : '0';
    }

    final streamed = await request.send();
    return http.Response.fromStream(streamed);
  }

  // ===================== UPDATE (data saja, tanpa gambar) =====================
  static Future<http.Response> updateBanner(
    String id,
    Map<String, dynamic> body,
  ) {
    return ApiClient.put(
      Uri.parse('${ApiConstants.baseUrl}/banners/$id'),
      headers: ApiConstants.headers,
      body: jsonEncode(body),
    );
  }

  // ===================== UPDATE IMAGE (multipart) =====================
  static Future<http.Response> updateBannerImage(String id, File image) async {
    final uri = Uri.parse('${ApiConstants.baseUrl}/banners/$id/image');
    final request = http.MultipartRequest('PUT', uri)
      ..headers.addAll(_multipartHeaders())
      ..files.add(await http.MultipartFile.fromPath('image', image.path));

    final streamed = await request.send();
    return http.Response.fromStream(streamed);
  }

  // ===================== DELETE =====================
  static Future<http.Response> deleteBanner(String id) {
    return ApiClient.delete(
      Uri.parse('${ApiConstants.baseUrl}/banners/$id'),
      headers: ApiConstants.headers,
    );
  }

  // Multipart request butuh header Authorization tapi TIDAK boleh set
  // Content-Type manual (http package yang generate boundary-nya sendiri).
  static Map<String, String> _multipartHeaders() {
    final headers = Map<String, String>.from(ApiConstants.headers);
    headers.removeWhere((key, _) => key.toLowerCase() == 'content-type');
    return headers;
  }
}
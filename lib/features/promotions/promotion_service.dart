import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:senkukoadmin/constant/api_client.dart';
import 'package:senkukoadmin/constant/api_constant.dart';

class PromotionService {
  // ── Promotions ────────────────────────────────────────────────────────────

  static Future<http.Response> getAllPromotions() {
    return ApiClient.get(
      Uri.parse('${ApiConstants.baseUrl}/promotions'),
      headers: ApiConstants.headers,
    );
  }

  static Future<http.Response> getPromotionById(String id) {
    return ApiClient.get(
      Uri.parse('${ApiConstants.baseUrl}/promotions/$id'),
      headers: ApiConstants.headers,
    );
  }

  static Future<http.Response> createPromotion(Map<String, dynamic> body) {
    return ApiClient.post(
      Uri.parse('${ApiConstants.baseUrl}/promotions'),
      headers: ApiConstants.headers,
      body: jsonEncode(body),
    );
  }

  static Future<http.Response> updatePromotion(
      String id, Map<String, dynamic> body) {
    return ApiClient.put(
      Uri.parse('${ApiConstants.baseUrl}/promotions/$id'),
      headers: ApiConstants.headers,
      body: jsonEncode(body),
    );
  }

  static Future<http.Response> deletePromotion(String id) {
    return ApiClient.delete(
      Uri.parse('${ApiConstants.baseUrl}/promotions/$id'),
      headers: ApiConstants.headers,
    );
  }

  // ── Conditions ────────────────────────────────────────────────────────────

  static Future<http.Response> addCondition(
      String promotionId, Map<String, dynamic> body) {
    return ApiClient.post(
      Uri.parse('${ApiConstants.baseUrl}/promotions/$promotionId/conditions'),
      headers: ApiConstants.headers,
      body: jsonEncode(body),
    );
  }

  static Future<http.Response> deleteCondition(
      String promotionId, String conditionId) {
    return ApiClient.delete(
      Uri.parse(
          '${ApiConstants.baseUrl}/promotions/$promotionId/conditions/$conditionId'),
      headers: ApiConstants.headers,
    );
  }

  // ── Rewards ───────────────────────────────────────────────────────────────

  static Future<http.Response> addReward(
      String promotionId, Map<String, dynamic> body) {
    return ApiClient.post(
      Uri.parse('${ApiConstants.baseUrl}/promotions/$promotionId/rewards'),
      headers: ApiConstants.headers,
      body: jsonEncode(body),
    );
  }

  static Future<http.Response> deleteReward(
      String promotionId, String rewardId) {
    return ApiClient.delete(
      Uri.parse(
          '${ApiConstants.baseUrl}/promotions/$promotionId/rewards/$rewardId'),
      headers: ApiConstants.headers,
    );
  }
}
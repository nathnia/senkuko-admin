import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:get/get.dart';
import 'package:senkukoadmin/features/promotions/promotion_model.dart';
import 'package:senkukoadmin/features/promotions/promotion_service.dart';

class PromotionController extends GetxController {
  final isLoading = false.obs;
  final isLoadingDetail = false.obs;
  final isSubmitting = false.obs;

  final promotionList = <PromotionData>[].obs;
  final selectedPromotion = Rxn<Map<String, dynamic>>();

  final searchText = ''.obs;
  final selectedFilter = 'Semua'.obs;

  @override
  void onInit() {
    super.onInit();
    fetchPromotions();
  }

  // ── Filters ───────────────────────────────────────────────────────────────

  List<PromotionData> get filteredPromotions {
    var list = promotionList.toList();

    switch (selectedFilter.value) {
      case 'Aktif':
        list = list.where((p) => p.isValid).toList();
        break;
      case 'Tidak Aktif':
        list = list.where((p) => !p.isActive).toList();
        break;
      case 'Kedaluwarsa':
        list = list.where((p) => p.isExpired).toList();
        break;
    }

    final q = searchText.value.toLowerCase();
    if (q.isNotEmpty) {
      list = list
          .where((p) =>
              p.name.toLowerCase().contains(q) ||
              p.code.toLowerCase().contains(q))
          .toList();
    }

    return list;
  }

  void updateSearch(String value) => searchText.value = value;
  void updateFilter(String value) => selectedFilter.value = value;

  // ── Fetch ─────────────────────────────────────────────────────────────────

  Future<void> fetchPromotions() async {
    isLoading.value = true;
    try {
      final res = await PromotionService.getAllPromotions();
      if (res.statusCode == 200) {
        promotionList.assignAll(promotionListModelFromJson(res.body).data);
      }
    } catch (e) {
      debugPrint('Error fetchPromotions: $e');
      Fluttertoast.showToast(msg: 'Gagal memuat data promosi');
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> fetchPromotionById(String id) async {
    isLoadingDetail.value = true;
    selectedPromotion.value = null;
    try {
      final res = await PromotionService.getPromotionById(id);
      if (res.statusCode == 200) {
        selectedPromotion.value = jsonDecode(res.body)['data'];
      }
    } catch (e) {
      debugPrint('Error fetchPromotionById: $e');
      Fluttertoast.showToast(msg: 'Gagal memuat detail promosi');
    } finally {
      isLoadingDetail.value = false;
    }
  }

  // ── Create / Update / Delete ──────────────────────────────────────────────

  Future<void> createPromotion(Map<String, dynamic> payload) async {
    isSubmitting.value = true;
    try {
      final res = await PromotionService.createPromotion(payload);
      if (res.statusCode == 200 || res.statusCode == 201) {
        Fluttertoast.showToast(msg: 'Promosi berhasil dibuat');
        await fetchPromotions();
        Get.back();
      } else {
        final msg = _errorMessage(res.body);
        Fluttertoast.showToast(msg: msg);
      }
    } catch (e) {
      debugPrint('Error createPromotion: $e');
      Fluttertoast.showToast(msg: 'Gagal membuat promosi');
    } finally {
      isSubmitting.value = false;
    }
  }

  Future<void> updatePromotion(String id, Map<String, dynamic> payload) async {
    isSubmitting.value = true;
    try {
      final res = await PromotionService.updatePromotion(id, payload);
      if (res.statusCode == 200) {
        Fluttertoast.showToast(msg: 'Promosi berhasil diperbarui');
        await fetchPromotions();
        Get.back();
      } else {
        Fluttertoast.showToast(msg: _errorMessage(res.body));
      }
    } catch (e) {
      debugPrint('Error updatePromotion: $e');
      Fluttertoast.showToast(msg: 'Gagal memperbarui promosi');
    } finally {
      isSubmitting.value = false;
    }
  }

  Future<void> deletePromotion(String id) async {
    try {
      final res = await PromotionService.deletePromotion(id);
      if (res.statusCode == 200) {
        promotionList.removeWhere((p) => p.id == id);
        Fluttertoast.showToast(msg: 'Promosi berhasil dihapus');
        if (Get.currentRoute != '/promotions') Get.back();
      } else {
        Fluttertoast.showToast(msg: _errorMessage(res.body));
      }
    } catch (e) {
      debugPrint('Error deletePromotion: $e');
      Fluttertoast.showToast(msg: 'Gagal menghapus promosi');
    }
  }

  Future<void> toggleActive(PromotionData promo) async {
    try {
      final res = await PromotionService.updatePromotion(promo.id, {
        'name': promo.name,
        'code': promo.code,
        'type': promo.type,
        'description': promo.description ?? '',
        'valid_from': promo.validFrom.toIso8601String(),
        'valid_to': promo.validTo.toIso8601String(),
        'usage_limit': promo.usageLimit,
        'is_active': !promo.isActive,
        'stackable': promo.stackable,
      });
      if (res.statusCode == 200) {
        await fetchPromotions();
        Fluttertoast.showToast(
          msg: promo.isActive ? 'Promosi dinonaktifkan' : 'Promosi diaktifkan',
        );
      }
    } catch (e) {
      debugPrint('Error toggleActive: $e');
      Fluttertoast.showToast(msg: 'Gagal mengubah status promosi');
    }
  }

  // ── Conditions ────────────────────────────────────────────────────────────

  Future<void> addCondition(
      String promotionId, Map<String, dynamic> payload) async {
    isSubmitting.value = true;
    try {
      final res =
          await PromotionService.addCondition(promotionId, payload);
      if (res.statusCode == 200 || res.statusCode == 201) {
        Fluttertoast.showToast(msg: 'Syarat berhasil ditambahkan');
        await fetchPromotionById(promotionId);
        Get.back();
      } else {
        Fluttertoast.showToast(msg: _errorMessage(res.body));
      }
    } catch (e) {
      debugPrint('Error addCondition: $e');
      Fluttertoast.showToast(msg: 'Gagal menambahkan syarat');
    } finally {
      isSubmitting.value = false;
    }
  }

  Future<void> deleteCondition(
      String promotionId, String conditionId) async {
    try {
      final res =
          await PromotionService.deleteCondition(promotionId, conditionId);
      if (res.statusCode == 200) {
        await fetchPromotionById(promotionId);
        Fluttertoast.showToast(msg: 'Syarat berhasil dihapus');
      } else {
        Fluttertoast.showToast(msg: _errorMessage(res.body));
      }
    } catch (e) {
      debugPrint('Error deleteCondition: $e');
      Fluttertoast.showToast(msg: 'Gagal menghapus syarat');
    }
  }

  // ── Rewards ───────────────────────────────────────────────────────────────

  Future<void> addReward(
      String promotionId, Map<String, dynamic> payload) async {
    isSubmitting.value = true;
    try {
      final res = await PromotionService.addReward(promotionId, payload);
      if (res.statusCode == 200 || res.statusCode == 201) {
        Fluttertoast.showToast(msg: 'Reward berhasil ditambahkan');
        await fetchPromotionById(promotionId);
        Get.back();
      } else {
        Fluttertoast.showToast(msg: _errorMessage(res.body));
      }
    } catch (e) {
      debugPrint('Error addReward: $e');
      Fluttertoast.showToast(msg: 'Gagal menambahkan reward');
    } finally {
      isSubmitting.value = false;
    }
  }

  Future<void> deleteReward(String promotionId, String rewardId) async {
    try {
      final res =
          await PromotionService.deleteReward(promotionId, rewardId);
      if (res.statusCode == 200) {
        await fetchPromotionById(promotionId);
        Fluttertoast.showToast(msg: 'Reward berhasil dihapus');
      } else {
        Fluttertoast.showToast(msg: _errorMessage(res.body));
      }
    } catch (e) {
      debugPrint('Error deleteReward: $e');
      Fluttertoast.showToast(msg: 'Gagal menghapus reward');
    }
  }

  // ── Dialogs ───────────────────────────────────────────────────────────────

  void confirmDelete(String id, String name) {
    Get.dialog(
      AlertDialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'Hapus Promosi',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
        content: Text('Yakin ingin menghapus promosi "$name"?'),
        actions: [
          TextButton(onPressed: Get.back, child: const Text('Batal')),
          TextButton(
            onPressed: () {
              Get.back();
              deletePromotion(id);
            },
            child: const Text('Hapus',
                style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  // ── Helper ────────────────────────────────────────────────────────────────

  String _errorMessage(String body) {
    try {
      return jsonDecode(body)['message'] ?? 'Terjadi kesalahan';
    } catch (_) {
      return 'Terjadi kesalahan';
    }
  }
}
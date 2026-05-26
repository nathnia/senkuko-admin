import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:senkukoadmin/constant/api_helper.dart';
import 'package:senkukoadmin/constant/app_dialog.dart';
import 'package:senkukoadmin/constant/app_toast.dart';
import 'package:senkukoadmin/features/promotions/promotion_model.dart';
import 'package:senkukoadmin/features/promotions/promotion_service.dart';

class PromotionController extends GetxController {
  // ===================== STATE =====================
  final isLoading = false.obs;
  final isLoadingDetail = false.obs;
  final isSubmitting = false.obs;

  // ===================== DATA =====================
  final promotionList = <PromotionData>[].obs;
  final filteredPromotions = <PromotionData>[].obs;
  final selectedPromotion = Rxn<PromotionData>();

  // ===================== PAGE STATE =====================
  final searchText = ''.obs;
  final selectedFilter = 'Semua'.obs;

  final hasError = false.obs;
  final errorMessage = ''.obs;

  // ===================== PROMOTION FORM =====================
  final nameC = TextEditingController();
  final codeC = TextEditingController();
  final descC = TextEditingController();
  final usageLimitC = TextEditingController(); // ← diubah (kosong)

  final validFrom = Rxn<DateTime>();
  final validTo = Rxn<DateTime>();

  final selectedType = ''.obs; // ← diubah (kosong)
  final isActive = true.obs;
  final stackable = false.obs;

  // Reset Form
  void resetForm() {
    nameC.clear();
    codeC.clear();
    descC.clear();
    usageLimitC.clear(); // ← kosong
    validFrom.value = null;
    validTo.value = null;
    selectedType.value = ''; // ← kosong
    isActive.value = true;
    stackable.value = false;
  }

  // Load dari existing promotion
  void loadFormFromPromotion(PromotionData p) {
    nameC.text = p.name;
    codeC.text = p.code;
    descC.text = p.description ?? '';
    usageLimitC.text = p.usageLimit.toString();
    validFrom.value = p.validFrom;
    validTo.value = p.validTo;
    selectedType.value = p.type; // ini tetap pakai data existing
    isActive.value = p.isActive;
    stackable.value = p.stackable;
  }

  // ===================== CONDITION FORM =====================
  final conditionType = ''.obs;
  final conditionOperator = ''.obs;
  final conditionValueC = TextEditingController();
  final conditionTargetIdC = TextEditingController();

  bool conditionNeedsTargetId(String type) =>
      type == 'specific_product' || type == 'specific_category';

  void resetConditionForm() {
    conditionType.value = '';
    conditionOperator.value = '';
    conditionValueC.clear();
    conditionTargetIdC.clear();
  }

  // ===================== REWARD FORM =====================
  final rewardType = ''.obs;
  final discountMode = ''.obs;
  final discountValueC = TextEditingController();
  final maxDiscountC = TextEditingController(text: '0');
  final freeVariantIdC = TextEditingController();
  final freeQtyC = TextEditingController(text: '1');

  void resetRewardForm() {
    rewardType.value = '';
    discountMode.value = '';
    discountValueC.clear();
    maxDiscountC.text = '';
    freeVariantIdC.clear();
    freeQtyC.text = '1';
  }

  // ===================== LIFECYCLE =====================
  @override
  void onInit() {
    super.onInit();
    fetchPromotions();
  }

  @override
  void onClose() {
    nameC.dispose();
    codeC.dispose();
    descC.dispose();
    usageLimitC.dispose();
    conditionValueC.dispose();
    conditionTargetIdC.dispose();
    discountValueC.dispose();
    maxDiscountC.dispose();
    freeVariantIdC.dispose();
    freeQtyC.dispose();
    super.onClose();
  }

  // ===================== FILTER =====================
  void _applyFilter() {
    filteredPromotions.assignAll(
      promotionList.where((p) {
        final matchFilter = switch (selectedFilter.value) {
          'Aktif' => p.isValid,
          'Tidak Aktif' => !p.isActive,
          'Kedaluwarsa' => p.isExpired,
          _ => true,
        };
        final q = searchText.value.toLowerCase();
        final matchSearch =
            q.isEmpty ||
            p.name.toLowerCase().contains(q) ||
            p.code.toLowerCase().contains(q);
        return matchFilter && matchSearch;
      }).toList(),
    );
  }

  void updateSearch(String value) {
    searchText.value = value;
    _applyFilter();
  }

  void updateFilter(String value) {
    selectedFilter.value = value;
    _applyFilter();
  }

  // ===================== FETCH =====================
  Future<void> fetchPromotions() async {
    if (isLoading.value) return;
    isLoading.value = true;
    hasError.value = false;
    errorMessage.value = '';
    try {
      final res = await PromotionService.getAllPromotions();
      if (res.statusCode == 200) {
        promotionList.assignAll(promotionListModelFromJson(res.body).data);
        _applyFilter();
      } else {
        hasError.value = true;
        errorMessage.value = ApiHelper.isNetworkError(res)
            ? ApiHelper.parseError(res.body)
            : 'Gagal memuat daftar promosi.';
      }
    } catch (e) {
      hasError.value = true;
      errorMessage.value = 'Gagal memuat data.';
    } finally {
      isLoading.value = false;
    }
  }

  final hasDetailError = false.obs;
  final detailErrorMessage = ''.obs;

  Future<void> fetchPromotionById(String id) async {
    isLoadingDetail.value = true;
    hasDetailError.value = false;
    detailErrorMessage.value = '';
    selectedPromotion.value = null;
    try {
      final res = await PromotionService.getPromotionById(id);
      if (res.statusCode == 200) {
        selectedPromotion.value = PromotionData.fromJson(
          jsonDecode(res.body)['data'],
        );
      } else {
        hasDetailError.value = true;
        detailErrorMessage.value = 'Gagal memuat detail promosi. Coba lagi.';
      }
    } catch (_) {
      hasDetailError.value = true;
      detailErrorMessage.value = 'Gagal memuat detail promosi. Coba lagi.';
    } finally {
      isLoadingDetail.value = false;
    }
  }

  // ===================== CREATE =====================
  Future<bool> createPromotion() async {
    if (nameC.text.trim().isEmpty || codeC.text.trim().isEmpty) {
      AppToast.show('Nama dan Kode Promo harus diisi');
      return false;
    }
    if (validFrom.value == null || validTo.value == null) {
      AppToast.show('Periode berlaku harus diisi');
      return false;
    }
    isSubmitting.value = true;
    try {
      final res = await PromotionService.createPromotion(_buildPayload());
      if (ApiHelper.isNetworkError(res)) {
        AppToast.show(ApiHelper.parseError(res.body));
        return false;
      }
      if (res.statusCode != 200 && res.statusCode != 201) {
        AppToast.show(_parseError(res.body));
        return false;
      }
      AppToast.show('Promosi berhasil dibuat');
      await fetchPromotions();
      resetForm();
      return true;
    } catch (e) {
      AppToast.show('Terjadi kesalahan saat membuat promosi');
      return false;
    } finally {
      isSubmitting.value = false;
    }
  }

  // ===================== UPDATE =====================
  Future<bool> updatePromotion(String id) async {
    if (nameC.text.trim().isEmpty || codeC.text.trim().isEmpty) {
      AppToast.show('Nama dan Kode Promo harus diisi');
      return false;
    }
    if (validFrom.value == null || validTo.value == null) {
      AppToast.show('Periode berlaku harus diisi');
      return false;
    }
    isSubmitting.value = true;
    try {
      final res = await PromotionService.updatePromotion(id, _buildPayload());
      if (ApiHelper.isNetworkError(res)) {
        AppToast.show(ApiHelper.parseError(res.body));
        return false;
      }
      if (res.statusCode < 200 || res.statusCode >= 300) {
        AppToast.show(_parseError(res.body));
        return false;
      }
      AppToast.show('Promosi berhasil diperbarui');
      await fetchPromotions();
      await fetchPromotionById(id);
      return true;
    } catch (e) {
      AppToast.show('Terjadi kesalahan saat memperbarui promosi');
      return false;
    } finally {
      isSubmitting.value = false;
    }
  }

  // ===================== DELETE =====================
  Future<void> deletePromotion(String id) async {
    try {
      final res = await PromotionService.deletePromotion(id);
      if (res.statusCode == 200) {
        promotionList.removeWhere((p) => p.id == id);
        _applyFilter();
        AppToast.show('Promosi berhasil dihapus');
        if (Get.currentRoute != '/promotions') Get.back();
      } else if (ApiHelper.isNetworkError(res)) {
        AppToast.show(ApiHelper.parseError(res.body));
      } else {
        AppToast.show(_parseError(res.body));
      }
    } catch (e) {
      AppToast.show('Terjadi kesalahan saat menghapus promosi');
    }
  }

  void confirmDelete(String id, String name) async {
    final confirm = await AppDialog.confirm(
      title: 'Hapus Promosi',
      content: 'Yakin ingin menghapus promosi "$name"?',
    );
    if (confirm) deletePromotion(id);
  }

  // ===================== TOGGLE ACTIVE =====================
  Future<void> toggleActive(PromotionData promo) async {
    try {
      final res = await PromotionService.updatePromotion(promo.id, {
        'name': promo.name,
        'code': promo.code,
        'type': promo.type,
        'description': promo.description ?? '',
        'valid_from': _formatDate(promo.validFrom),
        'valid_to': _formatDate(promo.validTo),
        'usage_limit': promo.usageLimit,
        'is_active': !promo.isActive,
        'stackable': promo.stackable,
      });
      if (res.statusCode == 200) {
        await fetchPromotions();
        AppToast.show(
          promo.isActive ? 'Promosi dinonaktifkan' : 'Promosi diaktifkan',
        );
      } else {
        AppToast.show(_parseError(res.body));
      }
    } catch (e) {
      AppToast.show('Gagal mengubah status promosi');
    }
  }

  // ===================== CONDITIONS =====================
  Future<bool> addCondition(String promotionId) async {
    if (conditionValueC.text.trim().isEmpty) {
      AppToast.show('Value harus diisi');
      return false;
    }
    if (conditionNeedsTargetId(conditionType.value) &&
        conditionTargetIdC.text.trim().isEmpty) {
      AppToast.show('Target ID harus diisi');
      return false;
    }

    isSubmitting.value = true;
    try {
      final payload = {
        'condition_type': conditionType.value,
        'operator': conditionOperator.value,
        'value': conditionValueC.text.trim(),
        'target_type': conditionNeedsTargetId(conditionType.value)
            ? conditionType.value
            : null,
        'target_id': conditionNeedsTargetId(conditionType.value)
            ? conditionTargetIdC.text.trim()
            : null,
      };
      final res = await PromotionService.addCondition(promotionId, payload);
      if (res.statusCode == 200 || res.statusCode == 201) {
        AppToast.show('Syarat berhasil ditambahkan');
        await fetchPromotionById(promotionId);
        resetConditionForm();
        return true;
      } else if (ApiHelper.isNetworkError(res)) {
        AppToast.show(ApiHelper.parseError(res.body));
      } else {
        AppToast.show(_parseError(res.body));
      }
      return false;
    } catch (e) {
      AppToast.show('Terjadi kesalahan saat menambahkan syarat');
      return false;
    } finally {
      isSubmitting.value = false;
    }
  }

  Future<void> deleteCondition(String promotionId, String conditionId) async {
    try {
      final res = await PromotionService.deleteCondition(
        promotionId,
        conditionId,
      );
      if (res.statusCode == 200) {
        await fetchPromotionById(promotionId);
        AppToast.show('Syarat berhasil dihapus');
      } else {
        AppToast.show(_parseError(res.body));
      }
    } catch (e) {
      AppToast.show('Terjadi kesalahan saat menghapus syarat');
    }
  }

  // ===================== REWARDS =====================
  Future<bool> addReward(String promotionId) async {
    isSubmitting.value = true;
    try {
      final Map<String, dynamic> payload;

      if (rewardType.value == 'free_item') {
        if (freeVariantIdC.text.trim().isEmpty) {
          AppToast.show('Variant ID harus diisi');
          return false;
        }
        payload = {
          'reward_type': rewardType.value,
          'free_variant_id': freeVariantIdC.text.trim(),
          'free_qty': int.tryParse(freeQtyC.text) ?? 1,
        };
      } else {
        if (discountValueC.text.trim().isEmpty) {
          AppToast.show('Nilai diskon harus diisi');
          return false;
        }
        payload = {
          'reward_type': rewardType.value,
          'discount_value': double.tryParse(discountValueC.text) ?? 0,
          'discount_mode': discountMode.value,
          'max_discount_amount': double.tryParse(maxDiscountC.text) ?? 0,
        };
      }

      final res = await PromotionService.addReward(promotionId, payload);
      if (res.statusCode == 200 || res.statusCode == 201) {
        AppToast.show('Reward berhasil ditambahkan');
        await fetchPromotionById(promotionId);
        resetRewardForm();
        return true;
      } else if (ApiHelper.isNetworkError(res)) {
        AppToast.show(ApiHelper.parseError(res.body));
      } else {
        AppToast.show(_parseError(res.body));
      }
      return false;
    } catch (e) {
      AppToast.show('Terjadi kesalahan saat menambahkan reward');
      return false;
    } finally {
      isSubmitting.value = false;
    }
  }

  Future<void> deleteReward(String promotionId, String rewardId) async {
    try {
      final res = await PromotionService.deleteReward(promotionId, rewardId);
      if (res.statusCode == 200) {
        await fetchPromotionById(promotionId);
        AppToast.show('Reward berhasil dihapus');
      } else {
        AppToast.show(_parseError(res.body));
      }
    } catch (e) {
      AppToast.show('Terjadi kesalahan saat menghapus reward');
    }
  }

  // ===================== DETAIL PAGE HELPERS =====================
  List<PromotionCondition> get detailConditions =>
      selectedPromotion.value?.conditions ?? [];

  List<PromotionReward> get detailRewards =>
      selectedPromotion.value?.rewards ?? [];

  String get detailValidPeriod {
    final p = selectedPromotion.value;
    if (p == null) return '';
    final df = DateFormat('dd MMM yyyy', 'id_ID');
    return '${df.format(p.validFrom)} – ${df.format(p.validTo)}';
  }

  String get detailUsageDisplay {
    final p = selectedPromotion.value;
    if (p == null) return '';
    return p.usageLimit == 0 ? 'Unlimited' : '${p.usageCount}/${p.usageLimit}x';
  }

  String get detailStackableLabel =>
      (selectedPromotion.value?.stackable ?? false) ? 'Ya' : 'Tidak';

  String get detailStatusLabel =>
      (selectedPromotion.value?.isActive ?? false) ? 'Aktif' : 'Tidak Aktif';

  String rewardSubtitle(PromotionReward r) {
    if (r.rewardType == 'free_item') {
      var text = 'Qty: ${r.freeQty}';
      if ((r.freeVariantId ?? '').isNotEmpty) {
        text += ' • Variant: ${r.freeVariantId}';
      }
      return text;
    }
    var text = '${r.discountValue} • ${r.discountModeLabel}';
    final maxDisc = r.maxDiscountAmount ?? 0;
    if (maxDisc > 0) text += ' • maks Rp$maxDisc';
    return text;
  }

  // ===================== PRIVATE =====================

  String _formatDate(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-'
      '${d.day.toString().padLeft(2, '0')} 12:00:00';

  Map<String, dynamic> _buildPayload() => {
    'name': nameC.text.trim(),
    'code': codeC.text.trim().toUpperCase(),
    'type': selectedType.value,
    'description': descC.text.trim(),
    'valid_from': _formatDate(validFrom.value!),
    'valid_to': _formatDate(validTo.value!),
    'usage_limit': int.tryParse(usageLimitC.text) ?? 0,
    'is_active': isActive.value,
    'stackable': stackable.value,
  };

  String _parseError(String body) {
    try {
      return jsonDecode(body)['message'] ?? 'Terjadi kesalahan';
    } catch (_) {
      return 'Terjadi kesalahan';
    }
  }
}

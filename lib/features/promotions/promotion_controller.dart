import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:senkukoadmin/constant/app_dialog.dart';
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

  // ── Form state (dipakai oleh PromotionFormPage) ───────────────────────────

  final formKey = GlobalKey<FormState>();

  final nameCtrl = TextEditingController();
  final codeCtrl = TextEditingController();
  final descCtrl = TextEditingController();
  final usageLimitCtrl = TextEditingController();

  final formType = 'discount_percent'.obs;
  final formIsActive = true.obs;
  final formStackable = false.obs;
  final formValidFrom = Rxn<DateTime>();
  final formValidTo = Rxn<DateTime>();

  /// Panggil ini sebelum buka halaman form.
  /// [data] = null artinya mode Create; isi data artinya mode Edit.
  void initForm([Map<String, dynamic>? data]) {
    nameCtrl.text = data?['name'] ?? '';
    codeCtrl.text = data?['code'] ?? '';
    descCtrl.text = data?['description'] ?? '';
    usageLimitCtrl.text = data?['usage_limit']?.toString() ?? '0';

    formType.value = (data?['type'] as String?) ?? 'discount_percent';
    formIsActive.value =
        data?['is_active'] == 1 || data?['is_active'] == true ? true : true;
    formStackable.value =
        data?['stackable'] == 1 || data?['stackable'] == true;

    formValidFrom.value =
        data != null ? DateTime.tryParse(data['valid_from'] ?? '') : DateTime.now();
    formValidTo.value = data != null
        ? DateTime.tryParse(data['valid_to'] ?? '')
        : DateTime.now().add(const Duration(days: 30));
  }

  void submitForm(String? editId) {
    if (!formKey.currentState!.validate()) return;
    if (formValidFrom.value == null || formValidTo.value == null) return;

    final payload = {
      'name': nameCtrl.text.trim(),
      'code': codeCtrl.text.trim().toUpperCase(),
      'type': formType.value,
      'description': descCtrl.text.trim(),
      'valid_from': formValidFrom.value!.toIso8601String(),
      'valid_to': formValidTo.value!.toIso8601String(),
      'usage_limit': int.tryParse(usageLimitCtrl.text) ?? 0,
      'is_active': formIsActive.value,
      'stackable': formStackable.value,
    };

    if (editId != null) {
      updatePromotion(editId, payload);
    } else {
      createPromotion(payload);
    }
  }

  @override
  void onClose() {
    nameCtrl.dispose();
    codeCtrl.dispose();
    descCtrl.dispose();
    usageLimitCtrl.dispose();
    super.onClose();
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

  @override
  void onInit() {
    super.onInit();
    fetchPromotions();
  }

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
        Fluttertoast.showToast(msg: _errorMessage(res.body));
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
      final res = await PromotionService.addCondition(promotionId, payload);
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

  void confirmDelete(String id, String name) async {
    final confirm = await AppDialog.confirm(
      title: 'Hapus Promosi',
      content: 'Yakin ingin menghapus promosi "$name"?',
    );
    if (confirm) deletePromotion(id);
  }

  // ── Detail page — computed getters ────────────────────────────────────────

  List<Map<String, dynamic>> get detailConditions =>
      (selectedPromotion.value?['conditions'] as List? ?? [])
          .cast<Map<String, dynamic>>();

  List<Map<String, dynamic>> get detailRewards =>
      (selectedPromotion.value?['rewards'] as List? ?? [])
          .cast<Map<String, dynamic>>();

  String get detailValidPeriod {
    final data = selectedPromotion.value;
    if (data == null) return '';
    final df = DateFormat('dd MMM yyyy', 'id_ID');
    return '${df.format(DateTime.parse(data['valid_from']))} – '
        '${df.format(DateTime.parse(data['valid_to']))}';
  }

  String get detailUsageDisplay {
    final data = selectedPromotion.value;
    if (data == null) return '';
    return data['usage_limit'] == 0
        ? 'Unlimited'
        : '${data['usage_count']}/${data['usage_limit']}x';
  }

  String get detailStackableLabel {
    final data = selectedPromotion.value;
    if (data == null) return '';
    return (data['stackable'] == 1 || data['stackable'] == true)
        ? 'Ya'
        : 'Tidak';
  }

  String get detailStatusLabel {
    final data = selectedPromotion.value;
    if (data == null) return '';
    return (data['is_active'] == 1 || data['is_active'] == true)
        ? 'Aktif'
        : 'Tidak Aktif';
  }

  // ── Label helpers ─────────────────────────────────────────────────────────

  String promotionTypeLabel(String type) {
    switch (type) {
      case 'discount_percent':
        return 'Diskon %';
      case 'discount_fixed':
        return 'Diskon Nominal';
      case 'free_item':
        return 'Gratis Item';
      default:
        return type;
    }
  }

  String conditionTypeLabel(String type) {
    switch (type) {
      case 'min_transaction_amount':
        return 'Min. Total Belanja';
      case 'min_qty':
        return 'Min. Qty Item';
      case 'specific_product':
        return 'Produk Tertentu';
      case 'specific_category':
        return 'Kategori Tertentu';
      case 'member_type':
        return 'Tipe Member';
      default:
        return type;
    }
  }

  String rewardTypeLabel(String type) {
    switch (type) {
      case 'discount_percent':
        return 'Diskon %';
      case 'discount_fixed':
        return 'Diskon Nominal';
      case 'free_item':
        return 'Gratis Item';
      default:
        return type;
    }
  }

  String discountModeLabel(String mode) {
    switch (mode) {
      case 'per_transaction':
        return 'Per Transaksi';
      case 'per_item':
        return 'Per Item';
      default:
        return mode;
    }
  }

  String rewardSubtitle(Map<String, dynamic> r) {
    if (r['reward_type'] == 'free_item') {
      var text = 'Qty: ${r['free_qty']}';
      if ((r['free_variant_id'] ?? '').toString().isNotEmpty) {
        text += ' • Variant: ${r['free_variant_id']}';
      }
      return text;
    }

    var text =
        '${r['discount_value']} • ${discountModeLabel(r['discount_mode'] ?? '')}';
    final maxDisc =
        double.tryParse(r['max_discount_amount']?.toString() ?? '0') ?? 0;
    if (maxDisc > 0) text += ' • maks Rp$maxDisc';
    return text;
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
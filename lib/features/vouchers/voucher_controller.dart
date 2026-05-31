import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:senkukoadmin/constant/api_helper.dart';
import 'package:senkukoadmin/constant/app_dialog.dart';
import 'package:senkukoadmin/constant/app_toast.dart';
import 'package:senkukoadmin/features/promotions/promotion_model.dart';
import 'package:senkukoadmin/features/vouchers/voucher_model.dart';
import 'package:senkukoadmin/features/vouchers/voucher_service.dart';

class VoucherController extends GetxController {
  // ===================== STATE =====================
  final isLoading = false.obs;
  final isSubmitting = false.obs;
  final hasError = false.obs;
  final errorMessage = ''.obs;

  // ===================== DATA =====================
  final voucherList = <VoucherData>[].obs;
  final filteredVouchers = <VoucherData>[].obs;

  // ===================== PAGE STATE =====================
  final searchText = ''.obs;
  final selectedFilter = 'Semua'.obs;
  final filterByPromotionId = Rxn<String>();

  // ===================== FORM =====================
  final codeC = TextEditingController();
  final promotionIdC = TextEditingController();
  final usageLimitC = TextEditingController(text: '0');
  final status = 'active'.obs;

  /// Holds the full [PromotionData] selected via the promotion picker sheet.
  /// Only used in standalone create mode (no pre-filled promotionId).
  final selectedPromotionObs = Rxn<PromotionData>();

  // ===================== DIRTY TRACKING =====================
  final isDirty = false.obs;

  String _snapCode = '';
  String _snapUsageLimit = '';
  String _snapStatus = '';

  Worker? _statusWorker;

  void _checkDirty() {
    isDirty.value =
        codeC.text != _snapCode ||
        usageLimitC.text != _snapUsageLimit ||
        status.value != _snapStatus;
  }

  void _checkDirtyCreate() {
    isDirty.value = codeC.text.trim().isNotEmpty &&
        promotionIdC.text.trim().isNotEmpty;
  }

  void resetForm() {
    codeC.clear();
    promotionIdC.clear();
    usageLimitC.text = '1';
    status.value = 'active';
    isDirty.value = false;
    selectedPromotionObs.value = null;

    _statusWorker?.dispose();
    codeC.removeListener(_checkDirty);
    codeC.removeListener(_checkDirtyCreate);
    usageLimitC.removeListener(_checkDirty);
    promotionIdC.removeListener(_checkDirtyCreate);

    // create mode — dirty only when both code and promotionId are filled
    codeC.addListener(_checkDirtyCreate);
    promotionIdC.addListener(_checkDirtyCreate);
  }

  void loadFromVoucher(VoucherData v, {String? prefilledPromotionId}) {
    codeC.text = v.code;
    promotionIdC.text = v.promotionId;
    usageLimitC.text = v.usageLimit.toString();
    status.value = v.status;
    isDirty.value = false;
    selectedPromotionObs.value = null;

    _snapCode = codeC.text;
    _snapUsageLimit = usageLimitC.text;
    _snapStatus = status.value;

    _statusWorker?.dispose();
    codeC.removeListener(_checkDirty);
    codeC.removeListener(_checkDirtyCreate);
    usageLimitC.removeListener(_checkDirty);
    promotionIdC.removeListener(_checkDirtyCreate);

    codeC.addListener(_checkDirty);
    usageLimitC.addListener(_checkDirty);
    _statusWorker = ever(status, (_) => _checkDirty());
  }

  // ===================== LIFECYCLE =====================
  @override
  void onInit() {
    super.onInit();
    fetchVouchers();
  }

  bool _initialized = false;

  void initPage(String? promotionId) {
    if (_initialized) return;
    _initialized = true;
    resetPageState(promotionId: promotionId);
    fetchVouchers();
  }

  void resetInit() => _initialized = false;

  @override
  void onClose() {
    _statusWorker?.dispose();
    codeC.removeListener(_checkDirty);
    codeC.removeListener(_checkDirtyCreate);
    usageLimitC.removeListener(_checkDirty);
    promotionIdC.removeListener(_checkDirtyCreate);
    codeC.dispose();
    promotionIdC.dispose();
    usageLimitC.dispose();
    super.onClose();
  }

  // ===================== FILTER =====================
  void _applyFilter() {
    filteredVouchers.assignAll(
      voucherList.where((v) {
        if (filterByPromotionId.value != null &&
            v.promotionId != filterByPromotionId.value) {
          return false;
        }
        final matchFilter = switch (selectedFilter.value) {
          'Aktif' => v.isActive && !v.isUsed,
          'Tidak Aktif' => !v.isActive,
          'Habis' => v.isUsed,
          _ => true,
        };
        final q = searchText.value.toLowerCase();
        final matchSearch = q.isEmpty || v.code.toLowerCase().contains(q);
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

  void resetPageState({String? promotionId}) {
    searchText.value = '';
    selectedFilter.value = 'Semua';
    filterByPromotionId.value = promotionId;
    _applyFilter();
  }

  // ===================== FETCH =====================
  Future<void> fetchVouchers() async {
    isLoading.value = true;
    hasError.value = false;
    try {
      final res = await VoucherService.getAllVouchers();
      if (res.statusCode == 200) {
        voucherList.assignAll(voucherListModelFromJson(res.body).data);
        _applyFilter();
      } else {
        hasError.value = true;
        errorMessage.value = 'Gagal memuat daftar voucher';
      }
    } catch (e) {
      hasError.value = true;
      errorMessage.value = 'Terjadi kesalahan saat memuat voucher';
    } finally {
      isLoading.value = false;
    }
  }

  // ===================== CREATE =====================
  Future<bool> createVoucher() async {
    if (codeC.text.trim().isEmpty) {
      AppToast.show('Kode voucher harus diisi');
      return false;
    }
    if (promotionIdC.text.trim().isEmpty) {
      AppToast.show('Pilih promosi terlebih dahulu');
      return false;
    }

    isSubmitting.value = true;
    try {
      final res = await VoucherService.createVoucher({
        'promotion_id': promotionIdC.text.trim(),
        'code': codeC.text.trim().toUpperCase(),
        'usage_limit': int.tryParse(usageLimitC.text) ?? 1,
      });

      if (ApiHelper.isNetworkError(res)) {
        AppToast.show(ApiHelper.parseError(res.body));
        return false;
      }
      if (res.statusCode != 200 && res.statusCode != 201) {
        AppToast.show(_parseError(res.body));
        return false;
      }

      AppToast.show('Voucher berhasil diterbitkan');
      await fetchVouchers();
      resetForm();
      return true;
    } catch (e) {
      AppToast.show('Terjadi kesalahan saat menerbitkan voucher');
      return false;
    } finally {
      isSubmitting.value = false;
    }
  }

  // ===================== UPDATE =====================
  Future<bool> updateVoucher(String id) async {
    if (codeC.text.trim().isEmpty) {
      AppToast.show('Kode voucher harus diisi');
      return false;
    }

    isSubmitting.value = true;
    try {
      final res = await VoucherService.updateVoucher(id, {
        'code': codeC.text.trim().toUpperCase(),
        'status': status.value,
        'usage_limit': int.tryParse(usageLimitC.text) ?? 1,
      });

      if (ApiHelper.isNetworkError(res)) {
        AppToast.show(ApiHelper.parseError(res.body));
        return false;
      }
      if (res.statusCode < 200 || res.statusCode >= 300) {
        AppToast.show(_parseError(res.body));
        return false;
      }

      AppToast.show('Voucher berhasil diperbarui');
      await fetchVouchers();
      return true;
    } catch (e) {
      AppToast.show('Terjadi kesalahan saat memperbarui voucher');
      return false;
    } finally {
      isSubmitting.value = false;
    }
  }

  // ===================== DELETE =====================
  Future<void> deleteVoucher(String id) async {
    try {
      final res = await VoucherService.deleteVoucher(id);
      if (res.statusCode == 200) {
        voucherList.removeWhere((v) => v.id == id);
        _applyFilter();
        AppToast.show('Voucher berhasil dihapus');
        if (Get.currentRoute != '/vouchers') Get.back();
      } else if (ApiHelper.isNetworkError(res)) {
        AppToast.show(ApiHelper.parseError(res.body));
      } else {
        AppToast.show(_parseError(res.body));
      }
    } catch (e) {
      AppToast.show('Terjadi kesalahan saat menghapus voucher');
    }
  }

  void confirmDelete(String id, String code) async {
    final confirm = await AppDialog.confirm(
      title: 'Hapus Voucher',
      content: 'Yakin ingin menghapus voucher "$code"?',
    );
    if (confirm) deleteVoucher(id);
  }

  // ===================== TOGGLE STATUS =====================
  Future<void> toggleStatus(VoucherData voucher) async {
    final idx = voucherList.indexWhere((v) => v.id == voucher.id);
    if (idx == -1) return;

    final newStatus = voucher.isActive ? 'inactive' : 'active';

    // optimistic update
    voucherList[idx] = voucher.copyWith(status: newStatus);
    _applyFilter();

    try {
      final res = await VoucherService.updateVoucher(voucher.id, {
        'code': voucher.code,
        'status': newStatus,
        'usage_limit': voucher.usageLimit,
      });
      if (res.statusCode == 200) {
        AppToast.show(
          newStatus == 'active'
              ? 'Voucher diaktifkan'
              : 'Voucher dinonaktifkan',
        );
      } else {
        // rollback
        voucherList[idx] = voucher;
        _applyFilter();
        AppToast.show(_parseError(res.body));
      }
    } catch (e) {
      // rollback
      voucherList[idx] = voucher;
      _applyFilter();
      AppToast.show('Gagal mengubah status voucher');
    }
  }

  // ===================== PRIVATE =====================
  String _parseError(String body) {
    try {
      return jsonDecode(body)['message'] ?? 'Terjadi kesalahan';
    } catch (_) {
      return 'Terjadi kesalahan';
    }
  }
}
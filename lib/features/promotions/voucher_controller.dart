import 'dart:convert';

import 'package:get/get.dart';
import 'package:senkukoadmin/constant/api_helper.dart';
import 'package:senkukoadmin/constant/app_dialog.dart';
import 'package:senkukoadmin/constant/app_toast.dart';
import 'package:senkukoadmin/features/promotions/voucher_model.dart';
import 'package:senkukoadmin/features/promotions/voucher_service.dart';

class VoucherController extends GetxController {
  // ===================== STATE =====================
  final isLoading = false.obs;
  final isSubmitting = false.obs;

  // ===================== DATA =====================
  final voucherList = <VoucherData>[].obs;
  final filteredVouchers = <VoucherData>[].obs;

  // ===================== PAGE STATE =====================
  final searchText = ''.obs;
  final selectedFilter = 'Semua'.obs;
  final filterByPromotionId = Rxn<String>();

  // ===================== LIFECYCLE =====================
  @override
  void onInit() {
    super.onInit();
    fetchVouchers();
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
    try {
      final res = await VoucherService.getAllVouchers();
      if (res.statusCode == 200) {
        voucherList.assignAll(voucherListModelFromJson(res.body).data);
        _applyFilter();
      } else if (ApiHelper.isNetworkError(res)) {
        AppToast.error(ApiHelper.parseError(res.body));
      } else {
        AppToast.error('Gagal memuat daftar voucher');
      }
    } catch (e) {
      AppToast.error('Terjadi kesalahan saat memuat voucher');
    } finally {
      isLoading.value = false;
    }
  }

  // ===================== CREATE =====================
  Future<bool> createVoucher(Map<String, dynamic> payload) async {
    isSubmitting.value = true;
    try {
      final res = await VoucherService.createVoucher(payload);

      if (ApiHelper.isNetworkError(res)) {
        AppToast.error(ApiHelper.parseError(res.body));
        return false;
      }
      if (res.statusCode != 200 && res.statusCode != 201) {
        AppToast.error(_parseError(res.body));
        return false;
      }

      AppToast.success('Voucher berhasil diterbitkan');
      await fetchVouchers();
      return true;
    } catch (e) {
      AppToast.error('Terjadi kesalahan saat menerbitkan voucher');
      return false;
    } finally {
      isSubmitting.value = false;
    }
  }

  // ===================== UPDATE =====================
  Future<bool> updateVoucher(String id, Map<String, dynamic> payload) async {
    isSubmitting.value = true;
    try {
      final res = await VoucherService.updateVoucher(id, payload);

      if (ApiHelper.isNetworkError(res)) {
        AppToast.error(ApiHelper.parseError(res.body));
        return false;
      }
      if (res.statusCode < 200 || res.statusCode >= 300) {
        AppToast.error(_parseError(res.body));
        return false;
      }

      AppToast.success('Voucher berhasil diperbarui');
      await fetchVouchers();
      return true;
    } catch (e) {
      AppToast.error('Terjadi kesalahan saat memperbarui voucher');
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
        AppToast.success('Voucher berhasil dihapus');
        if (Get.currentRoute != '/vouchers') Get.back();
      } else if (ApiHelper.isNetworkError(res)) {
        AppToast.error(ApiHelper.parseError(res.body));
      } else {
        AppToast.error(_parseError(res.body));
      }
    } catch (e) {
      AppToast.error('Terjadi kesalahan saat menghapus voucher');
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
    try {
      final newStatus = voucher.isActive ? 'inactive' : 'active';
      final res = await VoucherService.updateVoucher(voucher.id, {
        'code': voucher.code,
        'status': newStatus,
        'usage_limit': voucher.usageLimit,
      });
      if (res.statusCode == 200) {
        await fetchVouchers();
        AppToast.success(
          newStatus == 'active' ? 'Voucher diaktifkan' : 'Voucher dinonaktifkan',
        );
      } else {
        AppToast.error(_parseError(res.body));
      }
    } catch (e) {
      AppToast.error('Gagal mengubah status voucher');
    }
  }

  // ===================== PRIVATE HELPERS =====================
  String _parseError(String body) {
    try {
      return jsonDecode(body)['message'] ?? 'Terjadi kesalahan';
    } catch (_) {
      return 'Terjadi kesalahan';
    }
  }
}
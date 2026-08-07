import 'dart:convert';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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

  // ===================== PROMOTION DETAIL PREVIEW =====================
  final promotionVouchers = <VoucherData>[].obs;
  String? _previewPromotionId;

  // ===================== PAGE STATE =====================
  final searchText = ''.obs;
  final selectedFilter = 'Aktif'.obs;
  final filterByPromotionId = Rxn<String>();

  // ===================== FORM =====================
  final codeC = TextEditingController();
  final promotionIdC = TextEditingController();
  final usageLimitC = TextEditingController(text: '0');
  final status = 'active'.obs;

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
    isDirty.value =
        codeC.text.trim().isNotEmpty && promotionIdC.text.trim().isNotEmpty;
  }

  // ===================== GENERATE KODE =====================
  // Karakter dipilih agar mudah dibaca (hindari 0/O dan 1/I yang rancu).
  String _generateVoucherCode() {
    const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
    final rng = Random.secure();
    final suffix = List.generate(
      8,
      (_) => chars[rng.nextInt(chars.length)],
    ).join();
    return 'VC-$suffix';
  }

  /// Dipanggil dari tombol "Generate Ulang" di UI form voucher.
  void regenerateCode() {
    codeC.text = _generateVoucherCode();
    _checkDirtyCreate();
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

    // Isi kode otomatis saat form dibuka. Admin tetap bisa mengedit
    // manual atau menekan tombol generate ulang di UI.
    codeC.text = _generateVoucherCode();

    codeC.addListener(_checkDirtyCreate);
    promotionIdC.addListener(_checkDirtyCreate);
  }

  void loadFromVoucher(VoucherData v, {String? prefilledPromotionId}) {
    codeC.text = v.code;
    promotionIdC.text = v.promotionId;
    usageLimitC.text = v.usageLimit.toString();

    final normalized = v.status.trim().toLowerCase();
    status.value = (normalized == 'active' || normalized == 'inactive')
        ? normalized
        : 'active';

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
  bool _hasLoadedOnce = false;

  @override
  void onInit() {
    super.onInit();
    if (!_hasLoadedOnce) {
      fetchVouchers();
      _hasLoadedOnce = true;
    }
  }

  bool _initialized = false;

  void initPage(PromotionData? promotion) {
    if (_initialized) return;
    _initialized = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      resetPageState(promotion: promotion);
      refreshIfStale();
    });
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

  void resetPageState({PromotionData? promotion}) {
    searchText.value = '';
    selectedFilter.value = 'Aktif';
    filterByPromotionId.value = promotion?.id;
    _applyFilter();
  }

  // ===================== STALENESS (TTL) =====================
  DateTime? _lastFetchedAt;
  static const _staleAfter = Duration(seconds: 20);

  bool get _isStale =>
      _lastFetchedAt == null ||
      DateTime.now().difference(_lastFetchedAt!) > _staleAfter;

  void refreshIfStale() {
    if (_isStale) fetchVouchers();
  }

  // ===================== PROMOTION PREVIEW =====================
  void fetchVouchersForPromotion(String promotionId) {
    _previewPromotionId = promotionId;
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (voucherList.isEmpty || _isStale) {
        await fetchVouchers();
      } else {
        _refreshPromotionVouchers();
      }
    });
  }

  /// Called by PromotionDetailPage in dispose. Clears preview slice.
  void clearPromotionVouchers() {
    _previewPromotionId = null;
    promotionVouchers.clear();
  }

  void _refreshPromotionVouchers() {
    if (_previewPromotionId == null) return;
    promotionVouchers.assignAll(
      voucherList.where((v) => v.promotionId == _previewPromotionId).toList(),
    );
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
        _refreshPromotionVouchers();
        _lastFetchedAt = DateTime.now();
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
    final code = codeC.text.trim();

    if (code.isEmpty) {
      AppToast.show('Kode voucher harus diisi');
      return false;
    }
    if (code.contains(' ')) {
      AppToast.show('Kode voucher tidak boleh mengandung spasi');
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
        'code': code.toUpperCase(),
        'usage_limit': int.tryParse(usageLimitC.text) ?? 1,
      });

      if (ApiHelper.isNetworkError(res)) {
        AppToast.show(ApiHelper.parseError(res.body));
        return false;
      }
      if (res.statusCode != 200 && res.statusCode != 201) {
        final errMsg = _parseError(res.body);
        final isDuplicateCode =
            errMsg.toLowerCase().contains('code') ||
            errMsg.toLowerCase().contains('kode') ||
            res.statusCode == 409;

        if (isDuplicateCode) {
          codeC.text = _generateVoucherCode();
          AppToast.show('Kode sudah dipakai, kode baru sudah di-generate');
        } else {
          AppToast.show(errMsg);
        }
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
    final code = codeC.text.trim();

    if (code.isEmpty) {
      AppToast.show('Kode voucher harus diisi');
      return false;
    }
    if (code.contains(' ')) {
      AppToast.show('Kode voucher tidak boleh mengandung spasi');
      return false;
    }

    isSubmitting.value = true;
    try {
      final res = await VoucherService.updateVoucher(id, {
        'code': code.toUpperCase(),
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
        _refreshPromotionVouchers();
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

    voucherList[idx] = voucher.copyWith(status: newStatus);
    _applyFilter();
    _refreshPromotionVouchers();

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
        voucherList[idx] = voucher;
        _applyFilter();
        _refreshPromotionVouchers();
        AppToast.show(_parseError(res.body));
      }
    } catch (e) {
      voucherList[idx] = voucher;
      _applyFilter();
      _refreshPromotionVouchers();
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

// ===================== FORM FORMATTER (khusus field kode) =====================
// Otomatis mengubah teks yang diketik di codeC menjadi huruf besar, karena
// backend menyimpan kode voucher dalam bentuk uppercase (lihat
// `.toUpperCase()` pada createVoucher()/updateVoucher() di atas).
//
// Pemakaian di UI (VoucherFormPage), pasang di TextField yang controller-nya
// codeC:
//
// TextField(
//   controller: voucherC.codeC,
//   inputFormatters: [
//     FilteringTextInputFormatter.deny(RegExp(r'\s')), // tolak spasi
//     UpperCaseTextFormatter(),                         // auto uppercase
//   ],
//   decoration: InputDecoration(
//     labelText: 'Kode Voucher',
//     suffixIcon: IconButton(
//       icon: const Icon(Icons.refresh),
//       tooltip: 'Generate ulang kode',
//       onPressed: voucherC.regenerateCode,
//     ),
//   ),
// )
class UpperCaseTextFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    return newValue.copyWith(
      text: newValue.text.toUpperCase(),
      selection: newValue.selection,
    );
  }
}
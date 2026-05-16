import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:get/get.dart';
import 'package:senkukoadmin/features/promotions/voucher_model.dart';
import 'package:senkukoadmin/features/promotions/voucher_service.dart';

class VoucherController extends GetxController {
  final isLoading = false.obs;
  final isSubmitting = false.obs;

  final voucherList = <VoucherData>[].obs;
  final searchText = ''.obs;
  final selectedFilter = 'Semua'.obs;

  // optional: filter by promotion (dari promotion detail page)
  final filterByPromotionId = Rxn<String>();

  @override
  void onInit() {
    super.onInit();
    fetchVouchers();
  }

  // ── Filters ───────────────────────────────────────────────────────────────

  List<VoucherData> get filteredVouchers {
    var list = voucherList.toList();

    if (filterByPromotionId.value != null) {
      list = list
          .where((v) => v.promotionId == filterByPromotionId.value)
          .toList();
    }

    switch (selectedFilter.value) {
      case 'Aktif':
        list = list.where((v) => v.isActive && !v.isUsed).toList();
        break;
      case 'Tidak Aktif':
        list = list.where((v) => !v.isActive).toList();
        break;
      case 'Habis':
        list = list.where((v) => v.isUsed).toList();
        break;
    }

    final q = searchText.value.toLowerCase();
    if (q.isNotEmpty) {
      list = list.where((v) => v.code.toLowerCase().contains(q)).toList();
    }

    return list;
  }

  void updateSearch(String value) => searchText.value = value;
  void updateFilter(String value) => selectedFilter.value = value;

  // ── Fetch ─────────────────────────────────────────────────────────────────

  Future<void> fetchVouchers() async {
    isLoading.value = true;
    try {
      final res = await VoucherService.getAllVouchers();
      if (res.statusCode == 200) {
        voucherList.assignAll(voucherListModelFromJson(res.body).data);
      }
    } catch (e) {
      debugPrint('Error fetchVouchers: $e');
      Fluttertoast.showToast(msg: 'Gagal memuat data voucher');
    } finally {
      isLoading.value = false;
    }
  }

  // ── Create / Update / Delete ──────────────────────────────────────────────

  Future<void> createVoucher(Map<String, dynamic> payload) async {
    isSubmitting.value = true;
    try {
      final res = await VoucherService.createVoucher(payload);
      if (res.statusCode == 200 || res.statusCode == 201) {
        Fluttertoast.showToast(msg: 'Voucher berhasil diterbitkan');
        await fetchVouchers();
        Get.back();
      } else {
        Fluttertoast.showToast(msg: _errorMessage(res.body));
      }
    } catch (e) {
      debugPrint('Error createVoucher: $e');
      Fluttertoast.showToast(msg: 'Gagal menerbitkan voucher');
    } finally {
      isSubmitting.value = false;
    }
  }

  Future<void> updateVoucher(String id, Map<String, dynamic> payload) async {
    isSubmitting.value = true;
    try {
      final res = await VoucherService.updateVoucher(id, payload);
      if (res.statusCode == 200) {
        Fluttertoast.showToast(msg: 'Voucher berhasil diperbarui');
        await fetchVouchers();
        Get.back();
      } else {
        Fluttertoast.showToast(msg: _errorMessage(res.body));
      }
    } catch (e) {
      debugPrint('Error updateVoucher: $e');
      Fluttertoast.showToast(msg: 'Gagal memperbarui voucher');
    } finally {
      isSubmitting.value = false;
    }
  }

  Future<void> deleteVoucher(String id) async {
    try {
      final res = await VoucherService.deleteVoucher(id);
      if (res.statusCode == 200) {
        voucherList.removeWhere((v) => v.id == id);
        Fluttertoast.showToast(msg: 'Voucher berhasil dihapus');
        if (Get.currentRoute != '/vouchers') Get.back();
      } else {
        Fluttertoast.showToast(msg: _errorMessage(res.body));
      }
    } catch (e) {
      debugPrint('Error deleteVoucher: $e');
      Fluttertoast.showToast(msg: 'Gagal menghapus voucher');
    }
  }

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
        Fluttertoast.showToast(
          msg: newStatus == 'active'
              ? 'Voucher diaktifkan'
              : 'Voucher dinonaktifkan',
        );
      }
    } catch (e) {
      debugPrint('Error toggleStatus: $e');
      Fluttertoast.showToast(msg: 'Gagal mengubah status voucher');
    }
  }

  void confirmDelete(String id, String code) {
    Get.dialog(
      AlertDialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'Hapus Voucher',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
        content: Text('Yakin ingin menghapus voucher "$code"?'),
        actions: [
          TextButton(onPressed: Get.back, child: const Text('Batal')),
          TextButton(
            onPressed: () {
              Get.back();
              deleteVoucher(id);
            },
            child: const Text('Hapus',
                style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  String _errorMessage(String body) {
    try {
      return jsonDecode(body)['message'] ?? 'Terjadi kesalahan';
    } catch (_) {
      return 'Terjadi kesalahan';
    }
  }
}
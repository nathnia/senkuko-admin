import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:senkukoadmin/constant/api_helper.dart';
import 'package:senkukoadmin/constant/app_dialog.dart';
import 'package:senkukoadmin/constant/app_toast.dart';
import 'package:senkukoadmin/features/customers/customer_model.dart';
import 'package:senkukoadmin/features/customers/customer_service.dart';

class CustomerController extends GetxController {
  // ===================== FORM STATE =====================
  final isDirty = false.obs;
  final nameC = TextEditingController();
  final phoneC = TextEditingController();
  final emailC = TextEditingController();
  final selectedMemberType = MemberType.regular.obs;

  // ===================== LIST STATE =====================
  final isLoading = false.obs;
  final customerList = <CustomerData>[].obs;
  final filteredCustomers =
      <CustomerData>[].obs; // ← cached, bukan computed getter
  final selectedCustomer = Rxn<CustomerData>();
  final searchText = ''.obs;
  final Rxn<CustomerStatus> statusFilter = Rxn(CustomerStatus.active);

  final hasError = false.obs;
  final errorMessage = ''.obs;

  @override
  void onInit() {
    super.onInit();
    fetchCustomers();
  }

  @override
  void onClose() {
    nameC.dispose();
    phoneC.dispose();
    emailC.dispose();
    super.onClose();
  }

  // ===================== FORM HELPERS =====================
  void markDirty() => isDirty.value = true;

  void resetForm() {
    isDirty.value = false;
    nameC.clear();
    phoneC.clear();
    emailC.clear();
    selectedMemberType.value = MemberType.regular;
    selectedCustomer.value = null;
  }

  void populateForm(CustomerData c) {
    nameC.text = c.name;
    phoneC.text = c.phone ?? '';
    emailC.text = c.email ?? '';
    selectedMemberType.value = c.memberType;
  }

  // ===================== FILTER =====================


  void _applyFilter() {
    final lower = searchText.value.toLowerCase();

    filteredCustomers.assignAll(
      customerList.where((c) {
        final matchStatus =
            statusFilter.value == null || c.status == statusFilter.value;

        final matchSearch =
            lower.isEmpty ||
            c.name.toLowerCase().contains(lower) ||
            (c.phone?.toLowerCase().contains(lower) ?? false) ||
            (c.email?.toLowerCase().contains(lower) ?? false);

        return matchStatus && matchSearch;
      }).toList(),
    );
  }

  void updateSearch(String value) {
    searchText.value = value;
    _applyFilter();
  }

  void setStatusFilter(String label) {
    switch (label) {
      case 'Aktif':
        statusFilter.value = CustomerStatus.active;
        break;

      case 'Nonaktif':
        statusFilter.value = CustomerStatus.inactive;
        break;

      default:
        statusFilter.value = null;
        break;
    }

    _applyFilter();
  }

  String get statusFilterLabel {
    switch (statusFilter.value) {
      case CustomerStatus.active:
        return 'Aktif';

      case CustomerStatus.inactive:
        return 'Nonaktif';

      default:
        return 'Semua';
    }
  }

  // ===================== FETCH =====================
  Future<void> fetchCustomers() async {
    if (isLoading.value) return;
    isLoading.value = true;
    hasError.value = false;
    errorMessage.value = '';
    try {
      final res = await CustomerService.getAllCustomers();
      if (res.statusCode == 200) {
        customerList.assignAll(customerModelFromJson(res.body).data);
        _applyFilter();
      } else {
        hasError.value = true;
        errorMessage.value = ApiHelper.isNetworkError(res)
            ? ApiHelper.parseError(res.body)
            : 'Gagal memuat daftar pelanggan.';
      }
    } catch (e) {
      hasError.value = true;
      errorMessage.value = 'Gagal memuat data.';
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> fetchCustomerById(String id) async {
    isLoading.value = true;
    try {
      final res = await CustomerService.getCustomerById(id);
      if (res.statusCode == 200) {
        final json = jsonDecode(res.body);
        selectedCustomer.value = CustomerData.fromJson(json['data']);
      }
    } catch (e) {
      debugPrint('Error fetchCustomerById: $e');
    } finally {
      isLoading.value = false;
    }
  }

  // ===================== TOGGLE STATUS =====================
  Future<bool> toggleCustomerStatus(CustomerData customer) async {
    final newStatus = customer.isActive
        ? CustomerStatus.inactive
        : CustomerStatus.active;
    final label = newStatus == CustomerStatus.inactive
        ? 'nonaktifkan'
        : 'aktifkan';

    final confirmed = await AppDialog.confirm(
      title:
          '${newStatus == CustomerStatus.active ? 'Aktifkan' : 'Nonaktifkan'} Pelanggan',
      content: 'Yakin ingin $label "${customer.name}"?',
      confirmLabel: newStatus == CustomerStatus.active
          ? 'Aktifkan'
          : 'Nonaktifkan',
      confirmColor: newStatus == CustomerStatus.active
          ? Colors.green
          : Colors.orange,
    );

    if (!confirmed) return false;

    isLoading.value = true;
    try {
      final res = await CustomerService.updateCustomerStatus(
        customer.id,
        newStatus.name,
      );
      if (res.statusCode == 200) {
        final updated = CustomerData.fromJson(jsonDecode(res.body)['data']);
        final idx = customerList.indexWhere((c) => c.id == customer.id);
        if (idx != -1) {
          customerList[idx] = updated;
        }
        // Re-apply filter agar hasil list langsung sinkron
        _applyFilter();
        AppToast.show(
          newStatus == CustomerStatus.active
              ? 'Pelanggan diaktifkan'
              : 'Pelanggan dinonaktifkan',
        );
        return true;
      }
      AppToast.show('Gagal mengubah status');
      return false;
    } catch (e) {
      debugPrint('Error toggleStatus: $e');
      AppToast.show('Terjadi kesalahan');
      return false;
    } finally {
      isLoading.value = false;
    }
  }
}

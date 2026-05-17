import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
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
  final selectedCustomer = Rxn<CustomerData>();
  final searchText = ''.obs;

  // null = semua, active = aktif, inactive = nonaktif
  final Rxn<CustomerStatus> statusFilter = Rxn(CustomerStatus.active);

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
  List<CustomerData> get filteredCustomers {
    var list = customerList.toList();

    if (statusFilter.value != null) {
      list = list.where((c) => c.status == statusFilter.value).toList();
    }

    if (searchText.value.isNotEmpty) {
      final lower = searchText.value.toLowerCase();
      list = list.where((c) {
        return c.name.toLowerCase().contains(lower) ||
            (c.phone?.toLowerCase().contains(lower) ?? false) ||
            (c.email?.toLowerCase().contains(lower) ?? false);
      }).toList();
    }

    return list;
  }

  void updateSearch(String value) => searchText.value = value;

  void setStatusFilter(String label) {
    switch (label) {
      case 'Aktif':
        statusFilter.value = CustomerStatus.active;
        break;
      case 'Nonaktif':
        statusFilter.value = CustomerStatus.inactive;
        break;
      default: // 'Semua'
        statusFilter.value = null;
    }
  }

  // label untuk chip agar UI tahu mana yang aktif
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
    isLoading.value = true;
    try {
      final res = await CustomerService.getAllCustomers();
      if (res.statusCode == 200) {
        customerList.assignAll(customerModelFromJson(res.body).data);
      }
    } catch (e) {
      AppToast.error('Gagal memuat data pelanggan');
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
      // .name → convert enum ke string ('active'/'inactive') untuk dikirim ke API
      final res = await CustomerService.updateCustomerStatus(
        customer.id,
        newStatus.name,
      );
      if (res.statusCode == 200) {
        final idx = customerList.indexWhere((c) => c.id == customer.id);
        if (idx != -1) {
          final updated = CustomerData.fromJson(jsonDecode(res.body)['data']);
          customerList[idx] = updated;
          customerList.refresh();
        }
        AppToast.success(
          newStatus == CustomerStatus.active
              ? 'Pelanggan diaktifkan'
              : 'Pelanggan dinonaktifkan',
        );
        return true;
      }
      AppToast.error('Gagal mengubah status');
      return false;
    } catch (e) {
      debugPrint('Error toggleStatus: $e');
      AppToast.error('Terjadi kesalahan');
      return false;
    } finally {
      isLoading.value = false;
    }
  }
}

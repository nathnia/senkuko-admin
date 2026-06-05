import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:senkukoadmin/constant/api_helper.dart';
import 'package:senkukoadmin/constant/app_dialog.dart';
import 'package:senkukoadmin/constant/app_toast.dart';
import 'package:senkukoadmin/features/customers/customer_model.dart';
import 'package:senkukoadmin/features/customers/customer_service.dart';

class CustomerController extends GetxController {
  // ===================== EDIT FORM STATE =====================
  final isDirty = false.obs;
  final nameC = TextEditingController();
  final phoneC = TextEditingController();
  final emailC = TextEditingController();
  final selectedMemberType = MemberType.regular.obs;

  // ===================== ADD FORM STATE =====================
  final addIsDirty = false.obs;
  final isSubmitting = false.obs;
  final addNameC = TextEditingController();
  final addCodeC = TextEditingController();
  final addPhoneC = TextEditingController();
  final addEmailC = TextEditingController();
  final addAddressC = TextEditingController();
  final addCityC = TextEditingController();
  final addRegionC = TextEditingController();
  final addSubregionC = TextEditingController();
  final addCustomerGroup = CustomerGroup.general.obs;

  // ===================== LIST STATE =====================
  final isLoading = false.obs;
  final customerList = <CustomerData>[].obs;
  final filteredCustomers = <CustomerData>[].obs;
  final selectedCustomer = Rxn<CustomerData>();
  final searchText = ''.obs;
  final Rxn<CustomerStatus> statusFilter = Rxn(CustomerStatus.active);
  final Rxn<CustomerGroup> groupFilter = Rxn(null);

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
    addNameC.removeListener(_checkAddDirty);
    addCodeC.removeListener(_checkAddDirty);
    addPhoneC.removeListener(_checkAddDirty);
    addNameC.dispose();
    addCodeC.dispose();
    addPhoneC.dispose();
    addEmailC.dispose();
    addAddressC.dispose();
    addCityC.dispose();
    addRegionC.dispose();
    addSubregionC.dispose();
    super.onClose();
  }

  // ===================== EDIT FORM HELPERS =====================
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

  // ===================== ADD FORM HELPERS =====================

  void _checkAddDirty() {
    addIsDirty.value =
        addNameC.text.trim().isNotEmpty &&
        addCodeC.text.trim().isNotEmpty &&
        addPhoneC.text.trim().isNotEmpty;
  }

  void resetAddForm() {
    addIsDirty.value = false;
    addNameC.clear();
    addCodeC.clear();
    addPhoneC.clear();
    addEmailC.clear();
    addAddressC.clear();
    addCityC.clear();
    addRegionC.clear();
    addSubregionC.clear();
    addCustomerGroup.value = CustomerGroup.general;

    // re-wire listeners (safe to call multiple times)
    addNameC.removeListener(_checkAddDirty);
    addCodeC.removeListener(_checkAddDirty);
    addPhoneC.removeListener(_checkAddDirty);
    addNameC.addListener(_checkAddDirty);
    addCodeC.addListener(_checkAddDirty);
    addPhoneC.addListener(_checkAddDirty);
  }

  // ===================== FILTER =====================
  void _applyFilter() {
    final lower = searchText.value.toLowerCase();
    filteredCustomers.assignAll(
      customerList.where((c) {
        final matchStatus =
            statusFilter.value == null || c.status == statusFilter.value;
        final matchGroup =
            groupFilter.value == null || c.customerGroup == groupFilter.value;
        final matchSearch =
            lower.isEmpty ||
            c.name.toLowerCase().contains(lower) ||
            (c.phone?.toLowerCase().contains(lower) ?? false) ||
            (c.email?.toLowerCase().contains(lower) ?? false) ||
            c.code.toLowerCase().contains(lower);
        return matchStatus && matchGroup && matchSearch;
      }).toList(),
    );
  }

  void updateSearch(String value) {
    searchText.value = value;
    _applyFilter();
  }

  void setCombinedFilter(String label) {
    switch (label) {
      case 'Aktif':
        statusFilter.value = CustomerStatus.active;
        groupFilter.value = null;
        break;
      case 'Nonaktif':
        statusFilter.value = CustomerStatus.inactive;
        groupFilter.value = null;
        break;
      case 'Eceran':
        statusFilter.value = null;
        groupFilter.value = CustomerGroup.general;
        break;
      case 'Grosir':
        statusFilter.value = null;
        groupFilter.value = CustomerGroup.grosir;
        break;
      default:
        statusFilter.value = null;
        groupFilter.value = null;
        break;
    }
    _applyFilter();
  }

  String get combinedFilterLabel {
    if (statusFilter.value == CustomerStatus.active) return 'Aktif';
    if (statusFilter.value == CustomerStatus.inactive) return 'Nonaktif';
    if (groupFilter.value == CustomerGroup.general) return 'Eceran';
    if (groupFilter.value == CustomerGroup.grosir) return 'Grosir';
    return 'Semua';
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

  // ===================== CREATE CUSTOMER =====================
  Future<bool> createCustomer() async {
    if (addNameC.text.trim().isEmpty) {
      AppToast.show('Nama pelanggan wajib diisi');
      return false;
    }
    if (addCodeC.text.trim().isEmpty) {
      AppToast.show('Kode pelanggan wajib diisi');
      return false;
    }
    if (addPhoneC.text.trim().isEmpty) {
      AppToast.show('Nomor telepon wajib diisi');
      return false;
    }

    isSubmitting.value = true;
    try {
      final body = <String, dynamic>{
        'name': addNameC.text.trim(),
        'code': addCodeC.text.trim(),
        'phone': addPhoneC.text.trim(),
        'customer_group': addCustomerGroup.value.apiValue,
        if (addEmailC.text.trim().isNotEmpty) 'email': addEmailC.text.trim(),
        if (addAddressC.text.trim().isNotEmpty)
          'address': addAddressC.text.trim(),
        if (addCityC.text.trim().isNotEmpty) 'city': addCityC.text.trim(),
        if (addRegionC.text.trim().isNotEmpty) 'region': addRegionC.text.trim(),
        if (addSubregionC.text.trim().isNotEmpty)
          'subregion': addSubregionC.text.trim(),
      };

      final res = await CustomerService.createCustomer(body);

      if (res.statusCode == 201) {
        final newCustomer = CustomerData.fromJson(
          jsonDecode(res.body)['data'],
        );
        customerList.insert(0, newCustomer);
        _applyFilter();
        AppToast.show('Pelanggan berhasil ditambahkan');
        resetAddForm();
        return true;
      } else {
        debugPrint('createCustomer failed — status: ${res.statusCode}, body: ${res.body}');
        AppToast.show(ApiHelper.parseError(res.body, 'Gagal menambahkan pelanggan'));
        return false;
      }
    } catch (e) {
      debugPrint('Error createCustomer: $e');
      AppToast.show('Terjadi kesalahan');
      return false;
    } finally {
      isSubmitting.value = false;
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
      confirmLabel:
          newStatus == CustomerStatus.active ? 'Aktifkan' : 'Nonaktifkan',
      confirmColor:
          newStatus == CustomerStatus.active ? Colors.green : Colors.orange,
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
        if (idx != -1) customerList[idx] = updated;
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
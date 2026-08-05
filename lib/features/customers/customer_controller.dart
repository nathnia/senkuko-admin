import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:senkukoadmin/constant/api_helper.dart';
import 'package:senkukoadmin/constant/app_dialog.dart';
import 'package:senkukoadmin/constant/app_toast.dart';
import 'package:senkukoadmin/features/customers/customer_model.dart';
import 'package:senkukoadmin/features/customers/customer_service.dart';

class CustomerController extends GetxController {
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

  // ===================== FORM STATE =====================
  final isSubmitting = false.obs;
  final isDirty = false.obs;
  final nameC = TextEditingController();
  final codeC = TextEditingController();
  final phoneC = TextEditingController();
  final emailC = TextEditingController();
  final addressC = TextEditingController();
  final cityC = TextEditingController();
  final regionC = TextEditingController();
  final subregionC = TextEditingController();
  final customerGroup = CustomerGroup.general.obs;

  // Snapshot untuk edit dirty tracking
  String _snapName = '';
  String _snapCode = '';
  String _snapPhone = '';
  String _snapEmail = '';
  String _snapAddress = '';
  String _snapCity = '';
  String _snapRegion = '';
  String _snapSubregion = '';
  CustomerGroup _snapGroup = CustomerGroup.general;

  List<TextEditingController> get _formControllers => [
    nameC,
    codeC,
    phoneC,
    emailC,
    addressC,
    cityC,
    regionC,
    subregionC,
  ];

  // ===================== LIFECYCLE =====================
  bool _hasLoadedOnce = false;

  @override
  void onInit() {
    super.onInit();
    if (!_hasLoadedOnce) {
      fetchCustomers();
      _hasLoadedOnce = true;
    }
  }

  Future<void> refreshCustomers() => fetchCustomers();

  @override
  void onClose() {
    for (final c in _formControllers) {
      c.dispose();
    }
    super.onClose();
  }

  // ===================== STALENESS (TTL) =====================
  // Customer bisa berubah dari transaksi baru (total_spend) atau admin
  // lain nambah/edit — TTL sedikit lebih ketat dari Banner, tapi tetap
  // lebih longgar dari Voucher karena bukan data yang dipakai realtime
  // pas checkout.
  DateTime? _lastFetchedAt;
  static const _staleAfter = Duration(seconds: 30);

  bool get _isStale =>
      _lastFetchedAt == null ||
      DateTime.now().difference(_lastFetchedAt!) > _staleAfter;

  /// Panggil dari CustomerPage.initState() — GANTIKAN fetchCustomers()
  /// langsung. Controller sudah permanent (CoreBinding), jadi data yang
  /// masih fresh gak perlu di-fetch ulang tiap kali halaman dibuka.
  void refreshIfStale() {
    if (_isStale) fetchCustomers();
  }

  // ===================== GENERATE KODE =====================
  String _generateCustomerCode() {
    const chars = '0123456789';
    final rng = Random.secure();
    final suffix = List.generate(
      9,
      (_) => chars[rng.nextInt(chars.length)],
    ).join();
    return '0$suffix';
  }

  void regenerateCode() {
    codeC.text = _generateCustomerCode();
    _checkAddDirty();
  }

  // ===================== FORM HELPERS =====================
  void _removeListeners(VoidCallback fn) {
    for (final c in _formControllers) {
      c.removeListener(fn);
    }
  }

  void _addListeners(VoidCallback fn) {
    for (final c in _formControllers) {
      c.addListener(fn);
    }
  }

  void _checkAddDirty() {
    isDirty.value =
        nameC.text.trim().isNotEmpty &&
        codeC.text.trim().isNotEmpty &&
        phoneC.text.trim().isNotEmpty &&
        addressC.text.trim().isNotEmpty &&
        cityC.text.trim().isNotEmpty &&
        regionC.text.trim().isNotEmpty;
  }

  void _checkEditDirty() {
    isDirty.value =
        nameC.text.trim() != _snapName ||
        codeC.text.trim() != _snapCode ||
        phoneC.text.trim() != _snapPhone ||
        emailC.text.trim() != _snapEmail ||
        addressC.text.trim() != _snapAddress ||
        cityC.text.trim() != _snapCity ||
        regionC.text.trim() != _snapRegion ||
        subregionC.text.trim() != _snapSubregion ||
        customerGroup.value != _snapGroup;
  }

  void onGroupChanged(CustomerGroup val) {
    customerGroup.value = val;
    _checkEditDirty();
  }

  void resetForAdd() {
    _removeListeners(_checkAddDirty);
    _removeListeners(_checkEditDirty);
    for (final c in _formControllers) {
      c.clear();
    }
    customerGroup.value = CustomerGroup.general;
    isDirty.value = false;
    isSubmitting.value = false;

    codeC.text = _generateCustomerCode();

    _addListeners(_checkAddDirty);
  }

  void resetForEdit() {
    _removeListeners(_checkAddDirty);
    _removeListeners(_checkEditDirty);
    for (final c in _formControllers) {
      c.clear();
    }
    customerGroup.value = CustomerGroup.general;
    isDirty.value = false;
    isSubmitting.value = false;
  }

  void populateEditForm(CustomerData c) {
    _snapName = c.name;
    _snapCode = c.code;
    _snapPhone = c.phone ?? '';
    _snapEmail = c.email ?? '';
    _snapAddress = c.address ?? '';
    _snapCity = c.city ?? '';
    _snapRegion = c.region ?? '';
    _snapSubregion = c.subregion ?? '';
    _snapGroup = c.customerGroup;

    nameC.text = _snapName;
    codeC.text = _snapCode;
    phoneC.text = _snapPhone;
    emailC.text = _snapEmail;
    addressC.text = _snapAddress;
    cityC.text = _snapCity;
    regionC.text = _snapRegion;
    subregionC.text = _snapSubregion;
    customerGroup.value = _snapGroup;
    isDirty.value = false;

    _addListeners(_checkEditDirty);
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

  /// Reset search & filter ke kondisi default ("Aktif") — dipanggil dari
  /// CustomerPage.initState(). Controller bersifat permanent, jadi tanpa
  /// ini searchText/statusFilter/groupFilter bertahan dari kunjungan
  /// sebelumnya, sementara AppSearchBar (StatefulWidget baru tiap buka
  /// halaman) keliatan kosong — bikin search text/filter terkesan
  /// "nyangkut" padahal sebenarnya cuma gak sinkron sama tampilan.
  void resetFilters() {
    searchText.value = '';
    statusFilter.value = CustomerStatus.active;
    groupFilter.value = null;
    _applyFilter();
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
        _lastFetchedAt = DateTime.now();
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
    } catch (_) {
    } finally {
      isLoading.value = false;
    }
  }

  // ===================== CREATE =====================
  Future<bool> createCustomer() async {
    if (!_validateForm()) return false;

    isSubmitting.value = true;
    try {
      final body = <String, dynamic>{
        'name': nameC.text.trim(),
        'code': codeC.text.trim(),
        'phone': phoneC.text.trim(),
        'customer_group': customerGroup.value.apiValue,
        if (emailC.text.trim().isNotEmpty) 'email': emailC.text.trim(),
        if (addressC.text.trim().isNotEmpty) 'address': addressC.text.trim(),
        if (cityC.text.trim().isNotEmpty) 'city': cityC.text.trim(),
        if (regionC.text.trim().isNotEmpty) 'region': regionC.text.trim(),
        if (subregionC.text.trim().isNotEmpty)
          'subregion': subregionC.text.trim(),
      };

      final res = await CustomerService.createCustomer(body);

      if (res.statusCode == 201) {
        final newCustomer = CustomerData.fromJson(jsonDecode(res.body)['data']);
        customerList.insert(0, newCustomer);
        _applyFilter();
        AppToast.show('Pelanggan berhasil ditambahkan');
        resetForAdd();
        return true;
      } else {
        final errMsg = ApiHelper.parseError(res.body, '');
        final isDuplicateCode =
            errMsg.toLowerCase().contains('code') ||
            errMsg.toLowerCase().contains('kode') ||
            res.statusCode == 409;

        if (isDuplicateCode) {
          codeC.text = _generateCustomerCode();
          AppToast.show('Kode sudah dipakai, kode baru sudah di-generate');
        } else {
          AppToast.show(
            ApiHelper.parseError(res.body, 'Gagal menambahkan pelanggan'),
          );
        }
        return false;
      }
    } catch (e) {
      AppToast.show('Terjadi kesalahan');
      return false;
    } finally {
      isSubmitting.value = false;
    }
  }

  // ===================== UPDATE =====================
  Future<bool> updateCustomer(String id) async {
    if (!_validateForm()) return false;

    isSubmitting.value = true;
    try {
      final body = <String, dynamic>{
        'name': nameC.text.trim(),
        'code': codeC.text.trim(),
        'phone': phoneC.text.trim(),
        'customer_group': customerGroup.value.apiValue,
        'email': emailC.text.trim(),
        'address': addressC.text.trim(),
        'city': cityC.text.trim(),
        'region': regionC.text.trim(),
        'subregion': subregionC.text.trim(),
      };

      final res = await CustomerService.updateCustomer(id, body);

      if (res.statusCode == 200) {
        final updated = CustomerData.fromJson(jsonDecode(res.body)['data']);
        final idx = customerList.indexWhere((c) => c.id == id);
        if (idx != -1) customerList[idx] = updated;
        _applyFilter();
        AppToast.show('Pelanggan berhasil diperbarui');
        return true;
      } else {
        AppToast.show(
          ApiHelper.parseError(res.body, 'Gagal memperbarui pelanggan'),
        );
        return false;
      }
    } catch (e) {
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
      AppToast.show('Terjadi kesalahan');
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  // ===================== VALIDATION =====================
  bool _validateForm() {
    if (nameC.text.trim().isEmpty) {
      AppToast.show('Nama pelanggan wajib diisi');
      return false;
    }
    if (codeC.text.trim().isEmpty) {
      AppToast.show('Kode pelanggan wajib diisi');
      return false;
    }
    if (phoneC.text.trim().isEmpty) {
      AppToast.show('Nomor telepon wajib diisi');
      return false;
    }
    if (addressC.text.trim().isEmpty) {
      AppToast.show('Alamat wajib diisi');
      return false;
    }
    if (cityC.text.trim().isEmpty) {
      AppToast.show('Kota wajib diisi');
      return false;
    }
    if (regionC.text.trim().isEmpty) {
      AppToast.show('Provinsi wajib diisi');
      return false;
    }
    return true;
  }
}
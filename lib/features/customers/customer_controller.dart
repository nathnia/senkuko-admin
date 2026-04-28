import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:senkukoadmin/features/customers/customer_model.dart';
import 'package:senkukoadmin/features/customers/customer_service.dart';

class CustomerController extends GetxController {
  // ===================== FORM STATE =====================
  final isDirty = false.obs;
  final nameC = TextEditingController();
  final phoneC = TextEditingController();
  final emailC = TextEditingController();
  final selectedMemberType = 'regular'.obs;

  @override
  void onClose() {
    nameC.dispose();
    phoneC.dispose();
    emailC.dispose();
    super.onClose();
  }

  void markDirty() => isDirty.value = true;

  void resetForm() {
    isDirty.value = false;
    nameC.clear();
    phoneC.clear();
    emailC.clear();
    selectedMemberType.value = 'regular';
    selectedCustomer.value = null;
  }

  void populateForm(CustomerData c) {
    nameC.text = c.name;
    phoneC.text = c.phone ?? '';
    emailC.text = c.email ?? '';
    selectedMemberType.value = c.memberType;
  }

  final isLoading = false.obs;
  final customerList = <CustomerData>[].obs;
  final selectedCustomer = Rxn<CustomerData>();
  final searchText = ''.obs;

  // ===================== LIFECYCLE =====================
  @override
  void onInit() {
    super.onInit();
    fetchCustomers();
  }

  // ===================== FILTER =====================
  List<CustomerData> get filteredCustomers {
    if (searchText.value.isEmpty) return customerList;
    final lower = searchText.value.toLowerCase();
    return customerList.where((c) {
      return c.name.toLowerCase().contains(lower) ||
          (c.phone?.toLowerCase().contains(lower) ?? false) ||
          (c.email?.toLowerCase().contains(lower) ?? false);
    }).toList();
  }

  void updateSearch(String value) => searchText.value = value;

  // ===================== FETCH =====================
  Future<void> fetchCustomers() async {
    isLoading.value = true;
    try {
      final res = await CustomerService.getAllCustomers();
      if (res.statusCode == 200) {
        customerList.assignAll(customerModelFromJson(res.body).data);
      }
    } catch (e) {
      debugPrint('Error fetchCustomers: $e');
      Get.snackbar('Error', 'Gagal memuat data pelanggan');
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

  // ===================== CREATE =====================
  Future<bool> createCustomer({
    required String name,
    String? phone,
    String? email,
    required String memberType,
  }) async {
    isLoading.value = true;
    try {
      final res = await CustomerService.createCustomer(
        name: name,
        phone: phone,
        email: email,
        memberType: memberType,
      );
      if (res.statusCode == 201) {
        await fetchCustomers();
        Get.snackbar(
          'Sukses',
          'Pelanggan berhasil ditambahkan',
          backgroundColor: Colors.green,
          colorText: Colors.white,
        );
        return true;
      }
      Get.snackbar('Gagal', 'Gagal menambahkan pelanggan');
      return false;
    } catch (e) {
      debugPrint('Error createCustomer: $e');
      Get.snackbar('Error', 'Terjadi kesalahan');
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  // ===================== UPDATE =====================
  Future<bool> updateCustomer({
    required String id,
    required String name,
    String? phone,
    String? email,
    required String memberType,
  }) async {
    isLoading.value = true;
    try {
      final res = await CustomerService.updateCustomer(
        id: id,
        name: name,
        phone: phone,
        email: email,
        memberType: memberType,
      );
      if (res.statusCode == 200) {
        await fetchCustomers();
        Get.snackbar(
          'Sukses',
          'Pelanggan berhasil diupdate',
          backgroundColor: Colors.green,
          colorText: Colors.white,
        );
        return true;
      }
      Get.snackbar('Gagal', 'Gagal mengupdate pelanggan');
      return false;
    } catch (e) {
      debugPrint('Error updateCustomer: $e');
      Get.snackbar('Error', 'Terjadi kesalahan');
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  // ===================== DELETE =====================
  Future<bool> deleteCustomer(String id, String name) async {
    final confirmed =
        await Get.dialog<bool>(
          AlertDialog(
            title: const Text('Hapus Pelanggan'),
            content: Text('Yakin ingin menghapus "$name"?'),
            actions: [
              TextButton(
                onPressed: () => Get.back(result: false),
                child: const Text('Batal'),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                onPressed: () => Get.back(result: true),
                child: const Text(
                  'Hapus',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ],
          ),
          barrierDismissible: false,
        ) ??
        false;

    if (!confirmed) return false;

    isLoading.value = true;
    try {
      final res = await CustomerService.deleteCustomer(id);
      if (res.statusCode == 200) {
        customerList.removeWhere((c) => c.id == id);
        Get.snackbar(
          'Sukses',
          'Pelanggan berhasil dihapus',
          backgroundColor: Colors.green,
          colorText: Colors.white,
        );
        return true;
      }
      Get.snackbar('Gagal', 'Gagal menghapus pelanggan');
      return false;
    } catch (e) {
      debugPrint('Error deleteCustomer: $e');
      Get.snackbar('Error', 'Terjadi kesalahan');
      return false;
    } finally {
      isLoading.value = false;
    }
  }
}

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:senkukoadmin/features/transactions/transaction_model.dart';
import 'package:senkukoadmin/features/transactions/transaction_service.dart';

class TransactionController extends GetxController {
  final isLoading = false.obs;
  final isLoadingDetail = false.obs;
  final transactionList = <TransactionData>[].obs;
  final selectedTransaction = Rxn<Map<String, dynamic>>();
  final searchText = ''.obs;
  final selectedFilter = 'Semua'.obs;

  final List<String> filters = ['Semua', 'Tunai', 'Transfer', 'QRIS'];

  @override
  void onInit() {
    super.onInit();
    fetchTransactions();
  }

  // ===================== FILTER =====================
  List<TransactionData> get filteredTransactions {
    return transactionList.where((t) {
      final matchSearch =
          t.invoiceNumber.toLowerCase().contains(searchText.value.toLowerCase()) ||
          (t.customerName?.toLowerCase().contains(searchText.value.toLowerCase()) ?? false);

      final matchFilter = selectedFilter.value == 'Semua' ||
          (selectedFilter.value == 'Tunai' && t.paymentMethod == 'cash') ||
          (selectedFilter.value == 'Transfer' && t.paymentMethod == 'transfer') ||
          (selectedFilter.value == 'QRIS' && t.paymentMethod == 'qris');

      return matchSearch && matchFilter;
    }).toList();
  }

  void updateSearch(String value) => searchText.value = value;
  void updateFilter(String value) => selectedFilter.value = value;

  // ===================== FETCH =====================
  Future<void> fetchTransactions() async {
    isLoading.value = true;
    try {
      final res = await TransactionService.getAllTransactions();
      if (res.statusCode == 200) {
        transactionList.assignAll(transactionModelFromJson(res.body).data);
      }
    } catch (e) {
      debugPrint('Error fetchTransactions: $e');
      Get.snackbar('Error', 'Gagal memuat data transaksi');
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> fetchTransactionById(String id) async {
    isLoadingDetail.value = true;
    selectedTransaction.value = null;
    try {
      final res = await TransactionService.getTransactionById(id);
      if (res.statusCode == 200) {
        final jsonData = json.decode(res.body);
        selectedTransaction.value = jsonData['data'];
      }
    } catch (e) {
      debugPrint('Error fetchTransactionById: $e');
      Get.snackbar('Error', 'Gagal memuat detail transaksi');
    } finally {
      isLoadingDetail.value = false;
    }
  }

  // ===================== SUMMARY =====================
  double get totalRevenue {
    return transactionList.fold(
      0,
      (sum, t) => sum + (double.tryParse(t.grandTotal) ?? 0),
    );
  }

  String get formattedTotalRevenue {
    return 'Rp ${totalRevenue.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.')}';
  }
}
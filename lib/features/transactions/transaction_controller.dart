import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:senkukoadmin/constant/app_colors.dart';
import 'package:senkukoadmin/constant/app_toast.dart';
import 'package:senkukoadmin/constant/currency_formatter.dart';
import 'package:senkukoadmin/features/transactions/transaction_model.dart';
import 'package:senkukoadmin/features/transactions/transaction_service.dart';

class TransactionController extends GetxController {
  final isLoading = false.obs;
  final isLoadingDetail = false.obs;
  final transactionList = <TransactionData>[].obs;
  final selectedTransaction = Rxn<Map<String, dynamic>>();

  final searchText = ''.obs;
  final selectedDateRange = Rxn<DateTimeRange>();
  final selectedQuickDate = 'Hari Ini'.obs;

  final List<String> quickDateFilters = [
    'Hari Ini',
    '7 Hari',
    '30 Hari',
    'Semua',
    'Custom',
  ];

  @override
  void onInit() {
    super.onInit();
    fetchTransactions();
  }

  // ===================== FILTER =====================
  List<TransactionData> get filteredTransactions {
    final now = DateTime.now();

    return transactionList.where((t) {
      final matchSearch =
          t.invoiceNumber.toLowerCase().contains(
            searchText.value.toLowerCase(),
          ) ||
          (t.customerName?.toLowerCase().contains(
                searchText.value.toLowerCase(),
              ) ??
              false);

      bool matchDate = true;

      if (selectedQuickDate.value == 'Hari Ini') {
        matchDate =
            t.transactedAt.year == now.year &&
            t.transactedAt.month == now.month &&
            t.transactedAt.day == now.day;
      } else if (selectedQuickDate.value == '7 Hari') {
        matchDate = t.transactedAt.isAfter(
          now.subtract(const Duration(days: 7)),
        );
      } else if (selectedQuickDate.value == '30 Hari') {
        matchDate = t.transactedAt.isAfter(
          now.subtract(const Duration(days: 30)),
        );
      } else if (selectedQuickDate.value == 'Custom') {
        final range = selectedDateRange.value;
        if (range != null) {
          final end = DateTime(
            range.end.year,
            range.end.month,
            range.end.day,
            23,
            59,
            59,
          );
          matchDate =
              t.transactedAt.isAfter(range.start) &&
              t.transactedAt.isBefore(end);
        }
      }
      return matchSearch && matchDate;
    }).toList();
  }

  void updateSearch(String value) => searchText.value = value;

  void updateQuickDate(String value) {
    selectedQuickDate.value = value;
    if (value != 'Custom') {
      selectedDateRange.value = null;
    }
  }

  Future<void> pickDateRange(BuildContext context) async {
    final now = DateTime.now();
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: now,
      initialDateRange:
          selectedDateRange.value ??
          DateTimeRange(start: now.subtract(const Duration(days: 7)), end: now),
      builder: (context, child) => Theme(
        data: ThemeData(
          colorScheme: ColorScheme.light(
            primary: AppColors.primary,
            onPrimary: Colors.white,
            primaryContainer: AppColors.primary.withAlpha(40),
            onPrimaryContainer: AppColors.primary,
            surface: AppColors.background,
            onSurface: const Color.fromARGB(255, 26, 46, 28),
          ),
          textButtonTheme: TextButtonThemeData(
            style: TextButton.styleFrom(foregroundColor: AppColors.primary),
          ),
          dialogTheme: DialogThemeData(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
        ),
        child: child!,
      ),
    );

    if (picked != null) {
      selectedDateRange.value = picked;
      selectedQuickDate.value = 'Custom';
    }
  }

  // ===================== FETCH =====================

  Future<void> fetchTransactions() async {
    isLoading.value = true;
    try {
      final res = await TransactionService.getAllTransactions();
      if (res.statusCode == 200) {
        transactionList.assignAll(transactionModelFromJson(res.body).data);
      }
    } catch (e) {
      AppToast.error('Gagal memuat data transaksi');
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
        selectedTransaction.value = json.decode(res.body)['data'];
      }
    } catch (e) {
      AppToast.error('Gagal memuat detail transaksi');
    } finally {
      isLoadingDetail.value = false;
    }
  }

  // ===================== SUMMARY =====================

  // grandTotal sudah double — tidak perlu tryParse lagi
  double get totalRevenue =>
      filteredTransactions.fold(0, (sum, t) => sum + t.grandTotal);

  String get formattedTotalRevenue => CurrencyFormatter.format(totalRevenue);
}

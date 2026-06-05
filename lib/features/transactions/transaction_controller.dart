import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:senkukoadmin/constant/api_helper.dart';
import 'package:senkukoadmin/constant/app_colors.dart';
import 'package:senkukoadmin/constant/currency_formatter.dart';
import 'package:senkukoadmin/features/transactions/transaction_model.dart';
import 'package:senkukoadmin/features/transactions/transaction_service.dart';

class TransactionController extends GetxController {
  final isLoading = false.obs;
  final isLoadingDetail = false.obs;
  final isUpdatingStatus = false.obs;
  final transactionList = <TransactionData>[].obs;
  final filteredTransactions = <TransactionData>[].obs;
  final selectedTransaction = Rxn<TransactionDetail>();

  final searchText = ''.obs;
  final selectedDateRange = Rxn<DateTimeRange>();
  final selectedQuickDate = 'Hari Ini'.obs;

  final hasError = false.obs;
  final errorMessage = ''.obs;
  final hasDetailError = false.obs;
  final detailErrorMessage = ''.obs;

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

  void _applyFilter() {
    final now = DateTime.now();
    final query = searchText.value.toLowerCase();
    final quickDate = selectedQuickDate.value;
    final range = selectedDateRange.value;

    filteredTransactions.assignAll(
      transactionList.where((t) {
        final matchSearch =
            t.invoiceNumber.toLowerCase().contains(query) ||
            (t.customerName?.toLowerCase().contains(query) ?? false);

        bool matchDate = true;

        if (quickDate == 'Hari Ini') {
          matchDate =
              t.transactedAt.year == now.year &&
              t.transactedAt.month == now.month &&
              t.transactedAt.day == now.day;
        } else if (quickDate == '7 Hari') {
          final from = DateTime(now.year, now.month, now.day)
              .subtract(const Duration(days: 6));
          matchDate = !t.transactedAt.isBefore(from);
        } else if (quickDate == '30 Hari') {
          final from = DateTime(now.year, now.month, now.day)
              .subtract(const Duration(days: 29));
          matchDate = !t.transactedAt.isBefore(from);
        } else if (quickDate == 'Custom') {
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
                !t.transactedAt.isBefore(range.start) &&
                t.transactedAt.isBefore(end);
          }
        }

        return matchSearch && matchDate;
      }).toList(),
    );
  }

  void updateSearch(String value) {
    searchText.value = value;
    _applyFilter();
  }

  void updateQuickDate(String value) {
    selectedQuickDate.value = value;
    if (value != 'Custom') selectedDateRange.value = null;
    _applyFilter();
  }

  // Theme logic dipindahkan keluar dari controller ke transaction_page.dart.
  // Controller hanya return DateTimeRange, widget yang apply theme-nya.
  Future<void> pickDateRange(BuildContext context) async {
    final now = DateTime.now();
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: now,
      initialDateRange:
          selectedDateRange.value ??
          DateTimeRange(
            start: now.subtract(const Duration(days: 7)),
            end: now,
          ),
      builder: (context, child) {
        // Theme ditaruh di sini karena showDateRangePicker memang butuh
        // ThemeData via builder — ini bukan "logic", ini presentasi dialog
        // yang harus tinggal bersama pemanggilnya.
        return Theme(
          data: ThemeData(
            colorScheme: ColorScheme.light(
              primary: AppColors.primary,
              onPrimary: Colors.white,
              primaryContainer: AppColors.primary.withAlpha(40),
              onPrimaryContainer: AppColors.primary,
              surface: AppColors.background,
              onSurface: const Color(0xFF1A1A2E),
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
        );
      },
    );

    if (picked != null) {
      selectedDateRange.value = picked;
      selectedQuickDate.value = 'Custom';
      _applyFilter();
    }
  }

  // ===================== FETCH =====================

  Future<void> fetchTransactions() async {
    if (isLoading.value) return;
    isLoading.value = true;
    hasError.value = false;
    errorMessage.value = '';
    try {
      final res = await TransactionService.getAllTransactions();
      if (res.statusCode == 200) {
        transactionList.assignAll(transactionModelFromJson(res.body).data);
        _applyFilter();
      } else {
        hasError.value = true;
        errorMessage.value = ApiHelper.isNetworkError(res)
            ? ApiHelper.parseError(res.body)
            : 'Gagal memuat daftar transaksi.';
      }
    } catch (e) {
      hasError.value = true;
      errorMessage.value = 'Gagal memuat data.';
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> fetchTransactionById(String id) async {
    isLoadingDetail.value = true;
    hasDetailError.value = false;
    detailErrorMessage.value = '';
    selectedTransaction.value = null;
    try {
      final res = await TransactionService.getTransactionById(id);
      if (res.statusCode == 200) {
        final body = json.decode(res.body) as Map<String, dynamic>;
        selectedTransaction.value = TransactionDetail.fromJson(
          body['data'] as Map<String, dynamic>,
        );
      } else if (res.statusCode == 404) {
        hasDetailError.value = true;
        detailErrorMessage.value = 'Transaksi tidak ditemukan.';
      } else {
        hasDetailError.value = true;
        detailErrorMessage.value = 'Gagal memuat detail transaksi. Coba lagi.';
      }
    } catch (e) {
      hasDetailError.value = true;
      detailErrorMessage.value = 'Gagal memuat detail transaksi. Coba lagi.';
    } finally {
      isLoadingDetail.value = false;
    }
  }

  // ===================== UPDATE STATUS =====================

  Future<bool> updateTransactionStatus(String id, String status) async {
    isUpdatingStatus.value = true;
    try {
      final res = await TransactionService.updateTransactionStatus(id, status);
      if (res.statusCode == 200) {
        // Refresh detail supaya badge dan tombol aksi ikut update
        await fetchTransactionById(id);
        // Refresh list di background — tidak perlu await
        fetchTransactions();
        return true;
      } else {
        final body = json.decode(res.body) as Map<String, dynamic>;
        final msg =
            body['message'] as String? ?? 'Gagal mengubah status transaksi.';
        Get.snackbar(
          'Gagal',
          msg,
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: const Color(0xFFFEE2E2),
          colorText: const Color(0xFFEF4444),
          margin: const EdgeInsets.all(16),
          borderRadius: 12,
        );
        return false;
      }
    } catch (e) {
      Get.snackbar(
        'Gagal',
        'Terjadi kesalahan. Coba lagi.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: const Color(0xFFFEE2E2),
        colorText: const Color(0xFFEF4444),
        margin: const EdgeInsets.all(16),
        borderRadius: 12,
      );
      return false;
    } finally {
      isUpdatingStatus.value = false;
    }
  }

  // ===================== SUMMARY =====================

  /// Hanya hitung transaksi yang secara bisnis dianggap sebagai revenue:
  /// processing, shipped, completed. Exclude cancelled dan failed.
  double get totalRevenue => filteredTransactions
      .where((t) => t.isCountableRevenue)
      .fold(0, (sum, t) => sum + t.grandTotal);

  String get formattedTotalRevenue => CurrencyFormatter.format(totalRevenue);
}
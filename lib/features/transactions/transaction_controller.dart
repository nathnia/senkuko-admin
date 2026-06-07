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

  // Default "Semua" — volume transaksi masih kecil, admin perlu lihat semua
  final selectedQuickDate = 'Semua'.obs;

  // null = semua status (chip "Semua")
  final selectedStatus = Rxn<String>();

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

  /// Status chips yang ditampilkan di transaction page.
  /// null = semua transaksi, string = filter by status value.
  ///
  /// pending_payment sengaja tidak dimasukkan — status itu dikelola otomatis
  /// oleh webhook Midtrans, admin tidak perlu tahu atau melakukan apapun.
  static const List<({String label, String? value})> statusTabs = [
    (label: 'Semua', value: null),
    (label: 'Diproses', value: 'processing'),
    (label: 'Dikirim', value: 'shipped'),
    (label: 'Selesai', value: 'completed'),
    (label: 'Dibatalkan', value: 'cancelled'),
    (label: 'Gagal', value: 'failed'),
  ];

  @override
  void onInit() {
    super.onInit();
    _initFromArgs();
    fetchTransactions();
  }

  /// Dipanggil setiap kali TransactionPage dibuka (termasuk saat balik dari
  /// page lain). Reset filter ke default supaya admin selalu mulai fresh,
  /// kecuali kalau ada args dari dashboard yang minta filter tertentu.
  void resetOnEnter() {
    final args = Get.arguments;
    if (args is Map && args['statusFilter'] != null) {
      // Dari dashboard — terapkan filter yang diminta
      selectedStatus.value = args['statusFilter'] as String;
      selectedQuickDate.value = 'Semua';
      selectedDateRange.value = null;
    } else {
      // Buka biasa — reset ke default
      selectedStatus.value = null;
      selectedQuickDate.value = 'Semua';
      selectedDateRange.value = null;
    }
    searchText.value = '';
    _applyFilter();
  }

  void _initFromArgs() {
    final args = Get.arguments;
    if (args is Map && args['statusFilter'] != null) {
      selectedStatus.value = args['statusFilter'] as String;
    }
    // selectedQuickDate sudah default 'Semua' dari deklarasi
  }

  // ===================== FILTER =====================

  void _applyFilter() {
    final now = DateTime.now();
    final query = searchText.value.toLowerCase();
    final quickDate = selectedQuickDate.value;
    final range = selectedDateRange.value;
    final status = selectedStatus.value;

    filteredTransactions.assignAll(
      transactionList.where((t) {
        // Search
        final matchSearch =
            t.invoiceNumber.toLowerCase().contains(query) ||
            (t.customerName?.toLowerCase().contains(query) ?? false);

        // Date
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
        } else if (quickDate == 'Semua') {
          matchDate = true;
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

        // Status — null berarti semua
        final matchStatus = status == null || t.status == status;

        return matchSearch && matchDate && matchStatus;
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

  void updateStatus(String? value) {
    selectedStatus.value = value;
    _applyFilter();
  }

  void resetDateFilter() {
    selectedQuickDate.value = 'Semua';
    selectedDateRange.value = null;
    _applyFilter();
  }

  void resetFilters() {
    selectedQuickDate.value = 'Semua';
    selectedDateRange.value = null;
    selectedStatus.value = null;
    searchText.value = '';
    _applyFilter();
  }

  /// True kalau date filter bukan default — untuk dot indicator di filter button.
  bool get hasActiveDateFilter => selectedQuickDate.value != 'Semua';

  /// True kalau ada filter apapun aktif — untuk empty state reset button.
  bool get hasActiveFilters =>
      selectedStatus.value != null || selectedQuickDate.value != 'Semua';

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
        return Theme(
          data: ThemeData(
            colorScheme: ColorScheme.light(
              primary: AppColors.primary,
              onPrimary: Colors.white,
              primaryContainer: AppColors.primary.withAlpha(40),
              onPrimaryContainer: AppColors.primary,
              surface: AppColors.background,
              onSurface: AppColors.title,
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
        // Exclude pending_payment — dikelola otomatis webhook Midtrans,
        // tidak relevan untuk admin dan hanya membingungkan.
        final all = transactionModelFromJson(res.body).data;
        transactionList.assignAll(
          all.where((t) => t.status != 'pending_payment').toList(),
        );
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
        await fetchTransactionById(id);
        // Fire and forget — list refresh di background, tidak perlu tunggu
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
          backgroundColor: AppColors.dangerBg,
          colorText: AppColors.danger,
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
        backgroundColor: AppColors.dangerBg,
        colorText: AppColors.danger,
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
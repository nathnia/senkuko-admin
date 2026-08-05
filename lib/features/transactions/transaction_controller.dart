import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:senkukoadmin/constant/api_helper.dart';
import 'package:senkukoadmin/constant/app_colors.dart';
import 'package:senkukoadmin/constant/currency_formatter.dart';
import 'package:senkukoadmin/features/transactions/transaction_model.dart';
import 'package:senkukoadmin/features/transactions/transaction_service.dart';
import 'package:senkukoadmin/features/transactions/transaction_export_service.dart';

class TransactionController extends GetxController {
  final isLoading = false.obs;
  final isLoadingDetail = false.obs;
  final isUpdatingStatus = false.obs;
  final transactionList = <TransactionData>[].obs;
  final filteredTransactions = <TransactionData>[].obs;
  final selectedTransaction = Rxn<TransactionDetail>();

  final searchText = ''.obs;
  final Rxn<DateTimeRange> selectedDateRange = Rxn<DateTimeRange>();

  final selectedQuickDate = 'Semua'.obs;
  final Rxn<String> selectedStatus = Rxn<String>();
  final sortOrder = 'terbaru'.obs;

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

  static const List<({String label, String? value})> statusTabs = [
    (label: 'Semua', value: null),
    (label: 'Konfirmasi COD', value: 'pending_payment'),
    (label: 'Perlu Dikemas', value: 'processing'),
    (label: 'Dikirim', value: 'shipped'),
    (label: 'Selesai', value: 'completed'),
    (label: 'Dibatalkan', value: 'cancelled'),
    (label: 'Gagal', value: 'failed'),
  ];

  @override
  void onInit() {
    super.onInit();
    final args = Get.arguments;
    if (args is Map && args['statusFilter'] != null) {
      selectedStatus.value = args['statusFilter'] as String;
    }
    fetchTransactions();
  }

  // ===================== STALENESS (TTL) =====================
  // TTL sengaja PENDEK (15 detik) — jauh lebih ketat dari Voucher/Banner.
  // Transaksi COD butuh konfirmasi admin secepat mungkin, dan status bisa
  // berubah dari admin lain kapan aja. Ini CUMA buat nyegah spam fetch
  // kalau user gerak cepat antar halaman (mis. buka-tutup dalam <15 detik),
  // bukan buat nunda kebaruan data secara signifikan.
  DateTime? _lastFetchedAt;
  static const _staleAfter = Duration(seconds: 15);

  bool get _isStale =>
      _lastFetchedAt == null ||
      DateTime.now().difference(_lastFetchedAt!) > _staleAfter;

  /// Panggil dari TransactionPage.initState() — GANTIKAN fetchTransactions()
  /// langsung. PENTING: mutations (updateTransactionStatus, cancelTransaction)
  /// TETAP manggil fetchTransactions() langsung (lihat di bawah), BUKAN
  /// method ini — abis mutasi harus selalu fresh, gak boleh ke-skip staleness.
  void refreshIfStale() {
    if (_isStale) fetchTransactions();
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
          final from = DateTime(
            now.year,
            now.month,
            now.day,
          ).subtract(const Duration(days: 6));
          matchDate = !t.transactedAt.isBefore(from);
        } else if (quickDate == '30 Hari') {
          final from = DateTime(
            now.year,
            now.month,
            now.day,
          ).subtract(const Duration(days: 29));
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

        final matchStatus = status == null || t.status == status;

        return matchSearch && matchDate && matchStatus;
      }).toList()..sort(
        (a, b) => sortOrder.value == 'terlama'
            ? a.transactedAt.compareTo(b.transactedAt)
            : b.transactedAt.compareTo(a.transactedAt),
      ),
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

  void updateSortOrder(String value) {
    sortOrder.value = value;
    _applyFilter();
  }

  void resetDateFilter() {
    selectedQuickDate.value = 'Semua';
    selectedDateRange.value = null;
    sortOrder.value = 'terbaru';
    _applyFilter();
  }

  void resetFilters() {
    selectedQuickDate.value = 'Semua';
    selectedDateRange.value = null;
    selectedStatus.value = null;
    searchText.value = '';
    sortOrder.value = 'terbaru';
    _applyFilter();
  }

  bool get hasActiveDateFilter =>
      selectedQuickDate.value != 'Semua' || sortOrder.value != 'terbaru';

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
          DateTimeRange(start: now.subtract(const Duration(days: 7)), end: now),
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
        final all = transactionModelFromJson(res.body).data;
        transactionList.assignAll(
          all
              .where((t) => !(t.status == 'pending_payment' && !t.isCod))
              .toList(),
        );
        _applyFilter();
        _lastFetchedAt = DateTime.now();
      } else {
        hasError.value = true;
        errorMessage.value = ApiHelper.isNetworkError(res)
            ? ApiHelper.parseError(res.body)
            : 'Gagal memuat daftar transaksi. (${res.statusCode})';
      }
    } catch (e) {
      hasError.value = true;
      errorMessage.value = 'Gagal memuat data: $e';
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

  /// Parse pesan error dari response body dengan aman — SENGAJA dipisah
  /// dari try/catch utama di updateTransactionStatus/cancelTransaction.
  /// Kalau body-nya bukan JSON valid (mis. error HTML dari proxy/nginx,
  /// bukan dari handler Express), json.decode bakal throw — dan kalau itu
  /// kejadian DI DALAM try block utama, dia ketangkep catch(e) generik
  /// yang nge-print "Terjadi kesalahan. Coba lagi." — pesan error asli
  /// dari server (mis. "Forbidden: ...") jadi ke-mask dan susah didebug.
  static String _extractErrorMessage(http.Response? res, String fallback) {
    if (res == null) return fallback;
    try {
      final body = json.decode(res.body) as Map<String, dynamic>;
      return body['message'] as String? ?? fallback;
    } catch (_) {
      return fallback;
    }
  }

  Future<bool> updateTransactionStatus(String id, String status) async {
    isUpdatingStatus.value = true;
    try {
      final res = await TransactionService.updateTransactionStatus(id, status);
      if (res.statusCode == 200) {
        await fetchTransactionById(id);
        // Sengaja TIDAK pakai refreshIfStale() — abis mutasi, list HARUS
        // fresh, gak boleh ke-skip walau baru fetch <15 detik lalu.
        fetchTransactions();
        return true;
      } else {
        final msg = _extractErrorMessage(
          res,
          'Gagal mengubah status transaksi.',
        );
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

  Future<bool> cancelTransaction(String id) async {
    isUpdatingStatus.value = true;
    try {
      final res = await TransactionService.cancelTransaction(id);
      if (res.statusCode == 200) {
        await fetchTransactionById(id);
        fetchTransactions();
        return true;
      } else {
        final msg = _extractErrorMessage(res, 'Gagal membatalkan transaksi.');
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

  double get totalRevenue => filteredTransactions
      .where((t) => t.isCountableRevenue)
      .fold(0, (sum, t) => sum + t.grandTotal);

  String get formattedTotalRevenue => CurrencyFormatter.format(totalRevenue);

  final isExporting = false.obs;

  Future<void> exportRecap() async {
    if (isExporting.value) return;
    isExporting.value = true;
    try {
      await TransactionExportService.exportRecap(filteredTransactions);
    } catch (e) {
      Get.snackbar(
        'Gagal',
        'Gagal export rekap. Coba lagi.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: AppColors.dangerBg,
        colorText: AppColors.danger,
        margin: const EdgeInsets.all(16),
        borderRadius: 12,
      );
    } finally {
      isExporting.value = false;
    }
  }
}
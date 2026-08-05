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
import 'package:senkukoadmin/features/transactions/transaction_summary_model.dart';

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
    fetchDashboardSummary(); // <-- baru
  }

  // ===================== STALENESS (TTL) =====================
  DateTime? _lastFetchedAt;
  static const _staleAfter = Duration(seconds: 15);

  bool get _isStale =>
      _lastFetchedAt == null ||
      DateTime.now().difference(_lastFetchedAt!) > _staleAfter;

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

  /// [force] = true buat skip TTL item estimate juga — dipakai pas user
  /// pull-to-refresh manual, karena secara eksplisit minta data terbaru.
  Future<void> fetchTransactions({bool force = false}) async {
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
        // Fire-and-forget, gak blocking list utama.
        fetchPendingItemEstimate(force: force);
        fetchProcessingItemEstimate(force: force);
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

  // ===================== ITEM ESTIMATE (per status) =====================
  // Buat subtitle kartu "COD Perlu Konfirmasi" & "Perlu Dikemas" di
  // DashboardPage. Endpoint list (/transactions) gak balikin item, dan
  // /transactions/summary cuma teragregasi per rentang tanggal tanpa
  // filter status — jadi gak ada cara lain selain fetch detail per
  // transaksi buat dapetin angka spesifik per status.
  //
  // Ini beda dari N+1 yang dilaporkan ke Zanadin (yang masalahnya ratusan-
  // ribuan baris export bulanan). Di sini N secara alami kecil:
  // - `pending_payment` (COD): transient — begitu dikonfirmasi admin,
  //   statusnya pindah, jadi biasanya cuma segelintir.
  // - `processing`: bisa numpuk kalau admin telat proses.
  // Tapi keduanya TETAP dikasih `_itemEstimateCap` sebagai jaring pengaman
  // eksplisit di kode — bukan cuma mengandalkan asumsi bisnis. Kalau
  // jumlah transaksi di status itu ngelewatin cap, fetch detail di-skip
  // sama sekali dan subtitle-nya balik ke teks statis (jumlah transaksi
  // tetap kelihatan dari badge count di kartunya).

  static const _itemEstimateCap = 30;

  // TTL khusus buat item estimate — misah dari _staleAfter list utama
  // karena ini request yang lebih berat (N request detail, bukan 1).
  // Tanpa TTL sendiri, tiap fetchTransactions() (termasuk pull-to-refresh
  // berkali-kali) bakal nembak ulang semua request detail padahal
  // datanya kemungkinan besar belum berubah.
  static const _itemEstimateStaleAfter = Duration(seconds: 30);
  DateTime? _pendingEstimateFetchedAt;
  DateTime? _processingEstimateFetchedAt;

  final pendingItemEstimate = 0.obs;
  final isPendingEstimateLoading = false.obs;
  final processingItemEstimate = 0.obs;
  final isProcessingEstimateLoading = false.obs;

  /// true kalau jumlah transaksi pending/processing ngelewatin cap —
  /// dipakai DashboardPage buat mutusin tampilin subtitle statis atau
  /// estimasi.
  final pendingEstimateSkipped = false.obs;
  final processingEstimateSkipped = false.obs;

  /// [force] = true buat skip TTL, dipakai pas pull-to-refresh manual.
  Future<void> fetchPendingItemEstimate({bool force = false}) async {
    final pending = transactionList
        .where((t) => t.status == 'pending_payment')
        .toList();

    if (pending.length > _itemEstimateCap) {
      pendingEstimateSkipped.value = true;
      pendingItemEstimate.value = 0;
      return;
    }
    pendingEstimateSkipped.value = false;

    final isStale =
        _pendingEstimateFetchedAt == null ||
        DateTime.now().difference(_pendingEstimateFetchedAt!) >
            _itemEstimateStaleAfter;
    if (!force && !isStale) return;

    await _fetchItemEstimateForStatus(
      status: 'pending_payment',
      target: pendingItemEstimate,
      loadingFlag: isPendingEstimateLoading,
    );
    _pendingEstimateFetchedAt = DateTime.now();
  }

  /// [force] = true buat skip TTL, dipakai pas pull-to-refresh manual.
  Future<void> fetchProcessingItemEstimate({bool force = false}) async {
    final processing = transactionList
        .where((t) => t.status == 'processing')
        .toList();

    if (processing.length > _itemEstimateCap) {
      processingEstimateSkipped.value = true;
      processingItemEstimate.value = 0;
      return;
    }
    processingEstimateSkipped.value = false;

    final isStale =
        _processingEstimateFetchedAt == null ||
        DateTime.now().difference(_processingEstimateFetchedAt!) >
            _itemEstimateStaleAfter;
    if (!force && !isStale) return;

    await _fetchItemEstimateForStatus(
      status: 'processing',
      target: processingItemEstimate,
      loadingFlag: isProcessingEstimateLoading,
    );
    _processingEstimateFetchedAt = DateTime.now();
  }

  Future<void> _fetchItemEstimateForStatus({
    required String status,
    required RxInt target,
    required RxBool loadingFlag,
  }) async {
    final matching = transactionList.where((t) => t.status == status).toList();

    if (matching.isEmpty) {
      target.value = 0;
      return;
    }

    loadingFlag.value = true;
    try {
      final results = await Future.wait(
        matching.map((t) => TransactionService.getTransactionById(t.id)),
      );

      int total = 0;
      for (final res in results) {
        if (res.statusCode != 200) continue;
        try {
          final body = json.decode(res.body) as Map<String, dynamic>;
          final detail = TransactionDetail.fromJson(
            body['data'] as Map<String, dynamic>,
          );
          total += detail.items.fold(0, (sum, item) => sum + item.qty);
        } catch (_) {
          // Skip transaksi ini kalau parsing gagal, jangan gagalin semua.
        }
      }
      target.value = total;
    } catch (_) {
      // Diem-diem aja kalau gagal total — sama kayak fetchDashboardSummary,
      // dashboard tetap bisa dipakai tanpa angka ini.
    } finally {
      loadingFlag.value = false;
    }
  }

  // ===================== DASHBOARD SUMMARY =====================
  // Buat card estimasi jumlah barang terjual di DashboardPage. Data
  // teragregasi dari backend (/transactions/summary), bukan dihitung
  // manual dari transactionList (yang cuma nyimpen data list biasa,
  // gak ada info item per transaksi).

  final summary = Rxn<TransactionSummary>();
  final isSummaryLoading = false.obs;

  DateTime? _summaryFetchedAt;
  static const _summaryStaleAfter = Duration(minutes: 1);

  Future<void> fetchDashboardSummary({bool force = false}) async {
    final isStale =
        _summaryFetchedAt == null ||
        DateTime.now().difference(_summaryFetchedAt!) > _summaryStaleAfter;
    if (!force && !isStale) return;

    isSummaryLoading.value = true;
    try {
      final now = DateTime.now();
      final startOfMonth = DateTime(now.year, now.month, 1);
      summary.value = await TransactionService.fetchSummary(
        start: startOfMonth,
        end: now,
      );
      _summaryFetchedAt = DateTime.now();
    } catch (e) {
      // Sengaja diem-diem aja kalau gagal — dashboard tetap bisa dipakai
      // tanpa card ini, gak perlu snackbar/blocking error kayak fetch utama.
      summary.value = null;
    } finally {
      isSummaryLoading.value = false;
    }
  }

  // ===================== UPDATE STATUS =====================

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

  // ===================== SUMMARY / EXPORT =====================
  // DIUBAH: dulu exportRecap() cuma ngirim `filteredTransactions` (list
  // yang lagi ke-load di layar) ke TransactionExportService. Sekarang
  // narik data LENGKAP dari backend (`/transactions/export`, paginated)
  // sesuai rentang tanggal yang lagi dipilih user di filter — jadi hasil
  // export gak kebatas apa yang kebetulan udah ke-fetch/ke-cache di app,
  // dan gak perlu N+1 fetch per transaksi buat dapetin item-nya.

  double get totalRevenue => filteredTransactions
      .where((t) => t.isCountableRevenue)
      .fold(0, (sum, t) => sum + t.grandTotal);

  String get formattedTotalRevenue => CurrencyFormatter.format(totalRevenue);

  final isExporting = false.obs;

  /// Terjemahin filter tanggal yang lagi aktif di UI (quick date / custom)
  /// jadi rentang start–end konkret buat dikirim ke endpoint export.
  _DateRange _resolveExportRange() {
    final now = DateTime.now();
    switch (selectedQuickDate.value) {
      case 'Hari Ini':
        return _DateRange(DateTime(now.year, now.month, now.day), now);
      case '7 Hari':
        return _DateRange(
          DateTime(
            now.year,
            now.month,
            now.day,
          ).subtract(const Duration(days: 6)),
          now,
        );
      case '30 Hari':
        return _DateRange(
          DateTime(
            now.year,
            now.month,
            now.day,
          ).subtract(const Duration(days: 29)),
          now,
        );
      case 'Custom':
        final range = selectedDateRange.value;
        if (range != null) return _DateRange(range.start, range.end);
        return _DateRange(DateTime(2020), now);
      default: // 'Semua'
        return _DateRange(DateTime(2020), now);
    }
  }

  Future<void> exportRecap() async {
    if (isExporting.value) return;
    isExporting.value = true;
    try {
      final range = _resolveExportRange();

      final rows = await TransactionService.fetchAllExportRows(
        start: range.start,
        end: range.end,
      );

      // Backend export belum support filter status, jadi difilter di sini
      // kalau user lagi pilih tab status tertentu — konsisten sama
      // _applyFilter() di atas.
      final status = selectedStatus.value;
      final filteredRows = status == null
          ? rows
          : rows.where((r) => r.status == status).toList();

      final summary = await TransactionService.fetchSummary(
        start: range.start,
        end: range.end,
      );

      await TransactionExportService.exportRecap(
        rows: filteredRows,
        summary: summary,
      );
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

class _DateRange {
  final DateTime start;
  final DateTime end;
  const _DateRange(this.start, this.end);
}
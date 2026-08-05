import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:senkukoadmin/constant/app_colors.dart';
import 'package:senkukoadmin/constant/app_error_state.dart';
import 'package:senkukoadmin/constant/app_filter_button.dart';
import 'package:senkukoadmin/constant/app_filter_chips.dart';
import 'package:senkukoadmin/constant/app_searchbar.dart';
import 'package:senkukoadmin/constant/app_back_button.dart';
import 'package:senkukoadmin/features/transactions/transaction_card.dart';
import 'package:senkukoadmin/features/transactions/transaction_controller.dart';
import 'package:senkukoadmin/features/transactions/transaction_filter_sheet.dart';
import 'package:senkukoadmin/routes/routes.dart';

class TransactionPage extends StatefulWidget {
  const TransactionPage({super.key});

  @override
  State<TransactionPage> createState() => _TransactionPageState();
}

class _TransactionPageState extends State<TransactionPage>
    with WidgetsBindingObserver {
  late final TransactionController _c;

  @override
  void initState() {
    super.initState();
    _c = Get.find<TransactionController>();
    WidgetsBinding.instance.addObserver(this);

    _c.resetFilters();
    final args = Get.arguments;
    if (args is Map && args['statusFilter'] != null) {
      _c.updateStatus(args['statusFilter'] as String);
    }

    // fetchTransactions() gak pakai CacheService, murni network call,
    // aman dipanggil langsung.
    _c.refreshIfStale();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Nutup celah: user minimize app lama (mis. ada transaksi COD baru
    // masuk atau status diubah admin lain), balik lagi — data mungkin
    // udah basi walau halamannya gak pernah "dibuka ulang" secara route.
    if (state == AppLifecycleState.resumed) {
      _c.refreshIfStale();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: AppBackButton(onTap: () => Get.back()),
        title: const Text(
          'Transaksi',
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        centerTitle: true,
        actions: [
          Obx(
            () => GestureDetector(
              onTap: _c.isExporting.value ? null : _c.exportRecap,
              child: Container(
                margin: const EdgeInsets.only(right: 16, top: 10, bottom: 10),
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: AppColors.successBg,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _c.isExporting.value
                        ? SizedBox(
                            width: 13,
                            height: 13,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: AppColors.primary,
                            ),
                          )
                        : Icon(
                            Icons.file_download_outlined,
                            size: 13,
                            color: AppColors.primary,
                          ),
                    const SizedBox(width: 4),
                    Text(
                      'Export',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
            child: Row(
              children: [
                Expanded(
                  child: AppSearchBar(
                    hintText: 'Cari invoice atau nama pelanggan...',
                    onChanged: _c.updateSearch,
                  ),
                ),
                const SizedBox(width: 10),
                Obx(
                  () => AppFilterButton(
                    isActive: _c.hasActiveDateFilter,
                    onTap: () => showTransactionFilterSheet(context, _c),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      body: Column(
        children: [
          Obx(
            () => AppFilterChips(
              items: TransactionController.statusTabs
                  .map((t) => FilterChipItem(label: t.label))
                  .toList(),
              selectedLabel: TransactionController.statusTabs
                  .firstWhere(
                    (t) => t.value == _c.selectedStatus.value,
                    orElse: () => TransactionController.statusTabs.first,
                  )
                  .label,
              onChipTap: (label) {
                final tab = TransactionController.statusTabs.firstWhere(
                  (t) => t.label == label,
                );
                _c.updateStatus(tab.value);
              },
            ),
          ),
          Obx(() => _summaryBar()),
          Expanded(child: _transactionList()),
        ],
      ),
    );
  }

  Widget _summaryBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: _summaryCard(
                label: 'Total transaksi',
                value: '${_c.filteredTransactions.length}',
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _summaryCard(
                label: 'Total pendapatan',
                value: _c.formattedTotalRevenue,
                valueColor: AppColors.primary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _summaryCard({
    required String label,
    required String value,
    Color? valueColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontSize: 11, color: Colors.grey)),
          const SizedBox(height: 2),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: valueColor ?? AppColors.title,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _transactionList() {
    return Obx(() {
      if (_c.isLoading.value) {
        return const Center(child: CircularProgressIndicator());
      }

      if (_c.hasError.value) {
        return AppErrorState(
          message: _c.errorMessage.value,
          onRetry: _c.fetchTransactions,
        );
      }

      final list = _c.filteredTransactions;

      if (list.isEmpty) {
        return RefreshIndicator(
          color: AppColors.primary,
          onRefresh: () => _c.fetchTransactions(force: true),
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: SizedBox(
              height: 400,
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.receipt_long_outlined,
                      size: 48,
                      color: Colors.grey.shade300,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Tidak ada transaksi',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: AppColors.subtext,
                      ),
                    ),
                    if (_c.hasActiveDateFilter) ...[
                      const SizedBox(height: 8),
                      TextButton(
                        onPressed: _c.resetDateFilter,
                        child: const Text('Reset filter tanggal'),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        );
      }

      return RefreshIndicator(
        color: AppColors.primary,
        onRefresh: () => _c.fetchTransactions(force: true),
        child: ListView.builder(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          itemCount: list.length,
          itemBuilder: (context, index) => TransactionCard(
            transaction: list[index],
            onTap: () => Get.toNamed(
              AppRoutes.transactionDetail,
              arguments: list[index].id,
            ),
          ),
        ),
      );
    });
  }
}
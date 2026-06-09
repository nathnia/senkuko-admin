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

class _TransactionPageState extends State<TransactionPage> {
  late final TransactionController _controller;

  @override
  void initState() {
    super.initState();
    _controller = Get.find<TransactionController>();

    // Baca args dan apply filter SETELAH frame pertama selesai.
    // Ini juga handle kasus balik dari detail page — filter di-reset ke default,
    // kecuali kalau ada statusFilter dari dashboard.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final args = Get.arguments;
      if (args is Map && args['statusFilter'] != null) {
        _controller.updateStatus(args['statusFilter'] as String);
      } else {
        _controller.updateStatus(null);
      }
    });
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
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: Row(
              children: [
                Expanded(
                  child: AppSearchBar(
                    hintText: 'Cari invoice atau nama pelanggan...',
                    onChanged: _controller.updateSearch,
                  ),
                ),
                const SizedBox(width: 10),
                Obx(
                  () => AppFilterButton(
                    isActive: _controller.hasActiveDateFilter,
                    onTap: () =>
                        showTransactionFilterSheet(context, _controller),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      body: Column(
        children: [
          // ── Status filter chips ──────────────────────────────────────
          Obx(
            () => AppFilterChips(
              items: TransactionController.statusTabs
                  .map((t) => FilterChipItem(label: t.label))
                  .toList(),
              selectedLabel: TransactionController.statusTabs
                  .firstWhere(
                    (t) => t.value == _controller.selectedStatus.value,
                    orElse: () => TransactionController.statusTabs.first,
                  )
                  .label,
              onChipTap: (label) {
                final tab = TransactionController.statusTabs
                    .firstWhere((t) => t.label == label);
                _controller.updateStatus(tab.value);
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
      child: Row(
        children: [
          Expanded(
            child: _summaryCard(
              label: 'Total transaksi',
              value: '${_controller.filteredTransactions.length}',
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _summaryCard(
              label: 'Total pendapatan',
              value: _controller.formattedTotalRevenue,
              valueColor: AppColors.primary,
              valueFontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _summaryCard({
    required String label,
    required String value,
    Color? valueColor,
    double valueFontSize = 18,
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
          Text(
            label,
            style: const TextStyle(fontSize: 11, color: Colors.grey),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: TextStyle(
              fontSize: valueFontSize,
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
      if (_controller.isLoading.value) {
        return const Center(child: CircularProgressIndicator());
      }

      if (_controller.hasError.value) {
        return AppErrorState(
          message: _controller.errorMessage.value,
          onRetry: _controller.fetchTransactions,
        );
      }

      final list = _controller.filteredTransactions;

      if (list.isEmpty) {
        return RefreshIndicator(
          color: AppColors.primary,
          onRefresh: _controller.fetchTransactions,
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
                    if (_controller.hasActiveDateFilter) ...[
                      const SizedBox(height: 8),
                      TextButton(
                        onPressed: _controller.resetDateFilter,
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
        onRefresh: _controller.fetchTransactions,
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
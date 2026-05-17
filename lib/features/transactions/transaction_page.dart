import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:senkukoadmin/constant/app_colors.dart';
import 'package:senkukoadmin/constant/app_filter_chips.dart';
import 'package:senkukoadmin/constant/app_searchbar.dart';
import 'package:senkukoadmin/constant/currency_formatter.dart';
import 'package:senkukoadmin/constant/app_back_button.dart';
import 'package:senkukoadmin/features/transactions/transaction_card.dart';
import 'package:senkukoadmin/features/transactions/transaction_controller.dart';
import 'package:senkukoadmin/routes/routes.dart';

class TransactionPage extends StatelessWidget {
  const TransactionPage({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<TransactionController>();

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
          preferredSize: const Size.fromHeight(52),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
            child: AppSearchBar(
              hintText: 'Cari invoice...',
              onChanged: controller.updateSearch,
            ),
          ),
        ),
      ),
      body: Column(
        children: [
          Obx(() {
            final range = controller.selectedDateRange.value;
            return AppFilterChips(
              items: controller.quickDateFilters
                  .map(
                    (f) => FilterChipItem(
                      label: f,
                      icon: f == 'Custom' ? Icons.date_range_outlined : null,
                    ),
                  )
                  .toList(),
              selectedLabel: controller.selectedQuickDate.value,
              selectedLabelOverride:
                  (controller.selectedQuickDate.value == 'Custom' &&
                      range != null)
                  ? '${DateFormatter.formatShort(range.start)} – ${DateFormatter.formatShort(range.end)}'
                  : null,
              onChipTap: (label) async {
                if (label == 'Custom') {
                  await controller.pickDateRange(context);
                } else {
                  controller.updateQuickDate(label);
                }
              },
            );
          }),
          Obx(() => _summaryBar(controller)),
          Expanded(child: _transactionList(controller)),
        ],
      ),
    );
  }

  Widget _summaryBar(TransactionController controller) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 4),
      child: Row(
        children: [
          Expanded(
            child: _summaryCard(
              label: 'Total transaksi',
              value: '${controller.filteredTransactions.length}',
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _summaryCard(
              label: 'Total pendapatan',
              value: controller.formattedTotalRevenue,
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
          Text(label, style: const TextStyle(fontSize: 11, color: Colors.grey)),
          const SizedBox(height: 2),
          Text(
            value,
            style: TextStyle(
              fontSize: valueFontSize,
              fontWeight: FontWeight.w600,
              color: valueColor ?? const Color(0xFF1A1A2E),
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _transactionList(TransactionController controller) {
    return Obx(() {
      if (controller.isLoading.value) {
        return const Center(child: CircularProgressIndicator());
      }

      final list = controller.filteredTransactions;

      if (list.isEmpty) {
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Transaksi tidak ditemukan',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Colors.grey.shade500,
                ),
              ),
            ],
          ),
        );
      }

      return RefreshIndicator(
        color: AppColors.primary,
        onRefresh: () async {
          await controller.fetchTransactions();
        },
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

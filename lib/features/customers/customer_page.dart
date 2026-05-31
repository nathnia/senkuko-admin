import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:senkukoadmin/constant/app_colors.dart';
import 'package:senkukoadmin/constant/app_error_state.dart';
import 'package:senkukoadmin/constant/app_filter_chips.dart';
import 'package:senkukoadmin/constant/app_searchbar.dart';
import 'package:senkukoadmin/constant/app_back_button.dart';
import 'package:senkukoadmin/features/customers/customer_card.dart';
import 'package:senkukoadmin/features/customers/customer_controller.dart';

class CustomerPage extends StatelessWidget {
  const CustomerPage({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<CustomerController>();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: AppBackButton(onTap: () => Get.back()),
        title: const Text(
          'Pelanggan',
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        centerTitle: true,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(40),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
            child: Row(
              children: [
                Expanded(
                  child: AppSearchBar(
                    hintText: 'Cari nama, telepon, atau email...',
                    onChanged: controller.updateSearch,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      body: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Obx(
                  () => AppFilterChips(
                    items: const [
                      FilterChipItem(label: 'Semua'),
                      FilterChipItem(label: 'Aktif'),
                      FilterChipItem(label: 'Nonaktif'),
                    ],
                    selectedLabel: controller.statusFilterLabel,
                    onChipTap: controller.setStatusFilter,
                  ),
                ),
              ),
            ],
          ),

          Expanded(
            child: Obx(() {
              if (controller.isLoading.value &&
                  controller.customerList.isEmpty) {
                return const Center(child: CircularProgressIndicator());
              }

              // ADD THIS
              if (controller.hasError.value) {
                return AppErrorState(
                  message: controller.errorMessage.value,
                  onRetry: controller.fetchCustomers,
                );
              }

              final list = controller.filteredCustomers;
              if (list.isEmpty) {
                return const Center(
                  child: Text(
                    'Tidak ada pelanggan ditemukan',
                    style: TextStyle(color: Colors.grey),
                  ),
                );
              }
              return RefreshIndicator(
                color: AppColors.primary,
                onRefresh: controller.fetchCustomers,
                child: ListView.builder(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
                  itemCount: list.length,
                  itemBuilder: (context, index) {
                    final customer = list[index];
                    return CustomerCard(
                      customer: customer,
                      onToggleStatus: () =>
                          controller.toggleCustomerStatus(customer),
                    );
                  },
                ),
              );
            }),
          ),
        ],
      ),
    );
  }
}

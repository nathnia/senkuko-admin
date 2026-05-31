import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:senkukoadmin/constant/app_back_button.dart';
import 'package:senkukoadmin/constant/app_colors.dart';
import 'package:senkukoadmin/constant/app_error_state.dart';
import 'package:senkukoadmin/constant/app_filter_chips.dart';
import 'package:senkukoadmin/constant/app_searchbar.dart';
import 'package:senkukoadmin/features/vouchers/voucher_card.dart';
import 'package:senkukoadmin/features/vouchers/voucher_controller.dart';
import 'package:senkukoadmin/routes/routes.dart';

class VoucherPage extends StatefulWidget {
  const VoucherPage({super.key});

  @override
  State<VoucherPage> createState() => _VoucherPageState();
}

class _VoucherPageState extends State<VoucherPage> {
  final controller = Get.find<VoucherController>();
  late final String? _promotionId;

  @override
  void initState() {
    super.initState();
    _promotionId = Get.arguments as String?;
    controller.initPage(_promotionId);
  }

  @override
  void dispose() {
    controller.resetInit();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: const AppBackButton(),
        title: Text(
          _promotionId != null ? 'Voucher Promo' : 'Semua Voucher',
          style: const TextStyle(
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
            child: AppSearchBar(
              hintText: 'Cari kode voucher...',
              onChanged: controller.updateSearch,
            ),
          ),
        ),
      ),
      body: Column(
        children: [
          Obx(
            () => AppFilterChips(
              items: const [
                FilterChipItem(label: 'Semua'),
                FilterChipItem(label: 'Aktif'),
                FilterChipItem(label: 'Tidak Aktif'),
                FilterChipItem(label: 'Habis'),
              ],
              selectedLabel: controller.selectedFilter.value,
              onChipTap: controller.updateFilter,
            ),
          ),
          Expanded(child: _voucherList()),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.primary,
        onPressed: () =>
            Get.toNamed(AppRoutes.voucherForm, arguments: _promotionId),
        icon: const Icon(Icons.add_rounded, color: Colors.white),
        label: const Text(
          'Terbitkan Voucher',
          style: TextStyle(fontWeight: FontWeight.w600, color: Colors.white),
        ),
      ),
    );
  }

  Widget _voucherList() {
    return Obx(() {
      if (controller.isLoading.value) {
        return const Center(child: CircularProgressIndicator());
      }

      if (controller.hasError.value) {
        return AppErrorState(
          message: controller.errorMessage.value,
          onRetry: controller.fetchVouchers,
        );
      }

      final list = controller.filteredVouchers;

      if (list.isEmpty) {
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.confirmation_number_outlined,
                size: 48,
                color: Colors.grey.shade300,
              ),
              const SizedBox(height: 12),
              Text(
                'Belum ada voucher',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: AppColors.subtext,
                ),
              ),
            ],
          ),
        );
      }

      return RefreshIndicator(
        color: AppColors.primary,
        onRefresh: controller.fetchVouchers,
        child: ListView.builder(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
          itemCount: list.length,
          itemBuilder: (_, i) {
            final voucher = list[i];
            return VoucherCard(
              voucher: voucher,
              onTap: () => Get.toNamed(
                AppRoutes.voucherForm,
                arguments: {'id': voucher.id, 'isEdit': true},
              ),
              onToggleStatus: () => controller.toggleStatus(voucher),
              onDelete: () =>
                  controller.confirmDelete(voucher.id, voucher.code),
            );
          },
        ),
      );
    });
  }
}
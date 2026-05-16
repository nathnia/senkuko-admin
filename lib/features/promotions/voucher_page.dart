import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:senkukoadmin/constant/app_colors.dart';
import 'package:senkukoadmin/constant/app_back_button.dart';
import 'package:senkukoadmin/constant/app_filter_chips.dart';
import 'package:senkukoadmin/constant/app_searchbar.dart';
import 'package:senkukoadmin/features/promotions/voucher_card.dart';
import 'package:senkukoadmin/features/promotions/voucher_controller.dart';
import 'package:senkukoadmin/routes/routes.dart';

/// Bisa dipanggil dari:
/// 1. Menu utama → semua voucher (promotionId = null)
/// 2. Promotion detail → voucher by promotion (promotionId = id)
class VoucherPage extends StatelessWidget {
  const VoucherPage({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<VoucherController>();

    // kalau dipanggil dari promotion detail, arguments = promotionId
    final String? promotionId = Get.arguments as String?;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      controller.filterByPromotionId.value = promotionId;
      controller.fetchVouchers();
    });

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: const Padding(
          padding: EdgeInsets.only(left: 16),
          child: AppBackButton(),
        ),
        leadingWidth: 40,
        title: Text(
          promotionId != null ? 'Voucher Promo' : 'Semua Voucher',
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded,
                size: 20, color: Colors.black54),
            onPressed: controller.fetchVouchers,
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(52),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
            child: AppSearchBar(
              hintText: 'Cari kode voucher...',
              onChanged: controller.updateSearch,
            ),
          ),
        ),
      ),
      body: Column(
        children: [
          Obx(() => AppFilterChips(
                items: const [
                  FilterChipItem(label: 'Semua'),
                  FilterChipItem(label: 'Aktif'),
                  FilterChipItem(label: 'Tidak Aktif'),
                  FilterChipItem(label: 'Habis'),
                ],
                selectedLabel: controller.selectedFilter.value,
                onChipTap: controller.updateFilter,
              )),
          Expanded(child: _voucherList(controller, promotionId)),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.primary,
        onPressed: () => Get.toNamed(
          AppRoutes.voucherForm,
          // kalau dari promotion detail, langsung pre-fill promotion_id
          arguments: promotionId,
        ),
        icon: const Icon(Icons.add_rounded, color: Colors.white),
        label: const Text(
          'Terbitkan Voucher',
          style: TextStyle(fontWeight: FontWeight.w600, color: Colors.white),
        ),
      ),
    );
  }

  Widget _voucherList(VoucherController controller, String? promotionId) {
    return Obx(() {
      if (controller.isLoading.value) {
        return const Center(child: CircularProgressIndicator());
      }

      final list = controller.filteredVouchers;

      if (list.isEmpty) {
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.confirmation_number_outlined,
                  size: 48, color: Colors.grey.shade300),
              const SizedBox(height: 12),
              Text(
                'Belum ada voucher',
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
        onRefresh: controller.fetchVouchers,
        child: ListView.builder(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
          itemCount: list.length,
          itemBuilder: (context, index) {
            final voucher = list[index];
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
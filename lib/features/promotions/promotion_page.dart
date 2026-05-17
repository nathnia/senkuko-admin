import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:senkukoadmin/constant/app_back_button.dart';
import 'package:senkukoadmin/constant/app_colors.dart';
import 'package:senkukoadmin/constant/app_filter_chips.dart';
import 'package:senkukoadmin/constant/app_searchbar.dart';
import 'package:senkukoadmin/features/promotions/promotion_controller.dart';
import 'package:senkukoadmin/features/promotions/promotion_card.dart';
import 'package:senkukoadmin/routes/routes.dart';

class PromotionPage extends StatelessWidget {
  const PromotionPage({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<PromotionController>();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: const Padding(
          padding: EdgeInsets.only(left: 16),
          child: AppBackButton(),
        ),
        leadingWidth: 40,
        title: const Text(
          'Promosi',
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
              hintText: 'Cari nama atau kode promo...',
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
                FilterChipItem(label: 'Kedaluwarsa'),
              ],
              selectedLabel: controller.selectedFilter.value,
              onChipTap: controller.updateFilter,
            ),
          ),
          Expanded(child: _promotionList(controller)),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.primary,
        onPressed: () => Get.toNamed(AppRoutes.promotionForm),
        icon: const Icon(Icons.add_rounded, color: Colors.white),
        label: const Text(
          'Buat Promo',
          style: TextStyle(fontWeight: FontWeight.w600, color: Colors.white),
        ),
      ),
    );
  }

  Widget _promotionList(PromotionController controller) {
    return Obx(() {
      if (controller.isLoading.value) {
        return const Center(child: CircularProgressIndicator());
      }

      final list = controller.filteredPromotions;

      if (list.isEmpty) {
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.local_offer_outlined,
                size: 48,
                color: Colors.grey.shade300,
              ),
              const SizedBox(height: 12),
              Text(
                'Belum ada promosi',
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
        onRefresh: controller.fetchPromotions,
        child: ListView.builder(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
          itemCount: list.length,
          itemBuilder: (context, index) {
            final promo = list[index];
            return PromotionCard(
              promotion: promo,
              onTap: () =>
                  Get.toNamed(AppRoutes.promotionDetail, arguments: promo.id),
              onToggleActive: () => controller.toggleActive(promo),
              onDelete: () => controller.confirmDelete(promo.id, promo.name),
            );
          },
        ),
      );
    });
  }
}

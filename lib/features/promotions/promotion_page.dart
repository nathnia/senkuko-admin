import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:senkukoadmin/constant/app_back_button.dart';
import 'package:senkukoadmin/constant/app_colors.dart';
import 'package:senkukoadmin/constant/app_error_state.dart';
import 'package:senkukoadmin/constant/app_filter_chips.dart';
import 'package:senkukoadmin/constant/app_searchbar.dart';
import 'package:senkukoadmin/features/promotions/promotion_card.dart';
import 'package:senkukoadmin/features/promotions/promotion_controller.dart';
import 'package:senkukoadmin/routes/routes.dart';

class PromotionPage extends StatefulWidget {
  const PromotionPage({super.key});

  @override
  State<PromotionPage> createState() => _PromotionPageState();
}

class _PromotionPageState extends State<PromotionPage>
    with WidgetsBindingObserver {
  final controller = Get.find<PromotionController>();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // Controller permanent (onInit cuma jalan sekali seumur app), jadi
    // cek staleness di sini tiap kali halaman ini dibuka/dikunjungi lagi.
    controller.refreshIfStale();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Nutup celah: user minimize app lama, balik lagi — data mungkin
    // udah basi walau halamannya gak pernah "dibuka ulang" secara route.
    if (state == AppLifecycleState.resumed) {
      controller.refreshIfStale();
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
        leading: const AppBackButton(),
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
          preferredSize: const Size.fromHeight(40),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
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
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.primary,
        onPressed: () => Get.toNamed(AppRoutes.promotionForm),
        child: const Icon(Icons.add_rounded, color: Colors.white),
      ),
    );
  }

  Widget _promotionList(PromotionController controller) {
    return Obx(() {
      if (controller.isLoading.value) {
        return const Center(child: CircularProgressIndicator());
      }

      if (controller.hasError.value) {
        return AppErrorState(
          message: controller.errorMessage.value,
          onRetry: controller.fetchPromotions,
        );
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
                  color: AppColors.subtext,
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
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
          itemCount: list.length,
          itemBuilder: (_, i) {
            final promo = list[i];
            return PromotionCard(
              promotion: promo,
              onTap: () =>
                  Get.toNamed(AppRoutes.promotionDetail, arguments: promo.id),
            );
          },
        ),
      );
    });
  }
}
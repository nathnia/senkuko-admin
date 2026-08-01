import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:senkukoadmin/constant/app_colors.dart';
import 'package:senkukoadmin/constant/app_error_state.dart';
import 'package:senkukoadmin/constant/app_filter_chips.dart';
import 'package:senkukoadmin/constant/app_searchbar.dart';
import 'package:senkukoadmin/constant/app_back_button.dart';
import 'package:senkukoadmin/features/banners/banner_card.dart';
import 'package:senkukoadmin/features/banners/banner_controller.dart';
import 'package:senkukoadmin/routes/routes.dart';

class BannerPage extends StatefulWidget {
  const BannerPage({super.key});

  @override
  State<BannerPage> createState() => _BannerPageState();
}

class _BannerPageState extends State<BannerPage> with WidgetsBindingObserver {
  final controller = Get.find<BannerController>();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    controller.fetchBanners();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Nutup celah: user minimize app lama, balik lagi — banner mungkin
    // udah basi (mis. ditambah/diedit dari device admin lain).
    if (state == AppLifecycleState.resumed) {
      controller.fetchBanners();
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
          'Banner',
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
              hintText: 'Cari judul banner...',
              onChanged: controller.updateSearch,
            ),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          controller.resetForAdd();
          Get.toNamed(AppRoutes.bannerForm);
        },
        backgroundColor: AppColors.primary,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: const Icon(Icons.add_photo_alternate_rounded, color: Colors.white),
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
                  controller.bannerList.isEmpty) {
                return const Center(child: CircularProgressIndicator());
              }
              if (controller.hasError.value) {
                return AppErrorState(
                  message: controller.errorMessage.value,
                  onRetry: controller.fetchBanners,
                );
              }
              final list = controller.filteredBanners;
              if (list.isEmpty) {
                return const Center(
                  child: Text(
                    'Tidak ada banner ditemukan',
                    style: TextStyle(color: Colors.grey),
                  ),
                );
              }
              return RefreshIndicator(
                color: AppColors.primary,
                onRefresh: controller.fetchBanners,
                child: ListView.builder(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 80),
                  itemCount: list.length,
                  itemBuilder: (context, index) {
                    final banner = list[index];
                    return BannerCard(
                      banner: banner,
                      onTap: () => Get.toNamed(
                        AppRoutes.bannerForm,
                        arguments: banner,
                      ),
                      onToggleStatus: () =>
                          controller.toggleBannerStatus(banner),
                      onDelete: () => controller.deleteBanner(banner),
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
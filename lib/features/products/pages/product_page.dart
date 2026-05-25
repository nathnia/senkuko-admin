import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:senkukoadmin/constant/app_colors.dart';
import 'package:senkukoadmin/constant/app_filter_chips.dart';
import 'package:senkukoadmin/constant/app_searchbar.dart';
import 'package:senkukoadmin/constant/app_back_button.dart';
import 'package:senkukoadmin/constant/app_active_filter_chip.dart';
import 'package:senkukoadmin/constant/app_filter_button.dart';
import 'package:senkukoadmin/constant/connectivity_service.dart';
import 'package:senkukoadmin/features/products/controllers/price_controller.dart';
import 'package:senkukoadmin/features/products/controllers/product_controller.dart';
import 'package:senkukoadmin/features/products/controllers/product_variant_controller.dart';
import 'package:senkukoadmin/features/products/widgets/category_bottom_sheet.dart';
import 'package:senkukoadmin/features/products/widgets/filter_bottom_sheet.dart';
import 'package:senkukoadmin/features/products/widgets/overflow_category_button.dart';
import 'package:senkukoadmin/features/products/widgets/product_card.dart';
import 'package:senkukoadmin/routes/routes.dart';

class ProductPage extends StatelessWidget {
  ProductPage({super.key}) {
    controller.resetPageState();
    connectivityService.onReconnect = () => controller.loadInitialData();
  }

  final controller = Get.find<ProductController>();
  final variantC = Get.find<ProductVariantController>();
  final priceC = Get.find<PriceController>();
  final connectivityService = Get.find<ConnectivityService>();

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
          'Produk',
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
            child: Row(
              children: [
                Expanded(
                  child: AppSearchBar(
                    hintText: 'Cari produk...',
                    onChanged: controller.updateSearch,
                  ),
                ),
                const SizedBox(width: 10),
                Obx(
                  () => AppFilterButton(
                    isActive: controller.hasActiveFilters,
                    onTap: () => showFilterSheet(context, controller),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      body: Column(
        children: [
          // ── Category chips ───────────────────────────────────────────────
          // ✅ Di ProductPage — tambah key berdasarkan jumlah tabs
          Obx(() {
            final tabs = controller.tabs;
            final visibleTabs = tabs.take(6).toList();
            final hasMore = tabs.length > 6;
            final overflowTabs = tabs.skip(6).toList();

            return Row(
              children: [
                Expanded(
                  child: AppFilterChips(
                    key: ValueKey(
                      tabs.length,
                    ), // ✅ paksa rebuild kalau jumlah berubah
                    items: visibleTabs
                        .map((t) => FilterChipItem(label: t))
                        .toList(),
                    selectedLabel: controller.selectedTab.value,
                    onChipTap: controller.changeTab,
                  ),
                ),
                if (hasMore)
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: OverflowCategoryButton(
                      overflowTabs: overflowTabs,
                      selectedTab: controller.selectedTab.value,
                      onTap: () => showCategorySheet(context, controller),
                    ),
                  ),
              ],
            );
          }),
          // ── Active filter chips ──────────────────────────────────────────
          Obx(() {
            final chips = <Widget>[];

            if (controller.selectedSort.value.isNotEmpty) {
              chips.add(
                AppActiveFilterChip(
                  label: 'Urutan: ${controller.sortLabel}',
                  onRemove: () => controller.selectedSort.value = '',
                ),
              );
            }
            if (controller.minPrice.value != null ||
                controller.maxPrice.value != null) {
              chips.add(
                AppActiveFilterChip(
                  label: 'Harga: ${controller.priceRangeLabel}',
                  onRemove: controller.clearPriceRange,
                ),
              );
            }
            if (controller.showLowStockOnly.value) {
              chips.add(
                AppActiveFilterChip(
                  label: 'Stok Menipis',
                  onRemove: () => controller.showLowStockOnly.value = false,
                ),
              );
            }
            if (controller.showOutOfStockOnly.value) {
              chips.add(
                AppActiveFilterChip(
                  label: 'Stok Habis',
                  onRemove: () => controller.showOutOfStockOnly.value = false,
                ),
              );
            }

            if (chips.isEmpty) return const SizedBox.shrink();

            return SizedBox(
              height: 36,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                children: chips,
              ),
            );
          }),

          // ── Product list ─────────────────────────────────────────────────
          // ✅ FIXED — product list section in ProductPage
          Expanded(
            child: Obx(() {
              if (controller.isLoading.value) {
                return const Center(child: CircularProgressIndicator());
              }

              // NEW: error + retry state
              if (controller.hasError.value) {
                return Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.cloud_off_rounded,
                        size: 48,
                        color: Colors.grey[300],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        controller.errorMessage.value,
                        style: TextStyle(
                          fontSize: 14,
                          color: AppColors.subtext,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton.icon(
                        onPressed: controller.loadInitialData,
                        icon: const Icon(Icons.refresh_rounded, size: 18),
                        label: const Text('Coba Lagi'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }

              final list = controller.getFilteredProducts;

              if (list.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.inventory_2_outlined,
                        size: 48,
                        color: Colors.grey[300],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Produk tidak ditemukan',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: AppColors.subtext,
                        ),
                      ),
                      if (controller.hasActiveFilters) ...[
                        const SizedBox(height: 8),
                        TextButton(
                          onPressed: controller.resetPageState,
                          child: const Text('Reset semua filter'),
                        ),
                      ],
                    ],
                  ),
                );
              }

              return RefreshIndicator(
                color: AppColors.primary,
                onRefresh: controller
                    .loadInitialData, // now unified, handles error state
                child: ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 80),
                  itemCount: list.length,
                  itemBuilder: (context, i) => ProductCard(product: list[i]),
                ),
              );
            }),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          controller.resetForAddProduct();
          variantC.initPriceControllers();
          Get.toNamed(AppRoutes.addProduct);
        },
        backgroundColor: AppColors.primary,
        elevation: 3,
        icon: const Icon(Icons.add_rounded, size: 20, color: Colors.white),
        label: const Text(
          'Tambah',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
      ),
    );
  }
}

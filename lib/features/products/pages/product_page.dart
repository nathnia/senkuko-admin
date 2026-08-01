import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:senkukoadmin/constant/app_colors.dart';
import 'package:senkukoadmin/constant/app_error_state.dart';
import 'package:senkukoadmin/constant/app_filter_chips.dart';
import 'package:senkukoadmin/constant/app_searchbar.dart';
import 'package:senkukoadmin/constant/app_back_button.dart';
import 'package:senkukoadmin/constant/app_active_filter_chip.dart';
import 'package:senkukoadmin/constant/app_filter_button.dart';
import 'package:senkukoadmin/constant/connectivity_service.dart';
import 'package:senkukoadmin/features/products/controllers/price_controller.dart';
import 'package:senkukoadmin/features/products/controllers/product_controller.dart';
import 'package:senkukoadmin/features/products/controllers/product_variant_controller.dart';
import 'package:senkukoadmin/features/products/widgets/filter_bottom_sheet.dart';
import 'package:senkukoadmin/features/products/widgets/product_card.dart';
import 'package:senkukoadmin/routes/routes.dart';

class ProductPage extends StatefulWidget {
  const ProductPage({super.key});

  @override
  State<ProductPage> createState() => _ProductPageState();
}

class _ProductPageState extends State<ProductPage> with WidgetsBindingObserver {
  final controller = Get.find<ProductController>();
  final variantC = Get.find<ProductVariantController>();
  final priceC = Get.find<PriceController>();
  final connectivityService = Get.find<ConnectivityService>();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    controller.resetPageState();
    // FIX: ProductController permanent (CoreBinding) — onInit() cuma jalan
    // sekali seumur app, jadi loadInitialData() HARUS dipanggil lagi di sini
    // tiap kali halaman ini dibuka. Sebelumnya cuma resetPageState() (reset
    // filter doang, gak fetch apa-apa) — akibatnya stok/harga yang berubah
    // dari halaman lain (mis. transaksi dibatalin) gak pernah kelihatan
    // sampai user pull-to-refresh manual. loadInitialData() aman dipanggil
    // berkali-kali (ada guard isLoading di fetchProducts/fetchAllVariants),
    // dan karena Pola B (cache-first-paint + selalu fetch fresh di
    // background), pemanggilan ini murah dan sesuai trade-off "sengaja gak
    // hemat demi fresh" yang emang niatnya.
    //
    // gak perlu addPostFrameCallback lagi — fetchProducts/fetchAllVariants/
    // fetchPrices sekarang dijamin selalu async (fix di level controller,
    // via `await Future.microtask(() {})` di jalur cache-hit), jadi aman
    // dipanggil langsung di initState() tanpa risiko crash build-phase.
    controller.loadInitialData();
    connectivityService.onReconnect = () => controller.loadInitialData();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    connectivityService.onReconnect = null;
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Nutup celah: user minimize app lama (misal abis approve/cancel
    // transaksi dari notifikasi), balik lagi ke app — stok/harga di
    // halaman ini mungkin udah basi walau route-nya gak pernah "dibuka
    // ulang" secara navigasi.
    if (state == AppLifecycleState.resumed) {
      controller.loadInitialData();
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
          'Produk',
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        centerTitle: true,
        // ── Import Excel — pill button in AppBar, clearly separated ────
        actions: [
          GestureDetector(
            onTap: () => Get.toNamed(AppRoutes.importProduct),
            child: Container(
              margin: const EdgeInsets.only(right: 16, top: 10, bottom: 10),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.successBg,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.upload_file_rounded,
                      size: 13, color: AppColors.primary),
                  const SizedBox(width: 4),
                  Text(
                    'Import',
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
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(40),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
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
          Obx(
            () => AppFilterChips(
              items: controller.tabs
                  .map((t) => FilterChipItem(label: t))
                  .toList(),
              selectedLabel: controller.selectedTab.value,
              onChipTap: controller.changeTab,
            ),
          ),
          _ActiveFilterChips(controller: controller),
          Expanded(
            child: Obx(() {
              // CHANGED: spinner cuma muncul kalau loading DAN belum ada data
              // sama sekali (first load tanpa cache). Kalau ada cache,
              // langsung tampil list-nya sambil fetch fresh jalan di
              // background.
              if (controller.isLoading.value &&
                  controller.productList.isEmpty) {
                return const Center(child: CircularProgressIndicator());
              }

              // CHANGED: kalau ada cache, tetap tampilin data lama daripada
              // full error screen — silent degrade buat kondisi koneksi
              // jelek toko kecil.
              if (controller.hasError.value &&
                  controller.productList.isEmpty) {
                return AppErrorState(
                  message: controller.errorMessage.value,
                  onRetry: controller.loadInitialData,
                );
              }

              final list = controller.getFilteredProducts;

              if (list.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.inventory_2_outlined,
                          size: 48, color: Colors.grey[300]),
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
                onRefresh: controller.loadInitialData,
                child: ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
                  itemCount: list.length,
                  itemBuilder: (context, i) => ProductCard(product: list[i]),
                ),
              );
            }),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.primary,
        onPressed: () {
          controller.resetForAddProduct();
          variantC.initPriceControllers();
          Get.toNamed(AppRoutes.addProduct);
        },
        child: const Icon(Icons.add_rounded, color: Colors.white)
      ),
    );
  }
}

// ── Active Filter Chips ────────────────────────────────────────────────────────

class _ActiveFilterChips extends StatelessWidget {
  final ProductController controller;
  const _ActiveFilterChips({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final chips = <Widget>[
        if (controller.selectedSort.value.isNotEmpty)
          AppActiveFilterChip(
            label: 'Urutan: ${controller.sortLabel}',
            onRemove: () => controller.selectedSort.value = '',
          ),
        if (controller.minPrice.value != null ||
            controller.maxPrice.value != null)
          AppActiveFilterChip(
            label: 'Harga: ${controller.priceRangeLabel}',
            onRemove: controller.clearPriceRange,
          ),
        if (controller.showLowStockOnly.value)
          AppActiveFilterChip(
            label: 'Stok Menipis',
            onRemove: () => controller.showLowStockOnly.value = false,
          ),
        if (controller.showOutOfStockOnly.value)
          AppActiveFilterChip(
            label: 'Stok Habis',
            onRemove: () => controller.showOutOfStockOnly.value = false,
          ),
      ];

      if (chips.isEmpty) return const SizedBox.shrink();

      return SizedBox(
        height: 36,
        child: ListView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          children: chips,
        ),
      );
    });
  }
}
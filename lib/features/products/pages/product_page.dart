import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:senkukoadmin/constant/app_colors.dart';
import 'package:senkukoadmin/constant/app_filter_chips.dart';
import 'package:senkukoadmin/constant/app_searchbar.dart';
import 'package:senkukoadmin/constant/app_back_button.dart';
import 'package:senkukoadmin/features/products/widgets/product_card.dart';
import 'package:senkukoadmin/features/products/controllers/product_controller.dart';
import 'package:senkukoadmin/routes/routes.dart';

class ProductPage extends StatelessWidget {
  ProductPage({super.key});

  final controller = Get.find<ProductController>();

  @override
  Widget build(BuildContext context) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      controller.resetPageState();
    });

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
        actions: const [],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(52),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
            child: AppSearchBar(
              hintText: 'Cari produk...',
              onChanged: controller.updateSearch,
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
          Expanded(
            child: Obx(() {
              if (controller.isLoading.value) {
                return const Center(child: CircularProgressIndicator());
              }

              final list = controller.filteredProducts;

              if (list.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Produk tidak ditemukan',
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
                onRefresh: () => controller.fetchProducts(),
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
        onPressed: () => Get.toNamed(AppRoutes.addProduct),
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

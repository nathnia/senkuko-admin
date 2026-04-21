import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:senkukoadmin/constant/app_colors.dart';
import 'package:senkukoadmin/features/products/product_card.dart';
import 'package:senkukoadmin/features/products/product_controller.dart';
import 'package:senkukoadmin/routes/routes.dart';


class ProductPage extends StatelessWidget {
  ProductPage({super.key});

  final controller = Get.find<ProductController>();
  final TextEditingController searchController = TextEditingController();
  final RxString selectedTab = "Semua".obs;

  final List<String> tabs = ["Semua", "Aktif", "Non-Aktif"];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text("Produk"),
        backgroundColor: AppColors.background,
        elevation: 0,
      ),
      body: Column(
        children: [
          _searchBar(),
          _tabBar(),
          Expanded(
            child: Obx(() {
              if (controller.isLoading.value) {
                return const Center(child: CircularProgressIndicator());
              }

              var list = controller.productList.where((p) {
                final matchSearch = p.name.toLowerCase().contains(searchController.text.toLowerCase());
                final matchTab = selectedTab.value == "Semua" || 
                                (selectedTab.value == "Aktif" && p.isActive == 1) ||
                                (selectedTab.value == "Non-Aktif" && p.isActive == 0);
                return matchSearch && matchTab;
              }).toList();

              if (list.isEmpty) return const Center(child: Text("Produk tidak ditemukan"));

              return RefreshIndicator(
                onRefresh: () => controller.fetchProducts(),
                child: ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: list.length,
                  itemBuilder: (context, i) => ProductCard(product: list[i]),
                ),
              );
            }),
          ),
        ],
      ),
      floatingActionButton: _fab(),
    );
  }

  Widget _searchBar() {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: TextField(
        controller: searchController,
        onChanged: (value) => controller.productList.refresh(), // trigger obx
        decoration: InputDecoration(
          hintText: "Cari produk...",
          prefixIcon: const Icon(Icons.search),
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
        ),
      ),
    );
  }

  Widget _tabBar() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: tabs.map((t) => Obx(() {
          final isActive = selectedTab.value == t;
          return GestureDetector(
            onTap: () => selectedTab.value = t,
            child: Container(
              margin: const EdgeInsets.only(left: 12, right: 8),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: isActive ? AppColors.primary : Colors.white,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(t, style: TextStyle(color: isActive ? Colors.white : Colors.black)),
            ),
          );
        })).toList(),
      ),
    );
  }

  Widget _fab() {
    return FloatingActionButton.extended(
      onPressed: () => Get.toNamed(AppRoutes.addProduct),
      backgroundColor: AppColors.primary,
      icon: const Icon(Icons.add, color: Colors.white),
      label: const Text("Tambah Produk", style: TextStyle(color: Colors.white)),
    );
  }
}
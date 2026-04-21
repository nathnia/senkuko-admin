import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:senkukoadmin/constant/app_colors.dart';
import 'package:senkukoadmin/features/products/models/product_model.dart';
import 'package:senkukoadmin/features/products/product_controller.dart';
import 'package:senkukoadmin/routes/routes.dart';

class DetailProductPage extends StatelessWidget {
  DetailProductPage({super.key});

  final controller = Get.find<ProductController>();

  @override
  Widget build(BuildContext context) {
    final String? productId = Get.arguments as String?;

    if (productId == null || productId.isEmpty) {
      return const Scaffold(
        body: Center(child: Text("ID Produk tidak valid")),
      );
    }

    // Load data setelah halaman dibangun
    WidgetsBinding.instance.addPostFrameCallback((_) {
      controller.loadProductDetail(productId);
    });

    return Obx(() {
      final product = controller.selectedProduct.value;
      final variants = controller.productVariants;
      final isLoading = controller.isLoadingDetail.value;

      if (isLoading) {
        return const Scaffold(
          body: Center(child: CircularProgressIndicator()),
        );
      }

      if (product == null) {
        return Scaffold(
          appBar: AppBar(title: const Text("Detail Produk")),
          body: const Center(child: Text("Produk tidak ditemukan")),
        );
      }

      return Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          title: Text(product.name),
          backgroundColor: AppColors.background,
          actions: [
            // Tombol Edit
            IconButton(
              icon: const Icon(Icons.edit, color: Colors.blue),
              tooltip: "Edit Produk",
              onPressed: () {
                Get.toNamed(
                  AppRoutes.editProduct,
                  arguments: product.id,
                );
              },
            ),
            // Tombol Hapus
        
          ],
        ),
        body: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(16),
              color: Colors.white,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      width: 90,
                      height: 90,
                      color: Colors.grey.shade200,
                      child: const Icon(Icons.image_rounded, size: 40),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          product.name,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(product.categoryName),
                        const SizedBox(height: 8),
                        _buildStatus(product),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            if ((product.description ?? '').isNotEmpty)
              Padding(
                padding: const EdgeInsets.all(16),
                child: Text(product.description!),
              ),

            Expanded(
              child: variants.isEmpty
                  ? const Center(child: Text("Tidak ada varian"))
                  : ListView.builder(
                      padding: const EdgeInsets.all(12),
                      itemCount: variants.length,
                      itemBuilder: (_, i) {
                        final v = variants[i];
                        final prices = controller.getPricesByVariant(v.id);

                        return Container(
                          margin: const EdgeInsets.only(bottom: 10),
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                v.name,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text("Stok: ${v.stockQty} ${v.unitSymbol ?? 'unit'}"),
                              const SizedBox(height: 12),
                              if (prices.isEmpty)
                                const Text(
                                  "Belum ada harga",
                                  style: TextStyle(color: Colors.grey),
                                )
                              else
                                ...prices.map((p) => Padding(
                                      padding: const EdgeInsets.only(bottom: 4),
                                      child: Text(
                                        "• ${p.priceListName}: Rp ${p.price}",
                                      ),
                                    )),
                            ],
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      );
    });
  }

  Widget _buildStatus(ProductData product) {
    final isActive = product.isActive == 1;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: isActive 
            ? AppColors.primary.withAlpha(20) 
            : Colors.grey.shade200,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        isActive ? "AKTIF" : "TIDAK AKTIF",
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: isActive ? AppColors.primary : Colors.grey.shade700,
        ),
      ),
    );
  }
}
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:senkukoadmin/constant/app_colors.dart';
import 'package:senkukoadmin/features/products/models/product_model.dart';
import 'package:senkukoadmin/features/products/product_controller.dart';
import 'package:senkukoadmin/routes/routes.dart';

class ProductCard extends StatelessWidget {
  final ProductData product;

  const ProductCard({super.key, required this.product});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<ProductController>();

    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: () {
        print("NAVIGATE TO DETAIL WITH ID: ${product.id}");
        Get.toNamed(AppRoutes.detailProduct, arguments: product.id);
      },
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 7),
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(10),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Stack(
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Image
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: Container(
                    width: 80,
                    height: 80,
                    color: Colors.grey[200],
                    child: const Icon(
                      Icons.image_rounded,
                      color: Colors.grey,
                      size: 28,
                    ),
                  ),
                ),

                const SizedBox(width: 12),

                // Content
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Nama + Status
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              product.name,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                                color: Color(0xFF2D3436),
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          _buildStatusBadge(),
                        ],
                      ),

                      const SizedBox(height: 2),

                      // Category
                      Text(
                        product.categoryName,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                      ),

                      const SizedBox(height: 8),

                      // ================== PRICE SECTION (CLEAN) ==================
                      Obx(() {
                        final price = controller.getMainPriceForProduct(
                          product,
                        );
                        final additional = controller
                            .getAdditionalPriceCountForProduct(product);

                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Rp ${double.tryParse(price)?.toInt() ?? 0}",
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w900,
                                color: AppColors.primary,
                              ),
                            ),
                            if (additional > 0)
                              Text(
                                "+$additional harga lainnya",
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.grey.shade500,
                                ),
                              ),
                          ],
                        );
                      }),
                    ],
                  ),
                ),
              ],
            ),

            // Menu
            Positioned(right: 0, bottom: 0, child: _buildMenu(product)),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusBadge() {
    final isActive = product.isActive == 1;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: isActive
            ? AppColors.primary.withAlpha(20)
            : Colors.grey.shade200,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        isActive ? "AKTIF" : "DRAFT",
        style: TextStyle(
          fontSize: 10,
          color: isActive ? AppColors.primary : Colors.grey.shade700,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  Widget _buildMenu(ProductData product) {
    return PopupMenuButton<String>(
      onSelected: (value) async {
        if (value == "edit") {
          Get.toNamed(AppRoutes.editProduct, arguments: product.id);
        } else if (value == "variant") {
          Get.snackbar("Info", "Kelola Stok belum tersedia");
        } else if (value == "delete") {
          debugPrint(
            "🗑 Tombol delete diklik untuk produk: ${product.name} (${product.id})",
          );
          final controller = Get.find<ProductController>();
          await controller.deleteProduct(product.id, product.name);
        }
      },
      itemBuilder: (context) => [
        const PopupMenuItem(value: "edit", child: Text("Edit Produk")),
        const PopupMenuItem(value: "variant", child: Text("Kelola Stok")),
        PopupMenuItem(
          value: "delete",
          child: Row(
            children: const [
              Icon(Icons.delete, color: Colors.red, size: 20),
              SizedBox(width: 8),
              Text("Hapus Produk", style: TextStyle(color: Colors.red)),
            ],
          ),
        ),
      ],
    );
  }

}

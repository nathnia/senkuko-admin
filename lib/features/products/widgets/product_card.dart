import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:senkukoadmin/constant/app_colors.dart';
import 'package:senkukoadmin/constant/currency_formatter.dart';
import 'package:senkukoadmin/features/products/controllers/product_image_controller.dart';
import 'package:senkukoadmin/features/products/controllers/product_variant_controller.dart';
import 'package:senkukoadmin/features/products/models/product_model.dart';
import 'package:senkukoadmin/features/products/controllers/product_controller.dart';
import 'package:senkukoadmin/routes/routes.dart';

class ProductCard extends StatelessWidget {
  final ProductData product;

  const ProductCard({super.key, required this.product});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<ProductController>();
    final variantC = Get.find<ProductVariantController>();
    final imageC = Get.find<ProductImageController>();

    // Hitung jumlah varian & total stok dari priceList
    final relatedPrices = variantC.priceList.where((p) {
      final variantName = p.productVariantName.toLowerCase();
      final productName = product.name.toLowerCase();
      return variantName.contains(productName) ||
          productName.contains(variantName.split(' ').first);
    });

    final variantIds = relatedPrices.map((p) => p.productVariantId).toSet();
    final variantCount = variantIds.length;

    return GestureDetector(
      onTap: () => Get.toNamed(AppRoutes.detailProduct, arguments: product.id),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.grey.shade100, width: 0.5),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Gambar ──
            Obx(() {
              final images = imageC.getImagesForProduct(product.id);
              return ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: images.isEmpty
                    ? Container(
                        width: 80,
                        height: 80,
                        color: Colors.grey.shade100,
                        child: Icon(Icons.image_outlined, color: Colors.grey.shade400, size: 24),
                      )
                    : Image.network(
                        images.first.imageUrl,
                        width: 80,
                        height: 80,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(
                          width: 80,
                          height: 80,
                          color: Colors.grey.shade100,
                          child: Icon(Icons.broken_image_outlined, color: Colors.grey.shade400, size: 24),
                        ),
                      ),
              );
            }),

            const SizedBox(width: 12),

            // ── Info ──
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Nama
                  Text(
                    product.name,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                      color: Colors.black87,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 3),

                  // Kategori · varian
                  Row(
                    children: [
                      Icon(Icons.category_outlined, size: 11, color: Colors.grey.shade400),
                      const SizedBox(width: 3),
                      Flexible(
                        child: Text(
                          product.categoryName,
                          style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (variantCount > 0) ...[
                        Text('  ·  ', style: TextStyle(color: Colors.grey.shade300, fontSize: 12)),
                        Icon(Icons.layers_outlined, size: 11, color: Colors.grey.shade400),
                        const SizedBox(width: 3),
                        Text(
                          '$variantCount varian',
                          style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 8),

                  // Harga
                  Obx(() {
                    final price = controller.getMainPriceForProduct(product);
                    final additional = controller.getAdditionalPriceCountForProduct(product);
                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          CurrencyFormatter.format(price),
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: AppColors.primary,
                          ),
                        ),
                        if (additional > 0) ...[
                          const SizedBox(width: 6),
                          Padding(
                            padding: const EdgeInsets.only(bottom: 1),
                            child: Text(
                              '+$additional lainnya',
                              style: TextStyle(fontSize: 11, color: Colors.grey.shade400),
                            ),
                          ),
                        ],
                      ],
                    );
                  }),
                ],
              ),
            ),

            // ── Menu ──
            PopupMenuButton<String>(
              onSelected: (value) {
                if (value == 'edit') {
                  Get.toNamed(AppRoutes.editProduct, arguments: product.id);
                } else if (value == 'delete') {
                  controller.deleteProduct(product.id, product.name);
                }
              },
              icon: Icon(Icons.more_vert_rounded, size: 18, color: Colors.grey.shade400),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              elevation: 2,
              itemBuilder: (context) => [
                PopupMenuItem(
                  value: 'edit',
                  child: Row(
                    children: [
                      Icon(Icons.edit_rounded, size: 16, color: Colors.grey.shade700),
                      const SizedBox(width: 10),
                      const Text('Edit', style: TextStyle(fontSize: 13)),
                    ],
                  ),
                ),
                PopupMenuItem(
                  value: 'delete',
                  child: Row(
                    children: [
                      Icon(Icons.delete_outline_rounded, size: 16, color: Colors.red.shade400),
                      const SizedBox(width: 10),
                      Text('Hapus', style: TextStyle(fontSize: 13, color: Colors.red.shade400)),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
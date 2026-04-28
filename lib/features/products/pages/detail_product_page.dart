import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:senkukoadmin/constant/app_colors.dart';
import 'package:senkukoadmin/constant/currency_formatter.dart';
import 'package:senkukoadmin/features/products/controllers/product_image_controller.dart';
import 'package:senkukoadmin/features/products/controllers/product_variant_controller.dart';
import 'package:senkukoadmin/features/products/models/product_model.dart';
import 'package:senkukoadmin/features/products/controllers/product_controller.dart';
import 'package:senkukoadmin/routes/routes.dart';

class DetailProductPage extends StatelessWidget {
  DetailProductPage({super.key});

  final controller = Get.find<ProductController>();
  final variantC = Get.find<ProductVariantController>();
  final imageC = Get.find<ProductImageController>();

  @override
  Widget build(BuildContext context) {
    final String? productId = Get.arguments as String?;

    if (productId == null || productId.isEmpty) {
      return const Scaffold(body: Center(child: Text("ID Produk tidak valid")));
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      controller.loadProductDetail(productId);
      imageC.fetchProductImages(productId);
    });

    return Obx(() {
      final product = controller.selectedProduct.value;
      final variants = variantC.productVariants;
      final isLoading = controller.isLoadingDetail.value;

      if (isLoading) {
        return const Scaffold(body: Center(child: CircularProgressIndicator()));
      }

      if (product == null) {
        return const Scaffold(
          body: Center(child: Text("Produk tidak ditemukan")),
        );
      }

      return Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          backgroundColor: AppColors.background,
          elevation: 0,
          scrolledUnderElevation: 0,
          leading: GestureDetector(
            onTap: () => Get.back(),
            child: Container(
              margin: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: const Icon(Icons.arrow_back_ios_new_rounded, size: 14, color: Colors.black87),
            ),
          ),
          title: const Text(
            'Detail Produk',
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Colors.black87),
          ),
          centerTitle: true,
          actions: [
            GestureDetector(
              onTap: () => Get.toNamed(AppRoutes.editProduct, arguments: product.id),
              child: Container(
                margin: const EdgeInsets.only(right: 16, top: 10, bottom: 10),
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.edit_rounded, size: 13, color: Colors.white),
                    SizedBox(width: 4),
                    Text('Edit', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.white)),
                  ],
                ),
              ),
            ),
          ],
        ),
        body: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ================== GAMBAR PRODUK ==================
              Obx(() {
                final images = imageC.getImagesForProduct(product.id);
                return Container(
                  margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                  height: 220,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.grey.shade100),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: images.isEmpty
                        ? Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                width: 56,
                                height: 56,
                                decoration: BoxDecoration(
                                  color: Colors.grey.shade100,
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                child: Icon(Icons.image_outlined, size: 26, color: Colors.grey.shade400),
                              ),
                              const SizedBox(height: 8),
                              Text('Belum ada foto', style: TextStyle(fontSize: 12, color: Colors.grey.shade400)),
                            ],
                          )
                        : Image.network(
                            images.first.imageUrl,
                            fit: BoxFit.cover,
                            width: double.infinity,
                            errorBuilder: (_, __, ___) => Center(
                              child: Icon(Icons.broken_image_outlined, size: 32, color: Colors.grey.shade300),
                            ),
                          ),
                  ),
                );
              }),

              // ================== NAMA + STATUS ==================
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: Colors.grey.shade100),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Text(
                              product.name,
                              style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: Colors.black87, height: 1.3),
                            ),
                          ),
                          const SizedBox(width: 8),
                          _buildStatusBadge(product),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Icon(Icons.category_outlined, size: 13, color: Colors.grey.shade500),
                          const SizedBox(width: 4),
                          Text(product.categoryName, style: TextStyle(fontSize: 13, color: Colors.grey.shade600)),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              // ================== INFORMASI PRODUK ==================
              if (product.skuCode.isNotEmpty || (product.barcode?.isNotEmpty ?? false))
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: Colors.grey.shade100),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _sectionLabel('Informasi Produk'),
                        const SizedBox(height: 12),
                        if (product.skuCode.isNotEmpty)
                          _infoRow(Icons.qr_code_rounded, 'SKU', product.skuCode),
                        if (product.barcode?.isNotEmpty ?? false) ...[
                          const SizedBox(height: 10),
                          _infoRow(Icons.barcode_reader, 'Barcode', product.barcode!),
                        ],
                      ],
                    ),
                  ),
                ),

              // ================== DESKRIPSI ==================
              if ((product.description ?? '').isNotEmpty)
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: Colors.grey.shade100),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _sectionLabel('Deskripsi'),
                        const SizedBox(height: 10),
                        Text(
                          product.description!,
                          style: TextStyle(fontSize: 13, color: Colors.grey.shade700, height: 1.6),
                        ),
                      ],
                    ),
                  ),
                ),

              // ================== VARIANT ==================
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: Colors.grey.shade100),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _sectionLabel('Varian Produk'),
                      const SizedBox(height: 12),
                      if (variants.isEmpty)
                        Center(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 20),
                            child: Text('Tidak ada varian', style: TextStyle(color: Colors.grey.shade400, fontSize: 13)),
                          ),
                        )
                      else
                        ...variants.map((v) {
                          final prices = variantC.getPricesByVariant(v.id);
                          return Container(
                            margin: const EdgeInsets.only(bottom: 10),
                            decoration: BoxDecoration(
                              color: AppColors.background,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.grey.shade100),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Header variant
                                Padding(
                                  padding: const EdgeInsets.all(12),
                                  child: Row(
                                    children: [
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(v.name, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.black87)),
                                            const SizedBox(height: 2),
                                            Text(
                                              'Stok: ${v.stockQty} ${v.unitSymbol ?? 'unit'}',
                                              style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                                            ),
                                          ],
                                        ),
                                      ),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: v.stockQty > 0
                                              ? AppColors.primary.withAlpha(15)
                                              : Colors.red.shade50,
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: Text(
                                          v.stockQty > 0 ? '${v.stockQty} tersedia' : 'Habis',
                                          style: TextStyle(
                                            fontSize: 11,
                                            fontWeight: FontWeight.w600,
                                            color: v.stockQty > 0 ? AppColors.primary : Colors.red.shade400,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                // Harga
                                if (prices.isNotEmpty) ...[
                                  Divider(height: 1, thickness: 0.5, color: Colors.grey.shade200),
                                  Padding(
                                    padding: const EdgeInsets.all(12),
                                    child: Column(
                                      children: prices.map((p) => Padding(
                                        padding: const EdgeInsets.only(bottom: 6),
                                        child: Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: [
                                            Text(p.priceListName, style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                                            Text(
                                              CurrencyFormatter.format(p.price),
                                              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.primary),
                                            ),
                                          ],
                                        ),
                                      )).toList(),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          );
                        }),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    });
  }

  Widget _sectionLabel(String text) {
    return Text(
      text,
      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Colors.black54, letterSpacing: 0.3),
    );
  }

  Widget _infoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 14, color: Colors.grey.shade400),
        const SizedBox(width: 8),
        Text(label, style: TextStyle(fontSize: 13, color: Colors.grey.shade500)),
        const Spacer(),
        Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.black87)),
      ],
    );
  }

  Widget _buildStatusBadge(ProductData product) {
    final isActive = product.isActive == 1;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: isActive ? AppColors.primary.withAlpha(15) : Colors.grey.shade100,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        isActive ? 'Aktif' : 'Draft',
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: isActive ? AppColors.primary : Colors.grey.shade600,
        ),
      ),
    );
  }
}
// lib/features/products/pages/detail_product_page.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:senkukoadmin/constant/app_colors.dart';
import 'package:senkukoadmin/features/products/controllers/product_controller.dart';
import 'package:senkukoadmin/features/products/controllers/product_image_controller.dart';
import 'package:senkukoadmin/features/products/controllers/product_variant_controller.dart';
import 'package:senkukoadmin/features/products/widgets/app_card.dart';
import 'package:senkukoadmin/constant/app_back_button.dart';
import 'package:senkukoadmin/features/products/widgets/variant_item_card.dart';
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
      imageC.carouselIndex.value = 0;
    });

    return Obx(() {
      final product = controller.selectedProduct.value;
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
          leading: const AppBackButton(),
          title: const Text(
            'Detail Produk',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
          centerTitle: true,
          actions: [
            GestureDetector(
              onTap: () =>
                  Get.toNamed(AppRoutes.editProduct, arguments: product.id),
              child: Container(
                margin: const EdgeInsets.only(right: 16, top: 10, bottom: 10),
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.edit_rounded, size: 13, color: Colors.white),
                    SizedBox(width: 4),
                    Text(
                      'Edit',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
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
              _productImage(product.id),
              _nameCard(product),
              _infoCard(product),
              _descriptionCard(product),
              _variantsCard(),
            ],
          ),
        ),
      );
    });
  }

  // ── Product Image ──
  Widget _productImage(String productId) {
    return Obx(() {
      final images = imageC.getImagesForProduct(productId);

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
                      child: Icon(
                        Icons.image_outlined,
                        size: 26,
                        color: Colors.grey.shade400,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Belum ada foto',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade400,
                      ),
                    ),
                  ],
                )
              : Stack(
                  children: [
                    PageView.builder(
                      controller: imageC.carouselController,
                      itemCount: images.length,
                      onPageChanged: (i) => imageC.carouselIndex.value = i,
                      itemBuilder: (_, i) => Image.network(
                        images[i].imageUrl,
                        fit: BoxFit.cover,
                        width: double.infinity,
                        errorBuilder: (_, __, ___) => Center(
                          child: Icon(
                            Icons.broken_image_outlined,
                            size: 32,
                            color: Colors.grey.shade300,
                          ),
                        ),
                      ),
                    ),
                    if (images.length > 1) ...[
                      // counter badge pojok kanan atas
                      Positioned(
                        top: 10,
                        right: 10,
                        child: Obx(
                          () => Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.black.withAlpha(45),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              '${imageC.carouselIndex.value + 1} / ${images.length}',
                              style: const TextStyle(
                                fontSize: 11,
                                color: Colors.white,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ),
                      ),
                      // dot indicator bawah tengah
                      Positioned(
                        bottom: 10,
                        left: 0,
                        right: 0,
                        child: Obx(
                          () => Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: List.generate(images.length, (i) {
                              final isActive = i == imageC.carouselIndex.value;
                              return AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                margin: const EdgeInsets.symmetric(
                                  horizontal: 3,
                                ),
                                width: isActive ? 16 : 6,
                                height: 6,
                                decoration: BoxDecoration(
                                  color: isActive
                                      ? Colors.white
                                      : Colors.white.withAlpha(50),
                                  borderRadius: BorderRadius.circular(3),
                                ),
                              );
                            }),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
        ),
      );
    });
  }

  // ── Name + Category ──
  Widget _nameCard(dynamic product) {
    return AppCard(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            product.name,
            style: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w700,
              color: Colors.black87,
              height: 1.3,
            ),
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Icon(
                Icons.category_outlined,
                size: 13,
                color: Colors.grey.shade500,
              ),
              const SizedBox(width: 4),
              Text(
                product.categoryName,
                style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── SKU / Barcode ──
  Widget _infoCard(dynamic product) {
    final hasSku = (product.skuCode ?? '').isNotEmpty;
    final hasBarcode = (product.barcode ?? '').isNotEmpty;
    if (!hasSku && !hasBarcode) return const SizedBox.shrink();

    return AppCard(
      title: 'Informasi Produk',
      margin: const EdgeInsets.fromLTRB(16, 10, 16, 0),
      child: Column(
        children: [
          if (hasSku) _infoRow(Icons.qr_code_rounded, 'SKU', product.skuCode),
          if (hasSku && hasBarcode) const SizedBox(height: 10),
          if (hasBarcode)
            _infoRow(Icons.barcode_reader, 'Barcode', product.barcode!),
        ],
      ),
    );
  }

  // ── Description ──
  Widget _descriptionCard(dynamic product) {
    if ((product.description ?? '').isEmpty) return const SizedBox.shrink();

    return AppCard(
      title: 'Deskripsi',
      margin: const EdgeInsets.fromLTRB(16, 10, 16, 0),
      child: Text(
        product.description!,
        style: TextStyle(
          fontSize: 13,
          color: Colors.grey.shade700,
          height: 1.6,
        ),
      ),
    );
  }

  // ── Variants ──
  Widget _variantsCard() {
    return Obx(() {
      final variants = variantC.detailVariantMaps;

      return AppCard(
        title: 'Varian Produk',
        margin: const EdgeInsets.fromLTRB(16, 10, 16, 16),
        child: variants.isEmpty
            ? Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  child: Text(
                    'Tidak ada varian',
                    style: TextStyle(color: Colors.grey.shade400, fontSize: 13),
                  ),
                ),
              )
            : Column(
                children: variants.asMap().entries.map((entry) {
                  return VariantItemCard(
                    variant: entry.value,
                    mode: VariantCardMode.detail,
                    index: entry.key,
                  );
                }).toList(),
              ),
      );
    });
  }

  Widget _infoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 14, color: Colors.grey.shade400),
        const SizedBox(width: 8),
        Text(
          label,
          style: TextStyle(fontSize: 13, color: Colors.grey.shade500),
        ),
        const Spacer(),
        Text(
          value,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
      ],
    );
  }
}

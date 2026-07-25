import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:senkukoadmin/constant/app_colors.dart';
import 'package:senkukoadmin/constant/currency_formatter.dart';
import 'package:senkukoadmin/features/products/controllers/product_image_controller.dart';
import 'package:senkukoadmin/features/products/controllers/product_variant_controller.dart';
import 'package:senkukoadmin/features/products/models/product_model.dart';
import 'package:senkukoadmin/routes/routes.dart';

class ProductCard extends StatelessWidget {
  final ProductData product;

  // Get.find di field level — bukan di build()
  final _variantC = Get.find<ProductVariantController>();
  final _imageC = Get.find<ProductImageController>();

  ProductCard({super.key, required this.product});

  @override
  Widget build(BuildContext context) {
    // Obx ini HANYA observe variantC — tidak menyentuh imageC sama sekali
    // _ProductImage punya Obx sendiri untuk imageC
    return Obx(() {
      final summary = _variantC.getSummaryForProduct(product.id);
      final variantCount = _variantC.allVariants
          .where((v) => v.productId == product.id)
          .length;

      return Opacity(
        opacity: summary.isOutOfStock ? 0.45 : 1.0,
        child: GestureDetector(
          onTap: () =>
              Get.toNamed(AppRoutes.detailProduct, arguments: product.id),
          child: Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.grey.shade100, width: 0.5),
            ),
            child: IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _ProductImage(productId: product.id, imageC: _imageC),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _ProductInfo(
                      product: product,
                      summary: summary,
                      variantCount: variantCount,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    });
  }
}

// ── Product image — Obx sendiri, hanya rebuild saat imageC berubah ────────────
class _ProductImage extends StatelessWidget {
  final String productId;
  final ProductImageController imageC;

  const _ProductImage({required this.productId, required this.imageC});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final images = imageC.getImagesForProduct(productId);
      return ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: images.isEmpty
            ? Container(
                width: 90,
                color: Colors.grey.shade100,
                child: Icon(
                  Icons.image_outlined,
                  color: Colors.grey.shade400,
                  size: 22,
                ),
              )
            : Image.network(
                images.first.imageUrl,
                width: 90,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  width: 90,
                  color: Colors.grey.shade100,
                  child: Icon(
                    Icons.broken_image_outlined,
                    color: Colors.grey.shade400,
                    size: 22,
                  ),
                ),
              ),
      );
    });
  }
}

// ── Product info — pure display, tidak ada Obx di sini ───────────────────────
class _ProductInfo extends StatelessWidget {
  final ProductData product;
  final ProductSummary summary;
  final int variantCount;

  const _ProductInfo({
    required this.product,
    required this.summary,
    required this.variantCount,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    product.name,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                      color: Colors.black87,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                GestureDetector(
                  onTap: () => Get.toNamed(
                    AppRoutes.editProduct,
                    arguments: product.id,
                  ),
                  child: Padding(
                    padding: const EdgeInsets.only(left: 8),
                    child: Icon(
                      Icons.edit_outlined,
                      size: 16,
                      color: Colors.grey.shade400,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 2),
            Text(
              product.categoryName,
              style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text(
                  CurrencyFormatter.format(summary.mainPriceValue),
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primary,
                  ),
                ),
                if (summary.additionalPriceCount > 0) ...[
                  const SizedBox(width: 6),
                  Text(
                    '+${summary.additionalPriceCount} harga lain',
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
        if (variantCount > 0)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Wrap(
              spacing: 6,
              runSpacing: 4,
              children: [
                _Badge(
                  icon: Icons.layers_outlined,
                  label: '$variantCount varian',
                  type: _BadgeType.neutral,
                ),
                _StockBadge(
                  stock: summary.totalStock,
                  crisisStock: summary.crisisStockThreshold,
                ),
              ],
            ),
          ),
      ],
    );
  }
}

// ── Badge ─────────────────────────────────────────────────────────────────────

enum _BadgeType { neutral, success, warning, danger }

class _Badge extends StatelessWidget {
  final IconData icon;
  final String label;
  final _BadgeType type;

  const _Badge({required this.icon, required this.label, required this.type});

  @override
  Widget build(BuildContext context) {
    final Color bg;
    final Color fg;

    switch (type) {
      case _BadgeType.success:
        bg = AppColors.successBg;
        fg = AppColors.success;
        break;
      case _BadgeType.warning:
        bg = AppColors.warningBg;
        fg = AppColors.warning;
        break;
      case _BadgeType.danger:
        bg = AppColors.dangerBg;
        fg = AppColors.danger;
        break;
      case _BadgeType.neutral:
        bg = Colors.grey.shade100;
        fg = Colors.grey.shade600;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 11, color: fg),
          const SizedBox(width: 3),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: fg,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Stock badge — pakai crisis_stock dari backend, bukan angka hardcode.
// Kalau crisis_stock belum di-set (0 / tidak ada di backend), badge cuma
// bedain "habis" vs "ada stok" — gak nebak-nebak ambang batas sendiri.
class _StockBadge extends StatelessWidget {
  final int stock;
  final int crisisStock;

  const _StockBadge({required this.stock, required this.crisisStock});

  @override
  Widget build(BuildContext context) {
    if (stock == 0) {
      return const _Badge(
        icon: Icons.error_outline_rounded,
        label: 'Stok habis',
        type: _BadgeType.danger,
      );
    }
    if (crisisStock > 0 && stock <= crisisStock) {
      return _Badge(
        icon: Icons.warning_amber_rounded,
        label: '$stock stok',
        type: _BadgeType.warning,
      );
    }
    return _Badge(
      icon: Icons.inventory_2_outlined,
      label: '$stock stok',
      type: _BadgeType.success,
    );
  }
}
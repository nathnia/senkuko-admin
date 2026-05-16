import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:senkukoadmin/constant/app_colors.dart';
import 'package:senkukoadmin/constant/currency_formatter.dart';
import 'package:senkukoadmin/features/products/controllers/product_variant_controller.dart';

enum VariantCardMode { add, edit, detail }

class VariantItemCard extends StatelessWidget {
  final Map<String, dynamic> variant;
  final VariantCardMode mode;
  final int index;
  final VoidCallback? onDelete;
  final VoidCallback? onEdit;

  const VariantItemCard({
    super.key,
    required this.variant,
    required this.mode,
    required this.index,
    this.onDelete,
    this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    final variantC = Get.find<ProductVariantController>();

    // Pakai yang sorted biar konsisten
    final prices = variantC.getFormattedPricesSorted(variant);

    final name = variant['name']?.toString() ?? '';
    final stockQty = variant['stock_qty']?.toString() ?? '0';
    final unitName = variant['unit_name']?.toString() ?? '';
    final barcode = variant['barcode']?.toString() ?? '';

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 3),
                      _infoRow(
                        icon: Icons.inventory_2_outlined,
                        text: 'Stok: $stockQty $unitName',
                      ),
                      if (barcode.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        _infoRow(icon: Icons.barcode_reader, text: barcode),
                      ],
                    ],
                  ),
                ),

                if (onEdit != null || onDelete != null)
                  Row(
                    children: [
                      if (onEdit != null) ...[
                        _actionButton(
                          icon: Icons.edit_rounded,
                          color: AppColors.primary,
                          bgColor: AppColors.primary.withAlpha(15),
                          onTap: onEdit!,
                        ),
                        const SizedBox(width: 6),
                      ],
                      if (onDelete != null)
                        _actionButton(
                          icon: Icons.delete_outline_rounded,
                          color: Colors.red.shade400,
                          bgColor: Colors.red.shade50,
                          onTap: onDelete!,
                        ),
                    ],
                  ),
              ],
            ),
          ),

          // Harga Section
          if (prices.isNotEmpty) ...[
            Divider(height: 1, thickness: 0.5, color: Colors.grey.shade200),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                children: prices.map((p) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          p['price_list_name'],
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                          ),
                        ),
                        Text(
                          CurrencyFormatter.format(p['price']),
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: AppColors.primary,
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _infoRow({required IconData icon, required String text}) {
    return Row(
      children: [
        Icon(icon, size: 11, color: Colors.grey.shade400),
        const SizedBox(width: 3),
        Text(text, style: TextStyle(fontSize: 12, color: Colors.grey.shade500)),
      ],
    );
  }

  Widget _actionButton({
    required IconData icon,
    required Color color,
    required Color bgColor,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, size: 15, color: color),
      ),
    );
  }
}

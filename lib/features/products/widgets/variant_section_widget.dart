// lib/features/products/widgets/variant_section.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:senkukoadmin/constant/app_colors.dart';
import 'package:senkukoadmin/features/products/controllers/product_variant_controller.dart';
import 'package:senkukoadmin/constant/app_card.dart';
import 'package:senkukoadmin/features/products/widgets/variant_item_card.dart';
import 'package:senkukoadmin/routes/routes.dart';

class VariantSection extends StatelessWidget {
  final bool isEditMode;

  const VariantSection({super.key, required this.isEditMode});

  @override
  Widget build(BuildContext context) {
    return AppCard(
      title: 'VARIAN',
      child: Column(
        children: [
          // Edit mode: list dulu, add row di bawah
          // Add mode: add row dulu, list di bawah
          if (isEditMode) ...[
            _VariantList(isEditMode: true),
            const SizedBox(height: 8),
          ],
          _AddVariantRow(isEditMode: isEditMode),
          if (!isEditMode) ...[
            const SizedBox(height: 4),
            _VariantList(isEditMode: false),
          ],
        ],
      ),
    );
  }
}

// ── Variant list — reactive ───────────────────────────────────────────────────
class _VariantList extends StatelessWidget {
  final bool isEditMode;

  const _VariantList({required this.isEditMode});

  ProductVariantController get _variantC => Get.find<ProductVariantController>();

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final list =
          isEditMode ? _variantC.editVariantsTemp : _variantC.variantsTemp;

      if (list.isEmpty) return const SizedBox.shrink();

      return Column(
        children: list.asMap().entries.map((entry) {
          final i = entry.key;
          final v = entry.value;
          return Padding(
            padding: const EdgeInsets.only(top: 8),
            child: VariantItemCard(
              variant: v,
              mode: isEditMode ? VariantCardMode.edit : VariantCardMode.add,
              index: i,
              onEdit: () {
                _variantC.prepareEditVariant(i);
                Get.toNamed(
                  AppRoutes.variantForm,
                  arguments: {'index': i, 'isEditMode': isEditMode},
                );
              },
              onDelete: () => isEditMode
                  ? _variantC.deleteVariant(i, isEditMode: true)
                  : _variantC.removeTempVariant(i, isEditMode: false),
            ),
          );
        }).toList(),
      );
    });
  }
}

// ── Add variant row ───────────────────────────────────────────────────────────
class _AddVariantRow extends StatelessWidget {
  final bool isEditMode;

  const _AddVariantRow({required this.isEditMode});

  ProductVariantController get _variantC => Get.find<ProductVariantController>();

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        if (isEditMode) _variantC.clearVariantForm();
        Get.toNamed(
          AppRoutes.variantForm,
          arguments: {'isEditMode': isEditMode},
        );
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                isEditMode ? 'Tambah Varian Baru' : 'Tambah Varian',
                style: TextStyle(
                  color: AppColors.subtext,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            Icon(Icons.arrow_right_rounded, color: Colors.grey.shade400),
          ],
        ),
      ),
    );
  }
}